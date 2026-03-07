import Foundation
import Combine
import HealthKit
import UIKit

// MARK: - HealthKit Workout Data Model
struct HealthKitWorkout: Identifiable, Equatable {
    let id: String
    let type: HKWorkoutActivityType
    let startDate: Date
    let duration: TimeInterval
    let calories: Double
    let distance: Double? // meters
    let title: String

    var durationMinutes: Int { Int(duration / 60) }
    var caloriesInt: Int { Int(calories.rounded()) }
}

@MainActor
final class HealthDataManager: ObservableObject {
    @Published private(set) var todayStepCount = 0
    @Published private(set) var yesterdayStepCount = 0
    @Published private(set) var todayActiveEnergyBurned = 0
    @Published private(set) var todayBasalEnergyBurned = 0
    @Published private(set) var hourlyActiveEnergyBurned: [Double] = Array(repeating: 0, count: 24)
    @Published private(set) var latestHeartRate: Int?
    @Published private(set) var restingHeartRate: Int?
    @Published private(set) var latestOxygenSaturationPercent: Int?
    @Published private(set) var latestBodyMassKilograms: Double?
    @Published private(set) var batteryLevelPercent: Int?
    @Published private(set) var storageAvailableGB: Double = 0
    @Published private(set) var storageTotalGB: Double = 0
    @Published private(set) var lastRefreshDate: Date?

    // HealthKit Workouts (for tab3)
    @Published private(set) var recentWorkouts: [HealthKitWorkout] = []

    private let healthStore = HKHealthStore()
    private let calendar = Calendar.current
    private var hasRequestedAuthorization = false

    init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        refreshDeviceMetrics()
    }

    func refreshIfNeeded() async {
        refreshDeviceMetrics()

        guard HKHealthStore.isHealthDataAvailable() else {
            lastRefreshDate = Date()
            return
        }

        if !hasRequestedAuthorization {
            _ = await requestAuthorization()
        }

        await refreshHealthMetrics()
    }

    func refreshDeviceMetrics() {
        let battery = UIDevice.current.batteryLevel
        batteryLevelPercent = battery >= 0 ? Int((battery * 100).rounded()) : nil

        let homeURL = URL(fileURLWithPath: NSHomeDirectory())
        if let values = try? homeURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey, .volumeTotalCapacityKey]),
           let available = values.volumeAvailableCapacityForImportantUsage,
           let total = values.volumeTotalCapacity {
            storageAvailableGB = Double(available) / 1_000_000_000
            storageTotalGB = Double(total) / 1_000_000_000
        }
    }

    private func requestAuthorization() async -> Bool {
        hasRequestedAuthorization = true

        let identifiers: [HKQuantityTypeIdentifier] = [
            .stepCount,
            .activeEnergyBurned,
            .basalEnergyBurned,
            .heartRate,
            .restingHeartRate,
            .oxygenSaturation,
            .bodyMass
        ]

        var types: Set<HKObjectType> = Set(identifiers.compactMap { HKObjectType.quantityType(forIdentifier: $0) })

        // Add workout type for reading exercise history
        types.insert(HKObjectType.workoutType())

        return await withCheckedContinuation { continuation in
            healthStore.requestAuthorization(toShare: [], read: types) { success, _ in
                continuation.resume(returning: success)
            }
        }
    }

    private func refreshHealthMetrics() async {
        async let todaySteps = fetchStepCount(for: Date())
        async let yesterdaySteps = fetchStepCount(for: calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date())
        async let activeEnergy = fetchCumulativeQuantity(.activeEnergyBurned, unit: .kilocalorie(), on: Date())
        async let basalEnergy = fetchCumulativeQuantity(.basalEnergyBurned, unit: .kilocalorie(), on: Date())
        async let hourlyEnergy = fetchHourlyActiveEnergyBurnedToday()
        async let heartRate = fetchMostRecentQuantity(.heartRate, unit: HKUnit.count().unitDivided(by: .minute()))
        async let restingHR = fetchMostRecentQuantity(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute()))
        async let oxygen = fetchMostRecentQuantity(.oxygenSaturation, unit: .percent())
        async let bodyMass = fetchMostRecentQuantity(.bodyMass, unit: .gramUnit(with: .kilo))
        async let workouts = fetchRecentWorkouts(daysBack: 30)

        todayStepCount = await todaySteps
        yesterdayStepCount = await yesterdaySteps
        todayActiveEnergyBurned = Int((await activeEnergy).rounded())
        todayBasalEnergyBurned = Int((await basalEnergy).rounded())
        hourlyActiveEnergyBurned = await hourlyEnergy
        recentWorkouts = await workouts

        if let bpm = await heartRate {
            latestHeartRate = Int(bpm.rounded())
        }
        if let bpm = await restingHR {
            restingHeartRate = Int(bpm.rounded())
        }
        if let oxygenPercent = await oxygen {
            latestOxygenSaturationPercent = Int((oxygenPercent * 100).rounded())
        }
        latestBodyMassKilograms = await bodyMass
        lastRefreshDate = Date()
    }

    private func fetchStepCount(for date: Date) async -> Int {
        let value = await fetchCumulativeQuantity(.stepCount, unit: .count(), on: date)
        return Int(value.rounded())
    }

    private func fetchCumulativeQuantity(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit, on date: Date) async -> Double {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else { return 0 }

        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? date
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                let value = result?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }

    private func fetchMostRecentQuantity(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else { return nil }

        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: quantityType, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                let sample = samples?.first as? HKQuantitySample
                continuation.resume(returning: sample?.quantity.doubleValue(for: unit))
            }
            healthStore.execute(query)
        }
    }

    private func fetchHourlyActiveEnergyBurnedToday() async -> [Double] {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return Array(repeating: 0, count: 24)
        }

        let start = calendar.startOfDay(for: Date())
        let end = Date()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: start,
                intervalComponents: DateComponents(hour: 1)
            )

            query.initialResultsHandler = { [calendar] _, results, _ in
                guard let results else {
                    continuation.resume(returning: Array(repeating: 0, count: 24))
                    return
                }

                var buckets = Array(repeating: 0.0, count: 24)
                results.enumerateStatistics(from: start, to: end) { statistics, _ in
                    let hour = calendar.component(.hour, from: statistics.startDate)
                    buckets[hour] = statistics.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                }
                continuation.resume(returning: buckets)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - HealthKit Workouts

    /// Fetch recent workouts from HealthKit
    private func fetchRecentWorkouts(daysBack: Int) async -> [HealthKitWorkout] {
        let workoutType = HKWorkoutType.workoutType()
        let startDate = calendar.date(byAdding: .day, value: -daysBack, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: 100, sortDescriptors: [sort]) { _, samples, error in
                if let error = error {
                    print("⚠️ HealthKit Workout Query Error: \(error.localizedDescription)")
                }

                guard let workouts = samples as? [HKWorkout] else {
                    print("ℹ️ No workouts found in HealthKit (samples: \(samples?.count ?? 0))")
                    continuation.resume(returning: [])
                    return
                }

                print("✅ Found \(workouts.count) workouts in HealthKit")

                let mapped = workouts.map { workout -> HealthKitWorkout in
                    // Use statistics(for:) for iOS 18+ compatibility
                    let calories: Double
                    if #available(iOS 18.0, *) {
                        if let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
                            let stats = workout.statistics(for: energyType)
                            calories = stats?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                        } else {
                            calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
                        }
                    } else {
                        calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
                    }
                    let distance = workout.totalDistance?.doubleValue(for: .meter())

                    let title = Self.workoutTitle(for: workout.workoutActivityType)
                    print("   - \(title): \(workout.startDate) | \(Int(workout.duration/60))min | \(Int(calories))kcal")

                    return HealthKitWorkout(
                        id: workout.uuid.uuidString,
                        type: workout.workoutActivityType,
                        startDate: workout.startDate,
                        duration: workout.duration,
                        calories: calories,
                        distance: distance,
                        title: title
                    )
                }
                continuation.resume(returning: mapped)
            }
            healthStore.execute(query)
        }
    }

    private static func workoutTitle(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .running: return "Outdoor Running"
        case .walking: return "Walking"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .yoga: return "Yoga"
        case .functionalStrengthTraining: return "Strength Training"
        case .traditionalStrengthTraining: return "Weight Training"
        case .highIntensityIntervalTraining: return "HIIT"
        case .hiking: return "Hiking"
        case .pilates: return "Pilates"
        case .dance: return "Dance"
        case .martialArts: return "Martial Arts"
        case .gymnastics: return "Gymnastics"
        case .rowing: return "Rowing"
        case .elliptical: return "Elliptical"
        case .stairClimbing: return "Stairs"
        case .tennis: return "Tennis"
        case .basketball: return "Basketball"
        case .soccer: return "Soccer"
        case .golf: return "Golf"
        default: return "Workout"
        }
    }
}
