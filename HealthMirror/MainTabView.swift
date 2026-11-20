import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var health: HealthStoreManager
    @State private var selected = 0

    var body: some View {
        TabView(selection: $selected) {
            DashboardView().tabItem { Label("今天", systemImage: "sun.max") }.tag(0)
            TrendsView().tabItem { Label("趋势", systemImage: "chart.bar.xaxis") }.tag(1)
            BreathingView().tabItem { Label("呼吸", systemImage: "figure.mind.and.body") }.tag(2)
        }
        .tint(.blue)
    }
}

struct DashboardView: View {
    @EnvironmentObject private var h: HealthStoreManager
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("今天").font(.largeTitle.bold())
                            Text(Date.now.formatted(date: .complete, time: .omitted))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button { showSettings = true } label: {
                            Image(systemName: "gearshape").font(.title3).padding(11)
                                .background(.white, in: Circle())
                        }
                    }
                    statusCard
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        MetricCard(title: "静息心率", value: h.value(h.restingHeartRate, suffix: "bpm"), icon: "heart.fill", tint: .pink)
                        MetricCard(title: "手腕温度", value: h.value(h.wristTemperature, suffix: "°C", decimals: 1), icon: "thermometer.medium", tint: .orange)
                        MetricCard(title: "个人基线 HRV", value: h.value(h.hrv, suffix: "ms"), icon: "waveform.path.ecg", tint: .purple)
                        MetricCard(title: "心率", value: h.value(h.heartRate, suffix: "bpm"), icon: "heart", tint: .red)
                        MetricCard(title: "饮水量", value: "需手动记录", icon: "drop.fill", tint: .cyan)
                        MetricCard(title: "日照时间", value: "暂无数据", icon: "sun.max.fill", tint: .yellow)
                        MetricCard(title: "血氧", value: h.value(h.oxygen, suffix: "%", decimals: 1), icon: "lungs.fill", tint: .indigo)
                        MetricCard(title: "呼吸频率", value: h.value(h.respiratoryRate, suffix: "次/分", decimals: 1), icon: "wind", tint: .blue)
                    }
                    HStack {
                        Text("活动记录").font(.headline)
                        Spacer()
                        Text("来自 Apple 健康").font(.caption).foregroundStyle(.secondary)
                    }
                    HStack(spacing: 12) {
                        ActivityTile(title: "步数", value: h.value(h.steps, suffix: "步"), icon: "figure.walk", tint: .green)
                        ActivityTile(title: "活动能量", value: h.value(h.activeEnergy, suffix: "kcal"), icon: "flame.fill", tint: .orange)
                    }
                    ActivityTile(title: "睡眠时长", value: h.value(h.sleepHours, suffix: "小时", decimals: 1), icon: "moon.fill", tint: .purple)
                    if let error = h.errorMessage {
                        Text(error).font(.footnote).foregroundStyle(.secondary)
                    }
                    Button { Task { await h.refresh() } } label: {
                        Label("刷新健康数据", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity).padding()
                            .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
                    }
                }.padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .sheet(isPresented: $showSettings) { SettingsView() }
        }
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("压力状态", systemImage: "waveform.path")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("数据概览").font(.caption).foregroundStyle(.secondary)
            }
            Text("健康数据已连接").font(.title2.bold()).foregroundStyle(.green)
            Text("此处展示设备实际记录，不进行未经验证的疾病诊断。")
                .font(.caption).foregroundStyle(.secondary)
            HStack(spacing: 5) {
                ForEach(0..<5) { i in
                    Capsule().fill([Color.green, .mint, .yellow, .orange, .red][i]).frame(height: 7)
                }
            }
        }.padding().background(.white, in: RoundedRectangle(cornerRadius: 22))
    }
}

struct MetricCard: View {
    let title: String; let value: String; let icon: String; let tint: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon).font(.caption.weight(.medium)).foregroundStyle(tint)
            Text(value).font(.headline).lineLimit(2).minimumScaleFactor(0.8)
            Text("设备记录").font(.caption2).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
            .padding(14).background(.white, in: RoundedRectangle(cornerRadius: 20))
    }
}

struct ActivityTile: View {
    let title: String; let value: String; let icon: String; let tint: Color
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundStyle(tint).font(.title2)
            VStack(alignment: .leading) {
                Text(title).font(.caption).foregroundStyle(.secondary)
                Text(value).font(.headline)
            }
            Spacer(minLength: 0)
        }.padding().frame(maxWidth: .infinity, alignment: .leading)
            .background(.white, in: RoundedRectangle(cornerRadius: 18))
    }
}
