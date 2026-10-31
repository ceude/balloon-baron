import SwiftUI
import BalloonBaronCore

// v124 / v124.1: Bristol's town (prototype `briTownScenery`, `tudorPub`, `briOpening`, `TUFF_BY.bri`, `BATH`):
// Victorian red brick with slate gables, white sash windows under stone lintels, painted doors with fanlights; the hotels
// and the bank in honey Bath stone; the bazaar as a Tudor pub; red phone boxes and pillar boxes, double-deckers on the
// main roads, the pub's hanging sign, puddles, copper beeches and oaks, sheep behind hedges, the harbour with its tall
// ship behind the town, gulls and an overcast sky.
extension TownPainter {
    /// Victorian red brick with light mortar.
    static let bristolBrick = Tuff(lit: "#b65c42", shade: "#7a3426", top: "#8e4636",
                                   line: Color(red: 236 / 255, green: 222 / 255, blue: 204 / 255).opacity(0.42), brick: true)
    /// Honey Bath stone for the grander buildings (the hotels, the bank).
    static let bathStone = Tuff(lit: "#ecd39c", shade: "#b8955e", top: "#e0c896",
                                line: Color(red: 110 / 255, green: 80 / 255, blue: 40 / 255).opacity(0.13))
    /// Welsh slate.
    static let slate = "#5e6874"

    var bristol: Bool { s.region == .bri }
    /// How dark the night is (0 by day), for the lit phone boxes and fanlights.
    var nightK: Double { night?.k ?? 0 }

    // MARK: Brick

    /// Brick courses: short rows, a few bricks a shade darker or lighter, pale mortar.
    mutating func brickCourses(_ w: GraphicsContext, _ p: CGPoint, _ q: CGPoint, _ h: CGFloat, seed: Double, mortar: Bool) {
        let len = hypot(q.x - p.x, q.y - p.y)
        guard len > 1 else { return }
        var R = rng(seed)
        let ch: CGFloat = 5.5, bw: CGFloat = 12, step = bw / len
        var dark = Path(), light = Path()
        var y: CGFloat = 0, row = 0
        while y < h {
            var u = CGFloat(row % 2) * 0.5 * step - step
            while u < 1 {
                let r = R.next()
                if r <= 0.28 {
                    let a = lp(p, q, max(0, u)), b2 = lp(p, q, min(1, u + step))
                    let quad = path([pt(a.x, a.y - y), pt(b2.x, b2.y - y), pt(b2.x, b2.y - y - ch), pt(a.x, a.y - y - ch)])
                    if r < 0.14 { dark.addPath(quad) } else { light.addPath(quad) }
                }
                u += step
            }
            y += ch; row += 1
        }
        w.fill(dark, with: .color(rgba(60, 15, 8, 0.16)))
        w.fill(light, with: .color(rgba(255, 200, 170, 0.13)))
        guard mortar else { return }
        var lines = Path()
        y = ch; row = 0
        while y < h {
            lines.move(to: pt(p.x, p.y - y)); lines.addLine(to: pt(q.x, q.y - y))
            var u = CGFloat(row % 2) * 0.5 * step
            while u < 1 {
                let a = lp(p, q, u)
                lines.move(to: pt(a.x, a.y - y)); lines.addLine(to: pt(a.x, a.y - y + ch))
                u += step
            }
            y += ch; row += 1
        }
        w.stroke(lines, with: .color(tuff.line), lineWidth: 0.8)
    }

    // MARK: Windows and doors

    /// White-framed sash windows under a stone lintel; doors painted, each house its own colour, under a fanlight.
    mutating func bristolOpening(_ p: CGPoint, _ q: CGPoint, _ h: CGFloat, _ u: CGFloat, _ v: CGFloat, _ w: CGFloat, _ hh: CGFloat,
                                 door: Bool, lit: Bool) {
        let f = face(p, q, h)
        let x0 = u - w / 2, fr = min(w, hh) * 0.14
        func box(_ x: CGFloat, _ y: CGFloat, _ bw: CGFloat, _ bh: CGFloat, _ col: Color) { f.fill(Path(CGRect(x: x, y: y, width: bw, height: bh)), with: .color(col)) }
        if door {
            let cols = ["#1f4a7a", "#2e6a3e", "#a8232c", "#e0a020", "#3a3a44"]
            let pick = Int((abs(sin(Double(u) * 91.7 + Double(v) * 13.1 + Double(p.x) * 0.37)) * 5).rounded(.down)) % 5
            box(x0 - fr, v, w + fr * 2, hh + fr, hex("#f4efe4"))
            box(x0, v, w, hh * 0.82, hex(cols[pick]))
            box(x0, v + hh * 0.86, w, hh * 0.12, hex(lit || nightK > 0 ? "#ffd27a" : "#cfe0e8"))
            box(x0 + w * 0.12, v + hh * 0.1, w * 0.32, hh * 0.62, rgba(0, 0, 0, 0.18))
            box(x0 + w * 0.56, v + hh * 0.1, w * 0.32, hh * 0.62, rgba(0, 0, 0, 0.18))
            box(x0 + w * 0.78, v + hh * 0.38, w * 0.08, hh * 0.06, hex("#d8b040"))
            return
        }
        box(x0 - fr * 1.4, v + hh, w + fr * 2.8, fr * 1.6, hex("#d8c8a8")) // stone lintel
        box(x0 - fr, v - fr, w + fr * 2, fr, hex("#d8c8a8")) // sill
        box(x0, v, w, hh, hex("#f6f2ea"))
        box(x0 + fr, v + fr, w - fr * 2, hh - fr * 2, hex(lit ? "#ffd27a" : "#3b4656"))
        if !lit { box(x0 + fr, v + hh * 0.55, (w - fr * 2) * 0.5, hh * 0.4 - fr, rgba(180, 210, 230, 0.28)) }
        box(x0, v + hh * 0.48, w, fr * 0.9, hex("#f6f2ea"))
        box(u - fr * 0.35, v, fr * 0.7, hh, hex("#f6f2ea"))
        if lit {
            let m = lp(p, q, u)
            glow(m.x, m.y - h * (v + hh / 2), 24, Color(red: 1, green: 190 / 255, blue: 90 / 255), 0.16)
        }
    }

    // MARK: The Tudor pub

    /// The bazaar is the old harbour pub: whitewashed walls under black oak beams with braces, small leaded windows, a
    /// dark door, a slate gable roof and a chimney.
    mutating func tudorPub(_ b: TownBuilding) {
        let x0 = b.gx + 0.1, y0 = b.gy + 0.1, w = b.w - 0.2, d = b.d - 0.2, hh: CGFloat = 46
        let f = block(x0, y0, w, d, hh, lit: "#f3ede0", shade: "#cdc4b2", top: "#e8e0cc", courses: false)
        let beam = hex("#2a201a")
        for (p, q) in [(f.D, f.C), (f.C, f.B)] {
            let fc = face(p, q, hh)
            var beams = Path()
            beams.addRect(CGRect(x: 0, y: 0, width: 1, height: 0.07))
            beams.addRect(CGRect(x: 0, y: 0.46, width: 1, height: 0.06))
            beams.addRect(CGRect(x: 0, y: 0.93, width: 1, height: 0.07))
            for i in 0...5 { beams.addRect(CGRect(x: min(0.955, CGFloat(i) * 0.19), y: 0, width: 0.045, height: 1)) }
            fc.fill(beams, with: .color(beam))
            var braces = Path()
            for i in stride(from: 0, to: 5, by: 2) {
                let k = CGFloat(i) * 0.19
                braces.move(to: pt(k + 0.04, 0.52)); braces.addLine(to: pt(k + 0.19, 0.93))
                braces.move(to: pt(k + 0.19 + 0.04, 0.07)); braces.addLine(to: pt(k + 0.04 + 0.19 * 2 - 0.04, 0.46))
            }
            fc.stroke(braces, with: .color(beam), lineWidth: 0.035)
        }
        func win(_ p: CGPoint, _ q: CGPoint, _ u: CGFloat, _ v: CGFloat, _ lit: Bool) {
            let fc = face(p, q, hh)
            fc.fill(Path(CGRect(x: u - 0.09, y: v - 0.03, width: 0.18, height: 0.26)), with: .color(beam))
            fc.fill(Path(CGRect(x: u - 0.07, y: v, width: 0.14, height: 0.2)), with: .color(hex(lit || nightK > 0 ? "#ffcf6a" : "#5a6878")))
            var lead = Path()
            for i in 1..<4 { lead.move(to: pt(u - 0.07 + CGFloat(i) * 0.035, v)); lead.addLine(to: pt(u - 0.07 + CGFloat(i) * 0.035, v + 0.2)) }
            fc.stroke(lead, with: .color(rgba(40, 30, 20, 0.6)), lineWidth: 0.01)
        }
        win(f.D, f.C, 0.28, 0.6, false); win(f.D, f.C, 0.72, 0.6, true)
        win(f.C, f.B, 0.3, 0.6, true); win(f.C, f.B, 0.7, 0.6, false); win(f.C, f.B, 0.5, 0.14, true)
        let door = face(f.D, f.C, hh)
        door.fill(Path(CGRect(x: 0.4, y: 0, width: 0.2, height: 0.4)), with: .color(beam))
        door.fill(Path(CGRect(x: 0.43, y: 0, width: 0.14, height: 0.36)), with: .color(hex("#4a2a1a")))
        door.fill(Path(CGRect(x: 0.53, y: 0.17, width: 0.02, height: 0.03)), with: .color(hex("#d8b040")))
        gableRoof(x0, y0, w, d, hh, 30, Self.slate, eave: 0.12)
        // a chimney
        let ch = iso(x0 + w * 0.8, y0 + d * 0.5)
        rect(ch.x - 4, ch.y - hh - 40, 8, 18, hex("#8e4636"))
        rect(ch.x - 5, ch.y - hh - 42, 10, 3, hex("#5a2a20"))
    }

    // MARK: Hotels

    /// Pastel Clifton houses where Cappadocia has its cave suites (the cave hotel), with a slate roof and a chimney.
    mutating func pastelHouse(_ p: CGPoint, _ hh: CGFloat, _ gx: Double) {
        let pc = ["#f2b8c0", "#a8d4c8", "#f4dc8a"][Int((gx * 7).rounded()) % 3], ph = hh * 0.62
        rect(p.x - hh * 0.2, p.y - ph, hh * 0.4, ph, hex(pc))
        rect(p.x + hh * 0.1, p.y - ph, hh * 0.1, ph, mix(pc, "#000000", 0.15))
        poly([pt(p.x - hh * 0.23, p.y - ph), pt(p.x - hh * 0.12, p.y - ph - hh * 0.14), pt(p.x + hh * 0.12, p.y - ph - hh * 0.14), pt(p.x + hh * 0.23, p.y - ph)],
             hex(snowy(Self.slate)))
        rect(p.x + hh * 0.06, p.y - ph - hh * 0.2, hh * 0.06, hh * 0.1, hex("#8a5a44"))
    }

    // MARK: Trees, animals, street furniture

    mutating func copperBeech(_ x: CGFloat, _ y: CGFloat, _ k: CGFloat = 1) {
        roundTree(x, y, k * 1.05, "#7a2a3a")
        ellipse(x + 6 * k, y - 22 * k, 9 * k, 8 * k, rgba(150, 60, 70, 0.45))
    }

    mutating func oakTree(_ x: CGFloat, _ y: CGFloat, _ k: CGFloat = 1) {
        rect(x - 2.5 * k, y - 18 * k, 5 * k, 18 * k, hex("#4a3420"))
        for (dx, dy, r, col) in [(-9, -24, 12, "#3e6a2c"), (9, -26, 12, "#4a7a34"), (0, -34, 14, "#5a8a3e"), (-2, -24, 11, "#467a32")] as [(CGFloat, CGFloat, CGFloat, String)] {
            ellipse(x + dx * k, y + dy * k, r * k, r * 0.85 * k, hex(col))
        }
    }

    mutating func phoneBox(_ x: CGFloat, _ y: CGFloat) {
        rect(x - 6, y - 34, 12, 34, hex("#b8141c"))
        rect(x + 2, y - 34, 4, 34, hex("#8a0c12"))
        var top = Path()
        top.move(to: pt(x - 7, y - 34)); top.addQuadCurve(to: pt(x + 7, y - 34), control: pt(x, y - 40)); top.closeSubpath()
        c.fill(top, with: .color(hex("#8a0c12")))
        rect(x - 5, y - 32, 7, 2.5, hex("#f4f0e0"))
        for r in 0..<3 { rect(x - 4.5, y - 27 + CGFloat(r) * 7, 6, 5.5, hex(nightK > 0 ? "#ffe08a" : "#cfe0e8")) }
    }

    mutating func pillarBox(_ x: CGFloat, _ y: CGFloat) {
        rect(x - 4, y - 16, 8, 16, hex("#c0181e"))
        var g = c
        g.translateBy(x: x, y: y - 16)
        g.scaleBy(x: 1, y: 2.4 / 4.6)
        g.fill(Path { p in p.addArc(center: .zero, radius: 4.6, startAngle: .radians(.pi), endAngle: .radians(0), clockwise: false) }, with: .color(hex("#c0181e")))
        rect(x + 1.5, y - 16, 2.5, 16, hex("#8a0c12"))
        rect(x - 3, y - 12, 5, 1.2, hex("#1a1010"))
        rect(x - 4.5, y - 1.5, 9, 1.5, hex("#2a1a1a"))
    }

    /// A red double-decker going along a road; `onX`: along gx.
    mutating func decker(_ gx: Double, _ gy: Double, onX: Bool) {
        let w = onX ? 1.05 : 0.42, d = onX ? 0.42 : 1.05, H: CGFloat = 36
        let f = block(gx - w / 2, gy - d / 2, w, d, H, lit: "#c8202a", shade: "#8e1218", top: "#b81c24", courses: false)
        for (p, q) in [(f.D, f.C), (f.C, f.B)] {
            let fc = face(p, q, H)
            var wins = Path()
            for r in 0..<2 { for i in 0..<4 { wins.addRect(CGRect(x: 0.06 + CGFloat(i) * 0.235, y: 0.14 + CGFloat(r) * 0.44, width: 0.18, height: 0.26)) } }
            fc.fill(wins, with: .color(hex("#2a3440")))
            fc.fill(Path(CGRect(x: 0, y: 0.5, width: 1, height: 0.05)), with: .color(hex("#f4f0e0")))
        }
    }

    /// The pub's hanging sign: a post, an arm, and a swinging board with a balloon in your colours.
    mutating func pubSign(_ x: CGFloat, _ y: CGFloat) {
        rect(x - 1.5, y - 52, 3, 52, hex("#2a1e14"))
        rect(x - 1.5, y - 52, 20, 2.5, hex("#2a1e14"))
        var g = c
        g.translateBy(x: x + 14, y: y - 50)
        g.rotate(by: .radians(sin(t * 1.4) * 0.08))
        var chains = Path()
        chains.move(to: pt(-5, 0)); chains.addLine(to: pt(-5, 5)); chains.move(to: pt(5, 0)); chains.addLine(to: pt(5, 5))
        g.stroke(chains, with: .color(hex("#2a1e14")), lineWidth: 1)
        g.fill(Path(CGRect(x: -9, y: 5, width: 18, height: 22)), with: .color(hex("#1e3a2a")))
        g.stroke(Path(CGRect(x: -8, y: 6, width: 16, height: 20)), with: .color(hex("#c9a040")), lineWidth: 1.2)
        var bal = Path()
        bal.addArc(center: pt(0, 13), radius: 5, startAngle: .radians(.pi), endAngle: .radians(0), clockwise: false)
        bal.addQuadCurve(to: pt(1.5, 21), control: pt(5, 18))
        bal.addLine(to: pt(-1.5, 21))
        bal.addQuadCurve(to: pt(-5, 13), control: pt(-5, 18))
        bal.closeSubpath()
        g.fill(bal, with: .color(hex(s.colors.first ?? "#ff5e3a")))
        g.fill(Path(CGRect(x: -1.5, y: 22, width: 3, height: 2.5)), with: .color(hex("#6b4426")))
    }

    mutating func sheepFlock(_ x: CGFloat, _ y: CGFloat, _ n: Int, _ tt: Double) {
        for i in 0..<n {
            let sx = x + CGFloat(i % 3) * 13 - 13 + (i > 2 ? 6 : 0), sy = y + CGFloat(i / 3) * 7, b = CGFloat(sin(tt * 1.3 + Double(i))) * 0.5
            ellipse(sx, sy - 5 + b, 6, 4, hex("#f4f0e6"))
            ellipse(sx + 5, sy - 6 + b, 2.4, 2, hex("#2a2420"))
            rect(sx - 3, sy - 2, 1.2, 3, hex("#2a2420"))
            rect(sx + 2, sy - 2, 1.2, 3, hex("#2a2420"))
        }
    }

    mutating func hedge(_ x: CGFloat, _ y: CGFloat, _ len: CGFloat) {
        var i: CGFloat = 0
        while i <= len {
            ellipse(x + i, y - 5 - CGFloat(sin(Double(i))) * 1.5, 6, 5, hex(Int(i) % 16 != 0 ? "#2e5a24" : "#3a6a2c"))
            i += 8
        }
    }

    mutating func tallShip(_ x: CGFloat, _ y0: CGFloat) {
        let y = y0 + CGFloat(sin(t * 0.8)) * 1.5
        poly([pt(x - 60, y - 14), pt(x + 66, y - 18), pt(x + 50, y), pt(x - 50, y)], hex("#1e1a1a"))
        rect(x - 58, y - 13, 118, 2, hex("#c8a050"))
        var masts = Path(), yards = Path()
        for (dx, hh) in [(-30, 80), (4, 96), (36, 74)] as [(CGFloat, CGFloat)] {
            masts.move(to: pt(x + dx, y - 14)); masts.addLine(to: pt(x + dx, y - 14 - hh))
            for k in 1...3 {
                let yy = y - 14 - hh * CGFloat(k) / 3.6, yw = 16 - CGFloat(k) * 3
                yards.move(to: pt(x + dx - yw, yy)); yards.addLine(to: pt(x + dx + yw, yy))
            }
        }
        c.stroke(masts, with: .color(hex("#2a2018")), lineWidth: 2.4)
        c.stroke(yards, with: .color(hex("#2a2018")), lineWidth: 1.6)
        var rig = Path()
        rig.move(to: pt(x - 60, y - 14)); rig.addLine(to: pt(x - 30, y - 94)); rig.addLine(to: pt(x + 4, y - 110))
        rig.addLine(to: pt(x + 36, y - 88)); rig.addLine(to: pt(x + 80, y - 20))
        c.stroke(rig, with: .color(hex("#2a2018")), lineWidth: 0.7)
    }

    mutating func gulls(_ cx: CGFloat, _ cy: CGFloat) {
        var p = Path()
        for i in 0..<6 {
            let fi = Double(i)
            let x = cx + CGFloat(sin(t * 0.2 + fi * 1.3)) * 260 + CGFloat(i) * 30, y = cy + CGFloat(cos(t * 0.27 + fi)) * 60 + CGFloat(i) * 12
            let w = CGFloat(sin(t * 6 + fi)) * 4
            p.move(to: pt(x - 8, y - w))
            p.addQuadCurve(to: pt(x, y), control: pt(x - 4, y - 4 - w * 0.3))
            p.addQuadCurve(to: pt(x + 8, y - w), control: pt(x + 4, y - 4 - w * 0.3))
        }
        c.stroke(p, with: .color(rgba(250, 250, 246, 0.95)), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
    }

    /// Phone boxes, pillar boxes, the pub sign, a bus on each main road, gulls over the town.
    func bristolScenery() -> [TownItem] {
        var items: [TownItem] = []
        for (gx, gy) in [(7.32, 2.6), (8.7, 11.1), (3.2, 7.32)] {
            items.append(TownItem(depth: gx + gy, shadow: { p in let q = TownGeo.iso(gx, gy); p.blobShadow(q.x + 8, q.y + 2, 9, 3, 0.18) },
                                  draw: { p in let q = TownGeo.iso(gx, gy); p.phoneBox(q.x, q.y) }))
        }
        for (gx, gy) in [(7.3, 10.6), (11.6, 7.3), (8.7, 4.4)] {
            items.append(TownItem(depth: gx + gy, draw: { p in let q = TownGeo.iso(gx, gy); p.pillarBox(q.x, q.y) }))
        }
        items.append(TownItem(depth: 13.7 + 4.65, draw: { p in let q = TownGeo.iso(13.7, 4.65); p.pubSign(q.x, q.y) }))
        // a bus on each road, slowly; they go round the square and the one along gy gives way (`BristolBus`)
        for onX in [true, false] {
            let (bx, by) = BristolBus.at(t, onX: onX)
            items.append(TownItem(depth: bx + by + 0.6, draw: { p in p.decker(bx, by, onX: onX) }))
        }
        let k = nightK
        if k < 0.3 {
            items.append(TownItem(depth: 99, draw: { p in
                let q = TownGeo.iso(7.5, 6), keep = p.c
                p.c.opacity = 1 - k / 0.3
                p.gulls(q.x, q.y - 330)
                p.c = keep
            }))
        }
        return items
    }

    // MARK: Land

    /// What stands on the town's edges in Bristol: copper beeches and oaks, sheep behind a hedge.
    mutating func bristolEdge(_ x: CGFloat, _ y: CGFloat, _ seed: Double) {
        switch Int((seed * 10).rounded()) % 3 {
        case 0: copperBeech(x - 14, y, 1.3); oakTree(x + 16, y + 6, 1.2)
        case 1: hedge(x - 30, y + 2, 60); sheepFlock(x, y - 2, 5, t)
        default: oakTree(x, y, 1.4); copperBeech(x + 22, y + 8, 1)
        }
    }

    /// Out in the land: oaks and copper beeches, sheep behind hedges, now and then a church.
    mutating func bristolOuter(_ x: CGFloat, _ y: CGFloat, _ hh: CGFloat, _ i: Int) {
        if i % 5 == 0 {
            rect(x - 16, y - hh * 0.3, 26, hh * 0.3, hex("#cdb07a"))
            rect(x + 10, y - hh * 0.5, 12, hh * 0.5, hex("#a88a5a"))
            poly([pt(x + 9, y - hh * 0.5), pt(x + 16, y - hh * 0.85), pt(x + 23, y - hh * 0.5)], hex(Self.slate))
            poly([pt(x - 18, y - hh * 0.3), pt(x - 3, y - hh * 0.42), pt(x + 12, y - hh * 0.3)], hex(Self.slate))
            return
        }
        if i % 5 == 2 { hedge(x - 34, y + 4, 68); sheepFlock(x, y, 4 + i % 3, t + Double(i)); return }
        if i % 2 == 1 { oakTree(x, y, 1 + CGFloat(i % 3) * 0.2); oakTree(x + 22, y + 8, 0.9); return }
        copperBeech(x, y, 1.1)
    }

    /// The harbour behind the town: the quay, the water, the old tall ship and two dock cranes.
    mutating func bristolHarbour() {
        func band(_ y0: Double, _ y1: Double) -> [CGPoint] { [iso(-60, y0), iso(70, y0), iso(70, y1), iso(-60, y1)] }
        poly(band(-15.8, -9.2), hex("#b8a888"))
        poly(band(-14.6, -10.4), hex("#5f8494"))
        poly(band(-13.1, -12.7), Color.white.opacity(0.16))
        let sp = iso(2, -10.9)
        tallShip(sp.x, sp.y)
        var cranes = Path(), cables = Path()
        for (cx, cy) in [(9.0, -10.2), (12.0, -10.2)] {
            let p = iso(cx, cy)
            cranes.move(to: pt(p.x - 8, p.y)); cranes.addLine(to: pt(p.x, p.y - 90)); cranes.addLine(to: pt(p.x + 8, p.y))
            cranes.move(to: pt(p.x, p.y - 86)); cranes.addLine(to: pt(p.x - 70, p.y - 76))
            cables.move(to: pt(p.x - 60, p.y - 77)); cables.addLine(to: pt(p.x - 60, p.y - 40))
        }
        c.stroke(cranes, with: .color(hex("#c0582a")), lineWidth: 3)
        c.stroke(cables, with: .color(hex("#c0582a")), lineWidth: 1)
    }

    /// Puddles on the cobbles, a few per road.
    mutating func puddles(_ gx0: Double, _ gy0: Double, _ gx1: Double, _ gy1: Double, _ inner: GraphicsContext) {
        var R = rng(gx0 * 13 + gy0 * 7 + 5)
        var water = Path(), shine = Path()
        for _ in 0..<3 {
            let p = iso(gx0 + (gx1 - gx0) * (0.2 + R.next() * 0.6), gy0 + (gy1 - gy0) * (0.2 + R.next() * 0.6)), rx = 14 + CGFloat(R.next()) * 10
            water.addEllipse(in: CGRect(x: p.x - rx, y: p.y - 5, width: rx * 2, height: 10))
            shine.addEllipse(in: CGRect(x: p.x - 10, y: p.y - 2.4, width: 12, height: 2.8))
        }
        inner.fill(water, with: .color(rgba(150, 175, 195, 0.75)))
        inner.fill(shine, with: .color(Color.white.opacity(0.45)))
    }

    // MARK: Sky

    /// The overcast English sky: pale blue-grey, a pale sun behind the clouds, grey cloud banks.
    mutating func bristolSky(_ w: CGFloat, _ h: CGFloat, _ hz: CGFloat, _ px: CGFloat) {
        let sky = grad([(hex("#6a7c94"), 0), (hex("#a8b6c4"), 0.5), (hex("#dcd8d0"), 1)])
        c.fill(Path(CGRect(x: 0, y: 0, width: w, height: hz + 2)), with: .linearGradient(sky, startPoint: .zero, endPoint: pt(0, hz)))
        let sx = w * 0.74 + px, sy = hz - h * 0.045, sr = min(w, h) * 0.055
        if night == nil {
            var sunC = c
            sunC.opacity = 0.45
            let sun = grad([(rgba(255, 225, 160, 0.65), 0), (rgba(255, 170, 110, 0.25), 0.35), (rgba(255, 160, 110, 0), 1)])
            sunC.fill(Path(CGRect(x: sx - sr * 7, y: sy - sr * 7, width: sr * 14, height: sr * 14)),
                      with: .radialGradient(sun, center: pt(sx, sy), startRadius: 0, endRadius: sr * 7))
            sunC.fill(Path(ellipseIn: CGRect(x: sx - sr, y: sy - sr, width: sr * 2, height: sr * 2)), with: .color(hex("#fff0c8")))
            var cl = c
            cl.opacity = 0.55
            for i in 0..<5 {
                let cw = w * (0.4 + 0.12 * CGFloat(i % 2))
                let cx = CGFloat(pmod(Double(CGFloat(i) * w * 0.29) + t * Double(2 + i) + Double(px) * 0.5, Double(w + cw))) - cw * 0.5
                let cy = hz * (0.12 + CGFloat(i) * 0.15), rh = h * 0.02 + 4, rh2 = h * 0.016 + 3
                cl.fill(Path(ellipseIn: CGRect(x: cx - cw * 0.5, y: cy - rh, width: cw, height: rh * 2)), with: .color(hex("#c8ced6")))
                cl.fill(Path(ellipseIn: CGRect(x: cx + cw * 0.15 - cw * 0.3, y: cy - h * 0.012 - rh2, width: cw * 0.6, height: rh2 * 2)), with: .color(hex("#dfe3e8")))
            }
        }
    }
}

/// v125.x: Bristol's buses go round the square at the crossing instead of over its fountain: each swings out to its own
/// side (the paved square is wider than the roads) and back into its lane. The bus along gy gives way: it waits at its
/// stop line while the one along gx goes round, then follows. Both run on the same 32 s cycle, so their footprints never
/// touch each other or the fountain (prototype `BUS`, `busAt`).
enum BristolBus {
    /// Cycle (s), speed (tiles/s), the gy bus's stop line (path length), its wait and its offset (s).
    static let period = 32.0, speed = 0.75, stop = 7.4, wait = 4.2, lag = 0.6
    static let pathX: [(Double, Double)] = [(-1, 7.75), (6.8, 7.75), (7.45, 7.33), (8.55, 7.33), (9.2, 7.75), (16, 7.75)]
    static let pathY: [(Double, Double)] = [(8.25, -1), (8.25, 6.8), (8.67, 7.45), (8.67, 8.55), (8.25, 9.2), (8.25, 16)]
    /// The paved square both buses stay on while they go round.
    static let square = (7.08, 8.92)

    static func along(_ p: [(Double, Double)], _ s0: Double) -> (Double, Double) {
        var s = s0
        for i in 1..<p.count {
            let l = hypot(p[i].0 - p[i - 1].0, p[i].1 - p[i - 1].1)
            if s <= l || i == p.count - 1 {
                let f = min(max(s / l, 0), 1)
                return (p[i - 1].0 + (p[i].0 - p[i - 1].0) * f, p[i - 1].1 + (p[i].1 - p[i - 1].1) * f)
            }
            s -= l
        }
        return p[p.count - 1]
    }

    /// Where a bus is at time `t`; past the end of its road it waits outside town until its next run.
    static func at(_ t: Double, onX: Bool) -> (Double, Double) {
        func pmod(_ a: Double, _ m: Double) -> Double { (a.truncatingRemainder(dividingBy: m) + m).truncatingRemainder(dividingBy: m) }
        if onX { return along(pathX, pmod(t, period) * speed) }
        let u = pmod(t - lag, period), s = u * speed
        return along(pathY, s < stop ? s : u < stop / speed + wait ? stop : (u - wait) * speed)
    }
}
