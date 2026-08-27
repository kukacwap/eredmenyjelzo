import SwiftUI

@main
struct EredmenyjelzoApp: App {
    @StateObject private var match = MatchModel()
    @StateObject private var workoutManager = WorkoutManager()
    @StateObject private var pitchTracker = PitchTracker()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(match)
                .environmentObject(workoutManager)
                .environmentObject(pitchTracker)
                .task {
                    // A pulzusértékek a meccs idővonalára kerülnek.
                    workoutManager.heartRateHandler = { [weak match] bpm in
                        match?.recordHeartRate(bpm)
                    }
                }
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var match: MatchModel

    var body: some View {
        switch match.phase {
        case .notStarted:
            StartView()
        case .firstHalf, .secondHalf:
            ScoreboardView()
        case .halftime:
            HalftimeView()
        case .finished:
            SummaryView()
        }
    }
}
