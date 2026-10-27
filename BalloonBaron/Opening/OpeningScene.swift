import BalloonBaronCore
import QuartzCore
import SceneKit
import UIKit
import simd

/// The two takes of the opening film: the flight before dawn (A) and the lift-off (B).
enum OpeningPart { case a, b }

/// Plays the opening film on an `OpeningWorld` (the prototype's `OPEN3D`): one clock per take, the camera on its paths,
/// the dawn, the morning's balloons, the colour pick in the sky and the hero balloon. SceneKit calls `renderer(_:updateAtTime:)`
/// on its render thread; the SwiftUI side talks to it through the locked controls below.
final class OpeningFilm: NSObject, SCNSceneRendererDelegate {
    let world: OpeningWorld

    // controls, shared with the main thread
    private let lock = NSLock()
    private var part = OpeningPart.a
    private var t0 = CACurrentMediaTime()
    private var pickOn = false
    private var pickSel = -1
    private var aspect = 0.5
    private var pending: [() -> Void] = []
    private var pickSpots: [(F3, Float)] = []
    private var pickReady = 0.0

    // render-thread state
    private var pickBuilt = false
    private var pk = 0.0
    private var pkLast: Double?
    private var pkDir = D3(0, 1, 0)
    private var pickHome: [D3] = []
    private var pickSize: [Double] = []
    private var pickK: [Double] = []
    private var hero: FilmBalloon?
    private var lastDawn = -1.0
    private var heroBurn = false
    /// What the camera looks at after the lift-off (the shadows follow it), nil before.
    private var lastLook: D3?

    // v121.5: the flight to our town. `slot` (shared) is the launch-field spot the game gives the flagship.
    private var slot = (gx: 1.8, gy: 5.0)
    private var handoffInfo = (dist: 300.0, fov: 14.0, lookY: 3.5)
    /// The camera's offset from the balloon after the lift-off: behind the drift (south-west), up, then round to the
    /// game's own angle, from the south-east 30° down (`CRANE`).
    private let crane: CRCurve
    private static let craneFov = [66.0, 55, 48, 45, 40, 26, 14]
    /// The take B's length up to the hand-off to the game's town.
    static let landedAt = 23.8

    init(world: OpeningWorld) {
        self.world = world
        let B = world.BASKET, h72 = OpeningFilm.heroPos(7.2, basket: B, land: OpeningLand.tw(1.8, 5))
        let iso = D3(1, 0, 1) / 2.0.squareRoot() * cos(Double.pi / 6) + D3(0, sin(Double.pi / 6), 0)
        let cr0 = D3(B.x + 3, 1.2, B.z + 9) - h72, ISO = iso * 285
        crane = CRCurve([cr0, D3(-22, 32, 34), D3(-52, 96, 42), D3(-58, 140, 48), D3(10, 160, 110), D3(110, 155, 150), ISO])
        super.init()
        pickK = Array(repeating: 0, count: world.pick.count)
        frame(.a, 0, CACurrentMediaTime())
    }

    // MARK: controls (main thread)

    private func locked<T>(_ f: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return f()
    }

    /// The take on screen and its time.
    func clock() -> (OpeningPart, Double) { locked { (part, CACurrentMediaTime() - t0) } }

    /// Starts a take from its beginning.
    func start(_ p: OpeningPart) { locked { part = p; t0 = CACurrentMediaTime() } }

    /// Jumps the take on screen to `t` (`seek`): the flight's last frame is held under the cards.
    func seek(_ t: Double) { locked { t0 = CACurrentMediaTime() - t } }

    /// The colour pick in the sky on or off (`pick(choices)` / `pick(null)`); `aspect` is the view's width over height.
    func setPick(_ on: Bool, aspect a: Double) { locked { pickOn = on; aspect = a } }

    func select(_ i: Int) { locked { pickSel = i } }

    /// Builds the company's balloon (its texture here on the main thread), then hands it to the render thread.
    func prepareHero(name: String, colors: [String]) {
        let h = world.makeHero(name: name, colors: colors)
        locked {
            pending.append { [weak self] in
                guard let self else { return }
                self.hero?.node.removeFromParentNode()
                h.node.isHidden = true
                self.world.scene.rootNode.addChildNode(h.node)
                if let m = h.env.geometry?.firstMaterial { self.world.addFogged(m) }
                self.hero = h
                self.lastDawn = -1
            }
        }
    }

    /// v121.5: builds our town (in the background) from the new company's first day, and lands the balloon on the
    /// flagship's spot on the launch field (`fieldSlots`).
    func prepareTown(_ s: GameState) {
        let i = s.fieldBalloons.prefix(6).firstIndex { $0.id == s.local.flagship } ?? 0
        locked { slot = (1.8 + Double(i % 3) * 1.9, 5 + Double(i / 3) * 1.4) }
        let kit = world.kit, lit = world.litWindows
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let (node, mats) = OpeningTown.build(s, kit: kit, litWindows: lit)
            guard let self else { return }
            self.locked {
                self.pending.append { [weak self] in
                    guard let self else { return }
                    self.world.scene.rootNode.addChildNode(node)
                    for m in mats { self.world.addFogged(m) }
                    self.lastDawn = -1
                }
            }
        }
    }

    /// `OPEN3D.handoff()`: the 2D town's zoom that matches this frame (12 m tiles seen at the game's angle, the view `height`
    /// points tall), the flagship's grid spot, and how high above it the camera looks (in 2D pixels).
    func handoff(height: Double) -> (z: Double, gx: Double, gy: Double, up: Double) {
        let (h, s) = locked { (handoffInfo, slot) }
        let ppm = height / (2 * h.dist * tan(h.fov * Double.pi / 180 / 2))
        return (ppm * OpeningLand.TL * 2.0.squareRoot() / 128, s.gx, s.gy, h.lookY * OpeningTown.PXM)
    }

    /// The pick balloon under a tap (`pointerdown` on the canvas), once the camera has turned far enough to the sky.
    func pickTarget(at pt: CGPoint, in view: SCNView) -> Int? {
        let (spots, ready, up) = locked { (pickSpots, pickReady, pickUp) }
        guard ready >= 0.6, !spots.isEmpty else { return nil }
        var best: Int?, bd = Double.infinity
        for (i, (c, s)) in spots.enumerated() {
            let p = view.projectPoint(SCNVector3(c.x, c.y, c.z))
            let e = c + up * (s * 0.7)
            let q = view.projectPoint(SCNVector3(e.x, e.y, e.z))
            let rad = Double(hypot(q.x - p.x, q.y - p.y)) * 1.2
            guard p.z < 1, rad > 0 else { continue }
            let dd = Double(hypot(Float(pt.x) - p.x, Float(pt.y) - p.y)) / rad
            if dd < 1 && dd < bd { bd = dd; best = i }
        }
        return best
    }

    private var pickUp = F3(0, 1, 0)

    // MARK: the render loop

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        let now = CACurrentMediaTime()
        let (p, start, jobs) = locked { () -> (OpeningPart, Double, [() -> Void]) in
            let j = pending
            pending = []
            return (part, t0, j)
        }
        for j in jobs { j() }
        frame(p, now - start, now)
    }

    /// `frameAt(part, t)`: everything that moves, for this moment of the take.
    private func frame(_ part: OpeningPart, _ t: Double, _ time: Double) {
        let W = world
        let ta = part == .a ? t : 30 + t
        for c in W.crowd {
            let rise = max(0, ta - c.go), alt = c.v * max(0, rise - 2 + 2 * exp(-rise / 2)) // eases off the ground
            c.b.node.simdPosition = F3(Float(c.x + sin(time * 0.2 + c.ph) * 2 + rise * 0.8), Float(c.gy + alt), Float(c.z))
            let burn = ta < c.go + 6 ? (sin(time * 5 + c.ph * 3) > -0.3 ? 1 : 0.15) : (sin(time * 1.3 + c.ph) > 0.7 ? 0.8 : 0)
            c.b.glow.opacity = CGFloat(burn * (part == .a ? 1 - oClamp((t - 20) / 6, 0, 1) * 0.6 : 0.4))
            let gs = Float(0.9 + sin(time * 30 + c.ph) * 0.1)
            c.b.glow.scale = SCNVector3(gs, gs, gs)
        }
        if part == .a {
            dawn(oClamp((t - 5) / 17, 0, 1))
            W.cloth.isHidden = false
            W.basket.isHidden = false
            hero?.node.isHidden = true
            if heroBurn { heroBurn = false; W.flameLight.intensity = 0 }
        } else {
            // v121.5: night falls on the town after the landing (the darkening is the overlay's, in OpeningView)
            dawn(1 - OpeningFilm.dusk(t) * 0.97)
            W.cloth.isHidden = true
            W.basket.isHidden = true
            // the colour choices stay behind in the sky
            if pk > 0 {
                pk = 0
                for b in W.pick { b.node.isHidden = true }
                W.halo.isHidden = true
            }
            if let h = hero {
                let fill = oEaseIO3(t / 3.4)
                h.node.isHidden = false
                h.env.scale = SCNVector3(Float(oLerp(0.55, 1, fill)), Float(oLerp(0.25, 1, fill)), Float(oLerp(0.55, 1, fill)))
                h.env.simdEulerAngles = F3(0, 0, Float(oLerp(-1.25, 0, oEase3(fill * 1.2))))
                h.env.simdPosition = F3(Float(oLerp(0.5, 0, fill)), 0.3, 0)
                OpeningWorld.ropeFrame(h, fill: fill)
                h.node.simdPosition = F3(heroPos(t))
                let s = Float(OpeningFilm.heroS(t))
                h.node.scale = SCNVector3(s, s, s)
                h.node.simdEulerAngles = F3(0, Float(time * 0.05), 0)
                let burn = OpeningFilm.heroBurns(t)
                heroBurn = burn
                h.glow.opacity = burn ? 1 : 0
                let gs = Float(1.2 + sin(time * 40) * 0.2)
                h.glow.scale = SCNVector3(gs, gs, gs)
                // three.js's 300 cd ±70 at the burner; SceneKit's lumens, scaled to light the envelope's mouth alike
                W.flameLight.intensity = burn ? CGFloat((300 + sin(time * 33) * 70) / 300 * 5000) : 0
            }
        }
        place(part, t)
        if part == .a { pickFrame(time) }
        // the sun's shadow follows the camera, after the lift-off what it looks at
        let cam = W.cameraNode.simdPosition, focus = lastLook.map { F3($0) } ?? cam
        let tgt = F3(focus.x, 0, focus.z)
        W.sunNode.simdPosition = tgt + sunDir * 1100
        W.sunNode.simdOrientation = OpeningFilm.look(from: W.sunNode.simdPosition, to: tgt)
        for m in W.mists {
            let dx = Double(hypot(m.simdPosition.x - cam.x, m.simdPosition.z - cam.z) - m.scale.x * 0.5)
            let dy = Double(abs(m.simdPosition.y - cam.y))
            // no hard edge when the drone flies through
            m.opacity = CGFloat(0.3 * oClamp(max(dx / 120, (dy - 4) / 30), 0, 1) * (part == .a ? 1 : 0.6))
        }
    }

    /// The lift-off's burner: on while the envelope fills, in bursts until the balloon is away, then bursts to hold the
    /// height and to soften the landing.
    static func heroBurns(_ t: Double) -> Bool {
        (t < 9.5 && (t < 3.4 || sin(t * 4.1) > -0.1)) || (t > 13.5 && t < 14.6) || (t > 18.4 && t < 19.8)
    }

    /// Night falling after the landing (0 … 1).
    static func dusk(_ t: Double) -> Double { oEaseIO3((t - 21.4) / 2.2) }

    private static func heroAlt(_ t: Double) -> Double { t < 3.6 ? 0 : oEaseIO3((t - 3.6) / 8) * 90 }
    private func heroAlt(_ t: Double) -> Double { OpeningFilm.heroAlt(t) }

    /// Far from the camera the balloon shrinks to the game's scale.
    static func heroS(_ t: Double) -> Double { oLerp(15, 7.6, oEaseIO3((t - 9) / 7)) }

    /// After the lift-off the balloon drifts north-east to our town and comes down on its spot on the launch field.
    static func heroPos(_ t: Double, basket B: D3, land L: D3) -> D3 {
        let u = oEaseIO3((t - 6) / 15), alt = t < 14 ? heroAlt(t) : 90 * (1 - oEaseIO3((t - 14) / 7))
        return D3(oLerp(B.x, L.x, u), B.y + alt, oLerp(B.z, L.z, u))
    }

    private var land: D3 {
        let s = locked { slot }
        return OpeningLand.tw(s.gx, s.gy)
    }

    private func heroPos(_ t: Double) -> D3 { OpeningFilm.heroPos(t, basket: world.BASKET, land: land) }

    // MARK: camera

    /// A camera's orientation looking from `eye` at `target`, world up (three.js's `lookAt`).
    static func look(from eye: F3, to target: F3) -> simd_quatf {
        let z = simd_normalize(eye - target)
        var x = simd_cross(F3(0, 1, 0), z)
        x = simd_length(x) < 1e-5 ? F3(1, 0, 0) : simd_normalize(x)
        let y = simd_cross(z, x)
        return simd_quatf(simd_float3x3(columns: (x, y, z)))
    }

    /// The time along the flight: slower in the first orbit and at the end, quicker across the plateau.
    private func warp(_ t: Double) -> Double {
        let k = oClamp(t / OpeningWorld.flightDur, 0, 1)
        return oClamp(oEaseIO3(k) * 0.25 + k * 0.75, 0, 1)
    }

    private func flightFov(_ t: Double) -> Double {
        t < 6 ? 48 : t < 19 ? 52 : t < 24 ? 46 : oLerp(46, 38, oClamp((t - 24) / 6, 0, 1))
    }

    /// A soft max: rides `b` smoothly when `a` comes near it.
    private func smax(_ a: Double, _ b: Double, _ k: Double) -> Double { (a + b + ((a - b) * (a - b) + k * k).squareRoot()) / 2 }

    /// `place(part, t)`: the camera on its path.
    private func place(_ part: OpeningPart, _ t: Double) {
        let W = world, B = W.BASKET
        var eye: D3, at: D3, fov: Double
        if part == .a {
            let u = warp(t)
            eye = W.flightEye.point(u)
            eye.y = smax(eye.y, W.flightFloor(u), oLerp(6, 0.3, oClamp((u - 0.955) / 0.03, 0, 1)))
            at = W.flightAt.point(u)
            fov = flightFov(t)
        } else if t < 3.6 {
            eye = W.liftEye.point(oEaseIO3(t / 3.6) * 0.5)
            at = D3(B.x + 7, B.y + 6, B.z)
            fov = 46
        } else if t < 7.2 {
            eye = W.liftEye.point(0.5 + oEaseIO3((t - 3.6) / 3.6) * 0.5)
            at = D3(B.x, B.y + 10 + heroAlt(t) * 0.9, B.z - 12)
            fov = 66
        } else {
            // v121.5: the camera rides with the balloon: pulls away and climbs faster to look down from high, then swings
            // round to the game's own angle and closes in on a long lens as it lands (away quickly, settling slowly)
            let k = oClamp((t - 7.2) / 14.8, 0, 1), p = 1 - pow(1 - k, 2.4) * (1 - 0.5 * pow(1 - k, 6))
            let hp = heroPos(t), F = OpeningFilm.craneFov, fi = p * Double(F.count - 1), f0 = Int(floor(min(fi, Double(F.count - 2))))
            eye = hp + crane.point(p)
            let center = hp + D3(0, OpeningFilm.heroS(t) * 0.92, 0), old = D3(B.x, B.y + 10 + heroAlt(t) * 0.9, B.z - 12)
            let hand = land + D3(0, 3.5, 0)
            at = oLerp(oLerp(old, center, oEaseIO3((t - 7.2) / 1.3)), hand, oEaseIO3((t - 19) / 3))
            fov = oLerp(F[f0], F[f0 + 1], fi - Double(f0))
        }
        if part != .a { eye.y = max(eye.y, W.height(eye.x, eye.z) + 2) } // never into the ground
        lastLook = part == .b && t >= 7.2 ? at : nil
        W.cameraNode.simdPosition = F3(eye)
        W.cameraNode.simdOrientation = OpeningFilm.look(from: F3(eye), to: F3(at))
        W.camera.fieldOfView = CGFloat(fov)
        if part == .b {
            let info = (dist: simd_distance(eye, at), fov: fov, lookY: at.y)
            locked { handoffInfo = info }
        }
    }

    // MARK: the colour pick in the sky (v121.3)

    /// `pickBuild`: away from the sun, so the envelopes are lit from the front in full colour; the choices spread over the
    /// view like the 2D pick, the bigger ones nearer.
    private func pickBuild(_ aspect: Double) {
        pickBuilt = true
        let eye = world.flightEye.point(1), base = simd_normalize(D3(-0.45, 0, 1))
        let fwd = simd_normalize(base * 0.62 + D3(0, 0.78, 0)), right = simd_normalize(simd_cross(fwd, D3(0, 1, 0))), up = simd_cross(right, fwd)
        pkDir = fwd
        let tv = tan(50 * Double.pi / 180 / 2), th = tv * aspect
        pickHome = []
        pickSize = []
        for p in PickBalloon.all {
            let d = oLerp(150, 70, oClamp((p.scale - 0.45) / 0.6, 0, 1))
            pickSize.append(d * 0.085)
            pickHome.append(eye + fwd * d + right * ((2 * Double(p.x) - 1) * th * 0.85 * d) + up * ((1 - 2 * Double(p.y)) * tv * d))
        }
    }

    /// `pickFrame`: the camera turns up and round to the sky; the chosen balloon comes forward with its burner lit.
    private func pickFrame(_ time: Double) {
        let (on, sel, a) = locked { (pickOn, pickSel, aspect) }
        if on && !pickBuilt { pickBuild(a) }
        guard pickBuilt else { return }
        let dt = min(0.2, max(0, time - (pkLast ?? time)))
        pkLast = time
        pk = oClamp(pk + (on ? dt / 1.8 : -dt / 1.2), 0, 1)
        let k = oEaseIO3(pk)
        var spots: [(F3, Float)] = []
        for (i, b) in world.pick.enumerated() {
            let isSel = i == sel
            pickK[i] = oLerp(pickK[i], isSel ? 1 : 0, min(1, dt * 6))
            b.node.isHidden = pk <= 0
            let sz = pickSize[i], s = sz * (1 + pickK[i] * 0.35), ph = Double(i) * 1.7
            b.node.scale = SCNVector3(Float(s), Float(s), Float(s))
            var pos = pickHome[i] - pkDir * (pickK[i] * 12)
            pos.y += sin(time * 0.7 + ph) * sz * 0.25 - s * 0.92 + (1 - k) * 40 // the envelope's middle on the spot
            b.node.simdPosition = F3(pos)
            let burn = isSel && sin(time * 5 + ph) > -0.4
            b.glow.opacity = burn ? 1 : 0
            let gs = Float(1.1 + sin(time * 37) * 0.15)
            b.glow.scale = SCNVector3(gs, gs, gs)
            let center = F3(Float(pos.x), Float(pos.y + s * 0.92), Float(pos.z))
            if isSel {
                world.halo.simdPosition = center
                let hs = Float(s * 4.2)
                world.halo.scale = SCNVector3(hs, hs, hs)
            }
            spots.append((center, Float(s)))
        }
        world.halo.isHidden = !(pk > 0 && sel >= 0)
        if k > 0 {
            let cam = world.cameraNode
            let q0 = cam.simdOrientation, q1 = OpeningFilm.look(from: cam.simdPosition, to: cam.simdPosition + F3(pkDir))
            cam.simdOrientation = simd_slerp(q0, q1, Float(k))
            world.camera.fieldOfView = CGFloat(oLerp(Double(world.camera.fieldOfView), 50, k))
        }
        let up = world.cameraNode.simdOrientation.act(F3(0, 1, 0))
        let ready = pk
        locked {
            pickSpots = spots
            pickReady = ready
            pickUp = up
        }
    }

    // MARK: dawn

    private var sunDir = simd_normalize(F3(0.45, -0.07, -1))

    private static let zenNight = linearColor("#0b0a26"), zenDay = linearColor("#5d8fd0")
    private static let horNight = linearColor("#4a3460"), horDawn = linearColor("#ff9d70"), horDay = linearColor("#ffd6ae")
    private static let sunRed = linearColor("#ff7a3a"), sunDay = linearColor("#ffe0bc")
    private static let skyNight = linearColor("#5a6ab8"), skyDay = linearColor("#ffe2c8")
    private static let groundNight = linearColor("#2a1a2e"), groundDay = linearColor("#b07a52")
    private static let mistNight = linearColor("#6a5a8a"), mistDay = linearColor("#ffd2b4")
    private static let hole = linearColor(0x2a1812), window = linearColor(0xffb35a)

    /// `setDawn(u)`: 0 night … 1 morning. three.js's light intensities are divided by π (its Lambert); SceneKit's 1000 is 1.
    private func dawn(_ u: Double) {
        guard abs(u - lastDawn) > 1e-4 else { return }
        lastDawn = u
        let W = world, f = Float(u)
        func mix(_ a: F3, _ b: F3, _ k: Float) -> F3 { simd_mix(a, b, F3(repeating: k)) }
        let el = oLerp(-0.07, 0.17, u)
        sunDir = simd_normalize(F3(0.45, Float(el), -1))
        let sunK = Float(oClamp(u * 1.6 - 0.25, 0, 1))
        let zen = mix(OpeningFilm.zenNight, OpeningFilm.zenDay, f)
        let hor = mix(mix(OpeningFilm.horNight, OpeningFilm.horDawn, min(1, f * 1.5)), OpeningFilm.horDay, Float(oClamp((u - 0.7) / 0.3, 0, 1)))
        let sky = W.skyMaterial
        sky.setValue(OpeningKit.vector(sunDir), forKey: "oSunDir")
        sky.setValue(OpeningKit.vector(zen), forKey: "oZen")
        sky.setValue(OpeningKit.vector(hor), forKey: "oHor")
        sky.setValue(OpeningKit.vector(linearColor("#ffb26a")), forKey: "oGlow")
        sky.setValue(NSNumber(value: sunK), forKey: "oSunK")
        W.sun.intensity = CGFloat(oClamp(u * 1.5 - 0.2, 0, 1) * 3.8 / Double.pi * 1000)
        W.sun.color = OpeningKit.color(mix(OpeningFilm.sunRed, OpeningFilm.sunDay, f))
        // the hemisphere light: an even part all round, the rest from above (sky) or below (ground)
        let hemi = Float(oLerp(0.5, 0.7, u) / Double.pi)
        let skyC = mix(OpeningFilm.skyNight, OpeningFilm.skyDay, f) * hemi, groundC = mix(OpeningFilm.groundNight, OpeningFilm.groundDay, f) * hemi
        W.ambient.color = OpeningKit.color((skyC + groundC) / 2)
        W.skyFill.color = OpeningKit.color(simd_max(skyC - groundC, .zero) / 2)
        W.groundFill.color = OpeningKit.color(simd_max(groundC - skyC, .zero) / 2)
        let fogColor = OpeningKit.vector(hor * 0.85), density = NSNumber(value: Float(oLerp(0.0017, 0.0007, u)))
        for m in W.fogged {
            m.setValue(fogColor, forKey: "oFogColor")
            m.setValue(density, forKey: "oFogDensity")
        }
        W.stars.opacity = CGFloat(oClamp(1 - u * 2.4, 0, 1))
        W.moon.opacity = CGFloat(oClamp(1 - u * 1.8, 0, 1))
        W.litWindows.diffuse.contents = OpeningKit.color(mix(OpeningFilm.hole, OpeningFilm.window, Float(oClamp(1.15 - u * 1.3, 0.15, 1))))
        W.lantern.intensity = CGFloat(oLerp(40, 8, u) / 40 * 3000)
        W.mistMaterial.multiply.contents = OpeningKit.color(mix(OpeningFilm.mistNight, OpeningFilm.mistDay, f))
        W.dust.opacity = CGFloat(oClamp((u - 0.45) * 1.4, 0, 0.7))
        W.camera.exposureOffset = CGFloat(log2(oLerp(0.85, 1.05, u)))
    }
}
