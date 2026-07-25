import Foundation
import HealthKit

final class WorkoutManager: NSObject, ObservableObject {
    @Published var isWorkoutActive = false
    @Published var heartRate: Double = 0
    @Published var averageHeartRate: Double = 0
    @Published var maxHeartRate: Double = 0
    @Published var activeEnergy: Double = 0

    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    private let heartRateUnit = HKUnit.count().unitDivided(by: .minute())

    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let typesToShare: Set = [HKObjectType.workoutType()]
        var typesToRead: Set<HKObjectType> = []
        if let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate) {
            typesToRead.insert(heartRate)
        }
        if let energy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            typesToRead.insert(energy)
        }
        if let distance = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) {
            typesToRead.insert(distance)
        }

        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { _, _ in }
    }

    func startWorkout() {
        guard HKHealthStore.isHealthDataAvailable(), session == nil else { return }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .soccer
        configuration.locationType = .outdoor

        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                                         workoutConfiguration: configuration)
            session.delegate = self
            builder.delegate = self
            self.session = session
            self.builder = builder

            heartRate = 0
            averageHeartRate = 0
            maxHeartRate = 0
            activeEnergy = 0

            let start = Date()
            session.startActivity(with: start)
            builder.beginCollection(withStart: start) { _, _ in }
        } catch {
            self.session = nil
            self.builder = nil
        }
    }

    /// Félidőben és óramegállításnál az edzést is szüneteltetjük.
    func pauseWorkout() {
        guard let session, session.state == .running else { return }
        session.pause()
    }

    func resumeWorkout() {
        guard let session, session.state == .paused else { return }
        session.resume()
    }

    func endWorkout() {
        session?.end()
    }
}

extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState,
                        date: Date) {
        DispatchQueue.main.async {
            self.isWorkoutActive = (toState == .running)
        }

        if toState == .ended {
            builder?.endCollection(withEnd: date) { [weak self] _, _ in
                self?.builder?.finishWorkout { _, _ in
                    DispatchQueue.main.async {
                        self?.session = nil
                        self?.builder = nil
                        // Az összegzőn kellenek az átlag/max értékek, azokat megtartjuk.
                        self?.heartRate = 0
                    }
                }
            }
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isWorkoutActive = false
            self.session = nil
            self.builder = nil
        }
    }
}

extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder,
                        didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType,
                  let statistics = workoutBuilder.statistics(for: quantityType) else { continue }

            if quantityType == HKQuantityType.quantityType(forIdentifier: .heartRate) {
                let current = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit) ?? 0
                let average = statistics.averageQuantity()?.doubleValue(for: heartRateUnit) ?? 0
                let maximum = statistics.maximumQuantity()?.doubleValue(for: heartRateUnit) ?? 0
                DispatchQueue.main.async {
                    self.heartRate = current
                    self.averageHeartRate = average
                    self.maxHeartRate = maximum
                }
            } else if quantityType == HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
                let kilocalories = statistics.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                DispatchQueue.main.async {
                    self.activeEnergy = kilocalories
                }
            }
        }
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}
