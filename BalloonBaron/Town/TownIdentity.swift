import SwiftUI
import BalloonBaronCore

// v128: telling the town's buildings apart (prototype `tourist`, `guideWithUmbrella`, `mapBoard`, `phoneSign`,
// `ringLight`, `capFlag`, `windsockPole`, `trainingBalloon`, `MARKET`, `marketRow`, `hangOnWall`, `nightLite`).
// Players mixed up the guide office, the influencer agency, the bazaar and the pilot school. No writing on them: each
// carries a big drawn sign of its trade, in its region's style.

/// A small light a building carries (a lantern, the phone's screen, the ring light), lit again over the dark. Kept in
/// canvas coordinates, since the agency draws its roof shifted up.
struct NightLite {
    var p: CGPoint
    var r: CGFloat
    var rgb: (Double, Double, Double)
    var a: Double
}

/// The bazaar's colours per region: each shop's awning stripes, the goods, the lanterns.
struct MarketStyle {
    var awnings: [[String]]
    var goods: [String]
    var lamps: [String]

    static func of(_ r: RegionID) -> MarketStyle {
        switch r {
        case .cap: return MarketStyle(awnings: [["#c0283a", "#fff4dc"], ["#14a39a", "#fff4dc"], ["#e0a020", "#fff4dc"]],
                                      goods: ["#b8582e", "#2b8ab0", "#d08a3a", "#e8c05a", "#7a2a4a"], lamps: ["#e04a3a", "#2bb0a0", "#f2b02a", "#8a4ab0"])
        case .abq: return MarketStyle(awnings: [["#c0392b", "#f2a03a", "#2aa6a0", "#f6e7c8"], ["#2a7ab0", "#f6e7c8", "#e0602a", "#f6d04a"],
                                                ["#e0602a", "#f6d04a", "#c0392b", "#f6e7c8"]],
                                      goods: ["#c0392b", "#d07a3a", "#2aa6a0", "#e8c05a", "#8a4a2a"], lamps: ["#c8ccd2"])
        case .lux: return MarketStyle(awnings: [["#1f5fa8", "#f3e8d2"], ["#d08a2a", "#f3e8d2"], ["#2a8a6a", "#f3e8d2"]],
                                      goods: ["#c8402a", "#e0a020", "#8a5a2a", "#d06a2a", "#3a7a3a"], lamps: ["#d8a838"])
        case .bri: return MarketStyle(awnings: [["#2e6a3e", "#f4efe4"], ["#a8232c", "#f4efe4"], ["#1f4a7a", "#f4efe4"]],
                                      goods: ["#c8302a", "#7ab040", "#e8a020", "#f2d2a0", "#9a3a6a"], lamps: [])
        }
    }
}

extension TownPainter {
    /// A point on a wall-like plane: u along p→q, v up to h.
    func fpt(_ p: CGPoint, _ q: CGPoint, _ h: CGFloat, _ u: CGFloat, _ v: CGFloat) -> CGPoint {
        pt(p.x + (q.x - p.x) * u, p.y + (q.y - p.y) * u - h * v)
    }

    mutating func nightLite(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ rgb: (Double, Double, Double), _ a: Double = 1) {
        guard night != nil else { return }
        lites.append(NightLite(p: pt(x, y).applying(c.transform), r: r, rgb: rgb, a: a))
    }

    mutating func heart(_ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ col: Color) {
        var p = Path()
        p.move(to: pt(x, y + s))
        p.addCurve(to: pt(x, y - s * 0.35), control1: pt(x - s * 1.6, y - s * 0.2), control2: pt(x - s * 0.6, y - s * 1.3))
        p.addCurve(to: pt(x, y + s), control1: pt(x + s * 0.6, y - s * 1.3), control2: pt(x + s * 1.6, y - s * 0.2))
        c.fill(p, with: .color(col))
    }

    // MARK: People

    /// A tourist: a person with a sun hat or a cap and, now and then, a camera.
    mutating func tourist(_ x: CGFloat, _ y: CGFloat, _ col: String, hat: String?, camera: Bool, _ tt: Double, _ ph: Double) {
        person(x, y, col, tt, ph)
        let b = CGFloat(abs(sin(tt * 6 + ph))) * 1.5
        if let hat {
            ellipse(x, y - 17.6 - b, 5.2, 1.6, hex(hat))
            ellipse(x, y - 18.6 - b, 2.8, 2, hex(hat))
        }
        if camera { rect(x - 4.5, y - 10 - b, 4, 3, hex("#2a2430")) }
    }

    /// The guide: a navy jacket, one arm up with a bright yellow umbrella opened high over the group.
    mutating func guideWithUmbrella(_ x: CGFloat, _ y: CGFloat) {
        person(x, y, "#1f4a7a", 0, 0)
        let sw = CGFloat(sin(t * 1.7)) * 1.6, tx = x + 5 + sw, ty = y - 60, R: CGFloat = 17
        var arm = Path()
        arm.move(to: pt(x + 2, y - 11)); arm.addLine(to: pt(x + 5, y - 22))
        c.stroke(arm, with: .color(hex("#1f4a7a")), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
        line(pt(x + 5, y - 19), pt(tx, ty), hex("#2a1e14"), 1.5)
        // The canopy: six panels from the tip to a scalloped rim, the front half of it facing us.
        let tip = pt(tx, ty - 8)
        func rim(_ a: Double) -> CGPoint { pt(tx + CGFloat(cos(a)) * R, ty + 1 + CGFloat(sin(a)) * R * 0.3) }
        var edge = Path()
        edge.move(to: rim(0))
        for i in 0..<6 {
            let a0 = Double(i) * .pi / 6, a1 = Double(i + 1) * .pi / 6, p0 = rim(a0), p1 = rim(a1), m = rim((a0 + a1) / 2)
            var panel = Path()
            panel.move(to: tip); panel.addLine(to: p0); panel.addQuadCurve(to: p1, control: pt(m.x, m.y + 3.2)); panel.closeSubpath()
            c.fill(panel, with: .color(hex(i % 2 == 1 ? "#fff6e0" : "#ffc23d")))
            edge.addQuadCurve(to: p1, control: pt(m.x, m.y + 3.2))
        }
        poly([tip, rim(.pi * 0.5), rim(.pi)], rgba(120, 60, 10, 0.2))
        c.stroke(edge, with: .color(rgba(120, 60, 10, 0.55)), lineWidth: 0.8)
        ellipse(tip.x, tip.y - 1.5, 2, 2, hex("#ffc23d"))
        // A little pennant on the tip, so it reads from far off.
        let wv = CGFloat(sin(t * 4)) * 1.5
        poly([pt(tip.x, tip.y - 2), pt(tip.x, tip.y - 12), pt(tip.x + 11, tip.y - 8 + wv)], hex("#ff5e3a"))
        line(tip, pt(tip.x, tip.y - 12), hex("#2a1e14"), 1)
    }

    // MARK: The guide office's map

    /// A big folding map of the valley on an easel, facing the street: two panels, rivers and fields, the tours in dotted red.
    mutating func mapBoard(_ gx: Double, _ gy: Double) {
        let p = iso(gx, gy), q = iso(gx + 0.62, gy), H: CGFloat = 52, v0: CGFloat = 0.32
        let back = lp(p, q, 0.5), wood = hex("#4a2e1a")
        line(pt(back.x + 9, back.y - 5), pt(back.x, back.y - H * 0.9), wood, 2.4)
        for u: CGFloat in [0.1, 0.9] { line(fpt(p, q, H, u, 0), fpt(p, q, H, u, v0 + 0.04), wood, 2.4) }
        blobShadow(back.x + 14, back.y + 3, 22, 5, 0.16)
        let f = face(p, q, H)
        f.fill(Path(CGRect(x: 0, y: v0, width: 1, height: 1 - v0)), with: .color(hex("#6a4024")))
        f.fill(Path(CGRect(x: 0.04, y: v0 + 0.04, width: 0.44, height: 1 - v0 - 0.08)), with: .color(hex("#f7eed6")))
        f.fill(Path(CGRect(x: 0.52, y: v0 + 0.04, width: 0.44, height: 1 - v0 - 0.08)), with: .color(hex("#ede0bc")))
        let R = s.region
        let green = hex(R == .bri ? "#9fcf86" : R == .lux ? "#b7d48a" : "#c9d79a")
        for (x, y, rx, ry) in [(0.2, 0.82, 0.12, 0.07), (0.72, 0.5, 0.14, 0.08), (0.82, 0.84, 0.09, 0.06)] as [(CGFloat, CGFloat, CGFloat, CGFloat)] {
            f.fill(Path(ellipseIn: CGRect(x: x - rx, y: y - ry, width: rx * 2, height: ry * 2)), with: .color(green))
        }
        if R == .cap || R == .abq {
            var hills = Path()
            for (x, y) in [(0.36, 0.7), (0.42, 0.66), (0.6, 0.78)] as [(CGFloat, CGFloat)] {
                hills.move(to: pt(x - 0.035, y - 0.05)); hills.addLine(to: pt(x, y + 0.08)); hills.addLine(to: pt(x + 0.035, y - 0.05)); hills.closeSubpath()
            }
            f.fill(hills, with: .color(hex(R == .abq ? "#c8744a" : "#d4a27a")))
        }
        var river = Path()
        river.move(to: pt(0.04, 0.5))
        river.addCurve(to: pt(0.62, 0.66), control1: pt(0.3, 0.58), control2: pt(0.45, 0.4))
        river.addQuadCurve(to: pt(0.96, 0.7), control: pt(0.78, 0.88))
        f.stroke(river, with: .color(hex("#4aa0c8")), lineWidth: 0.045)
        var route = Path()
        route.move(to: pt(0.14, 0.46))
        route.addQuadCurve(to: pt(0.55, 0.74), control: pt(0.3, 0.95))
        route.addQuadCurve(to: pt(0.86, 0.9), control: pt(0.7, 0.62))
        f.stroke(route, with: .color(hex("#e04a3a")), style: StrokeStyle(lineWidth: 0.028, dash: [0.035, 0.03]))
        for (x, y) in [(0.14, 0.46), (0.55, 0.74), (0.86, 0.9)] as [(CGFloat, CGFloat)] {
            f.fill(Path(ellipseIn: CGRect(x: x - 0.035, y: y - 0.04, width: 0.07, height: 0.08)), with: .color(hex("#e04a3a")))
        }
        f.fill(Path(CGRect(x: 0.48, y: v0 + 0.04, width: 0.04, height: 1 - v0 - 0.08)), with: .color(rgba(60, 30, 10, 0.18)))
        // A small balloon drawn on the map's corner.
        let bp = fpt(p, q, H, 0.3, 0.9)
        ellipse(bp.x, bp.y - 1, 3.2, 3.6, hex("#ff5e3a"))
        rect(bp.x - 1, bp.y + 3, 2, 1.6, hex("#6a4024"))
    }

    // MARK: The agency's roof

    /// A big phone standing on the roof on two legs: dark body, glowing screen with a play button, hearts floating up.
    mutating func phoneSign(_ p: CGPoint, _ q: CGPoint, _ H: CGFloat, on: Bool) {
        let glowA = on ? 0.75 + 0.25 * sin(t * 5) : 0.55
        for u: CGFloat in [0.25, 0.75] { line(fpt(p, q, H, u, 0), fpt(p, q, H, u, 0.14), hex("#3a3048"), 2.5) }
        // Its thickness, on the side away from the light.
        let t0 = fpt(p, q, H, 1, 0.99), b0 = fpt(p, q, H, 1, 0.13)
        poly([t0, pt(t0.x + 3, t0.y + 1.5), pt(b0.x + 3, b0.y + 1.5), b0], hex("#120e1c"))
        if on {
            let cc = fpt(p, q, H, 0.5, 0.58)
            glow(cc.x, cc.y, 46, Color(red: 1, green: 111 / 255, blue: 168 / 255), 0.32 * glowA)
        }
        let f = face(p, q, H)
        f.fill(Path(roundedRect: CGRect(x: 0, y: 0.12, width: 1, height: 0.88), cornerRadius: 0.14), with: .color(hex("#221d33")))
        f.fill(Path(roundedRect: CGRect(x: 0.09, y: 0.2, width: 0.82, height: 0.7), cornerRadius: 0.08),
               with: .linearGradient(grad([(hex("#9b7be0"), 0), (hex("#ff6fa8"), 1)]), startPoint: pt(0, 0.2), endPoint: pt(0, 0.94)))
        var shine = Path()
        shine.move(to: pt(0.09, 0.9)); shine.addLine(to: pt(0.45, 0.9)); shine.addLine(to: pt(0.09, 0.5)); shine.closeSubpath()
        f.fill(shine, with: .color(Color.white.opacity(0.12 + 0.1 * glowA)))
        f.fill(Path(roundedRect: CGRect(x: 0.38, y: 0.925, width: 0.24, height: 0.035), cornerRadius: 0.015), with: .color(hex("#120e1c")))
        f.fill(Path(ellipseIn: CGRect(x: 0.3, y: 0.45, width: 0.4, height: 0.26)), with: .color(.white))
        var play = Path()
        play.move(to: pt(0.43, 0.66)); play.addLine(to: pt(0.62, 0.58)); play.addLine(to: pt(0.43, 0.5)); play.closeSubpath()
        f.fill(play, with: .color(hex("#ff5e8a")))
        for i in 0..<3 {
            f.fill(Path(CGRect(x: 0.2, y: 0.26 + CGFloat(i) * 0.045, width: i == 2 ? 0.3 : 0.6, height: 0.022)), with: .color(Color.white.opacity(0.85)))
        }
        // Hearts floating up off the screen.
        for i in 0..<3 {
            let u = (t * 0.45 + Double(i) / 3).truncatingRemainder(dividingBy: 1)
            let a = fpt(p, q, H, 0.75 + 0.15 * CGFloat(sin(Double(i) * 2)), 0.86)
            let x = a.x + CGFloat(u) * 12 + CGFloat(sin(t * 3 + Double(i))) * 2, y = a.y - CGFloat(u) * 34, sz = 3.4 * (1 - CGFloat(u) * 0.3)
            let keep = c
            c.opacity = (on ? 1 : 0.8) * (1 - u)
            heart(x, y, sz, hex(i % 2 == 1 ? "#ff3d6e" : "#ff8ab0"))
            c = keep
        }
        let sc = fpt(p, q, H, 0.5, 0.58)
        nightLite(sc.x, sc.y, 40, (255, 120, 180), on ? 0.9 : 0.6)
    }

    /// A ring light on a tripod: a bright white ring, warm inside when it's on.
    mutating func ringLight(_ cpt: CGPoint, on: Bool) {
        let top = pt(cpt.x, cpt.y - 34), R: CGFloat = 12.5, leg = hex("#2a2430")
        for dx: CGFloat in [-8, 1, 8] { line(pt(cpt.x + dx, cpt.y + (dx == 1 ? -3 : 1)), pt(top.x, top.y + 10), leg, 1.5) }
        line(pt(top.x, top.y + 10), pt(top.x, top.y - 4), leg, 2)
        let cy = top.y - 4 - R
        if on { glow(top.x, cy, R * 2.6, Color(red: 1, green: 250 / 255, blue: 235 / 255), 0.5 + 0.2 * sin(t * 5)) }
        let ring = Path(ellipseIn: CGRect(x: top.x - R, y: cy - R * 1.05, width: R * 2, height: R * 2.1))
        c.stroke(ring, with: .color(hex("#3a3048")), lineWidth: 6.5)
        c.stroke(ring, with: .color(hex(on ? "#fffdf4" : "#f2eee6")), lineWidth: 4.2)
        var hi = Path()
        hi.addArc(center: .zero, radius: 1, startAngle: .radians(.pi * 0.9), endAngle: .radians(.pi * 1.6), clockwise: false)
        let hiT = CGAffineTransform(a: R - 1, b: 0, c: 0, d: R * 1.05 - 1, tx: top.x - 0.6, ty: cy - 0.6)
        c.stroke(hi.applying(hiT), with: .color(Color.white.opacity(0.9)), lineWidth: 1.2)
        rect(top.x - 2.5, cy - 4, 5, 8, hex("#2a2430"))
        rect(top.x - 1.6, cy - 3, 3.2, 6, hex("#ff8ab0"))
        nightLite(top.x, cy, 34, (255, 248, 230), on ? 1 : 0.7)
    }

    // MARK: The pilot school

    /// The school's flag: navy, a white mortarboard with a gold tassel on it.
    mutating func capFlag(_ x: CGFloat, _ y: CGFloat, _ hgt: CGFloat) {
        line(pt(x, y), pt(x, y - hgt - 3), hex("#3a2416"), 2.5)
        ellipse(x, y - hgt - 4, 2.2, 2.2, hex("#ffc23d"))
        let L: CGFloat = 34, Hf: CGFloat = 23, top = y - hgt, tt = t
        func wv(_ k: CGFloat) -> CGFloat { CGFloat(sin(tt * 3 + Double(x) + Double(k) * 2.2)) * 3 * k }
        var fl = Path()
        fl.move(to: pt(x, top))
        for i in 1...8 { let k = CGFloat(i) / 8; fl.addLine(to: pt(x + L * k, top + wv(k) + k * 2)) }
        for i in stride(from: 8, through: 0, by: -1) { let k = CGFloat(i) / 8; fl.addLine(to: pt(x + L * k, top + Hf + wv(k) + k * 2)) }
        fl.closeSubpath()
        c.fill(fl, with: .color(hex("#2b2350")))
        let cx = x + L * 0.5, cy = top + Hf * 0.5 + wv(0.5) + 1
        var base = Path()
        base.move(to: pt(cx - 5, cy + 1)); base.addLine(to: pt(cx - 5, cy + 5))
        base.addQuadCurve(to: pt(cx + 5, cy + 5), control: pt(cx, cy + 7.5))
        base.addLine(to: pt(cx + 5, cy + 1)); base.closeSubpath()
        c.fill(base, with: .color(.white))
        poly([pt(cx - 10, cy - 1), pt(cx, cy - 5.5), pt(cx + 10, cy - 1), pt(cx, cy + 3.5)], .white)
        poly([pt(cx - 10, cy - 1), pt(cx, cy + 3.5), pt(cx + 10, cy - 1), pt(cx, cy + 1.5)], rgba(43, 35, 80, 0.25))
        var tassel = Path()
        tassel.move(to: pt(cx, cy - 1)); tassel.addLine(to: pt(cx + 7, cy + 0.5)); tassel.addLine(to: pt(cx + 7, cy + 6))
        c.stroke(tassel, with: .color(hex("#ffc23d")), lineWidth: 1.3)
        ellipse(cx + 7, cy + 6.6, 1.3, 1.6, hex("#ffc23d"))
    }

    /// A windsock on its own pole.
    mutating func windsockPole(_ x: CGFloat, _ y: CGFloat, _ H: CGFloat) {
        line(pt(x, y), pt(x, y - H), hex("#3a2416"), 2)
        let L: CGFloat = 26, sw = CGFloat(sin(t * 2.6)) * 3
        for i in 0..<4 {
            let k0 = CGFloat(i) / 4, k1 = CGFloat(i + 1) / 4, r0 = 6 - k0 * 2.6, r1 = 6 - k1 * 2.6
            let x0 = x + L * k0, x1 = x + L * k1, y0 = y - H + 2 + k0 * sw, y1 = y - H + 2 + k1 * sw
            poly([pt(x0, y0 - r0), pt(x1, y1 - r1), pt(x1, y1 + r1), pt(x0, y0 + r0)], hex(i % 2 == 1 ? "#fffaf3" : "#ff5e3a"))
        }
    }

    /// The training balloon: low over the yard on four ropes to pegs in the ground, its basket hanging just off it.
    mutating func trainingBalloon(_ g: CGPoint, big: Bool) {
        let bob = CGFloat(sin(t * 0.9)) * 2, R: CGFloat = 30, bx = g.x + CGFloat(sin(t * 0.6)) * 1.5, by = g.y - 16 - bob
        blobShadow(g.x + 18, g.y + 4, 26, 8, 0.2)
        balloon(bx, by, R, ["#14a39a", "#e8fff9"], burn: big ? t.truncatingRemainder(dividingBy: 2.4) < 0.35 : t.truncatingRemainder(dividingBy: 3) < 0.3)
        var ropes = Path()
        for (dx, dy) in [(-30, -4), (28, -7), (-20, 9), (32, 7)] as [(CGFloat, CGFloat)] {
            let sx = bx + (dx < 0 ? -1 : 1) * R * 0.3, sy = by - R * 0.3, ex = g.x + dx, ey = g.y + dy
            ropes.move(to: pt(sx, sy)); ropes.addQuadCurve(to: pt(ex, ey), control: pt((sx + ex) / 2, (sy + ey) / 2 + 3))
            rect(ex - 1.2, ey - 3, 2.4, 3.5, hex("#5a3a20"))
        }
        c.stroke(ropes, with: .color(rgba(70, 45, 30, 0.75)), lineWidth: 1)
    }

    // MARK: The bazaar

    /// The bazaar is a row of three small shops on the main road just past the square, their fronts to the road, each
    /// under its own striped awning over a stall of goods, lanterns hanging from the awnings and textiles hung on the
    /// end wall; in each region's own style.
    mutating func marketRow(_ b: TownBuilding) {
        let R = s.region, M = MarketStyle.of(R), n = 3, x0 = b.gx + 0.1, dep = 0.78, ul = (b.d - 0.2) / Double(n)
        let H: [CGFloat] = [44, 52, 44]
        func out(_ p: CGPoint, _ k: CGFloat) -> CGPoint { pt(p.x + TownGeo.TW / 2 * k, p.y + TownGeo.TH / 2 * k) }
        for i in 0..<n {
            let y0 = b.gy + 0.1 + Double(i) * ul + 0.03, w = ul - 0.06, h = H[i], aw = M.awnings[i]
            let white = R == .bri && i == 1
            let f = block(x0, y0, dep, w, h, lit: white ? "#efe6d2" : nil, shade: white ? "#c8bca4" : nil, top: white ? "#e2d8c2" : nil,
                          courses: !white, parapet: R == .cap, seed: Double(900 + i * 7))
            if R == .bri { gableRoof(x0, y0, dep, w, h, 20, Self.slate, eave: 0.06) }
            else if R == .abq || R == .lux { flatRoof(x0, y0, dep, w, h, dome: i == 1) }
            else if i == 1 { let cc = lp(f.a, f.c, 0.5); dome(cc.x, cc.y + 1, 12, s.local.winter != nil ? "#f2f5fa" : "#2b8ab0") }
            // The shop's open front on the road side, with goods inside.
            opening(f.C, f.B, h, 0.5, 0, 0.62, R == .bri ? 0.5 : 0.52, lit: true)
            if R == .bri {
                let fc = face(f.C, f.B, h)
                fc.fill(Path(CGRect(x: 0.08, y: 0.64, width: 0.84, height: 0.13)), with: .color(hex(aw[0])))
                fc.fill(Path(CGRect(x: 0.08, y: 0.76, width: 0.84, height: 0.015)), with: .color(Color.white.opacity(0.55)))
            }
            let inside = face(f.C, f.B, h)
            for r in 0..<2 {
                for j in 0..<5 {
                    inside.fill(Path(CGRect(x: 0.26 + CGFloat(j) * 0.1, y: 0.1 + CGFloat(r) * 0.16, width: 0.07, height: 0.1)),
                                with: .color(hex(M.goods[(i + j + r) % M.goods.count])))
                }
            }
            // The stall: a table out on the pavement piled with goods.
            let tb = block(x0 + dep + 0.03, y0 + 0.1, 0.2, w - 0.2, 12, lit: "#a8743e", shade: "#7a4e28", top: "#c08a50", courses: false, seed: Double(40 + i))
            for j in 0..<6 {
                let p = lp(lp(tb.a, tb.b, 0.5), lp(tb.d, tb.c, 0.5), (CGFloat(j) + 0.5) / 6), col = M.goods[(i * 2 + j) % M.goods.count]
                if R == .lux { // spice cones in bowls
                    poly([pt(p.x - 4, p.y + 1), pt(p.x, p.y - 6), pt(p.x + 4, p.y + 1)], hex(col))
                    ellipse(p.x, p.y + 1, 4.5, 1.6, hex("#8a6a40"))
                } else if R == .abq && i == 1 { // painted pots
                    ellipse(p.x, p.y - 3, 3.6, 4, hex(col))
                    rect(p.x - 3, p.y - 4, 6, 1, Color.white.opacity(0.5))
                } else {
                    ellipse(p.x - 1.5, p.y - 1.5, 2.6, 2.2, hex(col))
                    ellipse(p.x + 1.6, p.y - 0.8, 2.6, 2.2, mix(col, "#000000", 0.12))
                    ellipse(p.x, p.y - 3.4, 2.4, 2, mix(col, "#ffffff", 0.15))
                }
            }
            // The awning: stripes from the wall out over the stall, a scalloped edge, its shadow on the wall.
            let ah = h * 0.66, A0 = upp(f.C, ah), A1 = upp(f.B, ah), drop: CGFloat = 13
            var F0 = out(A0, 0.44), F1 = out(A1, 0.44)
            F0.y += drop; F1.y += drop
            poly([upp(f.C, ah), upp(f.B, ah), upp(f.B, ah - 10), upp(f.C, ah - 10)], rgba(60, 25, 10, 0.22))
            let ns = 8
            for st in 0..<ns {
                let k0 = CGFloat(st) / CGFloat(ns), k1 = CGFloat(st + 1) / CGFloat(ns)
                poly([lp(A0, A1, k0), lp(A0, A1, k1), lp(F0, F1, k1), lp(F0, F1, k0)], hex(aw[st % aw.count]))
            }
            outline([A0, A1, F1, F0], rgba(60, 25, 10, 0.25), 1)
            for st in 0..<ns {
                let a = lp(F0, F1, CGFloat(st) / CGFloat(ns)), cc = lp(F0, F1, CGFloat(st + 1) / CGFloat(ns)), m = lp(a, cc, 0.5)
                var sc = Path()
                sc.move(to: a); sc.addLine(to: cc); sc.addQuadCurve(to: a, control: pt(m.x, m.y + 7)); sc.closeSubpath()
                c.fill(sc, with: .color(mix(aw[st % aw.count], "#000000", 0.08)))
            }
            // The side of the awning nearest us.
            poly([A0, F0, pt(F0.x, F0.y + 2), pt(A0.x + 2, A0.y + 6)], mix(aw[0], "#000000", 0.25))
            // Hanging from the awning: lanterns (flower baskets in Bristol).
            for u: CGFloat in [0.2, 0.5, 0.8] {
                let a = lp(F0, F1, u), y = a.y + 6, x = a.x + CGFloat(sin(t * 1.6 + Double(u) * 9 + Double(i))) * 1.2
                line(pt(a.x, a.y + 2), pt(x, y), rgba(40, 25, 15, 0.7), 0.8)
                if R == .bri {
                    ellipse(x, y + 3, 4.2, 3.2, hex("#3a2a1a")); ellipse(x, y + 1.5, 4.6, 2.8, hex("#4e8a34"))
                    for j in 0..<4 { ellipse(x - 3 + CGFloat(j) * 2, y + 1 + CGFloat(j % 2), 1.3, 1.3, hex(["#ff6fa8", "#ffffff", "#e04a3a", "#ffc23d"][j])) }
                    continue
                }
                let col = M.lamps[(i * 3 + Int((u * 5).rounded())) % M.lamps.count]
                if R == .abq { // punched tin
                    rect(x - 2.6, y, 5.2, 7, hex("#c8ccd2"))
                    poly([pt(x - 3.4, y), pt(x, y - 2.6), pt(x + 3.4, y)], hex("#8a9098"))
                    for j in 0..<3 { rect(x - 1.6 + CGFloat(j) * 1.3, y + 2 + CGFloat(j % 2) * 2, 0.9, 0.9, hex("#ffd27a")) }
                } else if R == .lux { // a brass fanous with coloured glass
                    poly([pt(x - 2.5, y), pt(x + 2.5, y), pt(x + 3.6, y + 5), pt(x, y + 9), pt(x - 3.6, y + 5)], hex(col))
                    rect(x - 1.6, y + 1.6, 3.2, 3.2, hex(["#e04a3a", "#2a8ac8", "#3ab07a"][Int((u * 5).rounded()) % 3]))
                } else { // a mosaic glass lantern
                    rect(x - 1.6, y - 0.6, 3.2, 1.4, hex("#a8742a"))
                    ellipse(x, y + 4, 3, 4, hex(col))
                    rect(x - 0.7, y + 1.5, 1.4, 4, rgba(255, 240, 200, 0.65))
                    rect(x - 0.6, y + 8, 1.2, 2, hex("#a8742a"))
                }
                nightLite(x, y + 4, 14, (255, 190, 100), 0.9)
            }
            // The last shop's end wall, facing us.
            if i == n - 1 { hangOnWall(f, h) }
        }
        // Along the front: bunting in Bristol, papel picado in Albuquerque, strung between the awnings.
        if R == .bri || R == .abq {
            let P = out(upp(iso(x0 + dep, b.gy + 0.12), H[0] * 0.66 + 10), 0.5), Q = out(upp(iso(x0 + dep, b.gy + b.d - 0.12), H[2] * 0.66 + 10), 0.5)
            var wire = Path()
            wire.move(to: P); wire.addQuadCurve(to: Q, control: pt((P.x + Q.x) / 2, (P.y + Q.y) / 2 + 8))
            c.stroke(wire, with: .color(rgba(40, 25, 15, 0.7)), lineWidth: 0.8)
            let cols = R == .bri ? ["#a8232c", "#f4efe4", "#1f4a7a", "#e0a020", "#2e6a3e"] : ["#ff5e8a", "#ffc23d", "#2aa6a0", "#9b7be0", "#e0602a"]
            for i in 1..<14 {
                let k = CGFloat(i) / 14, x = P.x + (Q.x - P.x) * k, y = P.y + (Q.y - P.y) * k + 8 * 4 * k * (1 - k) * 0.5 + CGFloat(sin(t * 3 + Double(i))) * 0.6
                if R == .bri { poly([pt(x - 3, y), pt(x + 3, y), pt(x, y + 7)], hex(cols[i % cols.count])) }
                else { rect(x - 2.6, y, 5.2, 6.5, hex(cols[i % cols.count])) }
            }
        }
        // Shoppers browsing at the stalls.
        for j in 0..<3 {
            let p = iso(x0 + dep + 0.5 + Double(j % 2) * 0.12, b.gy + 0.5 + Double(j) * 0.8)
            tourist(p.x, p.y, ["#5aa9e6", "#ff8a3d", "#9b7be0"][j], hat: j == 1 ? "#f4e4c0" : nil, camera: false, t * 0.15, Double(j + 3))
        }
    }

    /// The end wall of the row: textiles from a rod (kilims, Navajo-style rugs and chile ristras, striped fabrics), or in
    /// Bristol a hanging sign with the company balloon and two flower baskets.
    mutating func hangOnWall(_ f: Box, _ h: CGFloat) {
        let R = s.region
        if R == .bri {
            face(f.D, f.C, h).fill(Path(CGRect(x: 0.15, y: 0.5, width: 0.7, height: 0.03)), with: .color(hex("#2a201a")))
            let sp = fpt(f.D, f.C, h, 0.5, 0.5)
            var g = c
            g.translateBy(x: sp.x, y: sp.y)
            g.rotate(by: .radians(sin(t * 1.4) * 0.06))
            g.fill(Path(CGRect(x: -9, y: 3, width: 18, height: 20)), with: .color(hex("#1e3a2a")))
            g.stroke(Path(CGRect(x: -8, y: 4, width: 16, height: 18)), with: .color(hex("#c9a040")), lineWidth: 1.2)
            var bal = Path()
            bal.addArc(center: pt(0, 11), radius: 4.5, startAngle: .radians(.pi), endAngle: .radians(0), clockwise: false)
            bal.addQuadCurve(to: pt(1.3, 18.5), control: pt(4.5, 16))
            bal.addLine(to: pt(-1.3, 18.5))
            bal.addQuadCurve(to: pt(-4.5, 11), control: pt(-4.5, 16))
            g.fill(bal, with: .color(hex(s.colors.first ?? "#ff5e3a")))
            g.fill(Path(CGRect(x: -1.3, y: 19.3, width: 2.6, height: 2)), with: .color(hex("#6b4426")))
            for u: CGFloat in [0.18, 0.82] {
                let p = fpt(f.D, f.C, h, u, 0.78)
                ellipse(p.x, p.y + 3, 5, 3.5, hex("#3a2a1a")); ellipse(p.x, p.y + 1, 5.6, 3.6, hex("#4e8a34"))
                for j in 0..<5 { ellipse(p.x - 4 + CGFloat(j) * 2, p.y + CGFloat(j % 2), 1.4, 1.4, hex(["#ff6fa8", "#ffffff", "#e04a3a", "#ffc23d", "#9b7be0"][j])) }
            }
            return
        }
        let K: [[String]] = R == .abq ? [["#c0392b", "#f6e7c8", "#2a2a2a"], ["#2a7ab0", "#f2c86a", "#c0392b"]]
            : R == .lux ? [["#1f5fa8", "#f3e8d2", "#c8402a"], ["#c8402a", "#e0a020", "#1f5fa8"]]
            : [["#b8322a", "#e6b04a", "#2b2350"], ["#2b4a8a", "#ead8b0", "#c2401f"]]
        let wall = face(f.D, f.C, h)
        wall.fill(Path(CGRect(x: 0.08, y: 0.9, width: 0.84, height: 0.03)), with: .color(hex("#4a2e1a")))
        for (j, k) in K.enumerated() {
            let a = hex(k[0]), b2 = hex(k[1]), cc = hex(k[2])
            let u0 = 0.12 + CGFloat(j) * 0.41, W: CGFloat = 0.34, v1: CGFloat = 0.89, v0: CGFloat = 0.3, sw = CGFloat(sin(t * 1.3 + Double(j) * 2)) * 0.008
            var g = wall
            g.concatenate(CGAffineTransform(a: 1, b: 0, c: sw, d: 1, tx: 0, ty: 0))
            g.fill(Path(CGRect(x: u0, y: v0, width: W, height: v1 - v0)), with: .color(a))
            g.fill(Path(CGRect(x: u0 + 0.03, y: v0 + 0.05, width: W - 0.06, height: 0.03)), with: .color(b2))
            g.fill(Path(CGRect(x: u0 + 0.03, y: v1 - 0.08, width: W - 0.06, height: 0.03)), with: .color(b2))
            if R == .lux {
                for st in 0..<4 { g.fill(Path(CGRect(x: u0, y: v0 + 0.12 + CGFloat(st) * 0.1, width: W, height: 0.04)), with: .color(st % 2 == 1 ? b2 : cc)) }
            } else {
                let cx = u0 + W / 2, cy = (v0 + v1) / 2, ry: CGFloat = R == .abq ? 0.14 : 0.17, rx: CGFloat = 0.1
                func diamond(_ s: CGFloat) -> Path { path([pt(cx, cy + ry * s), pt(cx + rx * s, cy), pt(cx, cy - ry * s), pt(cx - rx * s, cy)]) }
                g.fill(diamond(1), with: .color(cc))
                g.fill(diamond(0.45), with: .color(b2))
                if R == .abq {
                    g.fill(Path(CGRect(x: u0 + 0.03, y: cy - 0.015, width: 0.05, height: 0.03)), with: .color(cc))
                    g.fill(Path(CGRect(x: u0 + W - 0.08, y: cy - 0.015, width: 0.05, height: 0.03)), with: .color(cc))
                }
            }
            var fringe = Path()
            for st in 0..<6 { fringe.addRect(CGRect(x: u0 + 0.02 + CGFloat(st) * (W - 0.04) / 5.5, y: v0 - 0.05, width: 0.012, height: 0.05)) }
            g.fill(fringe, with: .color(b2))
        }
        if R == .abq { // ristras: strings of red chiles hanging at the corners
            for u: CGFloat in [0.04, 0.96] {
                let p = fpt(f.D, f.C, h, u, 0.92)
                line(p, pt(p.x, p.y + 26), hex("#6a4a2a"), 0.8)
                for j in 0..<9 {
                    let y = p.y + 3 + CGFloat(j) * 2.6
                    ellipse(p.x - 1.6, y, 1.9, 1.4, hex(j % 3 == 0 ? "#a81e18" : "#c0281e"))
                    ellipse(p.x + 1.6, y + 1.2, 1.9, 1.4, hex("#d0302a"))
                }
            }
        }
    }
}
