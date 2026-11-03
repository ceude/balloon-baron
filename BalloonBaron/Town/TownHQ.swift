import SwiftUI
import BalloonBaronCore

// v135: the holding's headquarters in the region's own architecture (prototype `hqHouse`, `hqShadow`, `HQ_GEO`,
// `HQ_LOOK`, `HQ_TOP`). The gold glass tower stood out of the town; the headquarters is built of the town's own
// materials: a restored stone konak round a courtyard in Cappadocia, a colonial villa with verandas in Luxor, a red-brick
// merchant's hall in Bristol, a Pueblo Revival office in Albuquerque. Its tower stays the tallest thing in town; a flagpole
// in your colours, a brass plaque by the gate and a little gold on the tower tell it is the holding.
// v135.1 (developer): it stands complete from the day the holding exists, it doesn't grow: both wings two storeys, a
// three-storey main house, the gatehouse, an arcade along the courtyard's street side, the tower with its crown and
// lantern stage, a gilded statue in the forecourt. At night fewer of its windows light up than elsewhere in town
// (`openDim`).

extension TownPainter {
    static let hqMain = (9.55, 0.3, 1.7, 1.05), hqTower = (10.68, 0.98, 0.5, 0.5)
    static let hqWingL = (9.08, 0.3, 0.47, 1.95), hqWingR = (11.25, 0.3, 0.5, 1.95), hqGate = (10.07, 2.08, 0.66, 0.36)
    static let hqMainH: CGFloat = 132, hqWingH: CGFloat = 92
    static let hqShaft: CGFloat = 192, hqCrown: CGFloat = 34, hqLantern: CGFloat = 26
    /// The height of the tower's top, for the name tag and the shadow.
    static let hqTop: CGFloat = hqShaft + hqCrown + hqLantern + 44

    private struct HQLook {
        var roof = "#b4553a", trim: String, dome: String?, shutter = "#3f7a5a"
        var wall: (lit: String, shade: String, top: String)?
    }

    private var hqLook: HQLook {
        switch s.region {
        case .cap: return HQLook(roof: "#b4553a", trim: "#fbead0", dome: "#e8b23a")
        case .lux: return HQLook(trim: "#fdf8ec", dome: "#e8b23a", wall: ("#f4dcae", "#c79d66", "#efd9ae"))
        case .bri: return HQLook(roof: "#5e6874", trim: "#ecd39c", dome: "#7ab0a0")
        case .abq: return HQLook(trim: "#3aa6a0", dome: nil)
        }
    }

    mutating func hqShadow() {
        let m = Self.hqMain, t0 = Self.hqTower
        boxShadow(m.0, m.1, m.2, m.3, Self.hqMainH + 20, 0.16)
        boxShadow(t0.0, t0.1, t0.2, t0.3, Self.hqTop - 20, 0.14)
        for g in [Self.hqWingL, Self.hqWingR] { boxShadow(g.0, g.1, g.2, g.3, Self.hqWingH, 0.14) }
    }

    mutating func hqHouse(_ b: TownBuilding) {
        openDim = true
        hqHouseDraw()
        openDim = false
    }

    private mutating func hqHouseDraw() {
        let R = s.region, L = hqLook, bri = R == .bri, abq = R == .abq, lux = R == .lux, cap = R == .cap
        let T = tuff, W = L.wall
        let wl = W?.lit ?? T.lit, ws = W?.shade ?? T.shade, wt = W?.top ?? T.top, wc = W == nil
        @discardableResult
        func wallBlock(_ p: inout TownPainter, _ gx: Double, _ gy: Double, _ w: Double, _ d: Double, _ h: CGFloat, courses: Bool? = nil) -> Box {
            p.block(gx, gy, w, d, h, lit: wl, shade: ws, top: wt, courses: courses ?? wc)
        }
        func roof(_ p: inout TownPainter, _ gx: Double, _ gy: Double, _ w: Double, _ d: Double, _ h: CGFloat, _ rise: CGFloat) {
            if cap || bri { p.hipRoof(gx, gy, w, d, h, rise, L.roof) } else { p.flatRoof(gx, gy, w, d, h, dome: false) }
        }
        // stone dressings: a cornice band under the roof, quoins at the corners (Bristol's Bath stone on brick)
        func cornice(_ p: inout TownPainter, _ f: Box, _ h: CGFloat) {
            for (a, b) in [(f.D, f.C), (f.C, f.B)] { p.poly([p.upp(a, h - 5), p.upp(b, h - 5), p.upp(b, h), p.upp(a, h)], p.hex(L.trim)) }
        }
        func quoins(_ p: inout TownPainter, _ f: Box, _ h: CGFloat) {
            guard bri else { return }
            for q in [f.D, f.C] {
                var y: CGFloat = 4
                while y < h - 6 { p.rect(q.x - (q == f.C ? 3 : 6), q.y - y - 6, 6, 6, p.hex(L.trim)); y += 12 }
            }
        }
        // window rows: the region's kind of opening, lit ones warm; Luxor's green shutters, Albuquerque's turquoise frames
        func row(_ p: inout TownPainter, _ a: CGPoint, _ b: CGPoint, _ h: CGFloat, _ us: [CGFloat], _ v: CGFloat, _ w: CGFloat, _ hh: CGFloat, _ lit: (CGFloat) -> Bool) {
            for u in us {
                p.opening(a, b, h, u, v, w, hh, lit: lit(u))
                if lux {
                    var f = p.face(a, b, h)
                    f.fill(Path(CGRect(x: u - w / 2 - w * 0.42, y: v, width: w * 0.38, height: hh * 0.72)), with: .color(p.hex(L.shutter)))
                    f.fill(Path(CGRect(x: u + w / 2 + w * 0.04, y: v, width: w * 0.38, height: hh * 0.72)), with: .color(p.hex(L.shutter)))
                }
                if abq {
                    let f = p.face(a, b, h)
                    f.stroke(Path(CGRect(x: u - w / 2 - 0.008, y: v - 0.01, width: w + 0.016, height: hh * 0.78)), with: .color(p.hex(L.trim)), lineWidth: 0.012)
                }
            }
        }
        func wing(_ p: inout TownPainter, _ G: (Double, Double, Double, Double), _ side: Int) {
            let h = Self.hqWingH, f = wallBlock(&p, G.0, G.1, G.2, G.3, h), two = true
            // the wing's end facing the street, and its long side facing the courtyard or the bank
            row(&p, f.D, f.C, h, [0.5], 0.14, 0.34, two ? 0.26 : 0.5) { _ in true }
            if two { row(&p, f.D, f.C, h, [0.5], 0.6, 0.34, 0.24) { _ in false } }
            let us: [CGFloat] = [0.12, 0.3, 0.48, 0.66, 0.84]
            row(&p, f.C, f.B, h, us, two ? 0.1 : 0.18, 0.07, two ? 0.26 : 0.45) { $0 > 0.4 }
            if two { row(&p, f.C, f.B, h, us, 0.6, 0.07, 0.24) { $0 < 0.3 || $0 > 0.8 } }
            if bri || cap { cornice(&p, f, h) }
            quoins(&p, f, h)
            roof(&p, G.0, G.1, G.2, G.3, h, 20)
        }
        var me = self
        defer { self = me }

        // the courtyard: paving, a fountain, a tree
        let (cA, cB, cC, cD) = me.corners(9.55, 1.35, 1.7, 0.95)
        me.poly([cA, cB, cC, cD], me.hex(abq ? "#d9a982" : bri ? "#b8b0a2" : "#e6cfa6"))
        var joints = Path()
        for i in 1..<6 { let k = CGFloat(i) / 6; joints.move(to: me.lp(cA, cD, k)); joints.addLine(to: me.lp(cB, cC, k)) }
        me.c.stroke(joints, with: .color(me.hex(abq ? "#b07a54" : "#a88a64").opacity(0.35)), lineWidth: 1)
        wing(&me, Self.hqWingL, 0)

        // the main house: three storeys; window rows placed in pixels
        let MH = Self.hqMainH, m = Self.hqMain, f = wallBlock(&me, m.0, m.1, m.2, m.3, MH)
        func px(_ v: CGFloat) -> CGFloat { v / MH }
        row(&me, f.D, f.C, MH, [0.1, 0.26, 0.42], px(9.6), 0.1, px(28.8)) { $0 != 0.26 }
        row(&me, f.D, f.C, MH, [0.1, 0.26, 0.42, 0.58], px(55.7), 0.1, px(25.9)) { $0 == 0.26 || $0 == 0.58 }
        row(&me, f.C, f.B, MH, [0.22, 0.5, 0.78], px(9.6), 0.16, px(28.8)) { _ in true }
        row(&me, f.C, f.B, MH, [0.22, 0.5, 0.78], px(55.7), 0.16, px(25.9)) { $0 == 0.5 }
        row(&me, f.D, f.C, MH, [0.1, 0.26, 0.42, 0.58], px(97), 0.1, px(24)) { $0 == 0.42 }
        row(&me, f.C, f.B, MH, [0.22, 0.5, 0.78], px(97), 0.16, px(24)) { $0 == 0.78 }
        me.opening(f.D, f.C, MH, 0.6, 0, 0.13, px(38.4), door: true)
        if cap { // a wooden cumba bay over the door
            let c0 = me.lp(f.D, f.C, 0.52), c1 = me.lp(f.D, f.C, 0.7), by: CGFloat = 48, bh: CGFloat = 30
            let q0 = me.upp(c0, by), q1 = me.upp(c1, by), Q0 = me.pt(q0.x - 11, q0.y + 5.5), Q1 = me.pt(q1.x - 11, q1.y + 5.5)
            me.poly([q0, q1, Q1, Q0], me.hex("#5a3418"))
            me.poly([Q0, Q1, me.upp(Q1, bh), me.upp(Q0, bh)], me.hex("#8a5a30"))
            for i in 0..<2 { let q = me.lp(Q0, Q1, (CGFloat(i) + 0.5) / 2); me.rect(q.x - 4, q.y - bh + 6, 8, 14, me.hex("#ffd27a")) }
            me.poly([me.upp(q0, bh), me.upp(q1, bh), me.upp(Q1, bh), me.upp(Q0, bh)], me.hex(L.roof))
        }
        if lux { // a deep veranda on slim columns along the ground floor, a balcony rail above
            let a = me.lp(f.D, f.C, 0.04), c2 = me.lp(f.D, f.C, 0.5), o = me.pt(-12, 6), hv: CGFloat = 46
            me.poly([me.upp(a, hv), me.upp(c2, hv), me.pt(c2.x + o.x, c2.y + o.y - hv), me.pt(a.x + o.x, a.y + o.y - hv)], me.hex(L.trim))
            for i in 0...4 {
                let q = me.lp(a, c2, CGFloat(i) / 4)
                me.rect(q.x + o.x - 1.5, q.y + o.y - hv, 3, hv, me.hex(L.trim))
                me.rect(q.x + o.x + 0.5, q.y + o.y - hv, 1, hv, me.rgba(120, 90, 50, 0.25))
            }
            var rail = Path()
            for i in 0...10 { let q = me.lp(a, c2, CGFloat(i) / 10); rail.move(to: me.pt(q.x + o.x, q.y + o.y - hv)); rail.addLine(to: me.pt(q.x + o.x, q.y + o.y - hv - 9)) }
            rail.move(to: me.pt(a.x + o.x, a.y + o.y - hv - 9)); rail.addLine(to: me.pt(c2.x + o.x, c2.y + o.y - hv - 9))
            me.c.stroke(rail, with: .color(me.hex(L.trim)), lineWidth: 1.2)
        }
        if bri || cap { cornice(&me, f, MH) }
        quoins(&me, f, MH)
        roof(&me, m.0, m.1, m.2, m.3, MH, 30)
        if bri { // chimney stacks with pots
            for u in [0.28, 0.72] {
                let q = me.upp(me.iso(m.0 + m.2 * u, m.1 + m.3 * 0.5), MH + 26)
                me.rect(q.x - 5, q.y - 22, 10, 26, me.hex("#8e4636")); me.rect(q.x, q.y - 22, 5, 26, me.hex("#7a3426"))
                for i in 0..<3 { me.rect(q.x - 4 + CGFloat(i) * 3.5, q.y - 27, 2.6, 5, me.hex("#c86a4a")) }
            }
        }
        if abq { // stepped parapets over the corners, the Pueblo Revival way
            for q in [f.d, f.c] {
                me.poly([me.pt(q.x - 14, q.y - 8), me.pt(q.x + 6, q.y - 8), me.pt(q.x + 6, q.y - 18), me.pt(q.x - 14, q.y - 18)], me.hex(T.lit))
                me.poly([me.pt(q.x - 8, q.y - 18), me.pt(q.x + 2, q.y - 18), me.pt(q.x + 2, q.y - 25), me.pt(q.x - 8, q.y - 25)], me.hex(T.top))
            }
        }

        // the tower: the tallest thing in town, a belvedere of arches at the top, a clock in Cappadocia and Bristol
        let tw = Self.hqTower, S = Self.hqShaft, ft = wallBlock(&me, tw.0, tw.1, tw.2, tw.3, S)
        for i in 0..<3 {
            for (a, b, lit) in [(ft.D, ft.C, true), (ft.C, ft.B, false)] {
                me.opening(a, b, S, 0.5, 0.2 + CGFloat(i) * 0.17, 0.22, 0.08, lit: lit && i == 1)
            }
        }
        for (a, b) in [(ft.D, ft.C), (ft.C, ft.B)] {
            me.poly([me.upp(a, S - 50), me.upp(b, S - 50), me.upp(b, S - 45), me.upp(a, S - 45)], me.hex(L.trim))
            for u: CGFloat in [0.3, 0.7] { me.opening(a, b, S, u, 1 - 40 / S, 0.28, 32 / S) }
        }
        quoins(&me, ft, S)
        if cap || bri { // the clock
            let ctr = me.upp(me.lp(ft.D, ft.C, 0.5), S - 68)
            var g = me.c
            g.concatenate(CGAffineTransform(a: 1, b: 0.5, c: 0, d: 1, tx: ctr.x, ty: ctr.y))
            let dial = Path(ellipseIn: CGRect(x: -9, y: -9, width: 18, height: 18))
            g.fill(dial, with: .color(me.hex("#fbf6ea"))); g.stroke(dial, with: .color(me.hex("#c99a2e")), lineWidth: 1.6)
            var hands = Path(); hands.move(to: .zero); hands.addLine(to: CGPoint(x: 0, y: -6.5)); hands.move(to: .zero); hands.addLine(to: CGPoint(x: 4.5, y: 1.5))
            g.stroke(hands, with: .color(me.hex("#2b2350")), lineWidth: 1.3)
            me.nightLite(ctr.x, ctr.y, 24, (255, 220, 150), 0.7)
        }
        if abq { // a gold bell in the belvedere
            let bp = me.upp(me.lp(ft.D, ft.C, 0.3), S - 26)
            var bell = Path()
            bell.move(to: me.pt(bp.x - 5, bp.y + 6))
            bell.addQuadCurve(to: me.pt(bp.x, bp.y - 6), control: me.pt(bp.x - 5, bp.y - 5))
            bell.addQuadCurve(to: me.pt(bp.x + 5, bp.y + 6), control: me.pt(bp.x + 5, bp.y - 5))
            me.c.fill(bell, with: .color(me.hex("#e8b23a")))
        }
        // stages on top of the tower: drawn shifted up, their windows moved up with them for the night
        func stage(_ p: inout TownPainter, _ inset: Double, _ lift: CGFloat, _ hgt: CGFloat, _ wv: CGFloat, _ ww: CGFloat, _ wh: CGFloat) -> Box {
            let keep = p.c, n0 = p.windows.count
            p.c.translateBy(x: 0, y: -lift)
            let fs = wallBlock(&p, tw.0 + inset, tw.1 + inset, tw.2 - inset * 2, tw.3 - inset * 2, hgt)
            for (a, b) in [(fs.D, fs.C), (fs.C, fs.B)] { p.opening(a, b, hgt, 0.5, wv, ww, wh, lit: true) }
            if bri || cap { cornice(&p, fs, hgt) }
            p.c = keep
            for i in n0..<p.windows.count { p.windows[i].p = p.upp(p.windows[i].p, lift); p.windows[i].q = p.upp(p.windows[i].q, lift) }
            return Box(A: fs.A, B: fs.B, C: fs.C, D: fs.D, a: p.upp(fs.a, lift), b: p.upp(fs.b, lift), c: p.upp(fs.c, lift), d: p.upp(fs.d, lift))
        }
        _ = stage(&me, 0.08, S, Self.hqCrown, 0.18, 0.4, 0.6) // the crown
        let top = stage(&me, 0.14, S + Self.hqCrown, Self.hqLantern, 0.2, 0.34, 0.55) // the lantern stage
        let tc = me.lp(top.a, top.c, 0.5), r = hypot(top.c.x - top.a.x, top.c.y - top.a.y) * 0.38
        if let dome = L.dome {
            me.dome(tc.x, tc.y - 2, r, dome)
            if bri { me.line(me.pt(tc.x - 7, tc.y - r - 24), me.pt(tc.x + 8, tc.y - r - 24), me.hex("#c99a2e"), 1.4) } // the gilded vane
        } else {
            me.poly([top.d, top.c, me.upp(top.c, 9), me.upp(top.d, 9)], me.hex(T.lit))
            me.poly([top.c, top.b, me.upp(top.b, 9), me.upp(top.c, 9)], me.hex(T.shade))
            me.poly([me.upp(top.a, 9), me.upp(top.b, 9), me.upp(top.c, 9), me.upp(top.d, 9)], me.hex(T.top))
        }
        let mine = s.colors.first ?? "#ff5e3a"
        me.flag(tc.x + (L.dome != nil ? 0 : 2), tc.y - (L.dome != nil ? r + 22 : 9), mine, hgt: 30)

        // the courtyard's things: a fountain and a tree
        let fo = me.iso(10.35, 1.88)
        me.ellipse(fo.x, fo.y, 17, 8.5, me.hex(abq ? "#c48a5e" : T.shade))
        me.ellipse(fo.x, fo.y - 2, 14, 7, me.hex(abq ? "#e2b08a" : T.lit))
        me.ellipse(fo.x, fo.y - 2, 10.5, 5, me.hex("#5fb8c8"))
        me.rect(fo.x - 2, fo.y - 13, 4, 11, me.hex(T.lit))
        for i in 0..<4 {
            let a = me.t * 2 + Double(i) * 1.6
            me.rect(fo.x + CGFloat(cos(a)) * 5 - 0.8, fo.y - 13 + CGFloat(abs(sin(a))) * 6, 1.6, 1.6, me.rgba(220, 245, 255, 0.8))
        }
        let tp = me.iso(9.78, 2.02)
        switch R {
        case .cap: me.cypress(tp.x, tp.y, 0.8)
        case .lux: me.palm(tp.x, tp.y, 0.62)
        case .bri: me.copperBeech(tp.x, tp.y, 0.7)
        case .abq: me.roundTree(tp.x, tp.y, 0.85, "#9aa84a")
        }
        wing(&me, Self.hqWingR, 1)

        // the courtyard's street side: an arcade of arches on slim piers under a cornice
        for (ax, aw) in [(9.08, 0.99), (10.73, 1.02)] {
            let fa = wallBlock(&me, ax, 2.25, aw, 0.12, 40, courses: false), k = Int((aw / 0.2).rounded())
            for i in 0..<k { me.opening(fa.D, fa.C, 40, (CGFloat(i) + 0.5) / CGFloat(k), 0, 0.62 / CGFloat(k), 0.72) }
            if bri || cap { cornice(&me, fa, 40) }
        }
        // the gatehouse: an arched gate under a little room, a small dome or a stepped parapet on top
        let g = Self.hqGate, gh: CGFloat = 58, fg = wallBlock(&me, g.0, g.1, g.2, g.3, gh)
        me.opening(fg.D, fg.C, gh, 0.5, 0, 0.42, 0.62, door: true)
        me.opening(fg.C, fg.B, gh, 0.5, 0.55, 0.3, 0.25, lit: true)
        if bri || cap { cornice(&me, fg, gh) }
        quoins(&me, fg, gh)
        if lux || cap { let q = me.lp(fg.a, fg.c, 0.5); me.dome(q.x, q.y - 1, 13, lux ? "#f6eedb" : (L.dome ?? "#e8b23a")) }
        else { roof(&me, g.0, g.1, g.2, g.3, gh, 14) }
        let plaqueAt = me.lp(fg.D, fg.C, 0.9), plaqueH: CGFloat = 26
        // the brass plaque by the gate: a small polished panel, no words at this size
        do {
            var g = me.c
            g.concatenate(CGAffineTransform(a: 1, b: -0.5, c: 0, d: 1, tx: plaqueAt.x, ty: plaqueAt.y - plaqueH))
            g.fill(Path(CGRect(x: -5.5, y: -7, width: 11, height: 8)),
                   with: .linearGradient(me.grad([(me.hex("#fff0b8"), 0), (me.hex("#d9a63a"), 0.5), (me.hex("#a8761c"), 1)]),
                                         startPoint: CGPoint(x: -5, y: -6), endPoint: CGPoint(x: 5, y: 6)))
            for i in 0..<2 { g.fill(Path(CGRect(x: -3.5, y: -5 + CGFloat(i) * 3, width: 7, height: 0.9)), with: .color(me.rgba(90, 60, 10, 0.5))) }
        }
        // the flagpole on the corner of the forecourt, your colours
        let fp = me.iso(9.2, 2.62)
        me.flag(fp.x, fp.y, mine, hgt: 96)
        me.ellipse(fp.x, fp.y - 98, 2.6, 2.6, me.hex("#e8b23a"))
        // a gilded statue of the founder on a stone plinth in the forecourt
        do {
            wallBlock(&me, 11.12, 2.48, 0.3, 0.3, 18, courses: false)
            let sp = me.upp(me.iso(11.27, 2.63), 18)
            let gold = GraphicsContext.Shading.linearGradient(me.grad([(me.hex("#fff0b0"), 0), (me.hex("#e0aa3a"), 0.5), (me.hex("#9a6a18"), 1)]),
                                                              startPoint: me.pt(sp.x - 6, 0), endPoint: me.pt(sp.x + 6, 0))
            var fig = Path()
            fig.addRect(CGRect(x: sp.x - 4, y: sp.y - 20, width: 8, height: 14))
            fig.addRect(CGRect(x: sp.x - 4, y: sp.y - 6, width: 3, height: 6)); fig.addRect(CGRect(x: sp.x + 1, y: sp.y - 6, width: 3, height: 6))
            fig.addEllipse(in: CGRect(x: sp.x - 4, y: sp.y - 28, width: 8, height: 8))
            me.c.fill(fig, with: gold)
            var arm = Path(); arm.move(to: me.pt(sp.x + 3, sp.y - 18)); arm.addLine(to: me.pt(sp.x + 9, sp.y - 30))
            me.c.stroke(arm, with: gold, lineWidth: 2.6)
        }
        // a lantern either side of the gate at night
        if (night?.k ?? 0) > 0 { for g in [(10.02, 2.42), (10.78, 2.42)] { let q = me.iso(g.0, g.1); me.lantern(q.x, q.y - 38) } }
    }
}
