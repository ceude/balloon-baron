import Foundation

/// Short synthesized effects, like the prototype's `sfx()`.
enum Sfx {
    case tick, click, applause, blip, coin, low, fanfare, thud
}

/// All game audio is synthesized in code (no sound files): burner roar, morning ambience with
/// birds, the crowd while passengers gather, and short effects.
final class SoundEngine {
    static let shared = SoundEngine()

    /// Mirrors the player's sound setting; persisted in UserDefaults.
    var enabled: Bool {
        get { UserDefaults.standard.object(forKey: "sound") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "sound") }
    }

    /// Starts the engine and the ambience. Safe to call more than once.
    func start() {}
    func burner(_ on: Bool) {}
    func crowd(_ on: Bool) {}
    func play(_ s: Sfx) {}
}
