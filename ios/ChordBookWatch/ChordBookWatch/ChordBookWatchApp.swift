import SwiftUI

@main
struct ChordBookWatchApp: App {
    @StateObject private var tunerEngine = TunerEngine()
    @StateObject private var connectivityManager = WatchConnectivityManager()

    var body: some Scene {
        WindowGroup {
            TabView {
                TunerView(engine: tunerEngine)
                ChordView(manager: connectivityManager)
            }
            .tabViewStyle(.verticalPage)
        }
    }
}
