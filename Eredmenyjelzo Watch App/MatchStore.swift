import Foundation

enum Team: String, Codable, CaseIterable, Identifiable {
    case green
    case white

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .green: return "Zöld"
        case .white: return "Fehér"
        }
    }

    var opposite: Team {
        switch self {
        case .green: return .white
        case .white: return .green
        }
    }
}

enum MatchPhase: String, Codable {
    case notStarted
    case firstHalf
    case halftime
    case secondHalf
    case finished

    /// Folyamatban lévő meccs – ilyet ajánlunk fel folytatásra, és ilyenkor fogadunk gólt.
    var isActive: Bool {
        self == .firstHalf || self == .halftime || self == .secondHalf
    }

    /// Ebben a két szakaszban járhat az óra.
    var isPlaying: Bool {
        self == .firstHalf || self == .secondHalf
    }
}

struct GoalEvent: Codable, Identifiable, Equatable {
    var id = UUID()
    var team: Team
    /// A kijelzett meccsidő a gól pillanatában.
    var matchTime: TimeInterval
}

/// A meccs állapota – ez kerül mentésre, és ezt olvassa az Action Button intent is.
///
/// Szándékosan nem tartalmaz beállítást: azok a `MatchSettings`-ben élnek, így egy
/// beállítás módosítása nem írja felül a folytatható meccset.
struct MatchSnapshot: Codable {
    var greenScore = 0
    var whiteScore = 0
    var phase: MatchPhase = .notStarted
    /// A meccs indításakor érvényes félidőhossz – ez adja a 2. félidő kezdőidejét.
    var halfLength: TimeInterval = 45 * 60
    var firstHalfAccumulated: TimeInterval = 0
    var secondHalfAccumulated: TimeInterval = 0
    /// Ha nem nil, az óra jár, és ekkor indult az aktuális szakasz.
    var segmentStart: Date?
    var goals: [GoalEvent] = []
    /// A meccs végén rögzített utolsó kijelzett idő.
    var finalMatchTime: TimeInterval = 0
    var savedAt = Date()
}

/// Meccsektől független beállítások. Túlélik az újraindítást, és nem érintik a mentett meccset.
enum MatchSettings {
    private static let halfLengthKey = "settings.halfLengthMinutes"
    private static let showClockKey = "settings.showClock"
    private static let myTeamKey = "settings.myTeam"
    private static let keeperIntervalKey = "settings.keeperIntervalSeconds"

    static var halfLengthMinutes: Int {
        get {
            let stored = UserDefaults.standard.integer(forKey: halfLengthKey)
            return stored > 0 ? stored : 45
        }
        set { UserDefaults.standard.set(max(1, newValue), forKey: halfLengthKey) }
    }

    static var showClock: Bool {
        get { UserDefaults.standard.object(forKey: showClockKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: showClockKey) }
    }

    /// A saját csapat – ennek ad gólt az Action Button és a Double Tap.
    static var myTeam: Team {
        get { Team(rawValue: UserDefaults.standard.string(forKey: myTeamKey) ?? "") ?? .green }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: myTeamKey) }
    }

    /// Kapuscsere-figyelmeztetés köze másodpercben. 0 = kikapcsolva.
    static var keeperIntervalSeconds: Int {
        get { UserDefaults.standard.integer(forKey: keeperIntervalKey) }
        set { UserDefaults.standard.set(max(0, newValue), forKey: keeperIntervalKey) }
    }

    /// A választható kapuscsere-közök: 3:00-tól 15:00-ig, 30 másodperces lépésekben.
    static let keeperIntervalOptions: [Int] = [0] + stride(from: 180, through: 900, by: 30).map { $0 }
}

extension MatchSnapshot {
    var isClockRunning: Bool { segmentStart != nil }

    /// Az aktuális félidőben eltelt idő.
    func periodElapsed(at date: Date) -> TimeInterval {
        let banked = (phase == .secondHalf) ? secondHalfAccumulated : firstHalfAccumulated
        guard let segmentStart else { return banked }
        return banked + max(0, date.timeIntervalSince(segmentStart))
    }

    /// A kijelzett meccsidő. A 2. félidő a félidő hosszától indul, ahogy a fociban szokás.
    func matchTime(at date: Date) -> TimeInterval {
        switch phase {
        case .notStarted:
            return 0
        case .firstHalf:
            return periodElapsed(at: date)
        case .halftime:
            return firstHalfAccumulated
        case .secondHalf:
            return halfLength + periodElapsed(at: date)
        case .finished:
            return finalMatchTime
        }
    }

    /// Tisztán játékkal töltött idő (a szünetek nélkül), a lezárt szakaszokból.
    var totalPlayedTime: TimeInterval {
        firstHalfAccumulated + secondHalfAccumulated
    }

    /// Tisztán játékkal töltött idő az éppen futó szakasszal együtt.
    /// A kapuscsere-ciklus ezt követi, így szünetben nem szalad tovább.
    func playedTime(at date: Date) -> TimeInterval {
        var total = totalPlayedTime
        if let segmentStart, phase.isPlaying {
            total += max(0, date.timeIntervalSince(segmentStart))
        }
        return total
    }

    func score(for team: Team) -> Int {
        team == .green ? greenScore : whiteScore
    }
}

/// Az állás mentése, hogy egy elszálló vagy kilőtt app ne vigye magával a meccset.
enum MatchStore {
    private static let key = "match.snapshot.v1"
    /// Ennél régebbi mentést nem ajánlunk fel folytatásra.
    private static let staleAfter: TimeInterval = 6 * 60 * 60

    static func load() -> MatchSnapshot? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let snapshot = try? JSONDecoder().decode(MatchSnapshot.self, from: data)
        else { return nil }
        return snapshot
    }

    /// Elmenti az állapotot, és visszaadja a mentés időpontját.
    @discardableResult
    static func save(_ snapshot: MatchSnapshot) -> Date {
        var copy = snapshot
        let now = Date()
        copy.savedAt = now
        if let data = try? JSONEncoder().encode(copy) {
            UserDefaults.standard.set(data, forKey: key)
        }
        return now
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    /// Folytatható meccs: aktív szakaszban van, és nem túl régi a mentés.
    static func resumable() -> MatchSnapshot? {
        guard let snapshot = load(),
              snapshot.phase.isActive,
              Date().timeIntervalSince(snapshot.savedAt) < staleAfter
        else { return nil }
        return snapshot
    }

    static func formatClock(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    /// Focis perc-jelölés, always-on kijelzőn és a gólnaplóban.
    static func formatMinute(_ interval: TimeInterval) -> String {
        "\(max(0, Int(interval) / 60))′"
    }

    /// Kapuscsere-köz megjelenítése, pl. „7:30" vagy „Ki".
    static func formatKeeperInterval(_ seconds: Int) -> String {
        seconds <= 0 ? "Ki" : String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
