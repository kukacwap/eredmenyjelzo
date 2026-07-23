import SwiftUI

struct MenuView: View {
    @EnvironmentObject private var match: MatchModel
    @EnvironmentObject private var workoutManager: WorkoutManager
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

                Toggle(isOn: $match.showClock) {
                    Label("Futó óra mutatása", systemImage: "stopwatch")
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
                    match.end()
                    dismiss()
                }
                Button("Mégse", role: .cancel) {}
            }
        }
    }
}
