import SwiftUI

struct TrendsView: View {
    @EnvironmentObject private var h: HealthStoreManager
    @State private var period = "周"
    private let periods = ["周", "月", "年"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Picker("时间范围", selection: $period) {
                        ForEach(periods, id: \.self) { Text($0).tag($0) }
                    }.pickerStyle(.segmented)
                    Text("关键指标").font(.headline)
                    Text("把恢复、睡眠、活动和日常习惯放在一起。")
                        .font(.subheadline).foregroundStyle(.secondary)
                    trendCard("活动能量", value: h.value(h.activeEnergy, suffix: "kcal"), color: .orange, symbol: "flame.fill")
                    trendCard("步数", value: h.value(h.steps, suffix: "步"), color: .green, symbol: "figure.walk")
                    trendCard("心率变异性", value: h.value(h.hrv, suffix: "ms"), color: .blue, symbol: "waveform.path.ecg")
                    trendCard("静息心率", value: h.value(h.restingHeartRate, suffix: "bpm"), color: .pink, symbol: "heart.fill")
                    Text("趋势图将在积累到足够的历史样本后显示。").font(.caption).foregroundStyle(.secondary)
                }.padding()
            }.background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("趋势")
        }
    }

    private func trendCard(_ title: String, value: String, color: Color, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: symbol).foregroundStyle(color)
            Text(value).font(.title2.bold())
            RoundedRectangle(cornerRadius: 5).fill(color.opacity(0.12)).frame(height: 7)
            Text("当前可读取的最新记录 · \(period)视图").font(.caption2).foregroundStyle(.secondary)
        }.padding().frame(maxWidth: .infinity, alignment: .leading)
            .background(.white, in: RoundedRectangle(cornerRadius: 20))
    }
}
