import SwiftUI
import BalloonBaronCore

// v141: the Maasai Mara's camp (prototype `thatchRoof`, `thatchCone`, `rondavel`, `acacia`, `maraOpening`,
// `termiteMound`, `kopjeRock`, `safariTent`, `landCruiser`, `giraffe`, `maraTownScenery`, `enkaji`, `cow`,
// `acaciaSil` and the Mara branches of the town painter): sun-baked red-earth plaster under makuti thatch, the hotels'
// canvas tents and the lodges' dressed stone, flat-topped acacias, Land Cruisers, a boma fire ring, termite mounds and a
// giraffe on the edge; outside, the Mara River with hippos and riverine trees, a Maasai manyatta, a waterhole and herds.

extension TownPainter {
    static let maraPlaster = Tuff(lit: "#e2b68c", shade: "#a8724c", top: "#d2a074", line: Color(red: 110 / 255, green: 60 / 255, blue: 30 / 255).opacity(0.12), smooth: true)
    /// The tented camp's canvas and the lodges' local stone.
    static let maraCanvas: Tuff = { var t = Tuff(lit: "#f0e6cc", shade: "#c8b48c", top: "#e4d6b2", line: Color(red: 120 / 255, green: 96 / 255, blue: 60 / 255).opacity(0.18), smooth: true); t.canvas = true; return t }()
    static let maraStone = Tuff(lit: "#d8c29c", shade: "#a68c66", top: "#cbb48c", line: Color(red: 90 / 255, green: 64 / 255, blue: 40 / 255).opacity(0.18))
    static let thatch = "#c9a25c"

    var maraRains: Bool { s.region == .mara && s.local.winter != nil }

    /// A thatched (makuti) roof over a block: four steep slopes of grass thatch with a deep overhang, strands down the
    /// slopes, a ridge cap and a dark, shaggy eave. Gable, hip and flat roofs in the Mara all become this.
    mutating func thatchRoof(_ gx: Double, _ gy: Double, _ w: Double, _ d: Double, _ h: CGFloat, _ rise: CGFloat) {
        let col = maraRains ? "#a8884a" : Self.thatch, e = 0.16, lng = w >= d
        func P(_ x: Double, _ y: Double, _ z: CGFloat) -> CGPoint { upp(iso(x, y), z) }
        let r0 = lng ? (gx + min(w * 0.3, d * 0.5), gy + d / 2) : (gx + w / 2, gy + min(d * 0.3, w * 0.5))
        let r1 = lng ? (gx + w - min(w * 0.3, d * 0.5), gy + d / 2) : (gx + w / 2, gy + d - min(d * 0.3, w * 0.5))
        let A = P(gx - e, gy - e, h - 4), B = P(gx + w + e, gy - e, h - 4), C = P(gx + w + e, gy + d + e, h - 4), D = P(gx - e, gy + d + e, h - 4)
        let R0 = P(r0.0, r0.1, h + rise), R1 = P(r1.0, r1.1, h + rise)
        let faces: [([CGPoint], Double)] = lng ? [([A, B, R1, R0], 0.3), ([D, A, R0], 0.12), ([C, B, R1], 0.26), ([D, C, R1, R0], 0)]
            : [([A, B, R0], 0.3), ([B, C, R1, R0], 0.26), ([D, A, R0, R1], 0.12), ([D, C, R1], 0)]
        for (pts, dk) in faces {
            poly(pts, mix(col, "#3a2410", dk))
            var g = c
            g.clip(to: path(pts))
            var strands = Path(), hi = Path()
            let tri = pts.count == 3
            var k: CGFloat = 0
            while k <= 1.001 {
                let b0 = lp(pts[0], pts[1], k), t0 = tri ? pts[2] : lp(pts[3], pts[2], k)
                strands.move(to: b0); strands.addLine(to: t0)
                k += 0.045
            }
            k = 0.02
            while k <= 1 {
                let b0 = lp(pts[0], pts[1], k), t0 = tri ? pts[2] : lp(pts[3], pts[2], k), m = lp(b0, t0, 0.35)
                hi.move(to: b0); hi.addLine(to: m)
                k += 0.09
            }
            g.stroke(strands, with: .color(mix(col, "#3a2410", dk + 0.22)), lineWidth: 1)
            g.stroke(hi, with: .color(mix(col, "#fff2c8", max(0, 0.35 - dk))), lineWidth: 0.8)
        }
        var eave = Path()
        eave.move(to: pt(D.x, D.y + 1)); eave.addLine(to: pt(C.x, C.y + 1)); eave.addLine(to: pt(B.x, B.y + 1))
        c.stroke(eave, with: .color(mix(col, "#2a1808", 0.45)), lineWidth: 3)
        line(R0, R1, mix(col, "#2a1808", 0.55), 3.5)
    }

    /// A cone of thatch (a rondavel's or a banda's roof): apex at (cx, cy − hgt), base an ellipse of radius r.
    mutating func thatchCone(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ hgt: CGFloat, _ colIn: String = TownPainter.thatch) {
        let col = maraRains ? hexMix(colIn, "#5a4420", 0.2) : colIn, ap = pt(cx, cy - hgt)
        var back = Path()
        for i in 0...16 { let a = Double.pi + Double.pi * Double(i) / 16; let q = pt(cx + r * CGFloat(cos(a)), cy + r * 0.42 * CGFloat(sin(a))); if i == 0 { back.move(to: q) } else { back.addLine(to: q) } }
        back.closeSubpath()
        c.fill(back, with: .color(mix(col, "#3a2410", 0.3)))
        var cone = Path()
        cone.move(to: pt(cx - r, cy)); cone.addLine(to: ap); cone.addLine(to: pt(cx + r, cy))
        for i in 0...16 { let a = Double.pi * Double(i) / 16; cone.addLine(to: pt(cx + r * CGFloat(cos(a)), cy + r * 0.42 * CGFloat(sin(a)))) }
        cone.closeSubpath()
        c.fill(cone, with: .linearGradient(grad([(mix(col, "#fff2c8", 0.1), 0), (hex(col), 0.55), (mix(col, "#3a2410", 0.35), 1)]), startPoint: pt(cx - r, 0), endPoint: pt(cx + r, 0)))
        var strands = Path()
        var a = 0.15
        while a < Double.pi { let x = cx + CGFloat(cos(a)) * r, y = cy + CGFloat(sin(a)) * r * 0.42; strands.move(to: pt(x, y)); strands.addLine(to: pt(ap.x + (x - cx) * 0.08, ap.y + 3)); a += 0.22 }
        c.stroke(strands, with: .color(mix(col, "#3a2410", 0.3)), lineWidth: 0.9)
        var rim = Path()
        for i in 0...16 { let a = 0.05 + (Double.pi - 0.1) * Double(i) / 16; let q = pt(cx + r * CGFloat(cos(a)), cy + r * 0.42 * CGFloat(sin(a))); if i == 0 { rim.move(to: q) } else { rim.addLine(to: q) } }
        c.stroke(rim, with: .color(mix(col, "#2a1808", 0.5)), lineWidth: 2.6)
        ellipse(ap.x, ap.y + 1, 2.4, 2.4, mix(col, "#2a1808", 0.5))
    }

    /// A flat-topped acacia: a forked trunk, an umbrella crown.
    mutating func acacia(_ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ colIn: String? = nil) {
        let col = colIn ?? (maraRains ? "#5a7a32" : "#6a7a34")
        var trunk = Path()
        trunk.move(to: pt(x, y)); trunk.addQuadCurve(to: pt(x - 2 * s, y - 24 * s), control: pt(x + 1 * s, y - 16 * s))
        c.stroke(trunk, with: .color(hex("#4a3420")), style: StrokeStyle(lineWidth: 3.2 * s, lineCap: .round))
        var br = Path()
        br.move(to: pt(x - 1 * s, y - 18 * s)); br.addQuadCurve(to: pt(x - 18 * s, y - 34 * s), control: pt(x - 10 * s, y - 26 * s))
        br.move(to: pt(x - 1.5 * s, y - 21 * s)); br.addQuadCurve(to: pt(x + 17 * s, y - 35 * s), control: pt(x + 8 * s, y - 28 * s))
        br.move(to: pt(x - 2 * s, y - 24 * s)); br.addLine(to: pt(x - 1 * s, y - 36 * s))
        c.stroke(br, with: .color(hex("#4a3420")), style: StrokeStyle(lineWidth: 2 * s, lineCap: .round))
        ellipse(x, y - 35 * s, 30 * s, 7 * s, mix(col, "#1a2008", 0.4))
        ellipse(x - 12 * s, y - 37 * s, 17 * s, 5.5 * s, hex(col))
        ellipse(x + 11 * s, y - 38 * s, 18 * s, 5.5 * s, hex(col))
        ellipse(x, y - 40 * s, 20 * s, 5 * s, mix(col, "#c8d070", 0.2))
        ellipse(x - 6 * s, y - 41.5 * s, 9 * s, 2 * s, mix(col, "#e8e8a0", 0.3))
    }

    /// An acacia in silhouette on the horizon.
    mutating func acaciaSil(_ x: CGFloat, _ y: CGFloat, _ h: CGFloat, _ col: Color) {
        var t = Path()
        t.move(to: pt(x, y)); t.addLine(to: pt(x, y - h * 0.55)); t.addLine(to: pt(x - h * 0.25, y - h * 0.8))
        t.move(to: pt(x, y - h * 0.55)); t.addLine(to: pt(x + h * 0.28, y - h * 0.82))
        c.stroke(t, with: .color(col), lineWidth: max(1.2, h * 0.05))
        ellipse(x, y - h * 0.84, h * 0.62, h * 0.1, col)
        ellipse(x - h * 0.2, y - h * 0.9, h * 0.3, h * 0.07, col)
    }

    /// A termite mound: a red-earth spire with a lit side.
    mutating func termiteMound(_ x: CGFloat, _ y: CGFloat, _ s: CGFloat) {
        var m = Path()
        m.move(to: pt(x - 9 * s, y)); m.addQuadCurve(to: pt(x - 2 * s, y - 30 * s), control: pt(x - 7 * s, y - 18 * s))
        m.addLine(to: pt(x + 1 * s, y - 26 * s)); m.addQuadCurve(to: pt(x + 4 * s, y - 22 * s), control: pt(x + 5 * s, y - 20 * s))
        m.addQuadCurve(to: pt(x + 10 * s, y), control: pt(x + 8 * s, y - 10 * s)); m.closeSubpath()
        c.fill(m, with: .color(hex("#9a5232")))
        var l = Path()
        l.move(to: pt(x - 9 * s, y)); l.addQuadCurve(to: pt(x - 2 * s, y - 30 * s), control: pt(x - 7 * s, y - 18 * s)); l.addLine(to: pt(x - 1 * s, y)); l.closeSubpath()
        c.fill(l, with: .color(hex("#c47a4a")))
    }

    /// A granite kopje: rounded boulders, a bush in a cleft.
    mutating func kopjeRock(_ x: CGFloat, _ y: CGFloat, _ hh: CGFloat) {
        let s = hh / 60
        ellipse(x - 20 * s, y - 12 * s, 26 * s, 14 * s, hex("#8a7a6c")); ellipse(x + 18 * s, y - 14 * s, 24 * s, 16 * s, hex("#a8988a"))
        ellipse(x - 2 * s, y - 32 * s, 22 * s, 16 * s, hex("#b8a898")); ellipse(x + 6 * s, y - 48 * s, 12 * s, 9 * s, hex("#9a8a7c"))
        ellipse(x - 6 * s, y - 38 * s, 10 * s, 4 * s, rgba(255, 240, 210, 0.25)); ellipse(x + 30 * s, y - 6 * s, 9 * s, 7 * s, hex("#6a7a34"))
    }

    /// A luxury safari tent on its deck: canvas walls, a fly sheet over the ridge, the door flaps tied back, a lantern.
    mutating func safariTent(_ x: CGFloat, _ y: CGFloat, _ s: CGFloat) {
        let w = 46 * s, d = 18 * s, hw = 26 * s, rg = 40 * s
        poly([pt(x - w * 0.6, y), pt(x + w * 0.2, y + d * 0.5), pt(x + w * 0.7, y - d * 0.2), pt(x - w * 0.1, y - d * 0.7)], hex("#7a5434"))
        rect(x + 2 * s, y - hw - 2 * s, w * 0.42, hw, hex("#c8b48c")); rect(x - w * 0.44, y - hw, w * 0.46, hw, hex("#f0e6cc"))
        poly([pt(x - w * 0.28, y), pt(x - w * 0.21, y - hw * 0.8), pt(x - w * 0.14, y)], hex(night != nil ? "#ffd27a" : "#4a3a28"))
        poly([pt(x - w * 0.33, y), pt(x - w * 0.21, y - hw * 0.82), pt(x - w * 0.27, y)], hex("#d8c8a2"))
        poly([pt(x - w * 0.09, y), pt(x - w * 0.21, y - hw * 0.82), pt(x - w * 0.15, y)], hex("#d8c8a2"))
        poly([pt(x - w * 0.56, y - hw + 2 * s), pt(x - w * 0.02, y - rg), pt(x + w * 0.52, y - rg + 4 * s), pt(x + w * 0.5, y - hw - 3 * s), pt(x + w * 0.04, y - hw - 6 * s)], hex("#d6c69c"))
        poly([pt(x - w * 0.56, y - hw + 2 * s), pt(x - w * 0.02, y - rg), pt(x + w * 0.04, y - hw - 6 * s)], hex("#efe4c4"))
        var ropes = Path()
        ropes.move(to: pt(x - w * 0.56, y - hw + 2 * s)); ropes.addLine(to: pt(x - w * 0.7, y))
        ropes.move(to: pt(x + w * 0.5, y - hw - 3 * s)); ropes.addLine(to: pt(x + w * 0.66, y - 4 * s))
        c.stroke(ropes, with: .color(rgba(90, 70, 40, 0.5)), lineWidth: 0.8)
        lantern(x - w * 0.38, y - hw * 0.55)
    }

    /// A round hut: an ochre wall and a thatched cone.
    mutating func rondavel(_ x: CGFloat, _ y: CGFloat, _ s: CGFloat) {
        let r = 22 * s, hw = 22 * s
        rect(x - r, y - hw, r * 2, hw, hex("#a8724c"))
        ellipse(x, y, r, r * 0.42, hex("#a8724c"))
        rect(x - r, y - hw, r * 0.9, hw, hex("#e2b68c"))
        rect(x - 4 * s, y - 13 * s + r * 0.3, 8 * s, 13 * s, hex(night != nil ? "#ffd27a" : "#4a2e1c"))
        thatchCone(x, y - hw, r * 1.22, 30 * s)
    }

    /// A Maasai enkaji: a low loaf-shaped house of branches plastered with earth, a dark doorway.
    mutating func enkaji(_ x: CGFloat, _ y: CGFloat) {
        var h = Path()
        h.move(to: pt(x - 13, y)); h.addQuadCurve(to: pt(x - 4, y - 14), control: pt(x - 14, y - 13)); h.addQuadCurve(to: pt(x + 13, y - 9), control: pt(x + 8, y - 15))
        h.addLine(to: pt(x + 13, y)); h.closeSubpath()
        c.fill(h, with: .color(hex("#8a6a4a")))
        var l = Path()
        l.move(to: pt(x - 13, y)); l.addQuadCurve(to: pt(x - 4, y - 14), control: pt(x - 14, y - 13)); l.addQuadCurve(to: pt(x - 1, y), control: pt(x - 2, y - 6)); l.closeSubpath()
        c.fill(l, with: .color(hex("#a8865e")))
        rect(x - 9, y - 7, 4, 7, hex("#3a2618"))
    }

    mutating func cow(_ x: CGFloat, _ y: CGFloat, _ col: String, _ d: CGFloat) {
        ellipse(x, y - 5, 6, 3.4, hex(col)); rect(x - 4.6, y - 3, 1.4, 3.4, hex(col)); rect(x + 3.2, y - 3, 1.4, 3.4, hex(col))
        ellipse(x + d * 6.4, y - 6.4, 2.4, 2, hex(col))
        var horn = Path()
        horn.move(to: pt(x + d * 5.4, y - 8)); horn.addQuadCurve(to: pt(x + d * 8.4, y - 10), control: pt(x + d * 6.4, y - 11))
        c.stroke(horn, with: .color(hex("#e8dcc0")), lineWidth: 1)
    }

    /// A zebra standing in town (the flight painter's animal at a bigger size).
    mutating func zebra(_ x: CGFloat, _ y: CGFloat, _ d: CGFloat, _ s: CGFloat) { MaraPainter.beast(&c, .zebra, x: x, y: y, d: d, s: s, p: 1, time: t + Double(x)) }
    mutating func beast(_ k: HerdKind, _ x: CGFloat, _ y: CGFloat, _ d: CGFloat, _ s: CGFloat) { MaraPainter.beast(&c, k, x: x, y: y, d: d, s: s, p: 1, time: t + Double(x)) }

    /// A giraffe browsing, its neck swaying.
    mutating func giraffe(_ x: CGFloat, _ y: CGFloat, _ s: CGFloat) {
        let col = hex("#d8a050"), sp = hex("#8a5a2a"), bob = CGFloat(sin(t * 0.8)) * 1.5
        for dx: CGFloat in [-9, -3, 5, 10] { rect(x + dx * s, y - 34 * s, 2 * s, 34 * s, col) }
        ellipse(x, y - 38 * s, 13 * s, 7 * s, col)
        poly([pt(x + 7 * s, y - 42 * s), pt(x + 15 * s, y - 72 * s + bob), pt(x + 20 * s, y - 70 * s + bob), pt(x + 13 * s, y - 38 * s)], col)
        ellipse(x + 20 * s, y - 73 * s + bob, 6 * s, 3 * s, col)
        rect(x + 16 * s, y - 80 * s + bob, 1.2 * s, 5 * s, sp); rect(x + 19 * s, y - 80 * s + bob, 1.2 * s, 5 * s, sp)
        for i in 0..<9 { rect(x - 10 * s + CGFloat(i % 5) * 5 * s, y - 42 * s + CGFloat(i / 5) * 5 * s, 3 * s, 3 * s, sp) }
        for i in 0..<4 { let fi = CGFloat(i); rect(x + 9 * s + fi * 2 * s, y - 48 * s - fi * 6 * s + bob * fi / 4, 2.6 * s, 2.6 * s, sp) }
    }

    /// A safari Land Cruiser with a canvas pop-up roof (grid position, colour).
    mutating func landCruiser(_ gx: Double, _ gy: Double, _ col: String) {
        let f = block(gx, gy, 0.7, 0.34, 15, lit: col, shade: hexMix(col, "#000000", 0.3), top: hexMix(col, "#ffffff", 0.15), courses: false)
        var a = face(f.D, f.C, 15)
        a.fill(Path(CGRect(x: 0.08, y: 0.5, width: 0.84, height: 0.35)), with: .color(hex("#2a3440")))
        for u: CGFloat in [0.3, 0.55, 0.78] { a.fill(Path(CGRect(x: u, y: 0.5, width: 0.03, height: 0.35)), with: .color(hex(col))) }
        let keep = c
        c.translateBy(x: 0, y: -15)
        _ = block(gx + 0.1, gy + 0.04, 0.5, 0.26, 6, lit: "#d8c8a0", shade: "#a8986e", top: "#e8dcb8", courses: false)
        c = keep
        for u: CGFloat in [0.18, 0.82] { let p = lp(f.D, f.C, u); ellipse(p.x, p.y - 1, 4, 4, hex("#1f1c22")) }
    }

    /// The Mara's openings: square, framed in dark timber, a rolled-up canvas blind over each window; doors of wide
    /// planks; the tents' doors are canvas flaps tied back.
    mutating func maraOpening(_ p: CGPoint, _ q: CGPoint, _ h: CGFloat, _ u: CGFloat, _ v: CGFloat, _ w: CGFloat, _ hh: CGFloat, door: Bool, lit: Bool) {
        var f = face(p, q, h)
        let x0 = u - w / 2, fr = min(w, hh) * 0.12
        func r(_ x: CGFloat, _ y: CGFloat, _ ww: CGFloat, _ hgt: CGFloat, _ col: Color) { f.fill(Path(CGRect(x: x, y: y, width: ww, height: hgt)), with: .color(col)) }
        if door {
            if tuff.canvas {
                var tri = Path(); tri.move(to: pt(x0, v)); tri.addLine(to: pt(u, v + hh)); tri.addLine(to: pt(x0 + w, v)); tri.closeSubpath()
                f.fill(tri, with: .color(hex(lit || night != nil ? "#ffd27a" : "#4a3a28")))
                return
            }
            r(x0 - fr, v, w + fr * 2, hh + fr, hex("#3e2616")); r(x0, v, w, hh, hex("#7a4a26"))
            for i in 1..<4 { r(x0 + w * CGFloat(i) / 4 - 0.004, v, 0.008, hh, rgba(40, 20, 8, 0.35)) }
            r(x0 + w * 0.78, v + hh * 0.42, w * 0.08, hh * 0.05, hex("#d8b040"))
            return
        }
        r(x0 - fr, v - fr, w + fr * 2, hh + fr * 2, hex("#3e2616"))
        r(x0, v, w, hh, hex(lit ? "#ffd27a" : "#2e2a26"))
        if !lit { r(x0, v + hh * 0.55, w * 0.45, hh * 0.4, rgba(200, 180, 140, 0.18)) }
        r(u - fr * 0.3, v, fr * 0.6, hh, hex("#3e2616"))
        r(x0 - fr * 0.6, v + hh - fr * 0.4, w + fr * 1.2, fr * 1.4, hex("#e8dcbc"))
        if lit {
            let m = lp(p, q, u)
            glow(m.x, m.y - h * (v + hh / 2), 24, Color(red: 1, green: 190 / 255, blue: 90 / 255), 0.16)
        }
    }

    /// The Mara's things in camp: Land Cruisers by the square, a boma fire ring (lit at night), termite mounds and a
    /// giraffe browsing an acacia on the camp's edge.
    func maraScenery() -> [TownItem] {
        var items: [TownItem] = []
        for (gx, gy, col) in [(9.2, 6.7, "#7a8a5a"), (10.2, 6.75, "#c8b48a")] {
            items.append(TownItem(depth: gx + gy + 1, shadow: { p in p.boxShadow(gx, gy, 0.7, 0.34, 18, 0.16) }, draw: { p in p.landCruiser(gx, gy, col) }))
        }
        items.append(TownItem(depth: 6.6 + 9.6, draw: { p in
            let q = p.iso(6.6, 9.6)
            for i in 0..<7 { let a = Double(i) / 7 * .pi * 2; p.ellipse(q.x + CGFloat(cos(a)) * 14, q.y + CGFloat(sin(a)) * 6, 4, 2.6, p.hex("#7a6a5a")) }
            var logs = Path()
            logs.move(to: p.pt(q.x - 7, q.y + 2)); logs.addLine(to: p.pt(q.x + 6, q.y - 2)); logs.move(to: p.pt(q.x - 5, q.y - 3)); logs.addLine(to: p.pt(q.x + 7, q.y + 2))
            p.c.stroke(logs, with: .color(p.hex("#5a3a20")), lineWidth: 3)
            if p.night != nil {
                let f = 1 + CGFloat(sin(p.t * 9)) * 0.15
                var fl = Path(); fl.move(to: p.pt(q.x - 6, q.y)); fl.addQuadCurve(to: p.pt(q.x + 6, q.y), control: p.pt(q.x, q.y - 22 * f)); fl.closeSubpath()
                p.c.fill(fl, with: .color(p.hex("#ffb030")))
                p.glow(q.x, q.y - 8, 60, Color(red: 1, green: 170 / 255, blue: 80 / 255), 0.5)
            }
        }))
        for (gx, gy, k) in [(15.9, 2.2, 1.1), (-0.9, 9.4, 1.3), (12.2, 15.9, 0.9)] {
            items.append(TownItem(depth: gx + gy, draw: { p in let q = p.iso(gx, gy); p.termiteMound(q.x, q.y, CGFloat(k)) }))
        }
        items.append(TownItem(depth: 16.6 + 13.6, draw: { p in let q = p.iso(16.6, 13.6); p.acacia(q.x + 26, q.y - 4, 1.3); p.giraffe(q.x, q.y, 0.9) }))
        return items
    }

    /// The camp's edges: acacias, a termite mound, a kopje.
    mutating func maraEdge(_ x: CGFloat, _ y: CGFloat, _ hh: CGFloat, _ seed: Double) {
        let k = Int((seed * 10).rounded()) % 3
        if k == 0 { acacia(x - 16, y, 1.5); acacia(x + 20, y + 8, 1.1); return }
        if k == 1 { termiteMound(x - 20, y + 4, 1.2); acacia(x + 8, y, 1.7); return }
        kopjeRock(x, y, hh * 0.5)
    }

    /// Out on the plains: acacias, kopjes, termite mounds, now and then a few giraffes.
    mutating func maraOuter(_ x: CGFloat, _ y: CGFloat, _ hh: CGFloat, _ i: Int) {
        if i % 6 == 0 { kopjeRock(x, y, hh * 0.5); return }
        if i % 6 == 3 { termiteMound(x - 18, y + 4, 1.1); acacia(x + 6, y, 1.6); return }
        if i % 9 == 4 { acacia(x + 20, y - 2, 1.4); giraffe(x - 6, y + 4, 0.8); return }
        acacia(x, y, 1.3 + CGFloat(i % 3) * 0.25)
        if i % 2 == 1 { acacia(x + 30, y + 8, 0.9) }
    }

    /// The Mara River behind the camp: a band of riverine green, brown water, hippos (`outerDecor`).
    mutating func maraRiver() {
        func band(_ y0: Double, _ y1: Double, _ col: Color) { poly([iso(-60, y0), iso(70, y0), iso(70, y1), iso(-60, y1)], col) }
        band(-15.5, -9.5, hex("#8a9a52")); band(-13.4, -11.4, hex("#7a6e4a")); band(-13.1, -12.8, Color.white.opacity(0.12))
        for (hx, hy) in [(3.0, -12.4), (3.6, -12.1), (11.5, -12.6), (19, -12.3)] {
            let q = iso(hx + sin(t * 0.2 + hx) * 0.05, hy)
            ellipse(q.x, q.y, 9, 4, hex("#4a4040")); ellipse(q.x + 7, q.y - 2, 4, 2.6, hex("#4a4040")); ellipse(q.x + 8, q.y - 3.4, 1, 1, .white)
        }
    }

    /// The rains: falling rain over the camp, in screen space.
    mutating func rainfall(_ w: CGFloat, _ h: CGFloat) {
        var r = Path()
        for i in 0..<110 {
            let d = Double(i)
            let x = CGFloat((d * 97.3 + t * 30).truncatingRemainder(dividingBy: Double(w) + 20)) - 10
            let y = CGFloat((d * 53.7 + t * (380 + Double(i % 5) * 40)).truncatingRemainder(dividingBy: Double(h)))
            r.move(to: pt(x, y)); r.addLine(to: pt(x - 3, y + 13))
        }
        c.stroke(r, with: .color(Color(red: 220 / 255, green: 230 / 255, blue: 245 / 255).opacity(0.55)), lineWidth: 1.1)
    }

    /// Tufts of red-oat grass where the other regions have vines.
    mutating func grassTufts(_ fields: [(Double, Double, Double, Double)]) {
        var tufts = Path()
        for (gx0, gy0, gw, gd) in fields {
            var R = rng(gx0 * 7 + gy0)
            for _ in 0..<40 {
                let q = iso(gx0 + R.next() * gw, gy0 + R.next() * gd)
                tufts.move(to: pt(q.x - 4, q.y)); tufts.addLine(to: pt(q.x - 2, q.y - 7))
                tufts.move(to: pt(q.x, q.y)); tufts.addLine(to: pt(q.x + 1, q.y - 8))
                tufts.move(to: pt(q.x + 4, q.y)); tufts.addLine(to: pt(q.x + 5, q.y - 6))
            }
        }
        c.stroke(tufts, with: .color(rgba(150, 110, 50, 0.45)), lineWidth: 1.4)
    }

    /// The Mara's grand lodge in place of the palace: a long stone house under one great thatch, a deep veranda on
    /// timber posts, a pool on the lawn, two suite tents, acacias.
    mutating func maraLodge(_ g: Double, _ k: Double, own: Bool) {
        let (oA, oB, oC, oD) = corners(g + 0.5, k + 2.15, 2.2, 0.66)
        poly([oA, oB, oC, oD], hex("#d8c8a8"))
        let (iA, iB, iC, iD) = corners(g + 0.58, k + 2.21, 2.04, 0.54)
        polyShade([iA, iB, iC, iD], .linearGradient(grad([(hex("#7fd8e0"), 0), (hex("#2a98b0"), 1)]), startPoint: iA, endPoint: iC))
        for (x, y) in [(g + 0.1, k + 1.6), (g + 3.0, k + 1.75)] { let q = iso(x, y); safariTent(q.x, q.y, 1.1) }
        for (x, y, sc) in [(g + 0.05, k + 0.1, 1.3), (g + 3.1, k + 0.6, 1.1)] { let q = iso(x, y); acacia(q.x, q.y, CGFloat(sc)) }
        let f = block(g + 0.45, k + 0.25, 2.3, 1.25, 84)
        for r in 0..<2 { for u: CGFloat in [0.12, 0.3, 0.48, 0.66, 0.84] { opening(f.D, f.C, 84, u, 0.12 + CGFloat(r) * 0.45, 0.1, 0.28, lit: r == 0 || u == 0.48) } }
        for u: CGFloat in [0.25, 0.75] { opening(f.C, f.B, 84, u, 0.5, 0.22, 0.28, lit: true) }
        opening(f.D, f.C, 84, 0.57, 0, 0.11, 0.34, door: true)
        let a = lp(f.D, f.C, 0.02), cc = lp(f.D, f.C, 0.98), hv: CGFloat = 40
        poly([upp(a, hv), upp(cc, hv), pt(cc.x - 14, cc.y + 7 - hv), pt(a.x - 14, a.y + 7 - hv)], hex("#5a3a20"))
        for i in 0...8 { let q = lp(a, cc, CGFloat(i) / 8); rect(q.x - 14 - 1.6, q.y + 7 - hv, 3.2, hv, hex("#5a3a20")) }
        thatchRoof(g + 0.45, k + 0.25, 2.3, 1.25, 84, 80)
        let rc = lp(f.D, f.C, 0.57)
        poly([rc, pt(rc.x + 10, rc.y + 5), pt(rc.x - 18, rc.y + 40), pt(rc.x - 28, rc.y + 35)], hex("#c0283a"))
        let top = lp(f.a, f.c, 0.5)
        flag(top.x, top.y - 76, own ? (s.colors.first ?? "#ffc23d") : "#ffc23d", hgt: 40)
        for (x, y, sc) in [(g + 0.2, k + 2.8, 0.9), (g + 2.9, k + 2.85, 1.0)] { let q = iso(x, y); acacia(q.x, q.y, CGFloat(sc)) }
    }
}
