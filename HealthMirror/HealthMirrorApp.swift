import SwiftUI

@main
struct HealthMirrorApp: App {
    @StateObject private var health = HealthStoreManager()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(health)
                .task { await health.requestAccessAndRefresh() }
                .preferredColorScheme(.light)
        }
    }
}
