import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var match: MatchModel

    var body: some View {
        List {
            if !match.history.isEmpty {
                summarySection
            }

            ForEach(match.history) { record in
                NavigationLink {
                    MatchDetailView(record: record)
                } label: {
                    row(record)
                }
            }
            .onDelete { match.deleteHistory(at: $0) }

            if match.history.isEmpty {
                Text("Még nincs lejátszott meccs.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Meccsek")
    }

    private var summarySection: some View {
        let summary = match.historySummary
        return VStack(alignment: .leading, spacing: 3) {
            Text("\(summary.matches) meccs")
                .font(.footnote.weight(.semibold))

            HStack(spacing: 6) {
                Text("\(summary.wins) Gy").foregroundStyle(.green)
                Text("\(summary.draws) D").foregroundStyle(.secondary)
                Text("\(summary.losses) V").foregroundStyle(.red)
            }
            .font(.caption2)

            Text("Gólok: \(summary.goalsFor)–\(summary.goalsAgainst) (\(summary.goalDifference >= 0 ? "+" : "")\(summary.goalDifference))")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private func row(_ record: MatchRecord) -> some View {
        HStack(spacing: 8) {
            Text(record.outcome.label)
                .font(.caption2.weight(.heavy))
                .foregroundStyle(outcomeColor(record.outcome))
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text("\(record.greenScore)")
                        .foregroundStyle(.green)
                    Text("–")
                        .foregroundStyle(.secondary)
                    Text("\(record.whiteScore)")
                        .foregroundStyle(.white)
                }
                .font(.body.weight(.bold).monospacedDigit())

                Text(record.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func outcomeColor(_ outcome: MatchRecord.Outcome) -> Color {
        switch outcome {
        case .win: return .green
        case .draw: return .secondary
        case .loss: return .red
        }
    }
}

struct MatchDetailView: View {
    let record: MatchRecord

    var body: some View {
        ScrollView {
            MatchSummaryContent(record: record)
        }
        .navigationTitle(record.date.formatted(date: .abbreviated, time: .omitted))
    }
}
