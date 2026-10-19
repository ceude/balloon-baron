import SwiftUI
import BalloonBaronCore

/// Frame-to-frame state of the office scene. Not observed: the canvas mutates it every frame.
final class OfficeSceneModel {
    let t0 = Date.timeIntervalSinceReferenceDate
    var last: Double?
    var bg: [BackgroundBalloon] = []
    var obstacles: [Obstacle] = []
    private var key = ""

    /// Rebuilds the world (like `buildWorld()`) when the day, region or fleet changes.
    func sync(_ s: GameState) {
        let alive = s.local.rivals.filter { $0.alive }.count
        let k = "\(s.region.rawValue)|\(s.weather?.seed ?? 0)|\(s.local.balloons.count)|\(alive)|\(s.local.fiesta != nil)|\(s.colors.joined())"
        guard k != key else { return }
        key = k
        bg = ScenePainter.backgroundBalloons(s)
        obstacles = s.weather.map { FlightWorld.obstacles(for: $0) } ?? []
    }

    /// Seconds since the last frame, capped so a paused app doesn't jump.
    func step(_ t: Double) -> Double {
        let dt = last.map { min(0.1, max(0, t - $0)) } ?? 0
        last = t
        return dt
    }
}

/// The live morning scene behind the home screen: drifting balloons, the landing field, and your
/// flagship with up to four more of your balloons on the launch field. Port of the prototype's
/// `draw()` outside a flight.
struct OfficeSceneView: View {
    @Environment(GameStore.self) private var store
    /// Top of the bottom dock in screen coordinates; the ground line sits 4 pt below it.
    let groundY: CGFloat
    /// Top of the altitude scale (below the HUD), in screen coordinates.
    var topY: CGFloat = 96
    @State private var model = OfficeSceneModel()

    var body: some View {
        let s = store.state
        TimelineView(.animation) { tl in
            Canvas { ctx, size in
                draw(&ctx, size: size, state: s, now: tl.date.timeIntervalSinceReferenceDate)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func draw(_ ctx: inout GraphicsContext, size: CGSize, state: GameState?, now: Double) {
        guard let s = state, let w = s.weather else {
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(hex: "#1b1840")))
            return
        }
        model.sync(s)
        let T = now - model.t0
        let dt = model.step(T)
        let p = 0.12 + sin(T * 0.05) * 0.02
        let dockTop = groundY > 0 ? groundY : size.height * 0.62
        let gy = min(max(size.height * 0.35, dockTop + 4), size.height)
        let top = min(topY, gy - 60)
        let cam = SceneCamera(size: size, groundY: gy, topY: top, focusX: FlightWorld.launchX + sin(T * 0.03) * 40)
        ScenePainter.drift(&model.bg, weather: w, cam: cam, dt: dt, time: T, inFlight: false)
        let vh = ScenePainter.scenery(&ctx, cam: cam, p: p, region: s.region, winter: s.local.winter != nil, time: T,
                                      background: model.bg, inFlight: false)
        ScenePainter.landingField(&ctx, cam: cam, target: w.target, p: p)
        let lx = cam.sx(FlightWorld.launchX)
        ScenePainter.rect(&ctx, lx - 40, gy - 1, 80, 4, ScenePainter.mix("#5c4a3a", "#b9996e", p))
        ScenePainter.obstacles(&ctx, cam: cam, model.obstacles, region: s.region, p: p)
        fleet(&ctx, s, lx: lx, gy: gy, pr: max(12, vh * 0.065), T: T)
    }

    /// Flagship on the launch field (burner flickering), then up to four more beside it.
    private func fleet(_ ctx: inout GraphicsContext, _ s: GameState, lx: CGFloat, gy: CGFloat, pr: CGFloat, T: Double) {
        let flag = s.balloon(s.local.flagship)
        let fk: CGFloat = flag?.size == .XL ? 1.35 : 1
        ScenePainter.balloon(&ctx, x: lx, y: gy - 1, r: pr * fk, colors: s.colors, burn: sin(T * 1.3) > 0.6,
                             ad: flag?.ad, design: flag.flatMap { s.design(of: $0) }, region: s.region, time: T)
        var i = 1
        for b in s.local.balloons where b.id != s.local.flagship {
            let k: CGFloat = b.size == .XL ? 1.35 : 1
            ScenePainter.balloon(&ctx, x: lx - CGFloat(i) * pr * 2.4, y: gy - 1, r: pr * 0.85 * k, colors: s.colors,
                                 ad: b.ad, design: s.design(of: b), region: s.region, time: T)
            i += 1
            if i > 4 { break }
        }
    }
}
