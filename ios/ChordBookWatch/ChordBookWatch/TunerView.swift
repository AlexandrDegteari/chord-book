import SwiftUI

struct TunerView: View {
    @ObservedObject var engine: TunerEngine

    var body: some View {
        VStack(spacing: 8) {
            Text("Tuner")
                .font(.caption)
                .foregroundColor(.secondary)

            // Note display
            ZStack {
                Circle()
                    .stroke(noteColor.opacity(0.5), lineWidth: 3)
                    .frame(width: 80, height: 80)

                VStack(spacing: 0) {
                    Text(engine.note)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(noteColor)

                    if engine.note != "--" {
                        Text("\(engine.octave)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Cents gauge
            GeometryReader { geo in
                let midX = geo.size.width / 2
                let range = geo.size.width / 2 - 8
                let needleX = midX + CGFloat(engine.cents / 50) * range

                ZStack {
                    // Track
                    Capsule()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 4)

                    // Center mark
                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 2, height: 12)

                    // Needle
                    Circle()
                        .fill(noteColor)
                        .frame(width: 10, height: 10)
                        .offset(x: needleX - midX)
                }
            }
            .frame(height: 16)

            // Status
            if engine.note != "--" {
                Text(engine.isInTune ? "In Tune" : engine.cents > 0 ? "Too high" : "Too low")
                    .font(.caption2)
                    .foregroundColor(noteColor)
            }

            // Frequency
            Text(engine.frequency > 0 ? String(format: "%.1f Hz", engine.frequency) : "Play a note...")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.secondary)

            // Guitar strings
            HStack(spacing: 4) {
                ForEach(0..<TunerEngine.guitarStrings.count, id: \.self) { i in
                    let gs = TunerEngine.guitarStrings[i]
                    let isActive = engine.activeString == i
                    let label = String(gs.name.prefix(while: { !$0.isNumber }))

                    VStack(spacing: 2) {
                        Text("\(gs.string)")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)

                        ZStack {
                            Circle()
                                .stroke(isActive ? noteColor : Color.gray.opacity(0.3), lineWidth: isActive ? 2 : 1)
                                .frame(width: 24, height: 24)

                            if isActive {
                                Circle()
                                    .fill(noteColor.opacity(0.2))
                                    .frame(width: 24, height: 24)
                            }

                            Text(label)
                                .font(.system(size: 10, weight: isActive ? .bold : .regular))
                                .foregroundColor(isActive ? noteColor : .secondary)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .onAppear { engine.start() }
        .onDisappear { engine.stop() }
    }

    private var noteColor: Color {
        if engine.note == "--" { return .gray }
        return engine.isInTune ? .green : .orange
    }
}
