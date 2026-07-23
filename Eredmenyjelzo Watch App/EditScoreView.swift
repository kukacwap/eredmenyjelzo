import SwiftUI

struct EditScoreView: View {
    @EnvironmentObject private var match: MatchModel

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                teamRow(name: "Zöld",
                        color: .green,
                        score: match.greenScore,
                        onMinus: { match.removeGoal(from: .green) },
                        onPlus: { match.goal(for: .green) })

                teamRow(name: "Fehér",
                        color: .white,
                        score: match.whiteScore,
                        onMinus: { match.removeGoal(from: .white) },
                        onPlus: { match.goal(for: .white) })

                Button(role: .destructive) {
                    match.resetScore()
                } label: {
                    Label("Nullázás", systemImage: "arrow.counterclockwise")
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 2)
        }
        .navigationTitle("Eredmény")
    }

    private func teamRow(name: String,
                         color: Color,
                         score: Int,
                         onMinus: @escaping () -> Void,
                         onPlus: @escaping () -> Void) -> some View {
        VStack(spacing: 4) {
            Text(name)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(color)

            HStack(spacing: 8) {
                Button(action: onMinus) {
                    Image(systemName: "minus")
                }

                Text("\(score)")
                    .font(.title2.weight(.bold).monospacedDigit())
                    .foregroundStyle(color)
                    .frame(minWidth: 36)

                Button(action: onPlus) {
                    Image(systemName: "plus")
                }
            }
        }
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))
    }
}
