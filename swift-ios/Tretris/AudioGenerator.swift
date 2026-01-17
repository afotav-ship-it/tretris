import AVFoundation
import Foundation

// MARK: - Audio Generator

class AudioGenerator {
    static let sampleRate: Double = 44100
    
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var musicBuffer: AVAudioPCMBuffer?
    private var isPlaying = false
    
    init() {
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        
        guard let engine = audioEngine, let player = playerNode else { return }
        
        engine.attach(player)
        
        let format = AVAudioFormat(standardFormatWithSampleRate: AudioGenerator.sampleRate, channels: 2)!
        engine.connect(player, to: engine.mainMixerNode, format: format)
        
        do {
            try engine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    // MARK: - Sound Effects
    
    func playLandingSound() {
        let buffer = generateLandingSound()
        playBuffer(buffer, volume: 0.5)
    }
    
    func playBlopperSound() {
        let buffer = generateBlopperSound()
        playBuffer(buffer, volume: 0.4)
    }
    
    func playExplosionSound(intensity: Int) {
        let buffer = generateExplosionSound(intensity: min(5, max(1, intensity)))
        playBuffer(buffer, volume: Float(0.4 + Double(intensity) * 0.1))
    }
    
    private func playBuffer(_ buffer: AVAudioPCMBuffer?, volume: Float) {
        guard let buffer = buffer, let player = playerNode else { return }
        
        // Create a one-shot player for sound effects
        let sfxPlayer = AVAudioPlayerNode()
        audioEngine?.attach(sfxPlayer)
        
        let format = AVAudioFormat(standardFormatWithSampleRate: AudioGenerator.sampleRate, channels: 2)!
        audioEngine?.connect(sfxPlayer, to: audioEngine!.mainMixerNode, format: format)
        
        sfxPlayer.volume = volume
        sfxPlayer.scheduleBuffer(buffer, completionHandler: { [weak self] in
            DispatchQueue.main.async {
                self?.audioEngine?.detach(sfxPlayer)
            }
        })
        sfxPlayer.play()
    }
    
    // MARK: - Music
    
    func startMusic(level: Int) {
        stopMusic()
        
        musicBuffer = generateFolkMusic(level: level)
        guard let buffer = musicBuffer, let player = playerNode else { return }
        
        player.volume = 0.3
        player.scheduleBuffer(buffer, at: nil, options: .loops)
        player.play()
        isPlaying = true
    }
    
    func stopMusic() {
        playerNode?.stop()
        isPlaying = false
    }
    
    // MARK: - Sound Generation
    
    private func generateLandingSound() -> AVAudioPCMBuffer? {
        let duration = 0.15
        let sampleCount = Int(AudioGenerator.sampleRate * duration)
        
        guard let buffer = createBuffer(sampleCount: sampleCount) else { return nil }
        
        let leftChannel = buffer.floatChannelData![0]
        let rightChannel = buffer.floatChannelData![1]
        
        for i in 0..<sampleCount {
            let t = Double(i) / AudioGenerator.sampleRate
            let decay = exp(-t * 25)
            
            let wave = sin(2 * .pi * 80 * t) * 0.5 +
                       sin(2 * .pi * 60 * t) * 0.3 +
                       sin(2 * .pi * 40 * t) * 0.2
            let noise = (Double.random(in: 0...1) - 0.5) * 0.3
            
            let value = Float((wave + noise) * decay * 0.5)
            leftChannel[i] = value
            rightChannel[i] = value
        }
        
        return buffer
    }
    
    private func generateBlopperSound() -> AVAudioPCMBuffer? {
        let duration = 0.2
        let sampleCount = Int(AudioGenerator.sampleRate * duration)
        
        guard let buffer = createBuffer(sampleCount: sampleCount) else { return nil }
        
        let leftChannel = buffer.floatChannelData![0]
        let rightChannel = buffer.floatChannelData![1]
        
        for i in 0..<sampleCount {
            let t = Double(i) / AudioGenerator.sampleRate
            let freq = 150 + 200 * sin(.pi * t / duration)
            let decay = exp(-t * 10)
            
            let wave = sin(2 * .pi * freq * t + sin(2 * .pi * 20 * t) * 2)
            let value = Float(wave * decay * 0.4)
            
            leftChannel[i] = value
            rightChannel[i] = value
        }
        
        return buffer
    }
    
    private func generateExplosionSound(intensity: Int) -> AVAudioPCMBuffer? {
        let duration = 0.3 + Double(intensity) * 0.15
        let sampleCount = Int(AudioGenerator.sampleRate * duration)
        
        guard let buffer = createBuffer(sampleCount: sampleCount) else { return nil }
        
        let leftChannel = buffer.floatChannelData![0]
        let rightChannel = buffer.floatChannelData![1]
        
        for i in 0..<sampleCount {
            let t = Double(i) / AudioGenerator.sampleRate
            
            // Initial blast
            let blastDecay = exp(-t * Double(15 - intensity * 2))
            let blastFreq = Double(400 + intensity * 100)
            let blast = sin(2 * .pi * blastFreq * t * exp(-t * 3)) * blastDecay
            
            // Low rumble
            let rumbleFreq = Double(40 + intensity * 10)
            let rumbleDecay = exp(-t * (3 - Double(intensity) * 0.3))
            let rumble = (sin(2 * .pi * rumbleFreq * t) * 0.5 +
                         sin(2 * .pi * rumbleFreq * 0.5 * t) * 0.3) * rumbleDecay
            
            // Noise
            let noiseIntensity = 0.3 + Double(intensity) * 0.15
            let noiseDecay = exp(-t * (4 - Double(intensity) * 0.5))
            let noise = (Double.random(in: 0...1) - 0.5) * noiseIntensity * noiseDecay
            
            // Shockwave
            var shockwave = 0.0
            if t < 0.1 {
                shockwave = sin(2 * .pi * 30 * t) * (1 - t * 10) * Double(intensity) * 0.3
            }
            
            let wave = blast * 0.4 + rumble * 0.3 + noise + shockwave
            let value = Float(wave * 0.3)
            
            leftChannel[i] = value
            rightChannel[i] = value
        }
        
        return buffer
    }
    
    private func generateFolkMusic(seed: Int? = nil, level: Int = 1) -> AVAudioPCMBuffer? {
        let seedValue = seed ?? Int.random(in: 0..<1000000)
        srand48(seedValue)
        
        // Minor pentatonic scale: A C D E G (two octaves)
        let scale: [Double] = [220, 262, 294, 330, 392, 440, 523, 587, 659, 784]
        
        // Bass notes
        let bassI = 110.0   // A (tonic)
        let bassIV = 147.0  // D (subdominant)
        let bassV = 165.0   // E (dominant)
        let bassVI = 175.0  // F (submediant)
        
        // Generate melodic phrases
        func generatePhrase(startIdx: Int, energy: String) -> [Double] {
            let patterns: [[Int]]
            switch energy {
            case "low":
                patterns = [[0, 1, 0, 0], [0, 2, 1, 0], [1, 0, 1, 0]]
            case "medium":
                patterns = [[0, 2, 3, 2], [2, 1, 0, 2], [0, 1, 2, 1]]
            default: // high
                patterns = [[2, 3, 4, 3], [3, 2, 4, 3], [0, 3, 2, 4]]
            }
            
            let pattern = patterns[Int(drand48() * Double(patterns.count))]
            return pattern.map { offset in
                let idx = max(0, min(scale.count - 1, startIdx + offset))
                return scale[idx]
            }
        }
        
        // Choose song structure
        let structures = [
            ["A", "A", "B", "A"],
            ["A", "B", "A", "B"],
            ["A", "A", "B", "C", "A"],
            ["A", "B", "C", "B"],
            ["A", "A", "A", "B"]
        ]
        let structure = structures[Int(drand48() * Double(structures.count))]
        
        let phraseA = generatePhrase(startIdx: 1, energy: "low")
        let phraseB = generatePhrase(startIdx: 2, energy: "medium")
        let phraseC = generatePhrase(startIdx: 3, energy: "high")
        
        let sections: [String: [Double]] = ["A": phraseA, "B": phraseB, "C": phraseC]
        
        var fullMelody: [Double] = []
        for section in structure {
            fullMelody.append(contentsOf: sections[section]!)
        }
        
        // Bass progression
        let bassPatterns: [String: [Double]] = [
            "A": [bassI, bassI],
            "B": [bassIV, bassV],
            "C": [bassVI, bassV]
        ]
        var fullBass: [Double] = []
        for section in structure {
            let pattern = bassPatterns[section]!
            fullBass.append(contentsOf: pattern)
            fullBass.append(contentsOf: pattern)
        }
        
        // Tempo
        let bpm = 75 + drand48() * 15
        let noteDuration = 60.0 / bpm
        let totalDuration = Double(fullMelody.count) * noteDuration
        
        let sampleCount = Int(AudioGenerator.sampleRate * totalDuration)
        guard let buffer = createBuffer(sampleCount: sampleCount) else { return nil }
        
        let leftChannel = buffer.floatChannelData![0]
        let rightChannel = buffer.floatChannelData![1]
        
        // Level-based features
        let hasRhythm = level >= 1
        let hasOffbeat = level >= 2
        let hasHarmony = level >= 3
        let hasCounter = level >= 4
        let hasFills = level >= 5
        
        for i in 0..<sampleCount {
            let t = Double(i) / AudioGenerator.sampleRate
            
            let noteIdx = min(Int(t / noteDuration), fullMelody.count - 1)
            let noteT = (t.truncatingRemainder(dividingBy: noteDuration)) / noteDuration
            
            let freq = fullMelody[noteIdx]
            let bassFreq = noteIdx < fullBass.count ? fullBass[noteIdx] : bassI
            
            // Envelope
            let attack = 0.08
            let sustainEnd = 0.75
            var envelope: Double
            if noteT < attack {
                envelope = noteT / attack
            } else if noteT < sustainEnd {
                envelope = 1.0 - (noteT - attack) * 0.08
            } else {
                envelope = 0.92 * (1 - (noteT - sustainEnd) / (1 - sustainEnd))
            }
            envelope = max(0, min(1.0, envelope))
            
            // Main melody
            let melodyWave = (sin(2 * .pi * freq * t) * 0.40 +
                             sin(2 * .pi * freq * 2 * t) * 0.12 +
                             sin(2 * .pi * freq * 3 * t) * 0.04) * envelope
            
            // Harmony
            var harmonyWave = 0.0
            if hasHarmony {
                let harmFreq = freq * 1.2
                harmonyWave = sin(2 * .pi * harmFreq * t) * 0.08 * envelope
            }
            
            // Counter-melody
            var counterWave = 0.0
            if hasCounter {
                var counterT = (t - 0.15).truncatingRemainder(dividingBy: totalDuration)
                if counterT < 0 { counterT += totalDuration }
                let counterIdx = min(Int(counterT / noteDuration), fullMelody.count - 1)
                let counterFreq = fullMelody[counterIdx] * 0.75
                counterWave = sin(2 * .pi * counterFreq * t) * 0.06 * envelope * 0.6
            }
            
            // Bass
            var bassWave = sin(2 * .pi * bassFreq * t) * 0.16 +
                          sin(2 * .pi * bassFreq * 2 * t) * 0.05
            bassWave += sin(2 * .pi * bassFreq * 1.5 * t) * 0.04
            
            // Rhythm section
            let beatNum = (t * bpm / 60).truncatingRemainder(dividingBy: 4)
            let beatPhase = beatNum.truncatingRemainder(dividingBy: 1)
            
            var kick = 0.0
            if hasRhythm {
                if beatPhase < 0.06 && (Int(beatNum) == 0 || Int(beatNum) == 2) {
                    kick = exp(-beatPhase * 60) * 0.12
                }
            }
            
            var hihat = 0.0
            if hasOffbeat {
                if beatPhase < 0.03 && (Int(beatNum) == 1 || Int(beatNum) == 3) {
                    hihat = exp(-beatPhase * 120) * 0.06
                }
            }
            
            var fill = 0.0
            if hasFills {
                let barPos = noteIdx % 16
                if barPos >= 14 {
                    let fillPhase = (t * bpm / 60 * 2).truncatingRemainder(dividingBy: 1)
                    if fillPhase < 0.04 {
                        fill = exp(-fillPhase * 80) * 0.05
                    }
                }
            }
            
            let total = melodyWave + harmonyWave + counterWave + bassWave + kick + hihat + fill
            let value = Float(total * 0.25)
            
            leftChannel[i] = value
            rightChannel[i] = value
        }
        
        return buffer
    }
    
    private func createBuffer(sampleCount: Int) -> AVAudioPCMBuffer? {
        let format = AVAudioFormat(standardFormatWithSampleRate: AudioGenerator.sampleRate, channels: 2)!
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(sampleCount)) else {
            return nil
        }
        buffer.frameLength = AVAudioFrameCount(sampleCount)
        return buffer
    }
    
    deinit {
        stopMusic()
        audioEngine?.stop()
    }
}
