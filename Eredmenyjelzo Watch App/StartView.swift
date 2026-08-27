import SwiftUI
import UserNotifications

struct StartView: View {
    @EnvironmentObject private var match: MatchModel
    @EnvironmentObject private var workoutManager: WorkoutManager
    @EnvironmentObject private var pitchTracker: PitchTracker

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
                    startTrackingIfEnabled()
                    match.startMatch()
                } label: {
                    Label(hasResumableMatch ? "Új meccs" : "Meccs indítása", systemImage: "play.fill")
                }
                .tint(.green)
                .buttonStyle(.borderedProminent)

                if !match.history.isEmpty {
                    NavigationLink {
                        HistoryView()
                    } label: {
                        Label("Meccsek (\(match.history.count))", systemImage: "list.bullet")
                            .font(.caption2)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }

                if workoutManager.healthKitProblem != nil {
                    Label("Nincs pulzusmérés", systemImage: "heart.slash")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }

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
            match.requestAlertAuthorization()
            hasResumableMatch = match.hasResumableMatch
        }
    }

    /// A hőtérkép opcionális, ezért csak akkor nyúlunk a helyadatokhoz, ha be van kapcsolva.
    private func startTrackingIfEnabled() {
        guard match.pitchHeatmapEnabled else { return }
        pitchTracker.start()
    }

    /// Félbehagyott meccs folytatása – pl. ha a rendszer kilőtte az appot.
    private var resumeSection: some View {
        VStack(spacing: 3) {
            Text("Félbehagyott meccs: \(match.savedScoreSummary ?? "")")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Button {
                workoutManager.startWorkout()
                startTrackingIfEnabled()
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
    @EnvironmentObject private var workoutManager: WorkoutManager
    @EnvironmentObject private var pitchTracker: PitchTracker

    @State private var notificationsDenied = false

    var body: some View {
        List {
            if let problem = workoutManager.healthKitProblem {
                Label(problem, systemImage: "heart.slash")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }

            Picker(selection: Binding(get: { match.halfLengthMinutes },
                                      set: { match.halfLengthMinutes = $0 })) {
                ForEach(MatchSettings.halfLengthOptions, id: \.self) { minutes in
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

            Picker(selection: Binding(get: { match.keeperIntervalSeconds },
                                      set: { match.keeperIntervalSeconds = $0 })) {
                ForEach(MatchSettings.keeperIntervalOptions, id: \.self) { seconds in
                    Text(MatchStore.formatKeeperInterval(seconds)).tag(seconds)
                }
            } label: {
                Label("Kapuscsere", systemImage: "hand.raised.fill")
            }

            Text("Kapuscsere: ennyi játékidőnként 2 másodperces rezgés jelzi, hogy jön a csere. Szünetben nem számol tovább.")
                .font(.caption2)
                .foregroundStyle(.secondary)

            if notificationsDenied && match.keeperIntervalSeconds > 0 {
                Label("Az értesítések le vannak tiltva, ezért csuklóleengedve nem fogod érezni a jelzést. Kapcsold be: Óra → Beállítások → Értesítések → Eredményjelző.",
                      systemImage: "exclamationmark.triangle.fill")
                    .font(.caption2)
                    .foregroundStyle(.red)
            }

            Text("Ha játék közben nem érzed: Beállítások → Hangok és haptika → Haptika erőssége feljebb, és a Kiemelt haptika bekapcsolva.")
                .font(.caption2)
                .foregroundStyle(.orange)

            Toggle(isOn: Binding(get: { match.pitchHeatmapEnabled },
                                 set: { enabled in
                                     match.pitchHeatmapEnabled = enabled
                                     if enabled { pitchTracker.requestAuthorization() }
                                 })) {
                Label("Mozgás-hőtérkép", systemImage: "map")
            }

            Text("Csak nyílt terepen működik, fedett pályán nincs GPS-jel. Hagyd a telefont hatótávon kívül – különben az óra annak a helyadatát veheti át, és a térkép a partvonalra ragad.")
                .font(.caption2)
                .foregroundStyle(.secondary)

            if let problem = pitchTracker.locationProblem {
                Label(problem, systemImage: "location.slash")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }

            Text("Action Button: gól a saját csapatnak. Double Tap és a bal oldali + gomb: gól az ellenfélnek.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Beállítások")
        .task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            notificationsDenied = settings.authorizationStatus == .denied
        }
    }
}
