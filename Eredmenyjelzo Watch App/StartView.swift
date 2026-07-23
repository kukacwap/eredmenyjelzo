import SwiftUI

struct StartView: View {
    @EnvironmentObject private var match: MatchModel
    @EnvironmentObject private var workoutManager: WorkoutManager

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "soccerball")
                .font(.system(size: 36))
                .foregroundStyle(.green)

            Text("Eredményjelző")
                .font(.headline)

            Button {
                workoutManager.startWorkout()
                match.start()
            } label: {
                Label("Meccs indítása", systemImage: "play.fill")
            }
            .tint(.green)
            .buttonStyle(.borderedProminent)

            Text("Labdarúgás edzésként rögzítjük")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 4)
        .onAppear {
            workoutManager.requestAuthorization()
        }
    }
}
