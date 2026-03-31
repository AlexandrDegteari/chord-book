import AVFoundation
import Accelerate
import Combine

class TunerEngine: ObservableObject {
    @Published var note: String = "--"
    @Published var octave: Int = 0
    @Published var cents: Double = 0
    @Published var frequency: Double = 0
    @Published var isInTune: Bool = false
    @Published var isListening: Bool = false
    @Published var activeString: Int? = nil

    private var audioEngine = AVAudioEngine()
    private var pitchHistory: [Double] = []
    private let historySize = 3

    static let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    static let guitarStrings: [(name: String, freq: Double, string: Int)] = [
        ("E2", 82.41, 6), ("A2", 110.0, 5), ("D3", 146.83, 4),
        ("G3", 196.0, 3), ("B3", 246.94, 2), ("E4", 329.63, 1)
    ]

    func start() {
        guard !isListening else { return }

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .measurement)
            try session.setActive(true)
        } catch {
            print("Audio session error: \(error)")
            return
        }

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        let sampleRate = format.sampleRate
        let bufferSize: AVAudioFrameCount = 2048

        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, _ in
            self?.processBuffer(buffer, sampleRate: sampleRate)
        }

        do {
            try audioEngine.start()
            DispatchQueue.main.async { self.isListening = true }
        } catch {
            print("Engine start error: \(error)")
        }
    }

    func stop() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        DispatchQueue.main.async {
            self.isListening = false
            self.note = "--"
            self.frequency = 0
            self.cents = 0
            self.activeString = nil
        }
    }

    private func processBuffer(_ buffer: AVAudioPCMBuffer, sampleRate: Double) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)

        // RMS check
        var rms: Float = 0
        vDSP_rmsqv(channelData, 1, &rms, vDSP_Length(frameLength))
        guard rms > 0.01 else { return }

        // YIN-like autocorrelation pitch detection
        let detected = detectPitch(data: channelData, count: frameLength, sampleRate: sampleRate)
        guard detected > 60 && detected < 1200 else { return }

        pitchHistory.append(detected)
        if pitchHistory.count > historySize { pitchHistory.removeFirst() }

        let sorted = pitchHistory.sorted()
        let freq = sorted[sorted.count / 2]

        let midiNote = 12.0 * log2(freq / 440.0) + 69.0
        let roundedMidi = Int(round(midiNote))
        let noteIndex = ((roundedMidi % 12) + 12) % 12
        let oct = (roundedMidi / 12) - 1
        let centsVal = (midiNote - Double(roundedMidi)) * 100.0

        // Find closest guitar string
        var closestString: Int? = nil
        var minDist = Double.infinity
        for (i, gs) in TunerEngine.guitarStrings.enumerated() {
            let stringMidi = 12.0 * log2(gs.freq / 440.0) + 69.0
            let dist = abs(midiNote - stringMidi)
            if dist < 2.0 && dist < minDist {
                minDist = dist
                closestString = i
            }
        }

        DispatchQueue.main.async {
            self.frequency = freq
            self.note = TunerEngine.noteNames[noteIndex]
            self.octave = oct
            self.cents = max(-50, min(50, centsVal))
            self.isInTune = abs(centsVal) < 5
            self.activeString = closestString
        }
    }

    private func detectPitch(data: UnsafePointer<Float>, count: Int, sampleRate: Double) -> Double {
        let minLag = Int(sampleRate / 1200)
        let maxLag = min(Int(sampleRate / 60), count / 2)
        let halfN = count / 2

        var bestCorr: Float = 0
        var bestLag = 0

        for lag in minLag...maxLag {
            var sum: Float = 0
            var norm1: Float = 0
            var norm2: Float = 0

            for i in 0..<halfN {
                let v1 = data[i]
                let v2 = data[i + lag]
                sum += v1 * v2
                norm1 += v1 * v1
                norm2 += v2 * v2
            }

            let denom = sqrt(norm1 * norm2)
            guard denom > 1e-10 else { continue }
            let corr = sum / denom

            if corr > bestCorr {
                bestCorr = corr
                bestLag = lag
            }
        }

        guard bestCorr > 0.85 && bestLag > 0 else { return 0 }

        // Parabolic interpolation
        if bestLag > minLag && bestLag < maxLag {
            var corrMinus: Float = 0, corrPlus: Float = 0
            var n1m: Float = 0, n2m: Float = 0, n1p: Float = 0, n2p: Float = 0

            for i in 0..<halfN {
                let v1 = data[i]
                let vm = data[i + bestLag - 1]
                let vp = data[i + bestLag + 1]
                corrMinus += v1 * vm; n1m += v1 * v1; n2m += vm * vm
                corrPlus += v1 * vp; n1p += v1 * v1; n2p += vp * vp
            }

            let dm = sqrt(n1m * n2m)
            let dp = sqrt(n1p * n2p)
            if dm > 1e-10 && dp > 1e-10 {
                corrMinus /= dm
                corrPlus /= dp
                let shift = 0.5 * (corrMinus - corrPlus) / (corrMinus - 2 * bestCorr + corrPlus)
                if abs(shift) < 1 {
                    return sampleRate / (Double(bestLag) + Double(shift))
                }
            }
        }

        return sampleRate / Double(bestLag)
    }
}
