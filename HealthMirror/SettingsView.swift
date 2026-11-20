import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                Section("数据与隐私") {
                    Label("Apple 健康数据权限", systemImage: "heart.text.square")
                    Label("数据仅保存在设备与 Apple 健康中", systemImage: "lock.shield")
                    Label("健康数据说明", systemImage: "doc.text")
                }
                Section("应用设置") {
                    Label("通知设置", systemImage: "bell")
                    Label("每日目标", systemImage: "target")
                    Label("外观主题", systemImage: "paintpalette")
                }
                Section {
                    Text("本应用仅用于个人健康数据浏览与生活方式记录，不提供医疗诊断、治疗建议或紧急监护。指标是否可用取决于设备、地区、系统版本和授权情况。")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }.navigationTitle("设置")
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("完成") { dismiss() } } }
        }
    }
}
