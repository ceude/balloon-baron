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

    init(world: OpeningWorld) {
        self.world = world
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
            dawn(1)
            W.cloth.isHidden = true
            W.basket.isHidden = true
            if let h = hero {
                let fill = oEaseIO3(t / 3.4)
                h.node.isHidden = false
                h.env.scale = SCNVector3(Float(oLerp(0.55, 1, fill)), Float(oLerp(0.25, 1, fill)), Float(oLerp(0.55, 1, fill)))
                h.env.simdEulerAngles = F3(0, 0, Float(oLerp(-1.25, 0, oEase3(fill * 1.2))))
                h.env.simdPosition = F3(Float(oLerp(0.5, 0, fill)), 0.3, 0)
                h.node.simdPosition = F3(Float(W.BASKET.x), Float(W.BASKET.y + heroAlt(t)), Float(W.BASKET.z))
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
        // the sun's shadow follows the camera
        let cam = W.cameraNode.simdPosition
        let tgt = F3(cam.x, 0, cam.z)
        W.sunNode.simdPosition = tgt + sunDir * 1100
        W.sunNode.simdOrientation = OpeningFilm.look(from: W.sunNode.simdPosition, to: tgt)
        for m in W.mists {
            let dx = Double(hypot(m.simdPosition.x - cam.x, m.simdPosition.z - cam.z) - m.scale.x * 0.5)
            let dy = Double(abs(m.simdPosition.y - cam.y))
            // no hard edge when the drone flies through
            m.opacity = CGFloat(0.3 * oClamp(max(dx / 120, (dy - 4) / 30), 0, 1) * (part == .a ? 1 : 0.6))
        }
    }

    /// The lift-off's burner: on while the envelope fills, then in bursts until the balloon is away.
    static func heroBurns(_ t: Double) -> Bool { t < 9.5 && (t < 3.4 || sin(t * 4.1) > -0.1) }

    private func heroAlt(_ t: Double) -> Double { t < 3.6 ? 0 : oEaseIO3((t - 3.6) / 8) * 90 }

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
            // the balloon stays in frame, then the view opens
            let k = oEaseIO3((t - 7.2) / 5)
            eye = W.liftUp.point(k)
            at = oLerp(D3(B.x, B.y + 8 + heroAlt(t), B.z), D3(-60, 40, -220), k * k * k)
            fov = oLerp(56, 42, k)
        }
        if part != .a { eye.y = max(eye.y, W.height(eye.x, eye.z) + 2) } // never into the ground
        W.cameraNode.simdPosition = F3(eye)
        W.cameraNode.simdOrientation = OpeningFilm.look(from: F3(eye), to: F3(at))
        W.camera.fieldOfView = CGFloat(fov)
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
