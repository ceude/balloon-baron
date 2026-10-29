import AVFoundation
import Foundation
import UIKit
import os

/// Short synthesized effects, like the prototype's `sfx()`.
enum Sfx {
    case tick, click, applause, blip, coin, low, fanfare, thud
}

/// All game audio is synthesized in code (no sound files): burner roar, morning ambience with
/// birds, the crowd while passengers gather, and short effects.
/// Port of the prototype's Web Audio graph onto one AVAudioEngine + AVAudioSourceNode.
/// Call from the main thread.
final class SoundEngine {
    static let shared = SoundEngine()

    /// Mirrors the player's sound setting; persisted in UserDefaults.
    var enabled: Bool {
        get { UserDefaults.standard.object(forKey: "sound") as? Bool ?? true }
        set {
            UserDefaults.standard.set(newValue, forKey: "sound")
            synth.send(.master(newValue))
            // with sound off the engine sleeps instead of rendering silence (battery)
            if newValue { resume() } else { engine?.pause() }
        }
    }

    /// Bird chirps over the ambience. The prototype only plays them on the ground
    /// (office, intro, setup, pick, collect); set false while flying.
    var ambienceBirds: Bool = true {
        didSet { if ambienceBirds != oldValue { synth.send(.birds(ambienceBirds)) } }
    }

    private let synth = Synth()
    private var engine: AVAudioEngine?
    private var node: AVAudioSourceNode?
    private var observers: [NSObjectProtocol] = []
    private var lastTick: TimeInterval = 0
    private var cricketTask: Task<Void, Never>?
    private var lastPop = -10.0
    private var showTask: Task<Void, Never>?
    private var filmID: Int32 = 0
    private var started = false
    private var inBackground = false

    private init() {}

    /// Starts the engine and the ambience. Safe to call more than once (also restarts a stopped engine).
    func start() {
        if !started {
            started = true
            let session = AVAudioSession.sharedInstance()
            try? session.setCategory(.ambient, mode: .default, options: [])
            try? session.setActive(true)
            synth.send(.master(enabled))
            synth.send(.birds(ambienceBirds))
            observe()
            build()
        }
        resume()
    }

    /// `level` scales the roar: 1 in flight; the design studio's spun balloon uses a faint one.
    func burner(_ on: Bool, level: Double = 1) {
        guard started else { return }
        synth.send(.burner(on, level))
    }

    func crowd(_ on: Bool) {
        guard started else { return }
        synth.send(.crowd(on))
    }

    /// Night: short trills from two crickets at slightly different pitches, an owl now and then.
    func crickets(_ on: Bool) {
        cricketTask?.cancel()
        cricketTask = nil
        guard on, started else { return }
        cricketTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                for (f, dl) in [(4300 + Double.random(in: 0..<200), 0.0), (4700 + Double.random(in: 0..<200), 0.25 + Double.random(in: 0..<0.3))] {
                    for i in 0..<(3 + Int.random(in: 0..<3)) { self.tone(f, f * 0.97, 0.035, .sine, 0.018, dl + Double(i) * 0.055) }
                }
                if Double.random(in: 0..<1) < 0.12 {
                    self.tone(420, 380, 0.32, .sine, 0.03, 0.5)
                    self.tone(400, 360, 0.45, .sine, 0.03, 0.95)
                }
                try? await Task.sleep(for: .milliseconds(380 + Int.random(in: 0..<520)))
            }
        }
    }

    /// The Balloon Show's music (`showMusic`): a steady beat with a rising pentatonic tune, burner roars as the balloons
    /// rise and dance, a fanfare and applause at the end. Sent beat by beat, so skipping the show stops it at once.
    func showMusic(_ on: Bool) {
        showTask?.cancel()
        showTask = nil
        guard on else { synth.send(.crowd(false)); return }
        guard started else { return }
        showTask = Task { @MainActor [weak self] in
            let pent = [262.0, 294, 330, 392, 440, 523, 587, 659, 784, 880], steps = [0, 2, 4, 3, 5, 4, 6, 7]
            func roar(_ at: Double, _ dur: Double, _ vol: Double) {
                self?.synth.send(.voice(VoiceSpec(noise: true, filter: .bandpass, filterFreq: 420, vol: vol, attack: 0.08,
                                                  decayEnd: dur, floor: 0.001, length: dur, delay: at)))
            }
            try? await Task.sleep(for: .milliseconds(1200))
            for i in 0..<6 { roar(0.3 + Double(i) * 0.7, 0.9, 0.05) }
            for b in 0..<50 {
                guard let self, !Task.isCancelled else { return }
                let at = 1 + Double(b) * 0.5
                if at > 25 { break }
                if b == 1 { self.synth.send(.crowd(true)) }
                if at >= 3 { self.tone(130, 45, 0.22, .sine, 0.16) }
                let step = min(9, steps[b % 8] + (at > 13 ? 2 : 0))
                self.tone(pent[step], pent[step], 0.32, .triangle, 0.05)
                if at > 7 && b % 2 == 0 { self.tone(pent[step] / 2, pent[step] / 2, 0.5, .sine, 0.05) }
                if at > 15 && b % 4 == 0 { self.tone(pent[min(9, step + 2)] * 2, pent[min(9, step + 2)] * 2, 0.25, .sine, 0.03, 0.25) }
                if at >= 8.5 && at < 13.5 && b % 2 == 1 { roar(0.2, 0.25, 0.06) } // burners on the beat
                if at == 21.5 { roar(0.3, 2.4, 0.08) }
                if at == 22 { for (i, f) in [523.0, 659, 784, 1047].enumerated() { self.tone(f, f, 0.6, .triangle, 0.07, 0.2 + Double(i) * 0.12) } }
                if at == 23.5 { self.synth.send(.crowd(false)); self.play(.applause) }
                try? await Task.sleep(for: .milliseconds(500))
            }
        }
    }

    /// The opening film's score (`filmMusic(part)`): wind under everything, a low drone on D whose low-pass opens at the
    /// sunrise, deep hits with risers, a ney in the Hicaz makam, darbuka in maqsum and strings once the flight gets going.
    /// `.bed` is the wind and drone alone (under the cards); nil fades everything out. A new part crossfades over 0.8 s.
    func filmMusic(_ part: FilmPart?) {
        guard started else { return }
        filmID &+= 1
        guard let part else { synth.send(.filmStop); return }
        synth.send(.filmStart(filmID, part))
        for n in FilmScore.notes(part) { synth.send(.filmNote(filmID, n)) }
    }

    /// Wedding fireworks: a soft thump and a crackle for each burst, about one a second (call it often).
    func firework(_ t: Double) {
        guard started, t > 0.8, t - lastPop > 1.1 else { return }
        lastPop = t
        tone(160, 55, 0.3, .triangle, 0.07)
        for i in 0..<5 { tone(2400 + Double.random(in: 0..<900), 1500, 0.06, .sine, 0.012, 0.2 + Double(i) * 0.05) }
    }

    func play(_ s: Sfx) {
        guard started else { return }
        switch s {
        case .tick:
            let now = ProcessInfo.processInfo.systemUptime
            if now - lastTick < 0.035 { return }
            lastTick = now
            tone(1500, 1300, 0.04, .sine, 0.05)
        case .click:
            tone(700, 500, 0.05, .triangle, 0.05)
        case .applause:
            // 160 short high-passed noise bursts over ~4 s, denser at the start.
            for _ in 0..<160 {
                let d = pow(Double.random(in: 0..<1), 1.3) * 4
                let v = 0.16 * max(0.15, 1 - d / 4.2)
                synth.send(.voice(VoiceSpec(noise: true, filter: .highpass, filterFreq: 700 + Double.random(in: 0..<900),
                                            vol: v, attack: 0, decayEnd: 0.05, floor: 0.0001, length: 0.07, delay: d)))
            }
        case .blip:
            tone(220 + Double.random(in: 0..<60), 200, 0.05, .triangle, 0.025)
        case .coin:
            tone(988, 988, 0.12, .triangle, 0.08)
            tone(1319, 1319, 0.25, .triangle, 0.08, 0.09)
        case .low:
            tone(330, 220, 0.35, .triangle, 0.07)
        case .fanfare:
            for (i, f) in [523.0, 659, 784, 1047].enumerated() { tone(f, f, 0.22, .triangle, 0.08, Double(i) * 0.1) }
        case .thud:
            synth.send(.voice(VoiceSpec(noise: true, filter: .lowpass, filterFreq: 260,
                                        vol: 0.6, attack: 0, decayEnd: 0.4, floor: 0.001, length: 0.4, delay: 0)))
            tone(110, 45, 0.3, .sine, 0.4)
        }
    }

    /// The prototype's `tone()`: exponential pitch glide f1→f2, 10 ms attack, exponential decay over `dur`.
    private func tone(_ f1: Double, _ f2: Double, _ dur: Double, _ wave: Wave, _ vol: Double, _ delay: Double = 0) {
        synth.send(.voice(VoiceSpec.tone(f1, f2, dur, wave, vol, delay)))
    }

    // MARK: engine lifecycle

    private func build() {
        let engine = AVAudioEngine()
        var sr = engine.outputNode.outputFormat(forBus: 0).sampleRate
        if sr <= 0 { sr = 44100 }
        synth.setSampleRate(sr)
        guard let fmt = AVAudioFormat(standardFormatWithSampleRate: sr, channels: 2) else { return }
        let synth = self.synth
        let node = AVAudioSourceNode(format: fmt) { _, _, frameCount, abl -> OSStatus in
            let bufs = UnsafeMutableAudioBufferListPointer(abl)
            let n = Int(frameCount)
            guard bufs.count > 0, let l = bufs[0].mData?.assumingMemoryBound(to: Float.self) else { return noErr }
            let r = bufs.count > 1 ? bufs[1].mData?.assumingMemoryBound(to: Float.self) : nil
            synth.render(n, l, r)
            return noErr
        }
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: fmt)
        engine.prepare()
        self.engine = engine
        self.node = node
        observers.append(NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main) { [weak self] _ in
            self?.resume()
        })
    }

    /// Restarts the engine if something (route change, interruption) stopped it.
    private func resume() {
        guard let engine, !engine.isRunning, enabled, !inBackground else { return }
        try? AVAudioSession.sharedInstance().setActive(true)
        engine.prepare()
        try? engine.start()
    }

    private func observe() {
        let nc = NotificationCenter.default
        // In the background nothing plays: the engine pauses until the app comes back (battery).
        observers.append(nc.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
            self?.inBackground = true
            self?.engine?.pause()
        })
        observers.append(nc.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
            guard let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  AVAudioSession.InterruptionType(rawValue: raw) == .ended else { return }
            self?.resume()
        })
        observers.append(nc.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }
            // Old engine is dead: rebuild everything.
            self.engine?.stop()
            if let node = self.node { self.engine?.detach(node) }
            self.engine = nil
            self.node = nil
            try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [])
            self.build()
            self.resume()
        })
        observers.append(nc.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in
            self?.inBackground = false
            self?.resume()
        })
    }
}

// MARK: - synth

enum Wave { case sine, triangle, sawtooth, square }
enum FilterKind { case lowpass, highpass, bandpass }

/// One scheduled voice: a tone, or filtered white noise.
struct VoiceSpec {
    var noise = false
    var wave = Wave.sine
    var f1 = 440.0, f2 = 440.0, sweep = 0.1     // exponential pitch glide over `sweep` s
    var filter = FilterKind.lowpass
    var filterFreq = 1000.0
    var vol = 0.1
    var attack = 0.01                            // linear 0→vol
    var decayEnd = 0.1                           // exponential vol→floor, ending here
    var floor = 0.0001
    var length = 0.15                            // voice stops here
    var delay = 0.0

    init(noise: Bool, filter: FilterKind, filterFreq: Double, vol: Double, attack: Double,
         decayEnd: Double, floor: Double, length: Double, delay: Double) {
        self.noise = noise; self.filter = filter; self.filterFreq = filterFreq; self.vol = vol
        self.attack = attack; self.decayEnd = decayEnd; self.floor = floor; self.length = length; self.delay = delay
    }

    init() {}

    static func tone(_ f1: Double, _ f2: Double, _ dur: Double, _ wave: Wave, _ vol: Double, _ delay: Double) -> VoiceSpec {
        var s = VoiceSpec()
        s.wave = wave; s.f1 = f1; s.f2 = f2; s.sweep = dur; s.vol = vol
        s.attack = 0.01; s.decayEnd = dur; s.floor = 0.0001; s.length = dur + 0.05; s.delay = delay
        return s
    }
}

/// The parts of the opening film's score: the flight (A), the lift-off (B), and the bed of wind and drone under the cards.
enum FilmPart { case a, b, bed }

/// One note of the film score, timed from the part's start: an oscillator (or filtered noise) with an exponential pitch
/// glide, a vibrato that fades in, a filter sweep and the prototype's `env()` (linear attack, hold, exponential release).
/// `swell` is the riser's envelope instead: an exponential rise over `attack`, then a 50 ms linear fade.
struct FilmNote {
    var noise = false
    var wave = Wave.sine
    var f = 440.0, fEnd = 440.0, glide = 0.0
    var vibRate = 0.0, vibDepth = 0.0, vibRamp = 0.0
    var filtered = false
    var filter = FilterKind.lowpass
    var cutoff = 1000.0, cutoffEnd = 1000.0, sweep = 0.0, q = 1.0
    var at = 0.0
    var attack = 0.01, peak = 0.1, hold = 0.0, release = 0.1
    var swell = false
    /// When the source stops (seconds after `at`); 0: at the end of its envelope.
    var stop = 0.0
}

/// The prototype's `filmMusic` score, note for note.
private enum FilmScore {
    /// Hicaz on D: D Eb F# G A Bb C D.
    static let N: [String: Double] = ["D3": 146.83, "A3": 220, "D4": 293.66, "Eb4": 311.13, "Fs4": 369.99, "G4": 392, "A4": 440, "Bb4": 466.16,
                                      "C5": 523.25, "D5": 587.33, "Eb5": 622.25, "Fs5": 739.99, "G5": 783.99]
    /// 84 bpm.
    static let B = 0.714

    static func notes(_ part: FilmPart) -> [FilmNote] {
        guard part != .bed else { return [] }
        var out: [FilmNote] = []
        func boom(_ at: Double, _ big: Bool) {
            var o = FilmNote()
            o.f = big ? 95 : 80; o.fEnd = 30; o.glide = big ? 1.4 : 0.8
            o.at = at; o.attack = 0.005; o.peak = big ? 0.55 : 0.35; o.hold = 0.05; o.release = big ? 1.8 : 1; o.stop = 2.2
            out.append(o)
            var n = FilmNote()
            n.noise = true; n.filtered = true; n.filter = .lowpass; n.cutoff = 900; n.cutoffEnd = 900
            n.at = at; n.attack = 0.003; n.peak = big ? 0.25 : 0.15; n.hold = 0.02; n.release = big ? 1.2 : 0.6; n.stop = 1.5
            out.append(n)
        }
        func riser(_ at: Double, _ dur: Double) {
            var n = FilmNote()
            n.noise = true; n.filtered = true; n.filter = .bandpass; n.q = 2; n.cutoff = 300; n.cutoffEnd = 4200; n.sweep = dur
            n.at = at; n.swell = true; n.attack = dur; n.peak = 0.12
            out.append(n)
        }
        func doum(_ at: Double) {
            var o = FilmNote()
            o.f = 140; o.fEnd = 62; o.glide = 0.22
            o.at = at; o.attack = 0.003; o.peak = 0.28; o.hold = 0.01; o.release = 0.3; o.stop = 0.4
            out.append(o)
        }
        func tek(_ at: Double, _ v: Double) {
            var n = FilmNote()
            n.noise = true; n.filtered = true; n.filter = .highpass; n.cutoff = 2600; n.cutoffEnd = 2600
            n.at = at; n.attack = 0.001; n.peak = v; n.hold = 0.005; n.release = 0.07; n.stop = 0.12
            out.append(n)
        }
        /// A ney: breathy, with a vibrato that comes in late.
        func ney(_ f: Double, _ at: Double, _ dur: Double, _ v: Double = 0.07) {
            let hold = max(0.05, dur - 0.4)
            for (wave, mul, gain) in [(Wave.triangle, 1.0, 1.0), (Wave.sine, 2.0, 0.25)] {
                var o = FilmNote()
                o.wave = wave; o.f = f * mul; o.fEnd = f * mul
                o.vibRate = 5.2; o.vibDepth = f * 0.012; o.vibRamp = min(0.6, dur * 0.6)
                o.at = at; o.attack = 0.12; o.peak = v * gain; o.hold = hold; o.release = 0.35; o.stop = dur + 0.5
                out.append(o)
            }
            var br = FilmNote()
            br.noise = true; br.filtered = true; br.filter = .bandpass; br.cutoff = f * 2; br.cutoffEnd = f * 2; br.q = 6
            br.at = at; br.attack = 0.08; br.peak = v * 0.5; br.hold = hold; br.release = 0.3; br.stop = dur + 0.5
            out.append(br)
        }
        func strings(_ fs: [Double], _ at: Double, _ dur: Double, _ v: Double = 0.035) {
            for fr in fs {
                for d in [-7.0, 7.0] {
                    var o = FilmNote()
                    o.wave = .sawtooth; o.f = fr * pow(2, d / 1200); o.fEnd = o.f
                    o.filtered = true; o.filter = .lowpass; o.cutoff = 1600; o.cutoffEnd = 1600
                    o.at = at; o.attack = dur * 0.4; o.peak = v; o.hold = dur * 0.3; o.release = dur * 0.4; o.stop = dur + 0.2
                    out.append(o)
                }
            }
        }
        func phrase(_ at: Double, _ notes: [(String, Double)]) {
            var x = at
            for (k, l) in notes {
                if let f = N[k] { ney(f, x, l * B * 0.95) }
                x += l * B
            }
        }
        /// Darbuka in maqsum: dum, tek, tek, dum, tek over four beats.
        func maqsum(_ from: Double, _ to: Double, _ v: Double) {
            var x = from
            while x < to {
                for (o, dum) in [(0.0, true), (0.5, false), (1.5, false), (2.0, true), (3.0, false)] {
                    let at = x + o * B
                    if at < to { if dum { doum(at) } else { tek(at, v) } }
                }
                x += B * 4
            }
        }
        func n(_ k: String) -> Double { N[k] ?? 0 }
        if part == .a {
            boom(1, false)
            phrase(2.6, [("A4", 2), ("Bb4", 1), ("A4", 1), ("G4", 1), ("Fs4", 1), ("G4", 2)])
            boom(9, false)
            maqsum(9, 26, 0.07)
            phrase(10.4, [("D5", 1), ("C5", 0.5), ("Bb4", 0.5), ("A4", 1), ("Bb4", 1), ("A4", 0.5), ("G4", 0.5), ("Fs4", 1), ("Eb4", 1), ("D4", 2)])
            riser(16.6, 2.9)
            boom(19.5, true)
            strings([n("D3"), n("Fs4"), n("A3"), n("D4")], 19.5, 5)
            strings([146.83 * 1.335, n("Bb4") / 2, n("D4")], 24.2, 4)
            phrase(19.7, [("A4", 1), ("D5", 1), ("Eb5", 0.5), ("Fs5", 0.5), ("G5", 2), ("Fs5", 0.5), ("Eb5", 0.5), ("D5", 2)])
            boom(24.5, false)
            ney(n("D4"), 27.5, 3, 0.05)
        } else {
            riser(1.6, 2)
            boom(3.6, true)
            maqsum(3.6, 18.6, 0.08)
            strings([n("D3"), n("A3"), n("D4"), n("Fs4")], 3.6, 7, 0.03)
            phrase(4.2, [("D5", 1), ("Eb5", 0.5), ("Fs5", 0.5), ("G5", 1), ("A4", 0.5), ("Bb4", 0.5), ("A4", 1), ("G4", 0.5), ("Fs4", 0.5), ("D5", 2)])
            boom(5.5, false)
            boom(10.8, true)
            // v121.5: the flight to our town and the landing: the drive thins out, a falling phrase on the way down, and the
            // touchdown resolves on D with a soft hit, strings and a long ney note
            strings([n("G4") / 2, n("Bb4") / 2, n("D4")], 11, 7, 0.026)
            phrase(13, [("A4", 1), ("G4", 0.5), ("Fs4", 0.5), ("G4", 1), ("Eb4", 1), ("D4", 2)])
            riser(18.8, 2.2)
            boom(21, false)
            strings([n("D3"), n("Fs4") / 2, n("A3"), n("D4")], 21, 5, 0.032)
            ney(n("D5"), 21.3, 3.2, 0.06)
        }
        return out
    }
}

private enum Command {
    case voice(VoiceSpec)
    case burner(Bool, Double)
    case crowd(Bool)
    case birds(Bool)
    case master(Bool)
    case filmStart(Int32, FilmPart)
    case filmNote(Int32, FilmNote)
    case filmStop
}

/// RBJ cookbook biquad, transposed direct form II. Q follows Web Audio
/// (bandpass: linear Q, constant 0 dB peak; lowpass/highpass: Q in dB).
struct Biquad {
    var b0 = 1.0, b1 = 0.0, b2 = 0.0, a1 = 0.0, a2 = 0.0
    var z1 = 0.0, z2 = 0.0

    mutating func set(_ kind: FilterKind, _ f: Double, _ q: Double, _ sr: Double) {
        let w0 = 2 * Double.pi * min(max(f, 10), sr * 0.49) / sr
        let c = cos(w0), s = sin(w0)
        let alpha: Double
        var nb0: Double, nb1: Double, nb2: Double
        switch kind {
        case .bandpass:
            alpha = s / (2 * max(q, 0.0001))
            nb0 = alpha; nb1 = 0; nb2 = -alpha
        case .lowpass:
            alpha = s / (2 * pow(10, q / 20))
            nb0 = (1 - c) / 2; nb1 = 1 - c; nb2 = nb0
        case .highpass:
            alpha = s / (2 * pow(10, q / 20))
            nb0 = (1 + c) / 2; nb1 = -(1 + c); nb2 = nb0
        }
        let a0 = 1 + alpha
        b0 = nb0 / a0; b1 = nb1 / a0; b2 = nb2 / a0
        a1 = -2 * c / a0; a2 = (1 - alpha) / a0
    }

    @inline(__always) mutating func process(_ x: Double) -> Double {
        let y = b0 * x + z1
        z1 = b1 * x - a1 * y + z2
        z2 = b2 * x - a2 * y
        return y
    }
}

/// os_unfair_lock wrapper (heap-allocated so its address is stable).
private final class UnfairLock {
    private let p: UnsafeMutablePointer<os_unfair_lock>
    init() {
        p = .allocate(capacity: 1)
        p.initialize(to: os_unfair_lock())
    }
    deinit {
        p.deinitialize(count: 1)
        p.deallocate()
    }
    func lock() { os_unfair_lock_lock(p) }
    func tryLock() -> Bool { os_unfair_lock_trylock(p) }
    func unlock() { os_unfair_lock_unlock(p) }
}

private struct Voice {
    var noise = false
    var wave = Wave.sine
    var start: Int64 = 0
    var t = 0
    var length = 0
    var attack = 0
    var decayEnd = 0
    var sweep = 0
    var freq = 440.0, fRatio = 1.0
    var phase = 0.0
    var vol = 0.1, gain = 0.1, gRatio = 1.0, floor = 0.0001
    var filter = Biquad()
}

/// A playing note of the film score (`FilmNote` in samples).
private struct FilmVoice {
    var layer: Int32 = 0
    var noise = false
    var wave = Wave.sine
    var start: Int64 = 0
    var t = 0, end = 1
    var freq = 440.0, fRatio = 1.0, glide = 0
    var vibRate = 0.0, vibDepth = 0.0, vibRamp = 1, vibPhase = 0.0
    var phase = 0.0
    var filtered = false
    var kind = FilterKind.lowpass
    var filter = Biquad()
    var cutoff = 1000.0, cutoffEnd = 1000.0, sweep = 0, q = 1.0
    var swell = false
    var attack = 1, holdEnd = 1, peak = 0.1, gain = 0.0, ratio = 1.0, fadeStep = 0.0
}

/// One part of the film score while it plays or fades: the wind (noise through a band that wanders), the drone on D and A
/// behind its low-pass, and the gain its notes play through.
private struct FilmLayer {
    var id: Int32 = 0
    var live = false
    var t0: Int64 = 0
    var gain = 0.0, target = 0.0, step = 0.0
    var endAt = Int64.max
    var wind = 0.08
    var opens = false
    var windBP = Biquad(), droneLP = Biquad()
    var ph0 = 0.0, ph1 = 0.0, ph2 = 0.0, ph3 = 0.0
}

/// One crowd "voice": a sawtooth through two moving formant bandpasses.
private struct CrowdVoice {
    var f0 = 120.0
    var freq = 120.0, freqTarget = 120.0
    var phase = 0.0
    var vibPhase = 0.0, vibRate = 5.0, vibDepth = 3.0
    var fA = Biquad(), fB = Biquad()
    var fAFreq = 350.0, fATarget = 350.0
    var fBFreq = 350.0, fBTarget = 350.0
    var env = 0.0, envLevel = 0.0
    var releaseAt: Int64 = 0
    var next: Int64 = 0
    var panL = 0.707, panR = 0.707
}

/// Renders the whole mix. `send` is called from the main thread; everything else runs on the
/// render thread, except `setSampleRate`, which is called before the engine starts.
private final class Synth {
    private let lock = UnfairLock()
    private let cmdCap = 1024
    private let pending: UnsafeMutablePointer<Command>   // main → render, guarded by lock
    private var pendingCount = 0
    private let local: UnsafeMutablePointer<Command>     // render-thread copy
    private let voiceCap = 512
    private let voices: UnsafeMutablePointer<Voice>
    private var voiceCount = 0

    private var sr = 44100.0
    private var frame: Int64 = 0
    private var rng: UInt64 = 0x9E3779B97F4A7C15

    // master (sound setting)
    private var masterOn = true
    private var master = 1.0

    // ambience: lowpassed noise bed + birds
    private var ambLP = Biquad()
    private var birds = true
    private var nextBird: Int64 = 0

    // burner: looping noise → bandpass 420 Hz Q 0.6, linear gain ramps
    private var burnBP = Biquad()
    private var burnGain = 0.0, burnTarget = 0.0, burnStep = 0.0

    // crowd
    private var crowdActive = false
    private var crowdOn = false
    private var crowdGain = 0.0, crowdStep = 0.0
    private var crowdVoices = [CrowdVoice](repeating: CrowdVoice(), count: 8)
    private var murmurBP = Biquad()
    /// Formant pairs (F1, F2) from the prototype's VOWELS table.
    private let vowels: [(Double, Double)] = [(730, 1090), (530, 1840), (270, 2290), (570, 840),
                                              (300, 870), (660, 1720), (440, 1020), (400, 2000)]
    private var ctrlCount = 0
    private var cFreq = 0.0, cFormant = 0.0, cEnvOn = 0.0, cEnvOff = 0.0, mSmooth = 0.0

    // the opening film's score: up to three parts at once (one playing, the others fading out) and their notes
    private let filmCap = 384
    private let filmVoices: UnsafeMutablePointer<FilmVoice>
    private var filmCount = 0
    private let layerCap = 3
    private let layers: UnsafeMutablePointer<FilmLayer>
    private var filmActive = false
    private var filmCtrl = 0
    /// The prototype's score peaks near full scale; a little headroom on a phone speaker, like the burner.
    private let filmLevel = 0.8

    init() {
        pending = .allocate(capacity: cmdCap)
        pending.initialize(repeating: .master(true), count: cmdCap)
        local = .allocate(capacity: cmdCap)
        local.initialize(repeating: .master(true), count: cmdCap)
        voices = .allocate(capacity: voiceCap)
        voices.initialize(repeating: Voice(), count: voiceCap)
        filmVoices = .allocate(capacity: filmCap)
        filmVoices.initialize(repeating: FilmVoice(), count: filmCap)
        layers = .allocate(capacity: layerCap)
        layers.initialize(repeating: FilmLayer(), count: layerCap)
        setSampleRate(44100)
    }

    deinit {
        pending.deallocate()
        local.deallocate()
        voices.deallocate()
        filmVoices.deallocate()
        layers.deallocate()
    }

    func send(_ c: Command) {
        lock.lock()
        if pendingCount < cmdCap {
            pending[pendingCount] = c
            pendingCount += 1
        }
        lock.unlock()
    }

    func setSampleRate(_ rate: Double) {
        sr = rate
        ambLP.set(.lowpass, 350, 1, sr)
        burnBP.set(.bandpass, 420, 0.6, sr)
        murmurBP.set(.bandpass, 900, 0.8, sr)
        // setTargetAtTime one-pole coefficients
        cFreq = 1 - exp(-1 / (0.04 * sr))
        cFormant = 1 - exp(-1 / (0.015 * sr))
        cEnvOn = 1 - exp(-1 / (0.012 * sr))
        cEnvOff = 1 - exp(-1 / (0.025 * sr))
        mSmooth = 1 - exp(-1 / (0.005 * sr))
        voiceCount = 0
        filmCount = 0
        for i in 0..<layerCap { layers[i].live = false }
        filmActive = false
        nextBird = frame + Int64(1.5 * sr)
    }

    // MARK: render thread

    @inline(__always) private func rand() -> Double {
        rng ^= rng >> 12; rng ^= rng << 25; rng ^= rng >> 27
        return Double((rng &* 2685821657736338717) >> 11) / 9007199254740992.0
    }

    @inline(__always) private func noise() -> Double { rand() * 2 - 1 }

    private func drain() {
        guard lock.tryLock() else { return }   // never block the render thread
        let n = pendingCount
        for i in 0..<n { local[i] = pending[i] }
        pendingCount = 0
        lock.unlock()
        for i in 0..<n { apply(local[i]) }
    }

    private func apply(_ c: Command) {
        switch c {
        case .voice(let s): add(s)
        case .master(let on): masterOn = on
        case .birds(let on): birds = on
        case .burner(let on, let level):
            if on {
                // A broadband roar is loud on a phone speaker; a third of the prototype's first level sits under the music.
                burnTarget = 0.12 * level
                burnStep = burnTarget / (0.08 * sr)
            } else {
                burnTarget = 0
                burnStep = max(burnGain, 0.0001) / (0.18 * sr)
            }
        case .crowd(let on):
            if on == crowdOn { return }
            crowdOn = on
            if on {
                if !crowdActive { startCrowd() }
                crowdStep = 0.55 / (0.6 * sr)
            } else {
                crowdStep = max(crowdGain, 0.0001) / (0.6 * sr)
            }
        case .filmStart(let id, let part): startFilm(id, part)
        case .filmNote(let id, let n): addFilm(id, n)
        case .filmStop: fadeFilm()
        }
    }

    // MARK: film score

    /// Every part still playing fades out over 0.8 s and stops a little later (`filmMusic`'s cross-fade).
    private func fadeFilm() {
        for i in 0..<layerCap where layers[i].live && layers[i].target > 0 {
            layers[i].target = 0
            layers[i].step = max(layers[i].gain, 0.0001) / (0.8 * sr)
            layers[i].endAt = frame + Int64(1.0 * sr)
        }
    }

    private func startFilm(_ id: Int32, _ part: FilmPart) {
        fadeFilm()
        // A free slot, or else the part closest to the end of its fade.
        var slot = -1
        for i in 0..<layerCap where !layers[i].live { slot = i; break }
        if slot < 0 {
            slot = 0
            for i in 1..<layerCap where layers[i].endAt < layers[slot].endAt { slot = i }
        }
        var L = FilmLayer()
        L.id = id
        L.live = true
        L.t0 = frame + Int64(0.15 * sr)
        L.target = 0.95 * filmLevel
        L.step = L.target / (1.2 * sr)
        L.wind = part == .b ? 0.05 : 0.08
        L.opens = part == .a
        L.windBP.set(.bandpass, 520, 0.45, sr)
        L.droneLP.set(.lowpass, 380, 1, sr)
        layers[slot] = L
        filmActive = true
    }

    private func addFilm(_ id: Int32, _ n: FilmNote) {
        guard filmCount < filmCap else { return }
        var layer: FilmLayer?
        for i in 0..<layerCap where layers[i].live && layers[i].id == id { layer = layers[i] }
        guard let layer else { return }
        var v = FilmVoice()
        v.layer = id
        v.noise = n.noise
        v.wave = n.wave
        v.start = layer.t0 + Int64(n.at * sr)
        let envEnd = n.swell ? n.attack + 0.05 : n.attack + n.hold + n.release
        v.end = max(1, Int((n.stop > 0 ? min(envEnd, n.stop) : envEnd) * sr))
        v.freq = n.f
        v.glide = Int(n.glide * sr)
        v.fRatio = v.glide > 0 ? pow(n.fEnd / n.f, 1 / Double(v.glide)) : 1
        v.vibRate = n.vibRate
        v.vibDepth = n.vibDepth
        v.vibRamp = max(1, Int(n.vibRamp * sr))
        v.filtered = n.filtered
        v.kind = n.filter
        v.cutoff = n.cutoff
        v.cutoffEnd = n.cutoffEnd
        v.sweep = Int(n.sweep * sr)
        v.q = n.q
        if n.filtered { v.filter.set(n.filter, n.cutoff, n.q, sr) }
        v.swell = n.swell
        v.attack = max(1, Int(n.attack * sr))
        v.holdEnd = v.attack + Int(n.hold * sr)
        v.peak = n.peak
        if n.swell {
            v.gain = 0.0001
            v.ratio = pow(n.peak / 0.0001, 1 / Double(v.attack))
        } else {
            v.gain = n.peak
            v.ratio = pow(0.0001 / max(n.peak, 0.0002), 1 / Double(max(1, Int(n.release * sr))))
        }
        filmVoices[filmCount] = v
        filmCount += 1
    }

    /// Drone pitches: D2 a little sharp and flat, A2, and D1 underneath.
    private static let droneF = (73.42 * pow(2, -6.0 / 1200), 73.42 * pow(2, 6.0 / 1200), 110 * pow(2, 3.0 / 1200), 36.71)

    /// One sample of the film score: the parts' wind and drone, then their notes.
    private func filmSample() -> Double {
        var out = 0.0
        var live = false
        let ctrl = filmCtrl == 0
        filmCtrl = (filmCtrl + 1) & 31
        for li in 0..<layerCap where layers[li].live {
            var L = layers[li]
            if frame >= L.endAt { layers[li].live = false; continue }
            live = true
            if L.gain < L.target { L.gain = min(L.target, L.gain + L.step) } else if L.gain > L.target { L.gain = max(L.target, L.gain - L.step) }
            if frame >= L.t0 {
                let ts = Double(frame - L.t0) / sr
                if ctrl {
                    L.windBP.set(.bandpass, 520 + 260 * sin(2 * Double.pi * 0.09 * ts), 0.45, sr)
                    if L.opens && ts > 17 && ts < 20.5 { L.droneLP.set(.lowpass, 380 + 720 * min(1, (ts - 17) / 3), 1, sr) }
                }
                let w = L.windBP.process(noise()) * L.wind
                let f = Synth.droneF
                var d = Synth.osc(.sawtooth, L.ph0, f.0 / sr) + Synth.osc(.sawtooth, L.ph1, f.1 / sr) + Synth.osc(.sawtooth, L.ph2, f.2 / sr)
                d += sin(2 * Double.pi * L.ph3)
                L.ph0 += f.0 / sr; if L.ph0 >= 1 { L.ph0 -= 1 }
                L.ph1 += f.1 / sr; if L.ph1 >= 1 { L.ph1 -= 1 }
                L.ph2 += f.2 / sr; if L.ph2 >= 1 { L.ph2 -= 1 }
                L.ph3 += f.3 / sr; if L.ph3 >= 1 { L.ph3 -= 1 }
                out += (w + L.droneLP.process(d) * 0.045 * min(1, ts / 4)) * L.gain
            }
            layers[li] = L
        }
        var k = 0
        while k < filmCount {
            if frame < filmVoices[k].start { k += 1; continue }
            var v = filmVoices[k]
            var lg = -1.0
            for li in 0..<layerCap where layers[li].live && layers[li].id == v.layer { lg = layers[li].gain }
            if lg < 0 {
                filmCount -= 1
                filmVoices[k] = filmVoices[filmCount]
                continue
            }
            var y: Double
            if v.noise {
                y = noise()
            } else {
                var f = v.freq
                if v.vibDepth > 0 {
                    f += v.vibDepth * min(1, Double(v.t) / Double(v.vibRamp)) * sin(2 * Double.pi * v.vibPhase)
                    v.vibPhase += v.vibRate / sr
                    if v.vibPhase >= 1 { v.vibPhase -= 1 }
                }
                let dt = f / sr
                y = Synth.osc(v.wave, v.phase, dt)
                v.phase += dt
                if v.phase >= 1 { v.phase -= floor(v.phase) }
                if v.t < v.glide { v.freq *= v.fRatio }
            }
            if v.filtered {
                if v.sweep > 0 && v.t & 31 == 0 {
                    v.filter.set(v.kind, v.cutoff * pow(v.cutoffEnd / v.cutoff, min(1, Double(v.t) / Double(v.sweep))), v.q, sr)
                }
                y = v.filter.process(y)
            }
            let g: Double
            if v.swell {
                if v.t < v.attack {
                    v.gain *= v.ratio
                } else {
                    if v.fadeStep == 0 { v.fadeStep = max(v.gain, 0.0001) / (0.05 * sr) }
                    v.gain = max(0, v.gain - v.fadeStep)
                }
                g = v.gain
            } else if v.t < v.attack {
                g = v.peak * Double(v.t) / Double(v.attack)
            } else if v.t < v.holdEnd {
                g = v.peak
            } else {
                v.gain *= v.ratio
                g = v.gain
            }
            out += y * g * lg
            v.t += 1
            if v.t >= v.end {
                filmCount -= 1
                filmVoices[k] = filmVoices[filmCount]
            } else {
                filmVoices[k] = v
                k += 1
            }
        }
        if !live { filmActive = false; filmCount = 0 }
        return out
    }

    private func add(_ s: VoiceSpec) {
        guard voiceCount < voiceCap else { return }
        var v = Voice()
        v.noise = s.noise
        v.wave = s.wave
        v.start = frame + Int64(s.delay * sr)
        v.length = max(1, Int(s.length * sr))
        v.attack = Int(s.attack * sr)
        v.decayEnd = max(v.attack + 1, Int(s.decayEnd * sr))
        v.sweep = max(1, Int(s.sweep * sr))
        v.freq = s.f1
        v.fRatio = pow(s.f2 / s.f1, 1 / Double(v.sweep))
        v.vol = s.vol
        v.gain = s.vol
        v.floor = s.floor
        v.gRatio = pow(s.floor / s.vol, 1 / Double(v.decayEnd - v.attack))
        if s.noise { v.filter.set(s.filter, s.filterFreq, 1, sr) }
        voices[voiceCount] = v
        voiceCount += 1
    }

    private func startCrowd() {
        crowdActive = true
        crowdGain = 0
        for i in 0..<8 {
            var c = CrowdVoice()
            c.f0 = i % 2 == 1 ? 105 + rand() * 35 : 185 + rand() * 55
            c.freq = c.f0; c.freqTarget = c.f0
            c.vibRate = 4 + rand() * 2
            c.vibDepth = c.f0 * 0.025
            c.fA.set(.bandpass, 350, 7, sr)
            c.fB.set(.bandpass, 350, 9, sr)
            let pan = rand() * 1.6 - 0.8
            let x = (pan + 1) / 2 * Double.pi / 2   // equal-power, mono input
            c.panL = cos(x); c.panR = sin(x)
            c.next = frame + Int64(rand() * 0.4 * sr)
            crowdVoices[i] = c
        }
        murmurBP.z1 = 0; murmurBP.z2 = 0
    }

    private func birdChirps() {
        let base = 2400 + rand() * 1400
        let n = 2 + Int(rand() * 3)
        for i in 0..<n {
            add(VoiceSpec.tone(base, base * (1.15 + rand() * 0.2), 0.09, .sine, 0.025, Double(i) * 0.13))
        }
    }

    @inline(__always) private static func blep(_ t: Double, _ dt: Double) -> Double {
        if t < dt { let x = t / dt; return x + x - x * x - 1 }
        if t > 1 - dt { let x = (t - 1) / dt; return x * x + x + x + 1 }
        return 0
    }

    @inline(__always) private static func osc(_ w: Wave, _ p: Double, _ dt: Double) -> Double {
        switch w {
        case .sine: return sin(2 * Double.pi * p)
        case .triangle: return p < 0.25 ? 4 * p : (p < 0.75 ? 2 - 4 * p : 4 * p - 4)
        case .sawtooth: return 2 * p - 1 - blep(p, dt)
        case .square:
            var q = p + 0.5; if q >= 1 { q -= 1 }
            return (p < 0.5 ? 1 : -1) + blep(p, dt) - blep(q, dt)
        }
    }

    func render(_ n: Int, _ outL: UnsafeMutablePointer<Float>, _ outR: UnsafeMutablePointer<Float>?) {
        drain()
        crowdVoices.withUnsafeMutableBufferPointer { cv in
            for i in 0..<n {
                var mono = 0.0, left = 0.0, right = 0.0

                // ambience bed
                mono += ambLP.process(noise()) * 0.045
                if frame >= nextBird {
                    if birds { birdChirps() }
                    nextBird = frame + Int64((2.5 + rand() * 5) * sr)
                }

                // burner
                if burnGain != burnTarget {
                    if burnGain < burnTarget { burnGain = min(burnTarget, burnGain + burnStep) }
                    else { burnGain = max(burnTarget, burnGain - burnStep) }
                }
                if burnGain > 0 { mono += burnBP.process(noise()) * burnGain }

                // the opening film's score
                if filmActive { mono += filmSample() }

                // one-shot voices
                var k = 0
                while k < voiceCount {
                    if frame < voices[k].start { k += 1; continue }
                    var v = voices[k]
                    let src: Double
                    if v.noise {
                        src = v.filter.process(noise())
                    } else {
                        let dt = v.freq / sr
                        src = Synth.osc(v.wave, v.phase, dt)
                        v.phase += dt
                        if v.phase >= 1 { v.phase -= floor(v.phase) }
                        if v.t < v.sweep { v.freq *= v.fRatio }
                    }
                    let g: Double
                    if v.t < v.attack { g = v.vol * Double(v.t) / Double(v.attack) }
                    else if v.t < v.decayEnd { g = v.gain; v.gain *= v.gRatio }
                    else { g = v.floor }
                    mono += src * g
                    v.t += 1
                    if v.t >= v.length {
                        voiceCount -= 1
                        voices[k] = voices[voiceCount]   // swap-remove; re-check slot k
                    } else {
                        voices[k] = v
                        k += 1
                    }
                }

                // crowd
                if crowdActive {
                    if crowdOn { crowdGain = min(0.55, crowdGain + crowdStep) }
                    else {
                        crowdGain -= crowdStep
                        if crowdGain <= 0 { crowdGain = 0; crowdActive = false }
                    }
                    let updateCoefs = ctrlCount == 0
                    var cl = 0.0, cr = 0.0
                    for j in 0..<8 {
                        if frame >= cv[j].next { syllable(&cv[j]) }
                        var c = cv[j]
                        c.freq += (c.freqTarget - c.freq) * cFreq
                        c.fAFreq += (c.fATarget - c.fAFreq) * cFormant
                        c.fBFreq += (c.fBTarget - c.fBFreq) * cFormant
                        if frame < c.releaseAt { c.env += (c.envLevel - c.env) * cEnvOn }
                        else { c.env -= c.env * cEnvOff }
                        if updateCoefs {
                            c.fA.set(.bandpass, c.fAFreq, 7, sr)
                            c.fB.set(.bandpass, c.fBFreq, 9, sr)
                        }
                        let f = c.freq + c.vibDepth * sin(2 * Double.pi * c.vibPhase)
                        c.vibPhase += c.vibRate / sr
                        if c.vibPhase >= 1 { c.vibPhase -= 1 }
                        let dt = f / sr
                        let s = Synth.osc(.sawtooth, c.phase, dt)
                        c.phase += dt
                        if c.phase >= 1 { c.phase -= floor(c.phase) }
                        let y = (c.fA.process(s) + c.fB.process(s)) * 0.6 * c.env
                        cl += y * c.panL
                        cr += y * c.panR
                        cv[j] = c
                    }
                    ctrlCount = (ctrlCount + 1) & 15
                    let m = murmurBP.process(noise()) * 0.02
                    left += (cl + m) * crowdGain
                    right += (cr + m) * crowdGain
                }

                // master (sound on/off), 5 ms smoothing against clicks
                master += ((masterOn ? 1 : 0) - master) * mSmooth
                let l = max(-1, min(1, (mono + left) * master))
                let r = max(-1, min(1, (mono + right) * master))
                if let outR {
                    outL[i] = Float(l); outR[i] = Float(r)
                } else {
                    outL[i] = Float((l + r) * 0.5)
                }
                frame += 1
            }
        }
    }

    /// The prototype's 25 ms chatter tick for one voice: new vowel, pitch, talk-or-pause envelope.
    private func syllable(_ c: inout CrowdVoice) {
        let vw = vowels[Int(rand() * Double(vowels.count)) % vowels.count]
        let dur = 0.07 + rand() * 0.16
        let talk = rand() < 0.78
        c.fATarget = vw.0
        c.fBTarget = vw.1
        c.freqTarget = c.f0 * (0.88 + rand() * 0.3)
        c.envLevel = talk ? 0.05 + rand() * 0.05 : 0
        c.releaseAt = frame + Int64(dur * 0.85 * sr)
        c.next = frame + Int64((dur + (rand() < 0.18 ? 0.3 + rand() * 0.5 : 0.015)) * sr)
    }
}
