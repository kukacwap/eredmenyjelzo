import SwiftUI

struct MenuView: View {
    @EnvironmentObject private var match: MatchModel
    @EnvironmentObject private var workoutManager: WorkoutManager
    @EnvironmentObject private var pitchTracker: PitchTracker
    @Environment(\.dismiss) private var dismiss

    @State private var isEndConfirmationPresented = false

    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    EditScoreView()
                } label: {
                    Label("Eredmény szerkesztése", systemImage: "plusminus.circle")
                }

                if match.phase.isPlaying {
                    Button {
                        if match.isClockRunning {
                            match.pauseClock()
                            workoutManager.pauseWorkout()
                            pitchTracker.pause()
                        } else {
                            match.resumeClock()
                            workoutManager.resumeWorkout()
                            pitchTracker.resume()
                        }
                        dismiss()
                    } label: {
                        Label(match.isClockRunning ? "Óra megállítása" : "Óra folytatása",
                              systemImage: match.isClockRunning ? "pause.circle" : "play.circle")
                    }
                }

                if match.phase == .firstHalf {
                    Button {
                        match.startHalftime()
                        workoutManager.pauseWorkout()
                        pitchTracker.pause()
                        dismiss()
                    } label: {
                        Label("Félidő", systemImage: "flag.2.crossed")
                    }
                }

                Toggle(isOn: Binding(get: { match.showClock },
                                     set: { match.showClock = $0 })) {
                    Label("Futó óra mutatása", systemImage: "stopwatch")
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

                if match.timeUntilKeeperChange(at: Date()) != nil {
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        HStack {
                            Label("Következő csere", systemImage: "timer")
                            Spacer()
                            Text(MatchStore.formatClock(match.timeUntilKeeperChange(at: context.date) ?? 0))
                                .monospacedDigit()
                        }
                        .foregroundStyle(.orange)
                    }
                }

                if workoutManager.heartRate > 0 {
                    HStack {
                        Label("Pulzus", systemImage: "heart.fill")
                        Spacer()
                        Text("\(Int(workoutManager.heartRate))")
                            .monospacedDigit()
                    }
                    .foregroundStyle(.red)
                }

                Button(role: .destructive) {
                    isEndConfirmationPresented = true
                } label: {
                    Label("Meccs befejezése", systemImage: "flag.checkered")
                }
            }
            .navigationTitle("Menü")
            .confirmationDialog("Biztosan befejezed a meccset?",
                                isPresented: $isEndConfirmationPresented,
                                titleVisibility: .visible) {
                Button("Meccs vége", role: .destructive) {
                    workoutManager.endWorkout()
                    let track = pitchTracker.finish(workoutDistanceMeters: workoutManager.distanceMeters)
                    match.endMatch(averageHeartRate: workoutManager.averageHeartRate,
                                   maxHeartRate: workoutManager.maxHeartRate,
                                   activeEnergy: workoutManager.activeEnergy,
                                   heatmap: track.heatmap,
                                   heatmapNote: track.note)
                    dismiss()
                }
                Button("Mégse", role: .cancel) {}
            }
        }
    }
}
