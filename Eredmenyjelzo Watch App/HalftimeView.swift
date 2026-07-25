import SwiftUI

struct HalftimeView: View {
    @EnvironmentObject private var match: MatchModel
    @EnvironmentObject private var workoutManager: WorkoutManager

    @State private var isMenuPresented = false

    var body: some View {
        VStack(spacing: 6) {
            Text("FÉLIDŐ")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(.yellow)
                .tracking(1.5)

            HStack(spacing: 8) {
                Text("\(match.greenScore)")
                    .foregroundStyle(.green)
                Text("–")
                    .foregroundStyle(.secondary)
                Text("\(match.whiteScore)")
                    .foregroundStyle(.white)
            }
            .font(.system(size: 40, weight: .heavy, design: .rounded).monospacedDigit())
            .minimumScaleFactor(0.5)
            .lineLimit(1)

            Text("1. félidő: \(MatchStore.formatClock(match.firstHalfTime))")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button {
                workoutManager.resumeWorkout()
                match.startSecondHalf()
            } label: {
                Label("2. félidő", systemImage: "play.fill")
            }
            .tint(.green)
            .buttonStyle(.borderedProminent)
            .padding(.top, 2)

            Button {
                isMenuPresented = true
            } label: {
                Label("Menü", systemImage: "ellipsis.circle")
                    .font(.footnote)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
        .sheet(isPresented: $isMenuPresented) {
            MenuView()
        }
    }
}
