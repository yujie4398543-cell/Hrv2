
import Foundation
import HealthKit
import Combine

@MainActor
final class HealthStoreManager: ObservableObject {

    @Published var heartRate: Double?
    @Published var restingHeartRate: Double?
    @Published var steps: Double?
    @Published var distance: Double?
    @Published var hrv: Double?
    @Published var oxygen: Double?
    @Published var respiratoryRate: Double?
    @Published var wristTemperature: Double?
    @Published var activeEnergy: Double?

    @Published var isAuthorized = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let healthStore = HKHealthStore()

    // MARK: - HealthKit Read Types

    private var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()

        let identifiers: [HKQuantityTypeIdentifier] = [
            .heartRate,
            .restingHeartRate,
            .stepCount,
            .distanceWalkingRunning,
            .heartRateVariabilitySDNN,
            .oxygenSaturation,
            .respiratoryRate,
            .appleSleepingWristTemperature,
            .activeEnergyBurned
        ]

        for identifier in identifiers {
            if let type = HKObjectType.quantityType(
                forIdentifier: identifier
            ) {
                types.insert(type)
            }
        }

        if let sleep = HKObjectType.categoryType(
            forIdentifier: .sleepAnalysis
        ) {
            types.insert(sleep)
        }

        return types
    }

    // MARK: - Compatibility Methods

    func requestAccessAndRefresh() async {
        await requestAuthorization()
    }

    func value(
        _ number: Double?,
        suffix: String,
        decimals: Int = 0
    ) -> String {
        guard let number, number.isFinite else {
            return "--"
        }

        let safeDecimals = min(max(decimals, 0), 4)
        let format = "%.\(safeDecimals)f"
        let formatted = String(format: format, number)

        return "\(formatted) \(suffix)"
    }

    // MARK: - HealthKit Authorization

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            errorMessage = "此设备不支持 Apple 健康数据"
            return
        }

        do {
            try await healthStore.requestAuthorization(
                toShare: [],
                read: readTypes
            )

            isAuthorized = true
            await refresh()

        } catch {
            errorMessage = "健康数据授权失败：\(error.localizedDescription)"
        }
    }

    // MARK: - Refresh Data

    func refresh() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            return
        }

        isLoading = true
        errorMessage = nil

        let rateUnit = HKUnit.count().unitDivided(
            by: HKUnit.minute()
        )

        async let heart = fetchLatest(
            .heartRate,
            unit: rateUnit
        )

        async let resting = fetchLatest(
            .restingHeartRate,
            unit: rateUnit
        )

        async let step = fetchCumulative(
            .stepCount,
            unit: HKUnit.count()
        )

        async let walkDistance = fetchCumulative(
            .distanceWalkingRunning,
            unit: HKUnit.meter()
        )

        async let heartVariability = fetchLatest(
            .heartRateVariabilitySDNN,
            unit: HKUnit.secondUnit(with: .milli)
        )

        async let bloodOxygen = fetchLatest(
            .oxygenSaturation,
            unit: HKUnit.percent()
        )

        async let breathing = fetchLatest(
            .respiratoryRate,
            unit: rateUnit
        )

        async let wristTemp = fetchLatest(
            .appleSleepingWristTemperature,
            unit: HKUnit.degreeCelsius()
        )

        async let energy = fetchCumulative(
            .activeEnergyBurned,
            unit: HKUnit.kilocalorie()
        )

        let results = await (
            heart,
            resting,
            step,
            walkDistance,
            heartVariability,
            bloodOxygen,
            breathing,
            wristTemp,
            energy
        )

        heartRate = results.0
        restingHeartRate = results.1
        steps = results.2
        distance = results.3
        hrv = results.4

        // HealthKit 血氧值转换为百分比
        oxygen = results.5.map { $0 * 100 }

        respiratoryRate = results.6
        wristTemperature = results.7
        activeEnergy = results.8

        isLoading = false
    }

    // MARK: - Fetch Latest Sample

    private func fetchLatest(
        _ identifier: HKQuantityTypeIdentifier,
        unit: HKUnit
    ) async -> Double? {

        guard let type = HKObjectType.quantityType(
            forIdentifier: identifier
        ) else {
            return nil
        }

        return await withCheckedContinuation { continuation in

            let sort = NSSortDescriptor(
                key: HKSampleSortIdentifierEndDate,
                ascending: false
            )

            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sort]
            ) { _, samples, error in

                guard error == nil,
                      let sample = samples?.first as? HKQuantitySample
                else {
                    continuation.resume(returning: nil)
                    return
                }

                let result = sample.quantity.doubleValue(for: unit)
                continuation.resume(returning: result)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Fetch Daily Cumulative Data

    private func fetchCumulative(
        _ identifier: HKQuantityTypeIdentifier,
        unit: HKUnit
    ) async -> Double? {

        guard let type = HKObjectType.quantityType(
            forIdentifier: identifier
        ) else {
            return nil
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: Date(),
            options: .strictStartDate
        )

        return await withCheckedContinuation { continuation in

            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in

                guard error == nil,
                      let quantity = statistics?.sumQuantity()
                else {
                    continuation.resume(returning: nil)
                    return
                }

                let result = quantity.doubleValue(for: unit)
                continuation.resume(returning: result)
            }

            healthStore.execute(query)
        }
    }
}
