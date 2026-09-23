import SwiftUI

/// A mozgás-hőtérkép rajza.
///
/// A tárolt 16×10-es rácsot enyhén elmossuk és felnagyítjuk, hogy ne legyen kockás.
/// A színskála két végét az egyenletes eloszláshoz mérjük, nem a legsűrűbb folthoz:
/// csúcshoz mérve egy tömör folt mellett a középen és elöl töltött idő ugyanolyan
/// kék lett, mint ahol sosem jártál. Így ahol nem jártál, ott a sötét pálya látszik,
/// a kevés idő is már színes, és csak a tényleg sűrű folt lesz piros.
struct PitchHeatmapView: View {
    let heatmap: PitchHeatmap
    /// A tiszta játékidő – ebből számoljuk, a meccs mekkora részéről van helyadat.
    var playedTime: TimeInterval = 0
    /// Ha meg van adva, tükrözni is lehet, és az új tájolás ide kerül mentésre.
    var onChange: ((PitchHeatmap) -> Void)?

    /// Ennyiszeres felbontásban rajzolunk a tárolt rácshoz képest. Átlátszatlan
    /// festésnél 3× mellett a foltok széle már lépcsősnek látszott.
    private static let upscale = 4
    /// A térkép háttere. A színeket előre erre keverjük, és átlátszatlanul festünk:
    /// az egymásba lógó, félig átlátszó cellák duplán festett széle rácsvonalnak látszott.
    private static let background = 0.11
    /// Az egyenletes eloszlás cellánkénti idejének ennyiszerese alatt nem festünk –
    /// ennyi pár elkóborolt GPS-fix, ott tényleg nem jártál.
    private static let visibleOfUniform = 0.1
    /// Eddig úszik be a szín a háttérből, hogy a „nem jártál" és a „kevés" határa ne
    /// legyen éles – a GPS 3–5 m-es hibája mellett nem is éles.
    private static let solidOfUniform = 0.25
    /// A beúszás kezdete: a küszöbnél ennyire fedi a szín a hátteret.
    private static let minimumOpacity = 0.15
    /// A skála teteje legalább az egyenletes sűrűség négyszerese: ha az idő
    /// egyenletesen oszlott el (középpályás), a legsűrűbb cella se legyen piros.
    private static let topOfUniform = 4.0

    /// Gyökös intenzitásra. A kék csak a küszöbnél marad: a kevés idő kékeszöld, a
    /// közepes zöld, a sok sárgától pirosig – így a kevés sem olvad a háttérbe.
    private static let ramp: [(stop: Double, red: Double, green: Double, blue: Double)] = [
        (0.00, 0.08, 0.28, 0.36),
        (0.22, 0.10, 0.50, 0.53),
        (0.40, 0.30, 0.68, 0.36),
        (0.60, 0.91, 0.83, 0.28),
        (0.80, 0.97, 0.52, 0.16),
        (1.00, 0.88, 0.18, 0.16)
    ]

    var body: some View {
        VStack(spacing: 4) {
            map

            thirdsLine

            if onChange != nil {
                HStack(spacing: 6) {
                    Button {
                        onChange?(heatmap.mirroredLengthwise())
                    } label: {
                        Image(systemName: "arrow.left.and.right")
                    }
                    Text("Saját kapu: bal oldalt")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                    Button {
                        onChange?(heatmap.mirroredWidthwise())
                    } label: {
                        Image(systemName: "arrow.up.and.down")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }

            Text(diagnostics)
                .font(.system(size: 9).monospacedDigit())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var map: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)),
                         with: .color(Color(white: Self.background)))

            let values = Self.blurred(heatmap.cells)
            // Sérült, rossz méretű rácsnál csak az üres pálya látszik, ne omoljon össze.
            guard values.count == PitchHeatmap.columns * PitchHeatmap.rows else { return }
            // Egyenletes eloszlásnál ennyi idő jutna egy cellára.
            let uniform = heatmap.totalTime / Double(PitchHeatmap.columns * PitchHeatmap.rows)
            let top = max(values.max() ?? 0, uniform * Self.topOfUniform, 0.001)
            let visible = uniform * Self.visibleOfUniform
            let solid = uniform * Self.solidOfUniform
            let columns = PitchHeatmap.columns * Self.upscale
            let rows = PitchHeatmap.rows * Self.upscale
            let cellWidth = size.width / CGFloat(columns)
            let cellHeight = size.height / CGFloat(rows)
            // Élsimítva a cellák széle a háttérrel keveredne, és hajszálvonal maradna köztük.
            let crisp = FillStyle(antialiased: false)

            for row in 0..<rows {
                for column in 0..<columns {
                    // A kis cella közepét mintavételezzük: a tárolt érték a rácscella
                    // közepéhez tartozik, különben a kép majdnem fél cellával balra-fel csúszna.
                    let value = Self.sample(values,
                                            column: (Double(column) + 0.5) / Double(Self.upscale) - 0.5,
                                            row: (Double(row) + 0.5) / Double(Self.upscale) - 0.5)
                    guard value > visible else { continue }
                    let intensity = min(1, value / top).squareRoot()
                    let presence = min(1, (value - visible) / (solid - visible))
                    // Fél pont túlnyúlás, hogy ne legyenek rések a cellák közt; a szín
                    // átlátszatlan, így az átfedés nem festődik kétszer.
                    let rect = CGRect(x: CGFloat(column) * cellWidth,
                                      y: CGFloat(row) * cellHeight,
                                      width: cellWidth + 0.5,
                                      height: cellHeight + 0.5)
                    let opacity = Self.minimumOpacity + (1 - Self.minimumOpacity) * presence
                    context.fill(Path(rect),
                                 with: .color(Self.color(for: intensity, opacity: opacity)),
                                 style: crisp)
                }
            }
        }
        .aspectRatio(CGFloat(PitchHeatmap.columns) / CGFloat(PitchHeatmap.rows),
                     contentMode: .fit)
        .overlay {
            // A mozgásterület kerete, felezővonala és a saját kapu jele a bal szélen.
            // A valódi pálya vonalait GPS-ből nem ismerjük, ezért 16-ost nem rajzolunk.
            GeometryReader { geometry in
                let size = geometry.size
                Path { path in
                    path.addRect(CGRect(origin: .zero, size: size))
                    path.move(to: CGPoint(x: size.width / 2, y: 0))
                    path.addLine(to: CGPoint(x: size.width / 2, y: size.height))
                }
                .stroke(Color.white.opacity(0.3), lineWidth: 1)

                Rectangle()
                    .fill(Color.white.opacity(0.85))
                    .frame(width: 3, height: size.height * 0.3)
                    .position(x: 1.5, y: size.height / 2)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    /// Harmadokra bontva a GPS-zaj sokkal kevésbé számít, mint cellánként – ez a
    /// sor akkor is megbízható, ha a térkép maga elmosódott.
    private var thirdsLine: some View {
        let thirds = heatmap.thirds
        return HStack(spacing: 0) {
            thirdLabel("Hátul", thirds.back)
            thirdLabel("Középen", thirds.middle)
            thirdLabel("Elöl", thirds.front)
        }
    }

    private func thirdLabel(_ title: String, _ share: Double) -> some View {
        VStack(spacing: 0) {
            Text("\(Int((share * 100).rounded()))%")
                .font(.system(size: 13, weight: .bold, design: .rounded).monospacedDigit())
            Text(title)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    /// Ebből látszik, lehet-e hinni a képnek: mekkora terület, a meccs mekkora
    /// részéről van adat, és mennyire volt pontos a GPS.
    private var diagnostics: String {
        var parts = ["Mozgásterület \(heatmap.sizeLabel)"]
        if playedTime > 0 {
            let covered = Int((min(heatmap.totalTime, playedTime) / 60).rounded())
            let total = Int((playedTime / 60).rounded())
            parts.append("helyadat \(covered)/\(total) perc")
        }
        if let accuracy = heatmap.medianAccuracy {
            parts.append(String(format: "±%.0f m", accuracy))
        }
        return parts.joined(separator: " · ")
    }

    // MARK: - Rács

    /// Egyszeres 3×3-as átlagolás. Kettő már a kaput is beleolvasztaná a környezetébe.
    private static func blurred(_ cells: [Double]) -> [Double] {
        guard cells.count == PitchHeatmap.columns * PitchHeatmap.rows else { return cells }
        var next = cells
        for row in 0..<PitchHeatmap.rows {
            for column in 0..<PitchHeatmap.columns {
                var total = 0.0
                var neighbours = 0.0
                for rowOffset in -1...1 {
                    for columnOffset in -1...1 {
                        let r = row + rowOffset
                        let c = column + columnOffset
                        guard r >= 0, r < PitchHeatmap.rows,
                              c >= 0, c < PitchHeatmap.columns else { continue }
                        total += cells[r * PitchHeatmap.columns + c]
                        neighbours += 1
                    }
                }
                next[row * PitchHeatmap.columns + column] = total / neighbours
            }
        }
        return next
    }

    private static func sample(_ values: [Double], column: Double, row: Double) -> Double {
        func at(_ c: Int, _ r: Int) -> Double {
            let clampedColumn = min(max(c, 0), PitchHeatmap.columns - 1)
            let clampedRow = min(max(r, 0), PitchHeatmap.rows - 1)
            return values[clampedRow * PitchHeatmap.columns + clampedColumn]
        }

        let column0 = Int(floor(column))
        let row0 = Int(floor(row))
        let columnFraction = column - Double(column0)
        let rowFraction = row - Double(row0)

        let top = at(column0, row0) * (1 - columnFraction) + at(column0 + 1, row0) * columnFraction
        let bottom = at(column0, row0 + 1) * (1 - columnFraction)
            + at(column0 + 1, row0 + 1) * columnFraction
        return top * (1 - rowFraction) + bottom * rowFraction
    }

    /// A skála színe előre a háttérre keverve – `opacity` a háttérből való beúszás.
    private static func color(for intensity: Double, opacity: Double) -> Color {
        let value = min(1, max(0, intensity))
        var lower = ramp[0]
        var upper = ramp[ramp.count - 1]
        for index in 0..<(ramp.count - 1) where value >= ramp[index].stop && value <= ramp[index + 1].stop {
            lower = ramp[index]
            upper = ramp[index + 1]
            break
        }

        let span = upper.stop - lower.stop
        let position = span > 0 ? (value - lower.stop) / span : 0
        func mixed(_ from: Double, _ to: Double) -> Double {
            let channel = from + (to - from) * position
            return background + (channel - background) * opacity
        }
        return Color(red: mixed(lower.red, upper.red),
                     green: mixed(lower.green, upper.green),
                     blue: mixed(lower.blue, upper.blue))
    }
}
