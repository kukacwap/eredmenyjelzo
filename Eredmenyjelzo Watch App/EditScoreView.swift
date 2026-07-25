import SwiftUI

struct EditScoreView: View {
    @EnvironmentObject private var match: MatchModel

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(Team.allCases) { team in
                    teamRow(team)
                }

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

    private func teamRow(_ team: Team) -> some View {
        let color: Color = team == .green ? .green : .white
        return VStack(spacing: 4) {
            Text(team.displayName)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(color)

            HStack(spacing: 8) {
                Button {
                    match.removeGoal(from: team)
                } label: {
                    Image(systemName: "minus")
                }

                Text("\(match.score(for: team))")
                    .font(.title2.weight(.bold).monospacedDigit())
                    .foregroundStyle(color)
                    .frame(minWidth: 36)

                Button {
                    match.goal(for: team)
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))
    }
}
