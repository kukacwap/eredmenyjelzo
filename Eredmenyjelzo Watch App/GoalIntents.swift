import AppIntents
import WatchKit

/// Gólt ad a saját csapatnak a mentett állás alapján.
///
/// Ultrán ez rendelhető az Action Buttonhoz: Beállítások → Action Button →
/// Parancs (Shortcut) → „Gól". A parancs az appot nem nyitja meg, így játék
/// közben egy narancs gombnyomás elég egy gólhoz.
struct AddGoalIntent: AppIntent {
    static var title: LocalizedStringResource = "Gól"
    static var description = IntentDescription("Gólt ad a saját csapatodnak a futó meccsen.")
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        guard var snapshot = MatchStore.load(), snapshot.phase.isActive else {
            WKInterfaceDevice.current().play(.failure)
            return .result()
        }

        let team = MatchSettings.myTeam
        let time = snapshot.matchTime(at: Date())
        switch team {
        case .green: snapshot.greenScore += 1
        case .white: snapshot.whiteScore += 1
        }
        snapshot.goals.append(GoalEvent(team: team, matchTime: time))
        MatchStore.save(snapshot)

        WKInterfaceDevice.current().play(team == .green ? .directionUp : .directionDown)
        return .result()
    }
}

/// Visszavon egy gólt a saját csapattól – téves Action Button nyomás javítására.
struct UndoGoalIntent: AppIntent {
    static var title: LocalizedStringResource = "Gól visszavonása"
    static var description = IntentDescription("Visszavonja a saját csapat utolsó gólját.")
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        guard var snapshot = MatchStore.load(), snapshot.phase.isActive else {
            WKInterfaceDevice.current().play(.failure)
            return .result()
        }

        let team = MatchSettings.myTeam
        guard snapshot.score(for: team) > 0 else {
            WKInterfaceDevice.current().play(.failure)
            return .result()
        }

        switch team {
        case .green: snapshot.greenScore -= 1
        case .white: snapshot.whiteScore -= 1
        }
        if let index = snapshot.goals.lastIndex(where: { $0.team == team }) {
            snapshot.goals.remove(at: index)
        }
        MatchStore.save(snapshot)

        WKInterfaceDevice.current().play(.retry)
        return .result()
    }
}

struct EredmenyjelzoShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddGoalIntent(),
            phrases: [
                "Gól a \(.applicationName)ben",
                "Add a goal in \(.applicationName)"
            ],
            shortTitle: "Gól",
            systemImageName: "soccerball"
        )
        AppShortcut(
            intent: UndoGoalIntent(),
            phrases: [
                "Gól visszavonása a \(.applicationName)ben",
                "Undo a goal in \(.applicationName)"
            ],
            shortTitle: "Gól visszavonása",
            systemImageName: "arrow.uturn.backward"
        )
    }
}
