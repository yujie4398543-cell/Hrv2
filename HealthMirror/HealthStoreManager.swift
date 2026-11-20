import Foundation
import Combine
import HealthKit
import CoreMotion

@MainActor
final class HealthStoreManager: ObservableObject {
    @Published var authorizationAvailable = HKHealthStore.isHealthDataAvailable()
    @Published var lastUpdated: Date?
    @Published var steps: Double?
    @Published var walkingDistance: Double?
    @Published var heartRate: Double?
    @Published var restingHeartRate: Double?
    @Published var hrv: Double?
    @Published var oxygen: Double?
    @Published var respiratoryRate: Double?
    @Published var wristTemperature: Double?
    @Published var sleepHours: Double?
    @Published var activeEnergy: Double?
    @Published var errorMessage: String?

    private let store = HKHealthStore()
    private let motion = CMPedometer()

    private var readTypes: Set<HKObjectType> {
        let identifiers: [HKQuantityTypeIdentifier] = [
            .stepCount, .distanceWalkingRunning, .heartRate,
            .restingHeartRate, .heartRateVariabilitySDNN,
            .oxygenSaturation, .respiratoryRate, .appleSleepingWristTemperature,
            .activeEnergyBurned
        ]
        var result = Set<HKObjectType>()
        identifiers.forEach {
            if let type = HKObjectType.quantityType(forIdentifier: $0) { result.insert(type) }
        }
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) { result.insert(sleep) }
        return result
    }

    func requestAccessAndRefresh() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            errorMessage = "此设备不支持 Apple 健康数据。"
            return
        }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            await refresh()
        } catch {
            errorMessage = "无法请求健康数据权限：\(error.localizedDescription)"
        }
    }

    func refresh() async {
        async let s: Void = load(.stepCount, unit: .count) { steps = $0 }
        async let d: Void = load(.distanceWalkingRunning, unit: .meter) { walkingDistance = $0 }
        async let hr: Void = load(.heartRate, unit: HKUnit.count().unitDivided(by: .minute)) { heartRate = $0 }
        async let rhr: Void = load(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute)) { restingHeartRate = $0 }
        async let variability: Void = load(.heartRateVariabilitySDNN, unit: .secondUnit(with: .milli)) { hrv = $0 }
        async let o2: Void = load(.oxygenSaturation, unit: .percent()) { oxygen = $0 * 100 }
        async let rr: Void = load(.respiratoryRate, unit: HKUnit.count().unitDivided(by: .minute)) { respiratoryRate = $0 }
        async let temp: Void = load(.appleSleepingWristTemperature, unit: .degreeCelsius()) { wristTemperature = $0 }
        async let energy: Void = load(.activeEnergyBurned, unit: .kilocalorie()) { activeEnergy = $0 }
        async let sleep: Void = loadSleep()
        _ = await (s,d,hr,rhr,variability,o2,rr,temp,energy,sleep)
        lastUpdated = Date()
        loadPedometerFallback()
    }

    private func load(_ id: HKQuantityTypeIdentifier, unit: HKUnit, assign: @escaping (Double?) -> Void) async {
        guard let type = HKObjectType.quantityType(forIdentifier: id) else { assign(nil); return }
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        let descriptor = HKStatisticsQueryDescriptor(predicate: HKSamplePredicate.quantitySample(type: type, predicate: predicate),
                                                      options: .mostRecent)
        do {
            let result = try await descriptor.result(for: store)
            assign(result?.mostRecentQuantity()?.doubleValue(for: unit))
        } catch { assign(nil) }
    }

    private func loadSleep() async {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        let start = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: [])
        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit,
                                  sortDescriptors: nil) { [weak self] _, samples, _ in
            let total = (samples as? [HKCategorySample] ?? [])
                .filter { $0.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                          $0.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                          $0.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                          $0.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue }
                .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
            Task { @MainActor in self?.sleepHours = total > 0 ? total / 3600 : nil }
        }
        store.execute(query)
    }

    private func loadPedometerFallback() {
        guard CMPedometer.isStepCountingAvailable(), steps == nil else { return }
        let start = Calendar.current.startOfDay(for: Date())
        motion.queryPedometerData(from: start, to: Date()) { [weak self] data, _ in
            Task { @MainActor in
                if let data { self?.steps = data.numberOfSteps.doubleValue }
            }
        }
    }

    func value(_ number: Double?, suffix: String, decimals: Int = 0) -> String {
        guard let number else { return "暂无数据" }
        return "\(number.formatted(.number.precision(.fractionLength(decimals)))) \(suffix)"
    }
}
