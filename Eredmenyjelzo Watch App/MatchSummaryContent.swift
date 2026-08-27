import SwiftUI

/// A meccs összegzése – ugyanezt mutatja a záróképernyő és a történet egy eleme is.
struct MatchSummaryContent: View {
    let record: MatchRecord

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Text("\(record.greenScore)")
                    .foregroundStyle(.green)
                Text("–")
                    .foregroundStyle(.secondary)
                Text("\(record.whiteScore)")
                    .foregroundStyle(.white)
            }
            .font(.system(size: 44, weight: .heavy, design: .rounded).monospacedDigit())
            .minimumScaleFactor(0.5)
            .lineLimit(1)

            HeartRateGoalChart(record: record)

            statRow(icon: "stopwatch",
                    label: "Játékidő",
                    value: MatchStore.formatClock(record.playedTime),
                    tint: .yellow)

            if record.averageHeartRate > 0 {
                statRow(icon: "heart.fill",
                        label: "Átlag pulzus",
                        value: "\(Int(record.averageHeartRate))",
                        tint: .red)
            }

            if record.maxHeartRate > 0 {
                statRow(icon: "arrow.up.heart.fill",
                        label: "Max pulzus",
                        value: "\(Int(record.maxHeartRate))",
                        tint: .red)
            }

            if record.activeEnergy > 0 {
                statRow(icon: "flame.fill",
                        label: "Kalória",
                        value: "\(Int(record.activeEnergy)) kcal",
                        tint: .orange)
            }

            if let heatmap = record.heatmap {
                PitchHeatmapView(heatmap: heatmap)
                    .padding(.top, 2)
            } else if let note = record.heatmapNote {
                Label(note, systemImage: "map")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }

            if !record.goals.isEmpty {
                goalTimeline
            }
        }
        .padding(.horizontal, 2)
    }

    private func statRow(icon: String, label: String, value: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .frame(width: 16)
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .monospacedDigit()
        }
        .font(.footnote)
    }

    private var goalTimeline: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Gólok")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundStyle(.secondary)
                .tracking(1.2)
                .padding(.top, 4)

            ForEach(record.goals) { goal in
                HStack(spacing: 6) {
                    Circle()
                        .fill(goal.team == .green ? Color.green : Color.white)
                        .frame(width: 7, height: 7)
                    Text(goal.team.displayName)
                        .foregroundStyle(goal.team == .green ? Color.green : Color.white)
                    Spacer()
                    if let bpm = record.heartRate(at: goal.matchTime) {
                        Text("\(Int(bpm))")
                            .foregroundStyle(.red)
                            .monospacedDigit()
                        Image(systemName: "heart.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.red)
                    }
                    Text(MatchStore.formatMinute(goal.matchTime))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .frame(minWidth: 28, alignment: .trailing)
                }
                .font(.footnote)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A meccs pulzusgörbéje, rárajzolt gólokkal. Ha nincs pulzusadat, csak a gólok
/// idővonala látszik – így HealthKit-engedély nélkül is mond valamit.
struct HeartRateGoalChart: View {
    let record: MatchRecord

    private var samples: [HeartRateSample] { record.heartRateSamples }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(samples.isEmpty ? "GÓLOK IDŐRENDBEN" : "PULZUS ÉS GÓLOK")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(.secondary)
                    .tracking(1)
                Spacer()
                if let range = bpmRange {
                    Text("\(Int(range.lowerBound))–\(Int(range.upperBound))")
                        .font(.system(size: 9, design: .rounded).monospacedDigit())
                        .foregroundStyle(.red)
                }
            }

            GeometryReader { geo in
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.06))

                    if samples.count > 1 {
                        heartRatePath(in: geo.size)
                            .stroke(Color.red.opacity(0.9),
                                    style: StrokeStyle(lineWidth: 1.5, lineJoin: .round))
                    } else {
                        // Nincs pulzusgörbe: középvonal, amihez a gólok igazodnak.
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: geo.size.height / 2))
                            path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height / 2))
                        }
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    }

                    ForEach(record.goals) { goal in
                        goalMarker(goal, in: geo.size)
                    }
                }
            }
            .frame(height: 58)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Skálázás

    private var bpmRange: ClosedRange<Double>? {
        let values = samples.map(\.bpm)
        guard let low = values.min(), let high = values.max() else { return nil }
        // Egyenletes pulzusnál se legyen nulla magas a sáv.
        return high - low < 5 ? (low - 5)...(high + 5) : low...high
    }

    private func x(for time: TimeInterval, in size: CGSize) -> CGFloat {
        let end = max(record.timelineEnd, 1)
        return size.width * CGFloat(min(max(time, 0), end) / end)
    }

    private func y(for bpm: Double, in size: CGSize) -> CGFloat {
        guard let range = bpmRange, range.upperBound > range.lowerBound else {
            return size.height / 2
        }
        let ratio = (bpm - range.lowerBound) / (range.upperBound - range.lowerBound)
        // 4 pont ráhagyás fent és lent, hogy a görbe ne érjen a keret széléhez.
        return size.height - 4 - CGFloat(ratio) * (size.height - 8)
    }

    private func heartRatePath(in size: CGSize) -> Path {
        Path { path in
            for (index, sample) in samples.enumerated() {
                let point = CGPoint(x: x(for: sample.matchTime, in: size),
                                    y: y(for: sample.bpm, in: size))
                if index == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
        }
    }

    private func goalMarker(_ goal: GoalEvent, in size: CGSize) -> some View {
        let color: Color = goal.team == .green ? .green : .white
        let markerX = x(for: goal.matchTime, in: size)
        // Pulzus híján a csapat oldalára tesszük a jelölőt, a középvonal fölé/alá.
        let markerY = record.heartRate(at: goal.matchTime).map { y(for: $0, in: size) }
            ?? (goal.team == .green ? size.height * 0.3 : size.height * 0.7)

        return ZStack {
            Path { path in
                path.move(to: CGPoint(x: markerX, y: 0))
                path.addLine(to: CGPoint(x: markerX, y: size.height))
            }
            .stroke(color.opacity(0.35), lineWidth: 1)

            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .position(x: markerX, y: markerY)
        }
    }
}
