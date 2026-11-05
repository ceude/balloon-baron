import BalloonBaronCore
import Foundation

/// v141.6: the contract vehicles' arrival and departure sounds, the prototype's `VEH_SFX` voice for voice. Each voice is
/// an oscillator (or noise) through a filter, a linear attack, a hold and an exponential release, the pitch gliding
/// from `f` to `f2` over the whole voice. Every sound is under 3 s long, low-passed and below the UI's clicks; the
/// planes' start later so they play with the landing (touchdown 4.5 s in) and the take-off run (4.4 … 9 s).
enum VehicleSound {
    /// `VX(w, f, f2, d, a, h, r, v, ft, fc, q)`; wave nil is noise.
    static func vx(_ w: Wave?, _ f: Double, _ f2: Double, _ d: Double, _ a: Double, _ h: Double, _ r: Double, _ v: Double,
                   _ ft: FilterKind = .lowpass, _ fc: Double = 2000, _ q: Double = 0.7) -> VoiceSpec {
        var s = VoiceSpec()
        s.noise = w == nil
        s.wave = w ?? .sine
        s.f1 = f; s.f2 = f2; s.sweep = a + h + r
        s.filtered = true; s.filter = ft; s.filterFreq = fc; s.q = q
        s.vol = v; s.attack = a; s.hold = h; s.decayEnd = a + h + r; s.floor = 0.0001
        s.length = a + h + r + 0.02; s.delay = d
        return s
    }
    static let noise: Wave? = nil

    static func hornNote(_ f: Double, _ d: Double, _ h: Double, _ v: Double) -> [VoiceSpec] {
        [vx(.triangle, f, f, d, 0.06, h, 0.35, v, .lowpass, 1100), vx(.triangle, f * 1.006, f * 1.006, d, 0.06, h, 0.35, v * 0.8, .lowpass, 1100),
         vx(.sine, f / 2, f / 2, d, 0.06, h, 0.35, v * 0.5)]
    }
    static func clack(_ d: Double, _ e: Double) -> [VoiceSpec] {
        [vx(noise, 1, 1, d, 0.004, 0, 0.07, 0.05 * e, .bandpass, 700, 0.9), vx(.sine, 140, 90, d, 0.003, 0, 0.08, 0.04 * e)]
    }
    static func clacks(_ ts: [Double], _ es: [Double], _ gaps: [Double]) -> [VoiceSpec] {
        ts.indices.flatMap { i in clack(ts[i], es[i]) + clack(ts[i] + gaps[i], es[i] * 0.8) }
    }
    static func toot(_ d: Double, _ h: Double) -> [VoiceSpec] {
        [vx(.triangle, 349, 349, d, 0.03, h, 0.2, 0.016, .lowpass, 1300), vx(.triangle, 440, 440, d, 0.03, h, 0.2, 0.014, .lowpass, 1300)]
    }
    static func blast(_ d: Double, _ h: Double) -> [VoiceSpec] {
        [vx(.sawtooth, 110, 108, d, 0.18, h, 0.5, 0.03, .lowpass, 380, 0.3), vx(.sawtooth, 165, 162, d, 0.18, h, 0.5, 0.02, .lowpass, 380, 0.3),
         vx(.sine, 55, 55, d, 0.18, h, 0.5, 0.022)]
    }

    static func voices(_ kind: ContractKind, leaving: Bool) -> [VoiceSpec] {
        switch (kind, leaving) {
        // a mellow British two-tone horn (high, low) and soft clickety-clack pairs, slowing and fading as it pulls in
        case (.train, false):
            return hornNote(392, 0, 0.32, 0.02) + hornNote(330, 0.5, 0.45, 0.02)
                + clacks([0.15, 0.7, 1.3, 1.95, 2.6], [1, 0.85, 0.65, 0.45, 0.25], [0.12, 0.12, 0.13, 0.14, 0.14])
        // leaving: the horn, then the clacks speeding up, swelling and fading away
        case (.train, true):
            return hornNote(392, 0, 0.25, 0.02) + hornNote(330, 0.45, 0.35, 0.02)
                + clacks([1, 1.5, 1.92, 2.28, 2.6], [0.3, 0.55, 0.7, 0.55, 0.3], [0.12, 0.11, 0.1, 0.095, 0.09])
        // the diesel settling, a soft air-brake sigh, a friendly two-note toot; leaving: a toot and the engine pulling away
        case (.bus, false):
            return [vx(.sawtooth, 70, 48, 0, 0.05, 0.5, 0.9, 0.05, .lowpass, 240), vx(noise, 1, 1, 0.9, 0.03, 0.12, 0.45, 0.022, .lowpass, 2400)]
                + toot(1.6, 0.14) + toot(1.95, 0.1)
        case (.bus, true):
            return toot(0, 0.14) + [vx(.sawtooth, 50, 82, 0.3, 0.4, 0.8, 1.2, 0.045, .lowpass, 260), vx(.sine, 100, 164, 0.3, 0.4, 0.8, 1.2, 0.015)]
        // a deep, rounded ship's horn: one long blast and a short one; leaving: one long blast and the screws churning
        case (.ship, false):
            return blast(0, 1) + blast(1.9, 0.35)
        case (.ship, true):
            return blast(0, 1.5) + [vx(noise, 1, 1, 0.6, 0.6, 0.6, 1, 0.02, .lowpass, 500)]
        // the charter plane: a jet's soft roar and whine coming down, two light tyre chirps, a short reverse-thrust swell
        case (.plane, false):
            return [vx(noise, 1, 1, 2.6, 1.2, 0.4, 1.3, 0.045, .lowpass, 900), vx(.sine, 1250, 1000, 2.6, 1, 0.5, 1.2, 0.006),
                    vx(noise, 1, 1, 4.5, 0.01, 0.02, 0.12, 0.03, .bandpass, 1600, 1.5), vx(noise, 1, 1, 4.68, 0.01, 0.02, 0.1, 0.02, .bandpass, 1600, 1.5),
                    vx(noise, 1, 1, 4.7, 0.25, 0.1, 0.55, 0.04, .lowpass, 700)]
        // leaving: the roar, whine and rumble rising with the take-off run and fading as it climbs
        case (.plane, true):
            return [vx(noise, 1, 1, 5.2, 0.9, 0.6, 1.5, 0.05, .lowpass, 1000), vx(.sine, 1300, 1900, 5.2, 0.9, 0.6, 1.5, 0.007),
                    vx(.sawtooth, 75, 110, 5.2, 0.9, 0.6, 1.5, 0.03, .lowpass, 300)]
        // the Mara's bush plane: a single propeller's low drone and the air, a soft bump on the dirt strip
        case (.bush, false):
            return [vx(.sawtooth, 105, 88, 2.6, 1, 0.6, 1.2, 0.035, .lowpass, 420), vx(noise, 1, 1, 2.6, 1, 0.6, 1.2, 0.025, .lowpass, 700),
                    vx(noise, 1, 1, 4.5, 0.02, 0.1, 0.3, 0.04, .lowpass, 400)]
        case (.bush, true):
            return [vx(.sawtooth, 90, 130, 5.2, 0.8, 0.7, 1.5, 0.04, .lowpass, 480), vx(noise, 1, 1, 5.2, 0.8, 0.7, 1.5, 0.025, .lowpass, 800)]
        }
    }
}
