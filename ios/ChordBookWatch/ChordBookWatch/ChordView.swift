import SwiftUI

struct ChordView: View {
    @ObservedObject var manager: WatchConnectivityManager

    var body: some View {
        VStack(spacing: 8) {
            if manager.songTitle.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)

                    Text("Open a song\non your iPhone")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else {
                // Song title
                Text(manager.songTitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Spacer()

                // Current chord - big
                if !manager.currentChord.isEmpty {
                    Text(manager.currentChord)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                }

                // Next chord
                if !manager.nextChord.isEmpty {
                    HStack(spacing: 4) {
                        Text("next:")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text(manager.nextChord)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.orange)
                    }
                }

                Spacer()

                // Current lyrics
                if !manager.currentLyrics.isEmpty {
                    Text(manager.currentLyrics)
                        .font(.system(size: 11))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
        }
        .padding(.horizontal, 8)
    }
}
