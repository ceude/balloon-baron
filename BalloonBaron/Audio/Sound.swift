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
    private var started = false

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

    func burner(_ on: Bool) {
        guard started else { return }
        synth.send(.burner(on))
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
        guard let engine, !engine.isRunning else { return }
        try? AVAudioSession.sharedInstance().setActive(true)
        engine.prepare()
        try? engine.start()
    }

    private func observe() {
        let nc = NotificationCenter.default
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

private enum Command {
    case voice(VoiceSpec)
    case burner(Bool)
    case crowd(Bool)
    case birds(Bool)
    case master(Bool)
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

    init() {
        pending = .allocate(capacity: cmdCap)
        pending.initialize(repeating: .master(true), count: cmdCap)
        local = .allocate(capacity: cmdCap)
        local.initialize(repeating: .master(true), count: cmdCap)
        voices = .allocate(capacity: voiceCap)
        voices.initialize(repeating: Voice(), count: voiceCap)
        setSampleRate(44100)
    }

    deinit {
        pending.deallocate()
        local.deallocate()
        voices.deallocate()
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
        case .burner(let on):
            if on {
                // A broadband roar is loud on a phone speaker; a third of the prototype's first level sits under the music.
                burnTarget = 0.12
                burnStep = 0.12 / (0.08 * sr)
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
        }
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
