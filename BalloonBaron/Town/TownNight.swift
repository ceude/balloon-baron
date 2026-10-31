import SwiftUI
import BalloonBaronCore

// The night between two days (prototype v82–v85): dusk falls on the town, windows and lamps light up,
// crickets sing, fireflies drift, and now and then something happens. A big button brings the morning;
// it also comes by itself after a few seconds, and looking around restarts the wait.

/// How dark it is (0 day … 1 night) and what lights the night up.
struct TownNight {
    var k: Double
    var event: NightEvent?
    /// When the night started, in painter time, for the event's animation.
    var t0: Double
    /// The sunrise glow at the dawn (0 … 1).
    var sunrise: Double = 0
    /// The Balloon Show's sprites, resolved from the night canvas's symbols.
    var sprite: ((BalloonShow.Look) -> GraphicsContext.ResolvedSymbol?)? = nil
    /// The balloons stay out on the launch field (the opening film's landing, v121.5).
    var fieldShown = false
}

/// The night camera (`nightBase`, `nightClamp`, `nightHorizon`): closer than the home screen, with a big sky.
/// The morning keeps it, so the home town uses it too until you zoom all the way out.
enum NightCamera {
    static func base(_ sz: CGSize) -> TownViewport {
        let c = TownGeo.iso(7.5, 7.5), z = min(max(sz.width / 820, 0.3), 0.7)
        return TownViewport(z: z, ox: sz.width / 2 - c.x * z, oy: sz.height * 0.7 - c.y * z)
    }

    /// Keep the town on screen however far you drag; sideways as far as the zoomed town (either corner of the walls).
    static func clamp(_ v: inout TownViewport, _ sz: CGSize) {
        let w = sz.width, h = sz.height, c = TownGeo.iso(7.5, 7.5)
        let sx = c.x * v.z + v.ox, sy = c.y * v.z + v.oy, mx = 16 * TownGeo.TW / 2 * v.z, my = 8 * TownGeo.TH / 2 * v.z
        v.ox += min(max(sx, min(w * 0.5, w * 0.85 - mx)), max(w * 0.5, w * 0.15 + mx)) - sx
        v.oy += min(max(sy, min(h * 0.5, h * 0.35 - my * 0.3)), max(h * 0.7, h * 0.75 + my * 0.3)) - sy
    }

    /// A big night sky; the horizon follows the town as you drag.
    static func horizon(_ v: TownViewport, _ sz: CGSize) -> CGFloat {
        let B = base(sz), h = sz.height
        return min(max(h * 0.34 + (v.oy - B.oy) * 0.6 - (v.z / B.z - 1) * h * 0.25, -h * 0.5), h * 0.55)
    }
}

/// A window or door drawn this frame, relit over the dark.
struct NightWindow {
    var p: CGPoint, q: CGPoint, h: CGFloat, u: CGFloat, v: CGFloat, w: CGFloat, hh: CGFloat
    var door: Bool
}

extension TownPainter {
    /// The sunrise: warm light swelling up from the horizon on the left, over the town and the last of the night.
    func sunriseLayer(screen: GraphicsContext, hz: CGFloat, amount: Double) {
        let a = sin(amount * .pi / 2), w = size.width, h = size.height, y = min(max(hz, 0), h)
        let all = Path(CGRect(x: 0, y: 0, width: w, height: h))
        var g = screen
        g.blendMode = .screen
        g.fill(all, with: .radialGradient(Gradient(stops: [
            .init(color: Color(red: 1, green: 178 / 255, blue: 92 / 255).opacity(0.55 * a), location: 0),
            .init(color: Color(red: 1, green: 140 / 255, blue: 90 / 255).opacity(0.22 * a), location: 0.45),
            .init(color: Color(red: 1, green: 140 / 255, blue: 90 / 255).opacity(0), location: 1)
        ]), center: CGPoint(x: w * 0.22, y: y), startRadius: 0, endRadius: max(w, h) * 0.95))
        g.fill(all, with: .color(Color(red: 1, green: 214 / 255, blue: 160 / 255).opacity(0.1 * a)))
    }

    mutating func nightLayer(screen: GraphicsContext, world: GraphicsContext, hz: CGFloat) {
        guard let n = night else { return }
        let k = n.k, w = size.width, h = size.height
        // The whole scene goes dusky blue; the corners sink deeper so the lit middle draws the eye.
        var dark = screen
        dark.blendMode = .multiply
        dark.fill(Path(CGRect(x: 0, y: 0, width: w, height: h)), with: .color(mix("#ffffff", "#2c3270", k)))
        dark.fill(Path(CGRect(x: 0, y: 0, width: w, height: h)),
                  with: .radialGradient(Gradient(colors: [.white, mix("#ffffff", "#5a5a90", k)]), center: pt(w / 2, h * 0.62),
                                        startRadius: min(w, h) * 0.25, endRadius: max(w, h) * 0.75))
        // Cool moonlight from the upper right and a thin mist on the far valley.
        var moon = screen
        moon.blendMode = .screen
        moon.fill(Path(CGRect(x: 0, y: 0, width: w, height: h)),
                  with: .radialGradient(Gradient(colors: [Color(red: 90 / 255, green: 110 / 255, blue: 170 / 255).opacity(0.22 * k), .clear]),
                                        center: pt(w * 0.78, 0), startRadius: 0, endRadius: h * 0.8))
        moon.fill(Path(CGRect(x: 0, y: hz - 20, width: w, height: 80)),
                  with: .linearGradient(Gradient(colors: [.clear, Color(red: 140 / 255, green: 150 / 255, blue: 200 / 255).opacity(0.16 * k), .clear]),
                                        startPoint: pt(0, hz - 20), endPoint: pt(0, hz + 60)))
        // Stars and the moon over the horizon.
        var sky = screen
        sky.opacity = k
        var R = Mulberry32(seed: 11)
        for i in 0..<90 {
            let x = CGFloat(R.next()) * w, y = CGFloat(R.next()) * hz * 0.95, sp = 1 + R.next() * 2
            let tw = 0.5 + 0.5 * sin(t * sp + Double(i))
            sky.fill(Path(CGRect(x: x, y: y, width: 1.6, height: 1.6)), with: .color(Color(red: 1, green: 248 / 255, blue: 220 / 255).opacity(0.35 + 0.5 * tw)))
        }
        if hz > 110 {
            let mx = w * 0.78, my = max(60, hz * 0.3)
            sky.fill(Path(ellipseIn: CGRect(x: mx - 70, y: my - 70, width: 140, height: 140)),
                     with: .radialGradient(Gradient(colors: [Color(red: 1, green: 250 / 255, blue: 225 / 255).opacity(0.45), .clear]),
                                           center: pt(mx, my), startRadius: 4, endRadius: 70))
            sky.fill(Path(ellipseIn: CGRect(x: mx - 15, y: my - 15, width: 30, height: 30)), with: .color(hex("#fff8dc")))
            sky.fill(Path(ellipseIn: CGRect(x: mx + 7 - 13, y: my - 4 - 13, width: 26, height: 26)), with: .color(mix("#fff8dc", "#262a62", 0.85)))
        }
        if case .shootingStar = n.event {
            let p = (t - n.t0).truncatingRemainder(dividingBy: 3.5) / 0.9
            if p < 1 {
                let x0 = w * 0.15 + CGFloat(p) * w * 0.5, y0 = hz * 0.15 + CGFloat(p) * hz * 0.25
                var trail = Path()
                trail.move(to: pt(x0 - 60, y0 - 30)); trail.addLine(to: pt(x0, y0))
                sky.stroke(trail, with: .linearGradient(Gradient(colors: [.clear, .white.opacity(0.95)]), startPoint: pt(x0 - 60, y0 - 30), endPoint: pt(x0, y0)),
                           lineWidth: 2)
            }
        }
        c = world
        relightWindows(k)
        var lit = world
        lit.blendMode = .plusLighter
        func glow(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ rgb: (Double, Double, Double), _ a: Double, sy: CGFloat = 1) {
            var g = lit
            g.translateBy(x: x, y: y)
            g.scaleBy(x: 1, y: sy)
            g.fill(Path(ellipseIn: CGRect(x: -r, y: -r, width: r * 2, height: r * 2)),
                   with: .radialGradient(Gradient(colors: [Color(red: rgb.0 / 255, green: rgb.1 / 255, blue: rgb.2 / 255).opacity(min(1, a)), .clear]),
                                         center: .zero, startRadius: 0, endRadius: r))
        }
        // Street lamps: a dark post, a small bright lantern, a halo and a warm pool of light on the cobbles.
        let lanterns = s.placed(.lanterns)
        let lamps: [(Double, Double)] = lanterns ? TownPainter.lanternSpots : [(3.5, 7.4), (11.5, 7.4), (7.4, 3.5), (7.4, 11.5)]
        for (gx, gy) in lamps {
            let p = iso(gx, gy), fl = 0.9 + 0.1 * sin(t * 9 + gx * 3) * sin(t * 4.1 + gy)
            glow(p.x + 6, p.y + 2, 58, (255, 180, 95), 0.42 * k * fl, sy: 0.42)
            if !lanterns {
                world.fill(Path(CGRect(x: p.x - 1.5, y: p.y - 40, width: 3, height: 40)), with: .color(hex("#1c1a30")))
                world.fill(Path(CGRect(x: p.x - 5, y: p.y - 47, width: 10, height: 7)), with: .color(hex("#1c1a30")))
            }
            glow(p.x, p.y - 44, 30, (255, 190, 110), 0.38 * k * fl)
            glow(p.x, p.y - 44, 7, (255, 240, 200), 0.95 * k)
        }
        // The influencer agency's pool, lit from below.
        if s.unlocked.contains(.agency) {
            let pp = iso(9.8, 11.17)
            glow(pp.x, pp.y, 46, (80, 220, 230), 0.45 * k * (0.85 + 0.15 * sin(t * 1.7)), sy: 0.45)
        }
        // Festoon lights between the lamps along the main roads, only with the bazaar's lantern strings.
        if lanterns {
            var pairs: [((Double, Double), (Double, Double))] = []
            for i in lamps.indices {
                for j in lamps.indices where j > i {
                    let a = lamps[i], b = lamps[j]
                    if (a.0 == b.0 || a.1 == b.1) && hypot(a.0 - b.0, a.1 - b.1) < 4.2 && !(a.0 < 7.4 && b.0 > 7.4) && !(a.1 < 7.4 && b.1 > 7.4) { pairs.append((a, b)) }
                }
            }
            for (a, b) in pairs {
                let P = iso(a.0, a.1), Q = iso(b.0, b.1), H: CGFloat = 42
                var wire = Path()
                wire.move(to: pt(P.x, P.y - H))
                wire.addQuadCurve(to: pt(Q.x, Q.y - H), control: pt((P.x + Q.x) / 2, (P.y + Q.y) / 2 - H + 22))
                world.stroke(wire, with: .color(Color(red: 30 / 255, green: 25 / 255, blue: 45 / 255).opacity(0.7 * k)), lineWidth: 0.8)
                for i in 1..<13 {
                    let f = CGFloat(i) / 13, x = P.x + (Q.x - P.x) * f, y = P.y + (Q.y - P.y) * f - H + 22 * f * (1 - f)
                    let tw = 0.65 + 0.35 * sin(t * 2.5 + Double(i) * 1.7 + a.0)
                    glow(x, y + 2, 6, i % 3 == 0 ? (255, 150, 170) : (255, 205, 130), 0.9 * k * tw)
                }
            }
        }
        // Each bazaar decoration gets its own night lighting.
        if s.placed(.fountain) {
            let p = iso(8, 8)
            glow(p.x, p.y, 70, (255, 190, 110), 0.25 * k, sy: 0.5)
            glow(p.x, p.y - 9, 30, (90, 230, 255), 0.75 * k, sy: 0.47)
            glow(p.x, p.y - 36, 16, (200, 250, 255), 0.6 * k)
            for i in 0..<8 {
                let an = t * 1.3 + Double(i) * 0.8, r = CGFloat(10 + (i * 7) % 16)
                glow(p.x + CGFloat(cos(an)) * r, p.y - 9 + CGFloat(sin(an)) * r * 0.45, 3, (255, 255, 255), (0.4 + 0.4 * sin(t * 6 + Double(i))) * k)
            }
        }
        if s.placed(.statue) {
            let p = iso(TownPainter.statueAt.0, TownPainter.statueAt.1)
            for sx: CGFloat in [-1, 1] {
                var beam = Path()
                beam.move(to: pt(p.x + sx * 8, p.y - 2)); beam.addLine(to: pt(p.x + sx * 34, p.y - 70)); beam.addLine(to: pt(p.x - sx * 4, p.y - 70)); beam.closeSubpath()
                lit.fill(beam, with: .linearGradient(Gradient(colors: [Color(red: 1, green: 230 / 255, blue: 180 / 255).opacity(0.5 * k), .clear]),
                                                     startPoint: p, endPoint: pt(p.x + sx * 6, p.y - 70)))
            }
            glow(p.x, p.y - 52, 34, (255, 200, 120), 0.35 * k)
            glow(p.x - 18, p.y - 52, 6, (255, 240, 200), (0.5 + 0.5 * sin(t * 2)) * k)
            glow(p.x + 20, p.y - 50, 5, (255, 240, 200), (0.5 + 0.5 * sin(t * 2 + 2)) * k)
        }
        if s.placed(.flags) {
            for (gx, gy) in TownPainter.flagSpots {
                let p = iso(gx, gy)
                var beam = Path()
                beam.move(to: pt(p.x - 3, p.y)); beam.addLine(to: pt(p.x + 3, p.y)); beam.addLine(to: pt(p.x + 26, p.y - 90)); beam.addLine(to: pt(p.x - 12, p.y - 90)); beam.closeSubpath()
                lit.fill(beam, with: .linearGradient(Gradient(colors: [Color(red: 1, green: 235 / 255, blue: 200 / 255).opacity(0.45 * k), .clear]),
                                                     startPoint: p, endPoint: pt(p.x, p.y - 90)))
                glow(p.x, p.y, 10, (255, 235, 200), 0.7 * k)
            }
        }
        // v113: bulbs along the welcome arches, the café's string lights, a warm wash over the rugs.
        if s.placed(.arch) {
            for (P0, Q0, _) in DecorPainter.arches {
                let p = iso(P0.0, P0.1), q = iso(Q0.0, Q0.1), H: CGFloat = 66, mx = (p.x + q.x) / 2, my = (p.y + q.y) / 2 - H
                for i in 0...12 {
                    let f = CGFloat(i) / 12
                    let x = (1 - f) * (1 - f) * p.x + 2 * (1 - f) * f * mx + f * f * q.x
                    let y = (1 - f) * (1 - f) * (p.y - H) + 2 * (1 - f) * f * (my - 30) + f * f * (q.y - H)
                    glow(x, y, 7, i % 2 == 1 ? (255, 210, 140) : (255, 170, 120), (0.7 + 0.3 * sin(t * 3 + Double(i))) * k)
                }
                glow(mx, my - 13, 26, (255, 220, 160), 0.45 * k)
            }
        }
        if s.placed(.cafe) {
            let a = DecorPainter.cafeAt, p = iso(a.0, a.1), d = DecorPainter(c: world)
            let A = d.iu(p, -0.75, -0.75), B = d.iu(p, 0.75, -0.75), C = d.iu(p, 0.75, 0.75)
            glow(p.x, p.y, 80, (255, 190, 110), 0.3 * k, sy: 0.5)
            for (P1, Q1) in [(A, B), (B, C)] {
                for i in 0...8 {
                    let f = CGFloat(i) / 8
                    glow(P1.x + (Q1.x - P1.x) * f, P1.y + (Q1.y - P1.y) * f - 44 + 40 * f * (1 - f), 6, (255, 215, 150), (0.75 + 0.25 * sin(t * 2.4 + Double(i))) * k)
                }
            }
        }
        if s.placed(.rugs) {
            let a = DecorPainter.rugsAt, p = iso(a.0, a.1)
            glow(p.x, p.y - 30, 50, (255, 180, 100), 0.32 * k)
        }
        // v128: the little lights the buildings carry (the bazaar's lanterns, the agency's phone sign and ring light)
        let inv = world.transform.inverted()
        for l in lites {
            let p = l.p.applying(inv)
            glow(p.x, p.y, l.r, l.rgb, 0.5 * l.a * k)
            glow(p.x, p.y, l.r * 0.25, (255, 245, 220), 0.8 * l.a * k)
        }
        // Fireflies over the launch field and the gardens.
        var RF = Mulberry32(seed: 5)
        for _ in 0..<26 {
            let gx = 1 + RF.next() * 13, gy = 4.4 + RF.next() * 9, ph = RF.next() * 6
            let p = iso(gx + sin(t * 0.4 + ph) * 0.4, gy + cos(t * 0.33 + ph) * 0.4), on = max(0, sin(t * 2.2 + ph * 3))
            if on > 0.2 { glow(p.x, p.y - 18 - CGFloat(sin(t + ph)) * 8, 9, (200, 255, 120), on * 0.8 * k) }
        }
        switch n.event {
        case .lanterns:
            for i in 0..<40 {
                let along = ((t - n.t0) * 0.9 + Double(i) * 0.38).truncatingRemainder(dividingBy: 17) - 1
                let off = 7.75 + Double(i % 3) * 0.2, onX = i % 2 == 1
                let p = iso(onX ? along : off, onX ? off : along)
                glow(p.x, p.y - 22, 16, (255, 170, 70), 0.8)
                world.fill(Path(CGRect(x: p.x - 2, y: p.y - 25, width: 4, height: 5)), with: .color(hex("#ffcf7a")))
            }
        case .balloonGlow:
            for i in 0..<min(6, s.local.balloons.count) {
                let gx = 1.8 + Double(i % 3) * 1.9, gy = 5 + Double(i / 3) * 1.4, p = iso(gx, gy), f = max(0, sin(t * 3 + Double(i) * 1.7))
                glow(p.x, p.y - 70, 80, (255, 150, 60), 0.25 + 0.55 * f)
            }
        case .fireworks(let hotel):
            fireworks(screen: screen, hz: hz, hotel: hotel, t0: n.t0, k: k)
        case .show(let ids):
            showLayer(screen: screen, hz: hz, ids: ids, t0: n.t0)
        case .nightGlow:
            // v124: the Night Glow: every balloon on the field fires on the beat, in waves across the rows, all
            // together at the end; fireworks from the ninth second
            for i in 0..<min(6, s.fieldBalloons.count) {
                let gx = 1.8 + Double(i % 3) * 1.9, gy = 5 + Double(i / 3) * 1.4, p = iso(gx, gy)
                glow(p.x, p.y - 70, 95, (255, 150, 60), 0.2 + 0.75 * BristolNight.glowPulse(t - n.t0, i))
            }
            if t - n.t0 > Glow.fireworksAt { fireworks(screen: screen, hz: hz, hotel: .stone, t0: n.t0, k: k) }
        case .eveningAscent:
            // v124: the evening ascent: the balloons lift off the field into the dusk, their burners glowing
            for i in 0..<min(6, s.fieldBalloons.count) {
                let gx = 1.8 + Double(i % 3) * 1.9, gy = 5 + Double(i / 3) * 1.4, p = iso(gx, gy), r = CGFloat(BristolNight.eveRise(t - n.t0, i))
                glow(p.x + r * 0.3, p.y - 70 - r, 50, (255, 160, 70), 0.35 + 0.4 * max(0, sin(t * 4 + Double(i))))
            }
        default: break
        }
    }

    /// Three in four windows are lit (fixed by place), mostly warm lamplight, a few deeper orange, now and then a TV's blue flicker.
    mutating func relightWindows(_ k: Double) {
        var lit = c
        lit.blendMode = .plusLighter
        for o in windows {
            let seed = abs(sin(Double(o.p.x) * 12.9898 + Double(o.p.y) * 78.233 + Double(o.u) * 37.7 + Double(o.v) * 11.3) * 43758.5).truncatingRemainder(dividingBy: 1)
            if !o.door && seed > 0.74 { continue }
            let tv = !o.door && seed < 0.07
            let col = o.door ? hex("#ffb85e") : tv ? hex("#9cc8ff") : hex(seed < 0.5 ? "#ffd68a" : "#ffb35c")
            let fl = tv ? 0.55 + 0.45 * abs(sin(t * 7 + seed * 40) * sin(t * 2.3 + seed * 9)) : 0.92 + 0.08 * sin(t * 1.3 + seed * 20)
            let a = k * fl * (o.door ? 0.55 : 1)
            var f = face(o.p, o.q, o.h)
            f.opacity = a
            let x0 = o.u - o.w / 2, top = o.door ? o.v + o.hh * 0.55 : o.v
            var arch = Path()
            arch.move(to: pt(x0, top))
            arch.addLine(to: pt(x0, o.v + o.hh - o.w / 2))
            arch.addQuadCurve(to: pt(x0 + o.w, o.v + o.hh - o.w / 2), control: pt(o.u, o.v + o.hh + o.w * 0.45))
            arch.addLine(to: pt(x0 + o.w, top))
            arch.closeSubpath()
            f.fill(arch, with: .color(col))
            if !o.door {
                // A window bar and a curtain edge so they read as windows, not dots.
                f.fill(Path(CGRect(x: o.u - o.w * 0.04, y: o.v, width: o.w * 0.08, height: o.hh)), with: .color(Color(red: 90 / 255, green: 50 / 255, blue: 20 / 255).opacity(0.45)))
                f.fill(Path(CGRect(x: x0, y: o.v + o.hh * 0.2, width: o.w * 0.18, height: o.hh * 0.7)), with: .color(Color(red: 200 / 255, green: 90 / 255, blue: 60 / 255).opacity(0.35)))
            }
            let m = lp(o.p, o.q, o.u), cy = m.y - o.h * (o.v + o.hh / 2), r = max(10, hypot(o.q.x - o.p.x, o.q.y - o.p.y) * o.w * 1.6)
            let warm = tv ? Color(red: 120 / 255, green: 170 / 255, blue: 1) : Color(red: 1, green: 175 / 255, blue: 90 / 255)
            lit.fill(Path(ellipseIn: CGRect(x: m.x - r, y: cy - r, width: r * 2, height: r * 2)),
                     with: .radialGradient(Gradient(colors: [warm.opacity(0.32 * a), .clear]), center: pt(m.x, cy), startRadius: 0, endRadius: r))
            // Light falling on the ground in front of the wall.
            var pool = lit
            pool.translateBy(x: m.x - 4, y: m.y + 6)
            pool.scaleBy(x: 1, y: 0.38)
            pool.fill(Path(ellipseIn: CGRect(x: -r * 1.4, y: -r * 1.4, width: r * 2.8, height: r * 2.8)),
                      with: .radialGradient(Gradient(colors: [warm.opacity(0.16 * a), .clear]), center: .zero, startRadius: 0, endRadius: r * 1.4))
        }
    }
}

extension TownPainter {
    /// Rockets rise from the hotel and burst above the town, in screen space (a wedding's fireworks, the Night Glow's).
    func fireworks(screen: GraphicsContext, hz: CGFloat, hotel: Hotel, t0: Double, k: Double) {
        let w = size.width
        var sparks = screen
        sparks.blendMode = .plusLighter
        let spot = [(2.0, 10.0), (5, 10), (2, 12.6), (5, 12.8)][Hotel.allCases.firstIndex(of: hotel) ?? 0]
        let hw = v.screen(iso(spot.0, spot.1)), hx = min(max(hw.x, w * 0.2), w * 0.8), hy = hw.y, tt = t - t0
        for j in 0..<5 {
            let ph = (tt * 0.55 + Double(j) * 0.21).truncatingRemainder(dividingBy: 1)
            let cx = w * (0.18 + CGFloat(j) * 0.16) + (hx - w / 2) * 0.2, cy = hz * (0.45 + CGFloat(j % 3) * 0.2)
            let col: (Double, Double, Double) = [(255, 94, 58), (255, 194, 61), (58, 208, 192), (255, 111, 168), (155, 123, 224)][j]
            func spark(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ c: (Double, Double, Double), _ a: Double) {
                sparks.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                            with: .radialGradient(Gradient(colors: [Color(red: c.0 / 255, green: c.1 / 255, blue: c.2 / 255).opacity(min(1, a)), .clear]),
                                                  center: pt(x, y), startRadius: 0, endRadius: r))
            }
            if ph < 0.3 {
                spark(cx, hy - (hy - cy) * CGFloat(ph / 0.3), 6, (255, 230, 180), 0.9)
            } else {
                let r = CGFloat((ph - 0.3) / 0.7), a = (1 - Double(r)) * k
                for i in 0..<18 {
                    let an = Double(i) / 18 * .pi * 2
                    spark(cx + CGFloat(cos(an)) * r * w * 0.14, cy + CGFloat(sin(an)) * r * w * 0.14 + r * r * 24, 7, col, a)
                }
                spark(cx, cy, w * 0.2 * r, col, 0.12 * a)
            }
        }
    }
}

/// The night screen: the town at night under a big sky. Drag to look around, pinch to zoom; the big button
/// (it fills up as the night passes) brings the morning. Port of `startNight` and `drawNightTown`.
struct NightView: View {
    @Environment(GameStore.self) private var store
    let night: GameStore.Night
    @State private var view: TownViewport?
    @State private var base = TownViewport(z: 0.3, ox: 0, oy: 0)
    @State private var size: CGSize = .zero
    @State private var lastDrag: CGSize = .zero
    @State private var pinchStart: TownViewport?
    @State private var idle = Date()
    @State private var dawn: Date?
    @State private var shown = false
    @State private var start = Date()

    /// Seconds the night waits before passing by itself; an event night waits longer. Never past 25 s.
    /// The Balloon Show plays to its end whatever you do (the button skips it).
    private var wait: Double {
        isShow ? BalloonShow.length : isGlow ? Glow.duration : night.event == nil ? 3.5 : isEve ? 8 : 5.5
    }
    private var isShow: Bool { if case .show? = night.event { return true }; return false }
    /// v124: Bristol's Night Glow plays to its end like the show; the evening ascent waits a little longer.
    private var isGlow: Bool { BristolNight.kind(night.event) == .glow }
    private var isEve: Bool { BristolNight.kind(night.event) == .eve }
    private var limit: Double { isShow ? BalloonShow.length : isGlow ? Glow.duration : 25 }
    private var showLooks: [BalloonShow.Look] {
        guard case .show(let ids)? = night.event, let s = store.state else { return [] }
        return BalloonShow.looks(s, ids: ids)
    }
    private func camera(_ sz: CGSize) -> TownViewport { isShow ? BalloonShow.camera(sz) : NightCamera.base(sz) }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "#1b1840").ignoresSafeArea()
            if let s = store.state {
                TimelineView(.animation) { tl in
                    Canvas(renderer: { ctx, sz in
                        let now = tl.date
                        let t = now.timeIntervalSince(start)
                        let k = dawn.map { max(0.25, 1 - now.timeIntervalSince($0) * 0.75) } ?? min(1, t / 1.4)
                        var v = view ?? camera(sz)
                        NightCamera.clamp(&v, sz)
                        v.hzFix = NightCamera.horizon(v, sz)
                        v.noLabels = true
                        let rc = ctx
                        let sprite: ((BalloonShow.Look) -> GraphicsContext.ResolvedSymbol?)? = isShow ? { look in rc.resolveSymbol(id: look) } : nil
                        var c = ctx
                        _ = TownPainter.render(&c, state: s, time: 1000 + t, viewport: v, size: sz,
                                               night: TownNight(k: k, event: night.event, t0: 1000,
                                                                sunrise: dawn.map { min(1, now.timeIntervalSince($0)) } ?? 0,
                                                                sprite: sprite))
                    }, symbols: {
                        ForEach(showLooks, id: \.self) { look in BalloonShow.Sprite(state: s, look: look).tag(look) }
                    })
                }
                .ignoresSafeArea()
                .accessibilityHidden(true)
                .background { GeometryReader { g in Color.clear.onAppear { size = g.size } } }
                .gesture(pan.simultaneously(with: pinch))
                caption(day: s.day)
                morningButton(day: s.day)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { shown = true }
            SoundEngine.shared.ambienceBirds = false
            SoundEngine.shared.crickets(true)
            if isShow || isGlow { SoundEngine.shared.showMusic(true) } // v124: the Night Glow plays to the show's music
        }
        .onDisappear {
            SoundEngine.shared.showMusic(false)
            SoundEngine.shared.crickets(false)
            SoundEngine.shared.ambienceBirds = true
        }
        .task { await passByItself() }
    }

    private func caption(day: Int) -> some View {
        VStack(spacing: 3) {
            Text(loc("night.title", num(day - 1))).font(Theme.font(26, .heavy, condensed: true))
            if let e = night.event {
                Text(e.line).font(Theme.font(15, .semibold))
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color(red: 20 / 255, green: 18 / 255, blue: 50 / 255).opacity(0.55), in: RoundedRectangle(cornerRadius: 14))
                    .padding(.top, 4)
            }
            Text(loc("night.wander")).font(Theme.font(12)).opacity(0.7).padding(.top, 4)
        }
        .foregroundStyle(Color(hex: "#fff8e6"))
        .multilineTextAlignment(.center)
        .shadow(color: .black.opacity(0.5), radius: 8, y: 2)
        .frame(maxWidth: 420)
        .padding(.horizontal, 16)
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, 18)
        .opacity(shown ? 1 : 0)
        .offset(y: shown ? 0 : -8)
        .allowsHitTesting(false)
    }

    private func morningButton(day: Int) -> some View {
        TimelineView(.animation(minimumInterval: 1 / 15)) { tl in
            let left = isShow || isGlow ? limit - tl.date.timeIntervalSince(start) : min(wait - tl.date.timeIntervalSince(idle), 25 - tl.date.timeIntervalSince(start))
            let p = dawn != nil ? 1 : min(max(1 - left / wait, 0), 1)
            Button {
                SoundEngine.shared.play(.click)
                bringMorning()
            } label: {
                // The night passing fills the whole face from the left (`.nightgo`'s --p), not just the text's line.
                HStack(spacing: 8) {
                    Text(loc("night.morning", num(day)))
                    LineGlyph(kind: .sun, size: 20, weight: 2.4)
                }
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(alignment: .topLeading) {
                        GeometryReader { g in
                            let w = g.size.width + 32
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.28))
                                .frame(width: w, height: g.size.height)
                                .mask(alignment: .leading) { Rectangle().frame(width: w * p) }
                                .offset(x: -16)
                        }
                    }
            }
            .buttonStyle(ChunkyButtonStyle(kind: .big))
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .opacity(shown ? 1 : 0)
        .offset(y: shown ? 0 : 20)
        .animation(.easeOut(duration: 0.6).delay(0.8), value: shown)
    }

    /// The night passes after a few quiet seconds (restarting while you look around), at most 25 s.
    private func passByItself() async {
        while dawn == nil {
            try? await Task.sleep(for: .milliseconds(200))
            let now = Date()
            if (!isShow && !isGlow && now.timeIntervalSince(idle) >= wait) || now.timeIntervalSince(start) >= limit { bringMorning() }
            if case .fireworks = night.event { SoundEngine.shared.firework(now.timeIntervalSince(start)) }
            if isGlow && now.timeIntervalSince(start) > Glow.fireworksAt { SoundEngine.shared.firework(now.timeIntervalSince(start)) }
        }
    }

    /// The sky pales for a second, then the morning starts where the night's camera is.
    private func bringMorning() {
        guard dawn == nil else { return }
        let now = Date()
        dawn = now
        SoundEngine.shared.showMusic(false)
        // v116: the show's highlights, if it got as far as two of its moments.
        var shots: GameStore.ShowShots?
        if case .show(let ids)? = night.event, let s = store.state {
            let reached = ShowMoments.reached(now.timeIntervalSince(start) - 1.2)
            if reached.count >= 2 { shots = GameStore.ShowShots(state: s, ids: ids, moments: reached, size: size, day: s.day - 1) }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            var v = view ?? camera(size)
            NightCamera.clamp(&v, size)
            store.endNight(camera: v, shots: shots)
        }
    }

    private var pan: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { g in
                idle = Date()
                var v = view ?? camera(size)
                v.ox += g.translation.width - lastDrag.width
                v.oy += g.translation.height - lastDrag.height
                lastDrag = g.translation
                view = v
            }
            .onEnded { _ in lastDrag = .zero }
    }

    private var pinch: some Gesture {
        MagnifyGesture()
            .onChanged { g in
                idle = Date()
                let B = NightCamera.base(size), st = pinchStart ?? view ?? camera(size)
                if pinchStart == nil { pinchStart = st }
                let z = min(max(st.z * g.magnification, B.z * 0.8), B.z * 2.8), k = z / st.z, p = g.startLocation
                view = TownViewport(z: z, ox: p.x - (p.x - st.ox) * k, oy: p.y - (p.y - st.oy) * k)
            }
            .onEnded { _ in pinchStart = nil }
    }
}
