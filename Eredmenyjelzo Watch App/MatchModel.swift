import Combine
import Foundation
import UserNotifications
import WatchKit

final class MatchModel: ObservableObject {
    @Published private var state: MatchSnapshot
    /// A legutóbbi saját mentés ideje – ennél régebbi külső mentést nem töltünk vissza.
    private var lastPersistedAt: Date = .distantPast

    /// Minden kapuscsere-jelzésnél nő – a képernyő erre villantja fel a figyelmeztetést.
    @Published private(set) var keeperAlertPulse = 0
    private var keeperTimer: Timer?

    /// A lejátszott meccsek, legfrissebb elöl.
    @Published private(set) var history: [MatchRecord] = []
    /// Az imént befejezett meccs – ezt mutatja a záróképernyő.
    @Published private(set) var lastRecord: MatchRecord?

    /// A futó meccs pulzusmintái. Csak memóriában élnek: ha a rendszer kilövi az
    /// appot, az állás megmarad, a görbe nem – ez elfogadható csere a mentés
    /// visszafelé kompatibilitásáért.
    private var heartRateSamples: [HeartRateSample] = []
    private var lastHeartRateSampleTime: TimeInterval = -.greatestFiniteMagnitude
    /// Ennyi meccsidőnként rögzítünk egy pulzusmintát.
    private let heartRateSampleInterval: TimeInterval = 15

    init() {
        // Induláskor nem folytatunk automatikusan: a StartView kérdezi meg.
        state = MatchSnapshot()
        // A meglévő mentést nem tekintjük „újnak", hogy ne töltse vissza magától.
        lastPersistedAt = MatchStore.load()?.savedAt ?? .distantPast
        history = MatchHistory.load()
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

    /// Mozgás-hőtérkép rögzítése GPS-szel.
    var pitchHeatmapEnabled: Bool {
        get { MatchSettings.pitchHeatmapEnabled }
        set { objectWillChange.send(); MatchSettings.pitchHeatmapEnabled = newValue }
    }

    // MARK: - Meccs életciklus

    func startMatch() {
        clearHeartRateSamples()
        lastRecord = nil
        state = MatchSnapshot(phase: .firstHalf,
                              halfLength: TimeInterval(MatchSettings.halfLengthMinutes * 60),
                              segmentStart: Date())
        persist()
    }

    /// Visszatölti a mentett, félbehagyott meccset.
    func resumeSavedMatch() {
        guard let snapshot = MatchStore.resumable() else { return }
        clearHeartRateSamples()
        lastRecord = nil
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

    /// Lezárja a meccset, és elmenti a történetbe. Az edzés statisztikáit a hívó adja át,
    /// mert azok a WorkoutManagernél élnek.
    func endMatch(averageHeartRate: Double = 0,
                  maxHeartRate: Double = 0,
                  activeEnergy: Double = 0,
                  heatmap: PitchHeatmap? = nil,
                  heatmapNote: String? = nil) {
        guard state.phase.isActive else { return }

        let displayed = state.matchTime(at: Date())
        bankSegment()
        state.finalMatchTime = displayed
        state.phase = .finished

        let record = MatchRecord(date: Date(),
                                 greenScore: state.greenScore,
                                 whiteScore: state.whiteScore,
                                 playedTime: state.totalPlayedTime,
                                 goals: state.goals,
                                 heartRateSamples: heartRateSamples,
                                 averageHeartRate: averageHeartRate,
                                 maxHeartRate: maxHeartRate,
                                 activeEnergy: activeEnergy,
                                 myTeam: MatchSettings.myTeam,
                                 heatmap: heatmap,
                                 heatmapNote: heatmapNote)
        lastRecord = record
        history.insert(record, at: 0)
        MatchHistory.save(history)

        persist()
        WKInterfaceDevice.current().play(.success)
    }

    // MARK: - Meccstörténet

    var historySummary: HistorySummary { HistorySummary(records: history) }

    /// A `remove(atOffsets:)` a SwiftUI-ból jönne, a modell viszont UI-mentes marad.
    func deleteHistory(at offsets: IndexSet) {
        history = history.enumerated()
            .filter { !offsets.contains($0.offset) }
            .map(\.element)
        MatchHistory.save(history)
    }

    func clearHistory() {
        history = []
        MatchHistory.save(history)
    }

    // MARK: - Pulzus

    /// A WorkoutManager hívja minden új pulzusértéknél. Csak futó óra mellett mintázunk,
    /// így a görbe és a gólok ugyanazon a meccsidő-tengelyen vannak.
    func recordHeartRate(_ bpm: Double) {
        guard bpm > 0, state.phase.isPlaying, state.isClockRunning else { return }
        let time = state.matchTime(at: Date())
        guard time - lastHeartRateSampleTime >= heartRateSampleInterval else { return }
        lastHeartRateSampleTime = time
        heartRateSamples.append(HeartRateSample(matchTime: time, bpm: bpm))
    }

    private func clearHeartRateSamples() {
        heartRateSamples = []
        lastHeartRateSampleTime = -.greatestFiniteMagnitude
    }

    /// A záróképernyő után vissza az indító képernyőre. A beállítások külön tárolódnak.
    func reset() {
        MatchStore.clear()
        state = MatchSnapshot()
        lastPersistedAt = Date()
        clearHeartRateSamples()
        lastRecord = nil
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
        // Előbb beolvassuk az esetleges Action Button-gólt, hogy ne írjuk felül.
        reloadFromStore()
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
        reloadFromStore()
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

    /// Értesítési engedély – enélkül a csuklóleengedett (háttérbe került) állapotban
    /// nem tudunk megbízhatóan rezegtetni.
    func requestAlertAuthorization() {
        UNUserNotificationCenter.current().delegate = KeeperNotificationDelegate.shared
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    /// Pontosan a következő ciklushatárra időzít, nem másodpercenként pollozunk.
    ///
    /// Két csatornán jelzünk, mert a `WKInterfaceDevice.play` csak akkor megbízható,
    /// ha az app aktív: a timer a képernyős jelzést és az azonnali rezgést adja,
    /// a helyi értesítés pedig csuklóleengedve, háttérben is felébreszti az órát.
    private func rescheduleKeeperAlert() {
        keeperTimer?.invalidate()
        keeperTimer = nil
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: Self.keeperNotificationIDs)

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

        scheduleKeeperNotifications(firstAfter: remaining, interval: interval)
    }

    deinit {
        keeperTimer?.invalidate()
    }

    private static let keeperNotificationPrefix = "keeper.change."
    /// Ennyi cserét ütemezünk előre. Ha a rendszer felfüggeszti az appot, a timer megáll,
    /// és csak ezek az előre beütemezett értesítések maradnak – ezért kell több belőlük.
    private static let keeperLookahead = 8

    private static var keeperNotificationIDs: [String] {
        (0..<keeperLookahead).map { "\(keeperNotificationPrefix)\($0)" }
    }

    private func scheduleKeeperNotifications(firstAfter seconds: TimeInterval,
                                             interval: TimeInterval) {
        let center = UNUserNotificationCenter.current()
        for index in 0..<Self.keeperLookahead {
            let content = UNMutableNotificationContent()
            content.title = "Kapuscsere"
            content.body = "Jön a csere – váltsatok kapust!"
            content.sound = .default
            // Áttöri a Fókusz módokat, hogy meccs közben biztosan megérkezzen.
            content.interruptionLevel = .timeSensitive

            let delay = seconds + interval * Double(index)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, delay),
                                                            repeats: false)
            let request = UNNotificationRequest(identifier: "\(Self.keeperNotificationPrefix)\(index)",
                                                content: content,
                                                trigger: trigger)
            center.add(request)
        }
    }

    private func fireKeeperAlert() {
        keeperAlertPulse += 1
        playKeeperHaptic()
        rescheduleKeeperAlert()
    }

    /// Kb. 2 másodpercnyi rezgés: a watchOS csak rövid mintákat játszik le, ezért sűrűn
    /// ismételjük őket. Két mintát váltogatunk, mert az azonos, gyors ismétléseket a
    /// rendszer összevonhatja.
    private func playKeeperHaptic() {
        let device = WKInterfaceDevice.current()
        let pulseCount = 7
        let spacing = 0.3
        for index in 0..<pulseCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + spacing * Double(index)) {
                device.play(index.isMultiple(of: 2) ? .notification : .failure)
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

/// Ha a képernyő aktív, a saját rezgés és a KAPUSCSERE felirat már jelzett, ezért nem
/// dobjuk rá az értesítést is. Háttérben viszont épp az értesítés az egyetlen csatorna,
/// amin csuklóleengedve is elérjük a felhasználót.
final class KeeperNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = KeeperNotificationDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let isActive = WKApplication.shared().applicationState == .active
        completionHandler(isActive ? [] : [.banner, .sound])
    }
}
