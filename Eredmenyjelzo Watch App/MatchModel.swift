import Foundation
import WatchKit

final class MatchModel: ObservableObject {
    @Published private var state: MatchSnapshot
    /// A legutóbbi saját mentés ideje – ennél régebbi külső mentést nem töltünk vissza.
    private var lastPersistedAt: Date = .distantPast

    /// Minden kapuscsere-jelzésnél nő – a képernyő erre villantja fel a figyelmeztetést.
    @Published private(set) var keeperAlertPulse = 0
    private var keeperTimer: Timer?

    init() {
        // Induláskor nem folytatunk automatikusan: a StartView kérdezi meg.
        state = MatchSnapshot()
        // A meglévő mentést nem tekintjük „újnak", hogy ne töltse vissza magától.
        lastPersistedAt = MatchStore.load()?.savedAt ?? .distantPast
        observeExternalChanges()
    }

    // MARK: - Olvasható állapot

    var greenScore: Int { state.greenScore }
    var whiteScore: Int { state.whiteScore }
    var phase: MatchPhase { state.phase }
    var goals: [GoalEvent] { state.goals }
    var isClockRunning: Bool { state.isClockRunning }
    var totalPlayedTime: TimeInterval { state.totalPlayedTime }
    var firstHalfTime: TimeInterval { state.firstHalfAccumulated }

    func score(for team: Team) -> Int { state.score(for: team) }

    func matchTime(at date: Date) -> TimeInterval { state.matchTime(at: date) }

    // MARK: - Beállítások

    // A beállítások a meccstől függetlenül tárolódnak, ezért kézzel jelezzük a változást.

    var showClock: Bool {
        get { MatchSettings.showClock }
        set { objectWillChange.send(); MatchSettings.showClock = newValue }
    }

    var myTeam: Team {
        get { MatchSettings.myTeam }
        set { objectWillChange.send(); MatchSettings.myTeam = newValue }
    }

    /// Az ellenfél – a Double Tap és a képernyő bal oldali gombja ennek ad gólt.
    var otherTeam: Team { MatchSettings.myTeam.opposite }

    /// Kapuscsere-figyelmeztetés köze másodpercben, 0 = kikapcsolva.
    var keeperIntervalSeconds: Int {
        get { MatchSettings.keeperIntervalSeconds }
        set {
            objectWillChange.send()
            MatchSettings.keeperIntervalSeconds = newValue
            rescheduleKeeperAlert()
        }
    }

    var halfLengthMinutes: Int {
        get { MatchSettings.halfLengthMinutes }
        set { objectWillChange.send(); MatchSettings.halfLengthMinutes = newValue }
    }

    // MARK: - Meccs életciklus

    func startMatch() {
        state = MatchSnapshot(phase: .firstHalf,
                              halfLength: TimeInterval(MatchSettings.halfLengthMinutes * 60),
                              segmentStart: Date())
        persist()
    }

    /// Visszatölti a mentett, félbehagyott meccset.
    func resumeSavedMatch() {
        guard let snapshot = MatchStore.resumable() else { return }
        state = snapshot
        persist()
    }

    var hasResumableMatch: Bool { MatchStore.resumable() != nil }

    /// A folytatható meccs állása rövid formában, pl. „2–1, 1. félidő".
    var savedScoreSummary: String? {
        guard let snapshot = MatchStore.resumable() else { return nil }
        let phaseName: String
        switch snapshot.phase {
        case .firstHalf: phaseName = "1. félidő"
        case .halftime: phaseName = "félidő"
        case .secondHalf: phaseName = "2. félidő"
        default: phaseName = ""
        }
        return "\(snapshot.greenScore)–\(snapshot.whiteScore), \(phaseName)"
    }

    func discardSavedMatch() {
        MatchStore.clear()
        lastPersistedAt = Date()
    }

    func startHalftime() {
        guard state.phase == .firstHalf else { return }
        bankSegment()
        state.phase = .halftime
        persist()
        WKInterfaceDevice.current().play(.stop)
    }

    func startSecondHalf() {
        guard state.phase == .halftime else { return }
        state.phase = .secondHalf
        state.segmentStart = Date()
        persist()
        WKInterfaceDevice.current().play(.start)
    }

    func endMatch() {
        let displayed = state.matchTime(at: Date())
        bankSegment()
        state.finalMatchTime = displayed
        state.phase = .finished
        persist()
        WKInterfaceDevice.current().play(.success)
    }

    /// A záróképernyő után vissza az indító képernyőre. A beállítások külön tárolódnak.
    func reset() {
        MatchStore.clear()
        state = MatchSnapshot()
        lastPersistedAt = Date()
        rescheduleKeeperAlert()
    }

    // MARK: - Óra

    func pauseClock() {
        guard state.isClockRunning else { return }
        bankSegment()
        persist()
        WKInterfaceDevice.current().play(.stop)
    }

    func resumeClock() {
        guard !state.isClockRunning, state.phase.isPlaying else { return }
        state.segmentStart = Date()
        persist()
        WKInterfaceDevice.current().play(.start)
    }

    /// Lezárja a futó szakaszt, és beírja az addig eltelt időt a félidő számlájára.
    private func bankSegment() {
        guard let start = state.segmentStart else { return }
        let delta = max(0, Date().timeIntervalSince(start))
        if state.phase == .secondHalf {
            state.secondHalfAccumulated += delta
        } else {
            state.firstHalfAccumulated += delta
        }
        state.segmentStart = nil
    }

    // MARK: - Gólok

    func goal(for team: Team) {
        let time = state.matchTime(at: Date())
        switch team {
        case .green: state.greenScore += 1
        case .white: state.whiteScore += 1
        }
        state.goals.append(GoalEvent(team: team, matchTime: time))
        persist()
        WKInterfaceDevice.current().play(team == .green ? .directionUp : .directionDown)
    }

    func removeGoal(from team: Team) {
        switch team {
        case .green:
            guard state.greenScore > 0 else { return }
            state.greenScore -= 1
        case .white:
            guard state.whiteScore > 0 else { return }
            state.whiteScore -= 1
        }
        if let index = state.goals.lastIndex(where: { $0.team == team }) {
            state.goals.remove(at: index)
        }
        persist()
        WKInterfaceDevice.current().play(.retry)
    }

    func resetScore() {
        state.greenScore = 0
        state.whiteScore = 0
        state.goals = []
        persist()
    }

    // MARK: - Kapuscsere

    /// Mennyi van hátra a következő kapuscseréig, ha a figyelmeztetés be van kapcsolva.
    func timeUntilKeeperChange(at date: Date) -> TimeInterval? {
        let interval = TimeInterval(MatchSettings.keeperIntervalSeconds)
        guard interval > 0, state.phase.isPlaying else { return nil }
        let played = state.playedTime(at: date)
        return interval - played.truncatingRemainder(dividingBy: interval)
    }

    /// Az app előtérbe kerülésekor hívjuk: felfüggesztés alatt a timer nem jár.
    func refreshKeeperSchedule() {
        rescheduleKeeperAlert()
    }

    /// Pontosan a következő ciklushatárra időzít, nem másodpercenként pollozunk.
    private func rescheduleKeeperAlert() {
        keeperTimer?.invalidate()
        keeperTimer = nil

        let interval = TimeInterval(MatchSettings.keeperIntervalSeconds)
        guard interval > 0, state.phase.isPlaying, state.isClockRunning else { return }

        let played = state.playedTime(at: Date())
        var remaining = interval - played.truncatingRemainder(dividingBy: interval)
        // Épp a határon állva ne tüzeljen azonnal újra.
        if remaining < 0.5 { remaining += interval }

        let timer = Timer(timeInterval: remaining, repeats: false) { [weak self] _ in
            self?.fireKeeperAlert()
        }
        RunLoop.main.add(timer, forMode: .common)
        keeperTimer = timer
    }

    deinit {
        keeperTimer?.invalidate()
    }

    private func fireKeeperAlert() {
        keeperAlertPulse += 1
        playKeeperHaptic()
        rescheduleKeeperAlert()
    }

    /// Kb. 2 másodpercnyi folyamatos rezgés: a watchOS csak rövid mintákat játszik le,
    /// ezért sűrűn ismételjük őket.
    private func playKeeperHaptic() {
        let device = WKInterfaceDevice.current()
        let pulseCount = 6
        let spacing = 0.33
        for index in 0..<pulseCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + spacing * Double(index)) {
                device.play(.notification)
            }
        }
    }

    // MARK: - Mentés

    private func persist() {
        lastPersistedAt = MatchStore.save(state)
        // Minden állapotváltás (félidő, szünet, folytatás) érinti a kapuscsere-ciklust.
        rescheduleKeeperAlert()
    }

    /// Visszaolvassa az állást, ha kívülről módosult (Action Button / Double Tap intent).
    func reloadFromStore() {
        guard let snapshot = MatchStore.load(), snapshot.savedAt > lastPersistedAt else { return }
        state = snapshot
        lastPersistedAt = snapshot.savedAt
        rescheduleKeeperAlert()
    }

    private func observeExternalChanges() {
        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reloadFromStore()
        }
    }
}
