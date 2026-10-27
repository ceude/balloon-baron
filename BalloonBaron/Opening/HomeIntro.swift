import Foundation
import SwiftUI

/// v121.5: the pull-back from the opening film's landing to day one's view of the town (`HOMEI` in the prototype). The
/// film hands over in the dark at its own spot and scale; the town pulls back in log-zoom, the landed balloon moving in a
/// straight line on the screen, while the night lifts and a sunrise glow passes.
struct HomeIntro: Equatable {
    /// The 2D zoom matching the film's last frame, and the world point (2D px) under the screen's centre then.
    let z0: CGFloat, px: CGFloat, py: CGFloat
    /// When the pull-back starts (the film fades out over it first).
    let start: Date
    static let dur = 3.4

    /// How far it has come (0 … 1, unclamped).
    func progress(_ now: Date) -> Double { now.timeIntervalSince(start) / HomeIntro.dur }

    /// The viewport at `now`, from the film's framing to `home`, on a canvas of `size`.
    func viewport(home: TownViewport, size: CGSize, now: Date) -> TownViewport {
        let k = CGFloat(oEaseIO3(progress(now)))
        let z = exp(log(z0) + (log(home.z) - log(z0)) * k)
        let sx = size.width / 2 + (px * home.z + home.ox - size.width / 2) * k
        let sy = size.height / 2 + (py * home.z + home.oy - size.height / 2) * k
        var v = TownViewport(z: z, ox: sx - px * z, oy: sy - py * z)
        v.noLabels = true
        return v
    }

    /// The night over the town: dark at the hand-off (0.85), lifting as it pulls back; the sunrise glow passes.
    func night(_ now: Date) -> (k: Double, sunrise: Double) {
        let p = progress(now)
        return (0.85 * (1 - oEaseIO3(oClamp(p * 1.25, 0, 1))), 0.75 * sin(Double.pi * oClamp(p, 0, 1)))
    }
}
