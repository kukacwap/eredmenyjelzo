import SwiftUI
import WatchKit

struct ScoreboardView: View {
    @EnvironmentObject private var match: MatchModel

    /// Always-on kijelzőn igaz: halványítunk, és ritkábban frissítünk.
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    @Environment(\.scenePhase) private var scenePhase

    @State private var crownValue: Double = 0
    @State private var accumulatedRotation: Double = 0
    @State private var goalCooldownUntil: Date = .distantPast
    @State private var isMenuPresented = false
    @State private var flashingTeam: Team?
    @State private var showCrownHints = true

    /// Ennyi kattanásnyi tekerés kell egy gólhoz, hogy a véletlen érintés ne számoljon.
    private let goalThreshold: Double = 3
    /// Gól után ennyi ideig nem fogadunk újabb tekerést, hogy ne duplázzon.
    private let goalCooldown: TimeInterval = 1.2

    var body: some View {
        GeometryReader { geo in
            ZStack {
                teamTints

                VStack(spacing: 0) {
                    scoreText(for: .green, rowHeight: scoreRowHeight(in: geo.size.height))
                    clock
                    scoreText(for: .white, rowHeight: scoreRowHeight(in: geo.size.height))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if showCrownHints && !isLuminanceReduced {
                    crownHints
                }

                if !isLuminanceReduced {
                    sideControls
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
        .onChange(of: match.greenScore) { _, _ in flash(.green) }
        .onChange(of: match.whiteScore) { _, _ in flash(.white) }
        .onChange(of: scenePhase) { _, newPhase in
            // Az Action Button intent külön írja az állást – aktiváláskor beolvassuk.
            if newPhase == .active { match.reloadFromStore() }
        }
        .task {
            try? await Task.sleep(for: .seconds(4))
            withAnimation(.easeOut(duration: 0.4)) { showCrownHints = false }
        }
        .sheet(isPresented: $isMenuPresented) {
            MenuView()
        }
    }

    // MARK: - Háttér

    /// Fél-fél tónus: felül zöld, alul világos – hogy a szám színétől függetlenül is
    /// azonnal látszódjon, melyik csapat melyik.
    private var teamTints: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [Color.green.opacity(isLuminanceReduced ? 0.07 : 0.20), .clear],
                           startPoint: .top, endPoint: .bottom)
            LinearGradient(colors: [.clear, Color.white.opacity(isLuminanceReduced ? 0.05 : 0.14)],
                           startPoint: .top, endPoint: .bottom)
        }
        .ignoresSafeArea()
    }

    // MARK: - Eredmény

    /// A futó óra hozzávetőleges magassága, hogy a két szám eloszthassa a maradék helyet.
    private var clockHeight: CGFloat { match.showClock ? 22 : 0 }

    /// A rendelkezésre álló magasságból kiszámolt egy-egy szám sormagassága,
    /// hogy a számok minden kijelzőméreten a lehető legnagyobbak legyenek.
    private func scoreRowHeight(in totalHeight: CGFloat) -> CGFloat {
        max(0, (totalHeight - clockHeight) / 2)
    }

    private func scoreText(for team: Team, rowHeight: CGFloat) -> some View {
        let color: Color = team == .green ? .green : .white
        let isFlashing = flashingTeam == team
        // A sormagasság ~1,2× a pontméretnek, ezért kicsit kisebb pontméret tölti ki
        // a sávot függőleges levágás nélkül.
        return Text("\(match.score(for: team))")
            .font(.system(size: rowHeight * 0.82, weight: .heavy, design: .rounded).monospacedDigit())
            .foregroundStyle(color.opacity(isLuminanceReduced ? 0.7 : 1))
            .minimumScaleFactor(0.3)
            .lineLimit(1)
            .scaleEffect(isFlashing ? 1.15 : 1)
            .shadow(color: color.opacity(isFlashing ? 0.9 : 0), radius: 14)
            .frame(maxWidth: .infinity, minHeight: rowHeight, maxHeight: rowHeight)
            .accessibilityLabel("\(team.displayName) csapat")
            .accessibilityValue("\(match.score(for: team)) gól")
    }

    /// Rövid felnagyítás + derengés, hogy a szem sarkából is látszódjon a regisztrált gól.
    private func flash(_ team: Team) {
        withAnimation(.spring(response: 0.22, dampingFraction: 0.5)) {
            flashingTeam = team
        }
        Task {
            try? await Task.sleep(for: .milliseconds(280))
            withAnimation(.easeOut(duration: 0.35)) {
                if flashingTeam == team { flashingTeam = nil }
            }
        }
    }

    // MARK: - Óra

    @ViewBuilder
    private var clock: some View {
        if match.showClock {
            // Always-on kijelzőn a rendszer percenként frissít, ezért ott percet mutatunk,
            // hogy ne álljon meg egy elavult másodpercértéken.
            TimelineView(.periodic(from: .now, by: isLuminanceReduced ? 60 : 1)) { context in
                HStack(spacing: 3) {
                    if !match.isClockRunning {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 11, weight: .bold))
                    }
                    Text(isLuminanceReduced
                         ? MatchStore.formatMinute(match.matchTime(at: context.date))
                         : MatchStore.formatClock(match.matchTime(at: context.date)))
                        .font(.system(size: 16, weight: .semibold, design: .rounded).monospacedDigit())
                }
                .foregroundStyle(Color.yellow.opacity(isLuminanceReduced ? 0.6 : 1))
            }
            .frame(height: clockHeight)
        }
    }

    // MARK: - Kezelőelemek

    /// A korona irányának emlékeztetője az első pár másodpercben.
    private var crownHints: some View {
        VStack {
            Image(systemName: "chevron.up")
                .padding(.top, 4)
            Spacer()
            Image(systemName: "chevron.down")
                .padding(.bottom, 4)
        }
        .font(.system(size: 11, weight: .bold))
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 3)
        .transition(.opacity)
        .allowsHitTesting(false)
    }

    private var sideControls: some View {
        HStack {
            myTeamGoalButton
            Spacer()
            menuButton
        }
    }

    /// Gól a saját csapatnak. Ez egyben a Double Tap célja is (Series 9 / Ultra 2-től).
    private var myTeamGoalButton: some View {
        Button {
            match.goal(for: match.myTeam)
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(match.myTeam == .green ? Color.green : Color.white)
                .frame(width: 34, height: 60)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .handGestureShortcut(.primaryAction)
        .accessibilityLabel("Gól a saját csapatnak: \(match.myTeam.displayName)")
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
        .accessibilityLabel("Menü")
    }

    // MARK: - Korona

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
