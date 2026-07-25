import SwiftUI

struct SummaryView: View {
    @EnvironmentObject private var match: MatchModel
    @EnvironmentObject private var workoutManager: WorkoutManager

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("VÉGEREDMÉNY")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(.secondary)
                    .tracking(1.2)

                HStack(spacing: 8) {
                    Text("\(match.greenScore)")
                        .foregroundStyle(.green)
                    Text("–")
                        .foregroundStyle(.secondary)
                    Text("\(match.whiteScore)")
                        .foregroundStyle(.white)
                }
                .font(.system(size: 44, weight: .heavy, design: .rounded).monospacedDigit())
                .minimumScaleFactor(0.5)
                .lineLimit(1)

                statRow(icon: "stopwatch",
                        label: "Játékidő",
                        value: MatchStore.formatClock(match.totalPlayedTime),
                        tint: .yellow)

                if workoutManager.averageHeartRate > 0 {
                    statRow(icon: "heart.fill",
                            label: "Átlag pulzus",
                            value: "\(Int(workoutManager.averageHeartRate))",
                            tint: .red)
                }

                if workoutManager.maxHeartRate > 0 {
                    statRow(icon: "arrow.up.heart.fill",
                            label: "Max pulzus",
                            value: "\(Int(workoutManager.maxHeartRate))",
                            tint: .red)
                }

                if workoutManager.activeEnergy > 0 {
                    statRow(icon: "flame.fill",
                            label: "Kalória",
                            value: "\(Int(workoutManager.activeEnergy)) kcal",
                            tint: .orange)
                }

                if !match.goals.isEmpty {
                    goalTimeline
                }

                Button {
                    match.reset()
                } label: {
                    Label("Kész", systemImage: "checkmark")
                }
                .tint(.green)
                .buttonStyle(.borderedProminent)
                .padding(.top, 4)
            }
            .padding(.horizontal, 2)
        }
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

            ForEach(match.goals) { goal in
                HStack(spacing: 6) {
                    Circle()
                        .fill(goal.team == .green ? Color.green : Color.white)
                        .frame(width: 7, height: 7)
                    Text(goal.team.displayName)
                        .foregroundStyle(goal.team == .green ? Color.green : Color.white)
                    Spacer()
                    Text(MatchStore.formatMinute(goal.matchTime))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                .font(.footnote)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
