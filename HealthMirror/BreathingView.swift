import SwiftUI

struct BreathingView: View {
    @State private var running = false
    @State private var phase = "准备开始"
    @State private var seconds = 0
    @State private var selected = "均衡呼吸"
    private let modes = ["放松呼吸", "均衡呼吸", "海浪呼吸", "深度呼吸"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Picker("呼吸模式", selection: $selected) {
                    ForEach(modes, id: \.self) { Text($0) }
                }.pickerStyle(.menu)
                Spacer()
                Circle().fill(Color.blue.opacity(0.13))
                    .frame(width: 220, height: 220)
                    .overlay {
                        Circle().stroke(Color.blue.opacity(0.35), lineWidth: 2).padding(15)
                        VStack(spacing: 8) {
                            Image(systemName: "wind").font(.largeTitle).foregroundStyle(.blue)
                            Text(phase).font(.title2.bold())
                            Text("\(seconds) 秒").foregroundStyle(.secondary)
                        }
                    }
                Text("跟随节奏缓慢呼吸。如有头晕或不适，请立即停止。")
                    .font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                Button(running ? "结束练习" : "开始练习") {
                    running.toggle()
                    phase = running ? "缓慢吸气" : "已结束"
                    if !running { seconds = 0 }
                }.buttonStyle(.borderedProminent).controlSize(.large)
                Spacer()
            }.padding()
            .navigationTitle("呼吸")
        }
    }
}
