import SwiftUI

/// A mozgás-hőtérkép rajza.
///
/// A tárolt 16×10-es rácsot elmossuk és felnagyítjuk, mert kockás foltokból nem
/// lehet leolvasni semmit – a GPS pontossága amúgy is elmosott képet indokol.
struct PitchHeatmapView: View {
    let heatmap: PitchHeatmap

    /// Ennyiszeres felbontásban rajzolunk a tárolt rácshoz képest.
    private static let upscale = 3

    private static let ramp: [(stop: Double, red: Double, green: Double, blue: Double)] = [
        (0.00, 0.10, 0.16, 0.42),
        (0.30, 0.16, 0.44, 0.80),
        (0.55, 0.25, 0.78, 0.78),
        (0.78, 0.95, 0.80, 0.25),
        (1.00, 0.90, 0.22, 0.18)
    ]

    var body: some View {
        VStack(spacing: 3) {
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
                        let intensity = value / peak
                        guard intensity > 0.03 else { continue }
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
                // Csak a mozgásterület kerete és felezővonala: a valódi pálya
                // vonalait GPS-ből nem ismerjük, ezért nem is rajzolunk kaput vagy 16-ost.
                GeometryReader { geometry in
                    Path { path in
                        path.addRect(CGRect(origin: .zero, size: geometry.size))
                        path.move(to: CGPoint(x: geometry.size.width / 2, y: 0))
                        path.addLine(to: CGPoint(x: geometry.size.width / 2, y: geometry.size.height))
                    }
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 4))

            Text("Mozgásterület · \(heatmap.sizeLabel)")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Rács

    /// Kétszeres 3×3-as átlagolás. Ekkora rácson ez pár száz művelet.
    private static func blurred(_ cells: [Double]) -> [Double] {
        guard cells.count == PitchHeatmap.columns * PitchHeatmap.rows else { return cells }
        var values = cells
        for _ in 0..<2 {
            var next = values
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
                            total += values[r * PitchHeatmap.columns + c]
                            neighbours += 1
                        }
                    }
                    next[row * PitchHeatmap.columns + column] = total / neighbours
                }
            }
            values = next
        }
        return values
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
