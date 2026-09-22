import SwiftUI

/// A mozgás-hőtérkép rajza.
///
/// A tárolt 16×10-es rácsot enyhén elmossuk és felnagyítjuk, hogy ne legyen kockás.
/// Az intenzitás gyökös: lineáris skálán a legsűrűbb folt mindent elnyomna, és a
/// kapuban töltött percek vagy a szélső játék sötétkékbe veszne.
struct PitchHeatmapView: View {
    let heatmap: PitchHeatmap
    /// A tiszta játékidő – ebből számoljuk, a meccs mekkora részéről van helyadat.
    var playedTime: TimeInterval = 0
    /// Ha meg van adva, tükrözni is lehet, és az új tájolás ide kerül mentésre.
    var onChange: ((PitchHeatmap) -> Void)?

    /// Ennyiszeres felbontásban rajzolunk a tárolt rácshoz képest.
    private static let upscale = 3
    /// Ez alatt a gyökös intenzitás alatt nem festünk – ott látszik a pálya.
    private static let visibleThreshold = 0.08

    private static let ramp: [(stop: Double, red: Double, green: Double, blue: Double)] = [
        (0.00, 0.10, 0.16, 0.42),
        (0.30, 0.16, 0.44, 0.80),
        (0.55, 0.25, 0.78, 0.78),
        (0.78, 0.95, 0.80, 0.25),
        (1.00, 0.90, 0.22, 0.18)
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
            let values = Self.blurred(heatmap.cells)
            let peak = max(values.max() ?? 0, 0.001)
            let columns = PitchHeatmap.columns * Self.upscale
            let rows = PitchHeatmap.rows * Self.upscale
            let cellWidth = size.width / CGFloat(columns)
            let cellHeight = size.height / CGFloat(rows)

            context.fill(Path(CGRect(origin: .zero, size: size)),
                         with: .color(Color(white: 0.11)))

            for row in 0..<rows {
                for column in 0..<columns {
                    let value = Self.sample(values,
                                            column: Double(column) / Double(Self.upscale),
                                            row: Double(row) / Double(Self.upscale))
                    let intensity = (value / peak).squareRoot()
                    guard intensity > Self.visibleThreshold else { continue }
                    // Fél pont túlnyúlás, hogy ne legyenek hajszálrések a cellák közt.
                    let rect = CGRect(x: CGFloat(column) * cellWidth,
                                      y: CGFloat(row) * cellHeight,
                                      width: cellWidth + 0.5,
                                      height: cellHeight + 0.5)
                    context.fill(Path(rect), with: .color(Self.color(for: intensity)))
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

    private static func color(for intensity: Double) -> Color {
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
        return Color(red: lower.red + (upper.red - lower.red) * position,
                     green: lower.green + (upper.green - lower.green) * position,
                     blue: lower.blue + (upper.blue - lower.blue) * position)
            .opacity(0.3 + 0.7 * value)
    }
}
