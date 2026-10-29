import SwiftUI
import BalloonBaronCore

/// v124: Bristol in flight (prototype `briFar`, `briGround`, `briDraw`, `briObstacle`, `briOverlay`): rolling green hills
/// with spires and terraces in the haze, hedgerowed fields and the tidal river, the Avon Gorge with its suspension
/// bridge, the harbour's water, tall ship and cranes, fields with sheep or cows, tidal mud, gulls; over everything the
/// morning fog and the airport's airspace.
enum BristolPainter {
    private static func mix(_ a: String, _ b: String, _ k: Double) -> Color { ScenePainter.mix(a, b, k) }
    private static func ell(_ ctx: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ c: Color) {
        ScenePainter.ell(&ctx, x, y, rx, ry, c)
    }
    private static func rect(_ ctx: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ c: Color) {
        ScenePainter.rect(&ctx, x, y, w, h, c)
    }
    private static func line(_ ctx: inout GraphicsContext, _ pts: [(CGFloat, CGFloat)], _ c: Color, _ w: CGFloat) {
        guard let first = pts.first else { return }
        var p = Path()
        p.move(to: CGPoint(x: first.0, y: first.1))
        for q in pts.dropFirst() { p.addLine(to: CGPoint(x: q.0, y: q.1)) }
        ctx.stroke(p, with: .color(c), style: StrokeStyle(lineWidth: w, lineCap: .round))
    }

    // MARK: Sky and land

    /// Sky stops: an overcast English morning.
    static func sky(_ p: Double) -> Gradient {
        Gradient(stops: [.init(color: mix("#28324a", "#8ea4ba", p), location: 0), .init(color: mix("#5a6076", "#c6d0d8", p), location: 0.55),
                         .init(color: mix("#a88a84", "#e6eae6", p), location: 1)])
    }
    static let horizon = ("#a88a84", "#e6eae6")

    /// The Mendips, soft and green, behind the nearer ridge.
    static func mendips(_ ctx: inout GraphicsContext, cam: SceneCamera, p: Double) {
        let W = cam.size.width, gy = cam.groundY, vh = cam.viewHeight
        var m = Path()
        m.move(to: CGPoint(x: -20, y: gy))
        var x: CGFloat = -20
        while x <= W + 40 {
            let wx = Double(x / cam.kx + CGFloat(cam.camX) * 0.08) * 0.004
            m.addLine(to: CGPoint(x: x, y: gy - vh * CGFloat(0.12 + 0.04 * sin(wx * 2.1 + 0.5) + 0.02 * sin(wx * 5.3))))
            x += 16
        }
        m.addLine(to: CGPoint(x: W + 40, y: gy))
        m.closeSubpath()
        ctx.fill(m, with: .color(mix("#2e3a3a", "#8aa08a", p)))
    }

    /// The nearer ridge: rolling, not peaked.
    static func ridge(_ ctx: inout GraphicsContext, cam: SceneCamera, p: Double) {
        let W = cam.size.width, gy = cam.groundY, vh = cam.viewHeight
        var r = Path()
        r.move(to: CGPoint(x: 0, y: gy))
        var x: CGFloat = -20
        while x <= W + 40 {
            let wx = Double(x / cam.kx + CGFloat(cam.camX) * 0.15) * 0.01
            r.addLine(to: CGPoint(x: x, y: gy - vh * CGFloat(0.085 + 0.03 * sin(wx * 0.8) + 0.012 * sin(wx * 2.1))))
            x += 12
        }
        r.addLine(to: CGPoint(x: W, y: gy))
        r.closeSubpath()
        ctx.fill(r, with: .color(mix("#2e3a2a", "#7a9a62", p)))
    }

    /// `briFar`: far scenery in the haze: a spire, a Georgian terrace, otherwise round trees.
    static func far(_ ctx: inout GraphicsContext, x: CGFloat, base: CGFloat, hh: CGFloat, ww: CGFloat, i: Int, col: Color) {
        if i % 6 == 1 {
            var s = Path(CGRect(x: x - ww * 0.5, y: base - hh * 0.45, width: ww, height: hh * 0.45))
            s.move(to: CGPoint(x: x - ww * 0.18, y: base - hh * 0.45))
            s.addLine(to: CGPoint(x: x, y: base - hh * 1.25))
            s.addLine(to: CGPoint(x: x + ww * 0.18, y: base - hh * 0.45))
            s.closeSubpath()
            ctx.fill(s, with: .color(col))
        } else if i % 6 == 4 {
            var t = Path()
            t.move(to: CGPoint(x: x - ww * 1.4, y: base))
            t.addLine(to: CGPoint(x: x - ww * 1.4, y: base - hh * 0.4))
            for k in 0..<6 {
                let a = x - ww * 1.4 + CGFloat(k) * ww * 0.47
                t.addLine(to: CGPoint(x: a, y: base - hh * 0.48))
                t.addLine(to: CGPoint(x: a + ww * 0.24, y: base - hh * 0.4))
            }
            t.addLine(to: CGPoint(x: x + ww * 1.4, y: base - hh * 0.4))
            t.addLine(to: CGPoint(x: x + ww * 1.4, y: base))
            t.closeSubpath()
            ctx.fill(t, with: .color(col))
        } else {
            ell(&ctx, x, base - hh * 0.35, ww * 0.6, hh * 0.32, col)
            ell(&ctx, x - ww * 0.3, base - hh * 0.22, ww * 0.4, hh * 0.22, col)
        }
    }

    /// Ground gradient: green fields.
    static func ground(_ p: Double) -> Gradient { Gradient(colors: [mix("#2a4220", "#7aa84a", p), mix("#1a2c14", "#4a7430", p)]) }

    /// `briGround`: fields in three greens divided by hedgerows, the tidal river with its mud bank.
    static func fields(_ ctx: inout GraphicsContext, cam: SceneCamera, p: Double) {
        let W = cam.size.width, H = cam.size.height, gy = cam.groundY, gh = H - gy, kx = cam.kx, camX = cam.camX
        let span = 150 * kx, off = CGFloat(ScenePainter.pmod(-camX * Double(kx) * 0.9, Double(span))) - span
        let shift = Int((camX * Double(kx) * 0.9 / Double(span)).rounded(.down))
        var x = off, i = 0
        let hedge = mix("#14240e", "#3e6a2a", p)
        while x < W + span {
            let k = i + shift, alt = ((k % 3) + 3) % 3
            let col = alt == 0 ? mix("#2a4420", "#86b452", p) : alt == 1 ? mix("#26401e", "#6e9e44", p) : mix("#2e4824", "#9ab85e", p)
            var f = Path()
            f.move(to: CGPoint(x: x, y: gy + 3))
            f.addLine(to: CGPoint(x: x + span, y: gy + 3))
            f.addLine(to: CGPoint(x: x + span * 1.25, y: gy + gh * 0.5))
            f.addLine(to: CGPoint(x: x + span * 0.25, y: gy + gh * 0.5))
            f.closeSubpath()
            ctx.fill(f, with: .color(col))
            line(&ctx, [(x, gy + 3), (x + span * 0.25, gy + gh * 0.5)], hedge, 3)
            x += span
            i += 1
        }
        // a hedgerow along the near side of the fields, bumpy
        let hc = mix("#16260f", "#3e6a2a", p)
        var hx = CGFloat(ScenePainter.pmod(-camX * Double(kx), 14)) - 14
        var bumps = Path()
        while hx < W + 14 {
            bumps.addEllipse(in: CGRect(x: hx - 9, y: gy + gh * 0.5 - 4.5, width: 18, height: 9))
            hx += 14
        }
        ctx.fill(bumps, with: .color(hc))
        // the tidal river further in front: a brown bank, grey water
        let ry = gy + gh * 0.66, rh = max(5, gh * 0.12)
        rect(&ctx, 0, ry - 3, W, rh + 6, mix("#3a3024", "#8a7454", p))
        rect(&ctx, 0, ry, W, rh, mix("#2a3a48", "#7f98a8", p))
        var glints = Path()
        for g in 0..<10 {
            let gx = CGFloat(ScenePainter.pmod(Double(g) * 151 - camX * Double(kx) * 0.7, Double(W + 60))) - 30
            glints.addRect(CGRect(x: gx, y: ry + rh * (0.3 + CGFloat(g % 3) * 0.2), width: 16, height: 1.5))
        }
        ctx.fill(glints, with: .color(Color.white.opacity(0.2)))
    }

    // MARK: World-space landmarks

    /// `briDraw`: harbour water and mud, the fenced fields with their animals, the gorge and its bridge, gulls.
    static func world(_ ctx: inout GraphicsContext, cam: SceneCamera, _ B: BristolWorld, p: Double, time T: Double) {
        let W = cam.size.width, gy = cam.groundY
        for s in B.water {
            let X0 = cam.sx(s.x0), X1 = cam.sx(s.x1)
            if X1 < -20 || X0 > W + 20 { continue }
            rect(&ctx, X0, gy - 1, X1 - X0, 8, mix("#2a3e50", "#6a90a8", p))
            var gl = Path()
            var x = X0 + 6
            while x < X1 { gl.addRect(CGRect(x: x, y: gy + 2, width: 10, height: 1.4)); x += 22 }
            ctx.fill(gl, with: .color(Color.white.opacity(0.25)))
            rect(&ctx, X1, gy - 4, 8, 6, mix("#5a4a3a", "#a8987a", p)) // the quay
        }
        for z in B.muds {
            let X0 = cam.sx(z.x0), X1 = cam.sx(z.x1)
            if X1 < -20 || X0 > W + 20 { continue }
            let mx = (X0 + X1) / 2
            ell(&ctx, mx, gy + 1, (X1 - X0) / 2, 5, mix("#3a2e20", "#8a6e48", p))
            ell(&ctx, mx, gy + 1.5, (X1 - X0) * 0.3, 2, mix("#2a3a48", "#8aa4b4", p))
            rect(&ctx, mx - 8, gy, 6, 1, Color.white.opacity(0.35))
        }
        // fields with animals behind a fence
        for z in B.pens {
            let X0 = cam.sx(z.x0), X1 = cam.sx(z.x1)
            if X1 < -20 || X0 > W + 20 { continue }
            var fence = Path()
            fence.move(to: CGPoint(x: X0, y: gy - 5)); fence.addLine(to: CGPoint(x: X1, y: gy - 5))
            fence.move(to: CGPoint(x: X0, y: gy - 2.5)); fence.addLine(to: CGPoint(x: X1, y: gy - 2.5))
            var px = X0
            while px <= X1 { fence.move(to: CGPoint(x: px, y: gy)); fence.addLine(to: CGPoint(x: px, y: gy - 7)); px += 14 }
            ctx.stroke(fence, with: .color(mix("#3a2a1a", "#8a6a44", p)), lineWidth: 1.2)
            var r = Mulberry32(seed: UInt32(z.seed * 1000))
            let dark = Color(hex: "#2a2420")
            for i in 0..<z.count {
                let x = X0 + 10 + CGFloat(r.next()) * (X1 - X0 - 20), y = gy - 1 + CGFloat(r.next()) * 3, d: CGFloat = r.next() < 0.5 ? -1 : 1
                let bob = CGFloat(sin(T * 1.5 + Double(i))) * 0.4
                if z.animal == .sheep {
                    ell(&ctx, x, y - 3.5 + bob, 4.6, 3, mix("#a8a49a", "#f6f2e8", p))
                    ell(&ctx, x + d * 4.4, y - 4 + bob, 1.8, 1.6, dark)
                    rect(&ctx, x - 2.5, y - 1, 1, 2, dark)
                    rect(&ctx, x + 1.5, y - 1, 1, 2, dark)
                } else {
                    let cow = Color(hex: "#1f1b1a")
                    rect(&ctx, x - 6, y - 7, 12, 5, mix("#8a8680", "#f4f0ea", p))
                    rect(&ctx, x - 3, y - 7, 4, 3, cow)
                    rect(&ctx, x + d * 6 - (d < 0 ? 3 : 0), y - 8, 3, 3, cow)
                    rect(&ctx, x - 5, y - 2, 1.4, 3, cow)
                    rect(&ctx, x + 4, y - 2, 1.4, 3, cow)
                }
            }
        }
        if let c = B.bridge { bridge(&ctx, cam: cam, c: c, p: p) }
        // gulls
        let gc = mix("#3a3a44", "#f8f8f4", p)
        var gp = Path()
        for g in B.gulls {
            let wx = g.x + T * g.speed * FlightWorld.timeScale * 0.4 + sin(T * 0.3 + g.phase) * 30
            let x = cam.sx(wx), y = cam.sy(g.alt + sin(T * 0.5 + g.phase) * 12), w = CGFloat(sin(T * 7 + g.phase)) * 3
            if x < -10 || x > W + 10 { continue }
            gp.move(to: CGPoint(x: x - 6, y: y - w))
            gp.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: x - 3, y: y - 3 - w * 0.3))
            gp.addQuadCurve(to: CGPoint(x: x + 6, y: y - w), control: CGPoint(x: x + 3, y: y - 3 - w * 0.3))
        }
        ctx.stroke(gp, with: .color(gc), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
    }

    /// The gorge and the suspension bridge: cliffs, the Avon at the bottom, two stone towers, chains, hangers, the deck.
    static func bridge(_ ctx: inout GraphicsContext, cam: SceneCamera, c: Double, p: Double) {
        let X = cam.sx(c), W = cam.size.width, gy = cam.groundY
        guard X > -400 && X < W + 400 else { return }
        func yA(_ a: Double) -> CGFloat { cam.sy(a) }
        let rock = mix("#4a4038", "#a89478", p), rock2 = mix("#3a3028", "#8a7860", p), green = mix("#2a3a20", "#6a8a48", p)
        let hw = BristolWorld.halfWidth, to = BristolWorld.towerOuter
        for s in [-1.0, 1.0] {
            var cl = Path()
            cl.move(to: CGPoint(x: cam.sx(c + s * hw), y: gy + 1))
            var a = hw
            while a >= 104 {
                let h = a > to ? BristolWorld.bridgeHeight(a) : BristolWorld.cliff
                cl.addLine(to: CGPoint(x: cam.sx(c + s * a), y: yA(h > 0 ? h : BristolWorld.cliff)))
                a -= 6
            }
            cl.addLine(to: CGPoint(x: cam.sx(c + s * 104), y: yA(BristolWorld.cliff)))
            cl.addLine(to: CGPoint(x: cam.sx(c + s * 88), y: gy + 1))
            cl.closeSubpath()
            ctx.fill(cl, with: .color(rock))
            for k in 0..<4 {
                let h = 44 - Double(k) * 7
                rect(&ctx, cam.sx(c + s * (112 + Double(k) * 9)) - 1, yA(h), 2.2, CGFloat(h) * cam.ky * 0.7, rock2)
            }
            var a2 = 130.0
            while a2 < hw {
                ell(&ctx, cam.sx(c + s * a2), yA(BristolWorld.bridgeHeight(a2)) + 2, 6 * cam.kx + 3, 4, green)
                a2 += 13
            }
        }
        rect(&ctx, cam.sx(c - 88), gy - 2, cam.sx(c + 88) - cam.sx(c - 88), 6, mix("#2a3a48", "#7f98a8", p)) // the Avon
        rect(&ctx, cam.sx(c - 88), gy - 3, 10, 4, mix("#3a2e20", "#8a6e48", p))
        rect(&ctx, cam.sx(c + 78), gy - 3, 10, 4, mix("#3a2e20", "#8a6e48", p))
        let dk = yA(BristolWorld.deck), tTop = yA(BristolWorld.tower)
        let stone = mix("#5a5040", "#d8c8a0", p), stoneD = mix("#4a4030", "#b0a07a", p)
        // chains and hangers
        let chain = mix("#1e1e24", "#4a4a54", p)
        var ch = Path()
        ch.move(to: CGPoint(x: cam.sx(c - 100), y: tTop + 4))
        ch.addQuadCurve(to: CGPoint(x: cam.sx(c + 100), y: tTop + 4), control: CGPoint(x: X, y: 2 * (dk - 3) - (tTop + 4)))
        ctx.stroke(ch, with: .color(chain), lineWidth: 2)
        var hangers = Path()
        var a = -84.0
        while a <= 84 {
            let k = CGFloat(a / 100), cy = tTop + 4 + (1 - k * k) * (dk - 3 - tTop - 4)
            hangers.move(to: CGPoint(x: cam.sx(c + a), y: cy))
            hangers.addLine(to: CGPoint(x: cam.sx(c + a), y: dk))
            a += 12
        }
        ctx.stroke(hangers, with: .color(chain), lineWidth: 0.8)
        rect(&ctx, cam.sx(c - 104), dk, cam.sx(c + 104) - cam.sx(c - 104), 4, mix("#2a2a30", "#5a5a64", p)) // the deck
        let arch = mix("#1e1a20", "#6a6a7a", p)
        for s in [-1.0, 1.0] {
            let x0 = cam.sx(c + s * 100 - 8), x1 = cam.sx(c + s * 100 + 8), tw = x1 - x0
            rect(&ctx, x0, tTop, tw, yA(BristolWorld.cliff) - tTop, stone)
            rect(&ctx, x0 + tw * 0.62, tTop, tw * 0.38, yA(BristolWorld.cliff) - tTop, stoneD)
            let aw = tw * 0.4, ah = yA(62) - yA(84)
            rect(&ctx, x0 + tw * 0.3, dk - ah, aw, ah + 4, arch)
            var top = Path()
            top.addArc(center: CGPoint(x: x0 + tw * 0.3 + aw / 2, y: dk - ah), radius: aw / 2, startAngle: .radians(.pi), endAngle: .radians(0), clockwise: false)
            ctx.fill(top, with: .color(arch))
            rect(&ctx, x0 - 1, tTop - 3, tw + 2, 4, stoneD)
        }
    }

    /// `briObstacle`: one Bristol obstacle: an oak or copper beech, a church, the observatory, the tall ship, a crane.
    static func obstacle(_ ctx: inout GraphicsContext, _ c: Obstacle, x: CGFloat, gy: CGFloat, cw: CGFloat, chh: CGFloat, p: Double) {
        switch c.kind {
        case .spire:
            let st = mix("#5a5040", "#cfc0a0", p), sd = mix("#3a3428", "#9a8a6a", p)
            rect(&ctx, x - cw * 0.55, gy - chh * 0.32, cw * 0.7, chh * 0.32, st)
            rect(&ctx, x + cw * 0.1, gy - chh * 0.5, cw * 0.3, chh * 0.5, st)
            var s = Path()
            s.move(to: CGPoint(x: x + cw * 0.06, y: gy - chh * 0.5)); s.addLine(to: CGPoint(x: x + cw * 0.25, y: gy - chh)); s.addLine(to: CGPoint(x: x + cw * 0.44, y: gy - chh * 0.5))
            s.closeSubpath()
            ctx.fill(s, with: .color(sd))
            var r = Path()
            r.move(to: CGPoint(x: x - cw * 0.6, y: gy - chh * 0.32)); r.addLine(to: CGPoint(x: x - cw * 0.2, y: gy - chh * 0.45)); r.addLine(to: CGPoint(x: x + cw * 0.15, y: gy - chh * 0.32))
            r.closeSubpath()
            ctx.fill(r, with: .color(mix("#3a2420", "#8a4a3a", p)))
        case .observatory:
            // a round stone tower on a grassy knoll, with a little dome
            ell(&ctx, x, gy + 2, cw * 1.6, chh * 0.14, mix("#2a3a20", "#6a8a48", p))
            let st = mix("#5a5040", "#d8c8a0", p), tw = max(9, cw * 0.8)
            rect(&ctx, x - tw / 2, gy - chh * 0.9, tw, chh * 0.9, st)
            rect(&ctx, x + tw * 0.18, gy - chh * 0.9, tw * 0.32, chh * 0.9, mix("#4a4030", "#b0a07a", p))
            for k in 0..<4 { rect(&ctx, x - tw * 0.56 + CGFloat(k) * tw * 0.34, gy - chh * 0.98, tw * 0.2, chh * 0.09, st) }
            var d = Path()
            d.addArc(center: CGPoint(x: x, y: gy - chh * 0.9), radius: tw * 0.3, startAngle: .radians(.pi), endAngle: .radians(0), clockwise: false)
            ctx.fill(d, with: .color(mix("#2a2a30", "#6a7a8a", p)))
            rect(&ctx, x - tw * 0.08, gy - chh * 0.62, tw * 0.16, chh * 0.1, Color(hex: "#1e1a20"))
            rect(&ctx, x - tw * 0.08, gy - chh * 0.3, tw * 0.16, chh * 0.1, Color(hex: "#1e1a20"))
        case .mast:
            // the old tall ship: dark hull on the water, three masts with yards and rigging
            let hw = cw * 1.1
            var hull = Path()
            hull.move(to: CGPoint(x: x - hw, y: gy - 9)); hull.addLine(to: CGPoint(x: x + hw * 1.1, y: gy - 9))
            hull.addLine(to: CGPoint(x: x + hw * 0.9, y: gy + 1)); hull.addLine(to: CGPoint(x: x - hw * 0.85, y: gy + 1))
            hull.closeSubpath()
            ctx.fill(hull, with: .color(mix("#1e1a1a", "#3a2e2a", p)))
            rect(&ctx, x - hw, gy - 9, hw * 2.1, 1.6, mix("#8a3a2a", "#c8a050", p))
            let wood = mix("#2a2018", "#5a4030", p)
            var masts = Path(), yards = Path()
            for (dx, k) in [(-0.55, 0.9), (0, 1), (0.5, 0.85)] as [(CGFloat, CGFloat)] {
                let mx = x + dx * hw
                masts.move(to: CGPoint(x: mx, y: gy - 9)); masts.addLine(to: CGPoint(x: mx, y: gy - chh * k))
                for y in 1...3 {
                    let yy = gy - 9 - (chh * k - 9) * CGFloat(y) / 3.4, yw = hw * (0.34 - CGFloat(y) * 0.06)
                    yards.move(to: CGPoint(x: mx - yw, y: yy)); yards.addLine(to: CGPoint(x: mx + yw, y: yy))
                }
            }
            ctx.stroke(masts, with: .color(wood), lineWidth: 2)
            ctx.stroke(yards, with: .color(wood), lineWidth: 2)
            line(&ctx, [(x - hw, gy - 9), (x - 0.55 * hw, gy - chh * 0.9), (x, gy - chh), (x + 0.5 * hw, gy - chh * 0.85), (x + hw * 1.25, gy - 10)], wood, 0.6)
        case .crane:
            // a dock crane: a lattice tower, a cab and a long jib
            let col = mix("#5a2a1a", "#c0582a", p), tw = cw * 0.4
            var legs = Path()
            legs.move(to: CGPoint(x: x - tw, y: gy)); legs.addLine(to: CGPoint(x: x - tw * 0.5, y: gy - chh * 0.82))
            legs.move(to: CGPoint(x: x + tw, y: gy)); legs.addLine(to: CGPoint(x: x + tw * 0.5, y: gy - chh * 0.82))
            ctx.stroke(legs, with: .color(col), lineWidth: 2)
            var lattice = Path()
            for k in 0..<5 {
                let y0 = gy - chh * 0.82 * CGFloat(k) / 5, y1 = gy - chh * 0.82 * CGFloat(k + 1) / 5
                lattice.move(to: CGPoint(x: x - tw + tw * 0.5 * CGFloat(k) / 5, y: y0))
                lattice.addLine(to: CGPoint(x: x + tw - tw * 0.5 * CGFloat(k + 1) / 5, y: y1))
            }
            ctx.stroke(lattice, with: .color(col), lineWidth: 0.8)
            rect(&ctx, x - tw * 0.9, gy - chh * 0.92, tw * 1.8, chh * 0.1, col)
            var jib = Path()
            jib.move(to: CGPoint(x: x - tw, y: gy - chh * 0.88)); jib.addLine(to: CGPoint(x: x - cw * 1.6, y: gy - chh * 0.78))
            jib.move(to: CGPoint(x: x, y: gy - chh)); jib.addLine(to: CGPoint(x: x - cw * 1.6, y: gy - chh * 0.8))
            ctx.stroke(jib, with: .color(col), lineWidth: 2.2)
            line(&ctx, [(x - cw * 1.3, gy - chh * 0.79), (x - cw * 1.3, gy - chh * 0.45)], col, 0.8)
            rect(&ctx, x - cw * 1.3 - 2, gy - chh * 0.45, 4, 4, Color(hex: "#2a2a30"))
        default:
            // oaks and copper beeches
            let beech = c.tone > 0.55
            let crown = beech ? ScenePainter.mix(ScenePainter.mixHex("#2a141a", "#7a2a3a", p), "#8a3a44", c.tone * 0.3)
                : ScenePainter.mix(ScenePainter.mixHex("#1e3418", "#4a7a32", p), "#5a8a3a", c.tone * 0.3)
            ScenePainter.tree(&ctx, x, gy + 1, cw * 1.5, chh, crown: crown, trunk: mix("#2a1e14", "#5a4430", p))
        }
    }

    // MARK: Fog and the airspace

    /// `briOverlay`: the airport's airspace (a red-striped zone above its floor, a label with a little plane) and the
    /// morning fog, over the scenery and under your balloon. `inside`: the balloon is in the airspace now.
    static func overlay(_ ctx: inout GraphicsContext, cam: SceneCamera, weather w: Weather, alt: Double?, inside: Bool, done: Bool,
                        time T: Double, airLabel: String, fogLabel: String) {
        let W = cam.size.width, H = cam.size.height, topY = cam.topY
        if let A = w.air {
            let X0 = cam.sx(A.x0), X1 = cam.sx(A.x1), Y = cam.sy(A.floor)
            if X1 > -10 && X0 < W + 10 {
                let zone = CGRect(x: X0, y: topY - 40, width: X1 - X0, height: Y - topY + 40)
                var z = ctx
                z.clip(to: Path(zone))
                z.fill(Path(zone), with: .color(Color(red: 229 / 255, green: 67 / 255, blue: 47 / 255).opacity(inside ? 0.22 : 0.12)))
                var stripes = Path()
                var x = X0 - (Y - topY)
                while x < X1 + 40 {
                    stripes.move(to: CGPoint(x: x, y: Y + 4))
                    stripes.addLine(to: CGPoint(x: x + (Y - topY) + 40, y: topY - 44))
                    x += 26
                }
                z.stroke(stripes, with: .color(Color(red: 229 / 255, green: 67 / 255, blue: 47 / 255).opacity(0.32)), lineWidth: 7)
                var edge = Path()
                edge.move(to: CGPoint(x: X0, y: topY - 40)); edge.addLine(to: CGPoint(x: X0, y: Y))
                edge.addLine(to: CGPoint(x: X1, y: Y)); edge.addLine(to: CGPoint(x: X1, y: topY - 40))
                ctx.stroke(edge, with: .color(Color(red: 229 / 255, green: 67 / 255, blue: 47 / 255).opacity(0.9)), style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                let label = ctx.resolve(Text(verbatim: airLabel).font(.custom("BarlowCondensed-ExtraBold", fixedSize: 14)).foregroundColor(.white))
                let tw = label.measure(in: CGSize(width: W, height: 40)).width + 40
                let lx = min(max((X0 + X1) / 2, X0 + 50), max(X0 + 50, X1 - 50)), ly = Y - 16
                ctx.fill(Path(roundedRect: CGRect(x: lx - tw / 2, y: ly - 12, width: tw, height: 24), cornerRadius: 12),
                         with: .color(Color(red: 160 / 255, green: 30 / 255, blue: 24 / 255).opacity(0.9)))
                ctx.draw(label, at: CGPoint(x: lx - tw / 2 + 32, y: ly), anchor: .leading)
                // the little plane
                var pl = ctx
                pl.translateBy(x: lx - tw / 2 + 16, y: ly)
                var plane = Path(ellipseIn: CGRect(x: -9, y: -2.2, width: 18, height: 4.4))
                plane.move(to: CGPoint(x: -1, y: 0)); plane.addLine(to: CGPoint(x: -5, y: -7)); plane.addLine(to: CGPoint(x: -2, y: -7))
                plane.addLine(to: CGPoint(x: 4, y: 0)); plane.addLine(to: CGPoint(x: -2, y: 7)); plane.addLine(to: CGPoint(x: -5, y: 7)); plane.closeSubpath()
                plane.move(to: CGPoint(x: -8, y: 0)); plane.addLine(to: CGPoint(x: -10, y: -4)); plane.addLine(to: CGPoint(x: -7.5, y: -4)); plane.addLine(to: CGPoint(x: -5, y: 0)); plane.closeSubpath()
                pl.fill(plane, with: .color(.white))
            }
        }
        if let fog = w.fog {
            let top = cam.sy(fog.top), under = (alt ?? 0) < fog.top, a = under ? 0.42 : 0.9
            let band = CGRect(x: 0, y: top - 46, width: W, height: H - top + 46)
            let fc = (226.0, 230.0, 234.0)
            func c(_ o: Double) -> Color { Color(red: fc.0 / 255, green: fc.1 / 255, blue: fc.2 / 255).opacity(o) }
            ctx.fill(Path(band), with: .linearGradient(Gradient(stops: [.init(color: c(0), location: 0), .init(color: c(a * 0.75), location: 0.14),
                                                                         .init(color: c(a), location: 0.4), .init(color: c(a), location: 1)]),
                                                        startPoint: CGPoint(x: 0, y: top - 46), endPoint: CGPoint(x: 0, y: H)))
            var puffs = Path()
            for i in 0..<9 {
                let x = CGFloat(ScenePainter.pmod(Double(i) * 173 + T * 6, Double(W + 200))) - 100
                puffs.addEllipse(in: CGRect(x: x - 90, y: top + 6 + CGFloat(i % 3) * 10 - 12, width: 180, height: 24))
            }
            ctx.fill(puffs, with: .color(Color.white.opacity(under ? 0.12 : 0.3)))
            if let alt, alt >= fog.top, !done {
                ctx.draw(Text(verbatim: fogLabel).font(.custom("BarlowCondensed-ExtraBold", fixedSize: 13))
                            .foregroundColor(Color(red: 60 / 255, green: 70 / 255, blue: 90 / 255).opacity(0.85)),
                         at: CGPoint(x: W - 12, y: top - 8), anchor: .trailing)
            }
        }
    }
}
