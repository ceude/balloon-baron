import SwiftUI
import BalloonBaronCore

/// v124: Bristol's festival nights (prototype `glowPulse`, `eveRise`): the Night Glow's beat and the evening ascent.
enum BristolNight {
    enum Kind { case glow, eve }

    static func kind(_ e: NightEvent?) -> Kind? {
        switch e {
        case .nightGlow?: .glow
        case .eveningAscent?: .eve
        default: nil
        }
    }

    /// The Night Glow's beat (about 112 bpm): waves along the rows for the first part, then everyone at once.
    static func glowPulse(_ tt: Double, _ i: Int) -> Double {
        let beat = tt * 112 / 60, ph = beat.truncatingRemainder(dividingBy: 1), on = ph < 0.35 ? 1 - ph / 0.35 : 0
        if tt > 6.5 { return on }
        return Int(beat.rounded(.down)) % 4 == i % 4 ? on : on * 0.15
    }

    /// How far (screen points) balloon `i` has risen into the dusk.
    static func eveRise(_ tt: Double, _ i: Int) -> Double {
        let u = tt - 0.8 - Double(i) * 0.35
        return max(0, u) * 34 * min(1, u / 2 + 0.3)
    }
}
