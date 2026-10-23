import UIKit
import BalloonBaronCore

/// Small taps in the hand. The burner hums while it fires, price steps tick, landings land: soft when they
/// are soft, hard when they are hard. iOS turns them off by itself when the phone's system haptics are off.
enum Haptics {
    private static let soft = UIImpactFeedbackGenerator(style: .soft)
    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let medium = UIImpactFeedbackGenerator(style: .medium)
    private static let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private static let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private static let selection = UISelectionFeedbackGenerator()
    private static let notice = UINotificationFeedbackGenerator()
    private static var lastBurn = 0.0
    private static var lastVent = 0.0

    /// While the burner fires: a low rumble, about eight pulses a second.
    static func burner(at t: Double) {
        guard t - lastBurn >= 0.12 else { return }
        lastBurn = t
        soft.impactOccurred(intensity: 0.45)
    }

    /// Burner lit or put out.
    static func burnerToggled(on: Bool) { (on ? medium : light).impactOccurred(intensity: on ? 0.7 : 0.4) }

    /// The parachute vent pulled open: a light tug.
    static func ventOpened() { light.impactOccurred(intensity: 0.6) }

    /// While the vent is held open (and the burner is off): a faint flutter as the air escapes, five pulses a second.
    static func vent(at t: Double) {
        guard t - lastVent >= 0.2 else { return }
        lastVent = t
        light.impactOccurred(intensity: 0.25)
    }

    /// A price step, or any small dial: barely there.
    static func tick() { selection.selectionChanged() }

    /// A button that starts something (take off, collect passengers).
    static func press() { medium.impactOccurred(intensity: 0.6) }

    /// Touchdown, by how it went.
    static func landed(_ q: FlightResult.Landing) {
        switch q {
        case .perfect: notice.notificationOccurred(.success)
        case .good: medium.impactOccurred()
        case .far: light.impactOccurred()
        case .hard: heavy.impactOccurred(intensity: 1)
        case .crash:
            heavy.impactOccurred(intensity: 1)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { rigid.impactOccurred(intensity: 1) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { notice.notificationOccurred(.error) }
        case .cancel: break
        }
    }

    /// Something good happened: a special request done, a chapter finished, a purchase arrived.
    static func success() { notice.notificationOccurred(.success) }

    /// A warning: red flag, cash below zero.
    static func warning() { notice.notificationOccurred(.warning) }

    /// Coins: a small bright tap.
    static func coin() { rigid.impactOccurred(intensity: 0.5) }
}
