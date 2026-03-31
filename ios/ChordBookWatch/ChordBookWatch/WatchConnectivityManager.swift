import WatchConnectivity
import SwiftUI

class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    @Published var currentChord: String = ""
    @Published var nextChord: String = ""
    @Published var currentLyrics: String = ""
    @Published var songTitle: String = ""
    @Published var isConnected: Bool = false

    override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = activationState == .activated
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            if let chord = message["currentChord"] as? String {
                self.currentChord = chord
            }
            if let next = message["nextChord"] as? String {
                self.nextChord = next
            }
            if let lyrics = message["currentLyrics"] as? String {
                self.currentLyrics = lyrics
            }
            if let title = message["songTitle"] as? String {
                self.songTitle = title
            }
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async {
            if let chord = applicationContext["currentChord"] as? String {
                self.currentChord = chord
            }
            if let next = applicationContext["nextChord"] as? String {
                self.nextChord = next
            }
            if let lyrics = applicationContext["currentLyrics"] as? String {
                self.currentLyrics = lyrics
            }
            if let title = applicationContext["songTitle"] as? String {
                self.songTitle = title
            }
        }
    }
}
