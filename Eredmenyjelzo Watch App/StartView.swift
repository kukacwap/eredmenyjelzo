import SwiftUI

struct StartView: View {
    @EnvironmentObject private var match: MatchModel
    @EnvironmentObject private var workoutManager: WorkoutManager

    @State private var hasResumableMatch = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 7) {
                Image(systemName: "soccerball")
                    .font(.system(size: 28))
                    .foregroundStyle(.green)

                if hasResumableMatch {
                    resumeSection
                }

                Button {
                    workoutManager.startWorkout()
                    match.startMatch()
                } label: {
                    Label(hasResumableMatch ? "Új meccs" : "Meccs indítása", systemImage: "play.fill")
                }
                .tint(.green)
                .buttonStyle(.borderedProminent)

                NavigationLink {
                    MatchSettingsView()
                } label: {
                    Label("\(match.halfLengthMinutes) perc · \(match.myTeam.displayName)",
                          systemImage: "slider.horizontal.3")
                        .font(.caption2)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)
            .navigationTitle("Eredményjelző")
        }
        .onAppear {
            workoutManager.requestAuthorization()
            hasResumableMatch = match.hasResumableMatch
        }
    }

    /// Félbehagyott meccs folytatása – pl. ha a rendszer kilőtte az appot.
    private var resumeSection: some View {
        VStack(spacing: 3) {
            Text("Félbehagyott meccs: \(match.savedScoreSummary ?? "")")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Button {
                workoutManager.startWorkout()
                match.resumeSavedMatch()
            } label: {
                Label("Folytatás", systemImage: "arrow.clockwise")
            }
            .tint(.yellow)
            .buttonStyle(.borderedProminent)

            Button("Elvetés") {
                match.discardSavedMatch()
                hasResumableMatch = false
            }
            .font(.caption2)
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
    }
}

struct MatchSettingsView: View {
    @EnvironmentObject private var match: MatchModel

    private let halfLengthOptions = [20, 25, 30, 35, 45]

    var body: some View {
        List {
            Picker(selection: Binding(get: { match.halfLengthMinutes },
                                      set: { match.halfLengthMinutes = $0 })) {
                ForEach(halfLengthOptions, id: \.self) { minutes in
                    Text("\(minutes) perc").tag(minutes)
                }
            } label: {
                Label("Félidő hossza", systemImage: "stopwatch")
            }

            Picker(selection: Binding(get: { match.myTeam },
                                      set: { match.myTeam = $0 })) {
                ForEach(Team.allCases) { team in
                    Text(team.displayName).tag(team)
                }
            } label: {
                Label("Saját csapat", systemImage: "person.fill")
            }

            Text("Action Button: gól a saját csapatnak. Double Tap és a bal oldali + gomb: gól az ellenfélnek.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Beállítások")
    }
}
