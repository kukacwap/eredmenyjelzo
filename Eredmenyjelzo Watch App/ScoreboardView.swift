import SwiftUI
import WatchKit

struct ScoreboardView: View {
    @EnvironmentObject private var match: MatchModel

    @State private var crownValue: Double = 0
    @State private var accumulatedRotation: Double = 0
    @State private var goalCooldownUntil: Date = .distantPast
    @State private var isMenuPresented = false

    /// Ennyi kattanásnyi tekerés kell egy gólhoz, hogy a véletlen érintés ne számoljon.
    private let goalThreshold: Double = 3
    /// Gól után ennyi ideig nem fogadunk újabb tekerést, hogy ne duplázzon.
    private let goalCooldown: TimeInterval = 1.2

    var body: some View {
        GeometryReader { geo in
            ZStack {
                VStack(spacing: 0) {
                    scoreText(match.greenScore, color: .green, rowHeight: scoreRowHeight(in: geo.size.height))
                    clock
                    scoreText(match.whiteScore, color: .white, rowHeight: scoreRowHeight(in: geo.size.height))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                HStack {
                    Spacer()
                    menuButton
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea(edges: .horizontal)
        .focusable()
        .digitalCrownRotation(
            $crownValue,
            from: -1_000,
            through: 1_000,
            by: 1,
            sensitivity: .low,
            isContinuous: true,
            isHapticFeedbackEnabled: false
        )
        .onChange(of: crownValue) { oldValue, newValue in
            handleCrown(delta: newValue - oldValue)
        }
        .sheet(isPresented: $isMenuPresented) {
            MenuView()
        }
    }

    /// A futó óra hozzávetőleges magassága, hogy a két szám eloszthassa a maradék helyet.
    private var clockHeight: CGFloat { match.showClock ? 22 : 0 }

    /// A rendelkezésre álló magasságból kiszámolt egy-egy szám sormagassága,
    /// hogy a számok minden kijelzőméreten a lehető legnagyobbak legyenek.
    private func scoreRowHeight(in totalHeight: CGFloat) -> CGFloat {
        max(0, (totalHeight - clockHeight) / 2)
    }

    private func scoreText(_ score: Int, color: Color, rowHeight: CGFloat) -> some View {
        // A sormagasság ~1,2× a pontméretnek, ezért kicsit kisebb pontméret tölti ki
        // a sávot függőleges levágás nélkül.
        Text("\(score)")
            .font(.system(size: rowHeight * 0.82, weight: .heavy, design: .rounded).monospacedDigit())
            .foregroundStyle(color)
            .minimumScaleFactor(0.3)
            .lineLimit(1)
            .frame(maxWidth: .infinity, minHeight: rowHeight, maxHeight: rowHeight)
    }

    @ViewBuilder
    private var clock: some View {
        if match.showClock {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(MatchModel.format(match.elapsedTime(at: context.date)))
                    .font(.system(size: 16, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.yellow)
            }
            .frame(height: clockHeight)
        }
    }

    private var menuButton: some View {
        Button {
            isMenuPresented = true
        } label: {
            Image(systemName: "ellipsis.circle.fill")
                .font(.system(size: 24))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.gray)
                .frame(width: 40, height: 64)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func handleCrown(delta: Double) {
        // A folytonos tartomány átfordulásakor keletkező nagy ugrás nem tekerés.
        guard abs(delta) < 100 else { return }

        guard Date() >= goalCooldownUntil else {
            accumulatedRotation = 0
            return
        }

        if delta * accumulatedRotation < 0 {
            accumulatedRotation = 0
        }
        accumulatedRotation += delta

        if accumulatedRotation >= goalThreshold {
            registerGoal(for: .green)
        } else if accumulatedRotation <= -goalThreshold {
            registerGoal(for: .white)
        }
    }

    private func registerGoal(for team: Team) {
        match.goal(for: team)
        accumulatedRotation = 0
        goalCooldownUntil = Date().addingTimeInterval(goalCooldown)
    }
}
