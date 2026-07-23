import Foundation
import WatchKit

enum Team {
    case green
    case white
}

final class MatchModel: ObservableObject {
    @Published var greenScore = 0
    @Published var whiteScore = 0
    @Published var showClock = true
    @Published var isRunning = false
    @Published private(set) var startDate: Date?

    func start() {
        greenScore = 0
        whiteScore = 0
        startDate = Date()
        isRunning = true
    }

    func end() {
        isRunning = false
        startDate = nil
    }

    func goal(for team: Team) {
        switch team {
        case .green:
            greenScore += 1
            WKInterfaceDevice.current().play(.directionUp)
        case .white:
            whiteScore += 1
            WKInterfaceDevice.current().play(.directionDown)
        }
    }

    func removeGoal(from team: Team) {
        switch team {
        case .green:
            greenScore = max(0, greenScore - 1)
        case .white:
            whiteScore = max(0, whiteScore - 1)
        }
    }

    func resetScore() {
        greenScore = 0
        whiteScore = 0
    }

    func elapsedTime(at date: Date) -> TimeInterval {
        guard let startDate else { return 0 }
        return date.timeIntervalSince(startDate)
    }

    static func format(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}
