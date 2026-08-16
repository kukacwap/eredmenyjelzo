import SwiftUI

struct SummaryView: View {
    @EnvironmentObject private var match: MatchModel

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("VÉGEREDMÉNY")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(.secondary)
                    .tracking(1.2)

                if let record = match.lastRecord {
                    MatchSummaryContent(record: record)
                }

                Button {
                    match.reset()
                } label: {
                    Label("Kész", systemImage: "checkmark")
                }
                .tint(.green)
                .buttonStyle(.borderedProminent)
                .padding(.top, 4)

                Text("A meccs elmentve a történetbe.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
