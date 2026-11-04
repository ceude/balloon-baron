import SwiftUI
import BalloonBaronCore

/// v141: the Maasai Mara in flight (prototype `maraFar`, `maraGround`, `maraBeast`, `maraDraw`, `maraObstacle` and the
/// Mara branches of `scenery`): an African dawn, the long flat wall of the Oloololo escarpment, the plains nearly flat,
/// acacias in the haze, golden grass with a red-earth game track and termite mounds; on the flight line the Mara River
/// winding toward you (hippos, a crocodile, riverine trees), herds grazing within their patch of plain (wildebeest,
/// zebra, elephants, giraffes) with a faint dashed line under them, vultures circling; the rains fall as rain.
enum MaraPainter {
    private static func mix(_ a: String, _ b: String, _ k: Double) -> Color { ScenePainter.mix(a, b, k) }
    private static func ell(_ ctx: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ c: Color) {
        ScenePainter.ell(&ctx, x, y, rx, ry, c)
    }
    private static func rect(_ ctx: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ c: Color) {
        ScenePainter.rect(&ctx, x, y, w, h, c)
    }
    private static func poly(_ ctx: inout GraphicsContext, _ pts: [(CGFloat, CGFloat)], _ c: Color) {
        guard let f = pts.first else { return }
        var p = Path()
        p.move(to: CGPoint(x: f.0, y: f.1))
        for q in pts.dropFirst() { p.addLine(to: CGPoint(x: q.0, y: q.1)) }
        p.closeSubpath()
        ctx.fill(p, with: .color(c))
    }

    // MARK: Sky and land

    static func sky(_ p: Double) -> Gradient {
        Gradient(stops: [.init(color: mix("#1a2244", "#5a9ad0", p), location: 0), .init(color: mix("#7a3a4a", "#f6b070", p), location: 0.5),
                         .init(color: mix("#f08a3a", "#ffe0a0", p), location: 1)])
    }
    static let horizon = ("#f08a3a", "#ffe0a0")

    /// The Oloololo escarpment: a long flat-topped wall that falls away now and then.
    static func escarpment(_ ctx: inout GraphicsContext, cam: SceneCamera, p: Double) {
        let W = cam.size.width, gy = cam.groundY, vh = cam.viewHeight
        var m = Path()
        m.move(to: CGPoint(x: -20, y: gy))
        var x: CGFloat = -20
        while x <= W + 40 {
            let wx = Double(x / cam.kx + CGFloat(cam.camX) * 0.06) * 0.004, e = 0.5 + 0.5 * sin(wx * 0.8 + 0.4)
            let k = 0.035 + 0.075 * min(max(e * 3 - 1, 0), 1) + 0.0015 * sin(wx * 23)
            m.addLine(to: CGPoint(x: x, y: gy - vh * CGFloat(k)))
            x += 14
        }
        m.addLine(to: CGPoint(x: W + 40, y: gy))
        m.closeSubpath()
        ctx.fill(m, with: .color(mix("#3a2a44", "#b08a96", p)))
    }

    /// The plains' near edge: nearly flat.
    static func ridge(_ ctx: inout GraphicsContext, cam: SceneCamera, p: Double) {
        let W = cam.size.width, gy = cam.groundY, vh = cam.viewHeight
        var r = Path()
        r.move(to: CGPoint(x: 0, y: gy))
        var x: CGFloat = -20
        while x <= W + 40 {
            let wx = Double(x / cam.kx + CGFloat(cam.camX) * 0.15) * 0.01
            r.addLine(to: CGPoint(x: x, y: gy - vh * CGFloat(0.05 + 0.015 * sin(wx * 0.9) + 0.006 * sin(wx * 3.1))))
            x += 16
        }
        r.addLine(to: CGPoint(x: W, y: gy))
        r.closeSubpath()
        ctx.fill(r, with: .color(mix("#4a3a3a", "#c8a07a", p)))
    }

    /// Far scenery: small acacias and bush in the haze.
    static func far(_ ctx: inout GraphicsContext, x: CGFloat, base: CGFloat, hh: CGFloat, ww: CGFloat, i: Int, col: Color) {
        let s: CGFloat = 0.45
        if i % 3 == 1 {
            rect(&ctx, x - 0.8, base - hh * 0.55 * s, 1.6, hh * 0.55 * s, col)
            ell(&ctx, x, base - hh * 0.56 * s, ww * 0.7, hh * 0.06 * s + 1, col)
            ell(&ctx, x + ww * 0.2, base - hh * 0.6 * s, ww * 0.4, hh * 0.05 * s + 1, col)
        } else if i % 7 == 3 {
            ell(&ctx, x, base - hh * 0.1 * s, ww * 0.6, hh * 0.14 * s, col)
            ell(&ctx, x + ww * 0.4, base - hh * 0.06 * s, ww * 0.35, hh * 0.1 * s, col)
        }
    }

    static func ground(_ p: Double, rains: Bool) -> Gradient {
        rains ? Gradient(colors: [mix("#3a4a22", "#9ab060", p), mix("#22301a", "#6a8a3a", p)])
            : Gradient(colors: [mix("#6a5226", "#d8b464", p), mix("#3a2a16", "#a8803e", p)])
    }

    /// Golden grass in bands, a red-earth game track, grass tufts and termite mounds.
    static func groundDetail(_ ctx: inout GraphicsContext, cam: SceneCamera, p: Double) {
        let W = cam.size.width, H = cam.size.height, gy = cam.groundY, gh = H - gy, kx = cam.kx, camX = cam.camX
        rect(&ctx, 0, gy + gh * 0.2, W, gh * 0.1, mix("#5a4422", "#d8b060", p))
        let ty = gy + gh * 0.48
        var track = Path()
        track.move(to: CGPoint(x: 0, y: ty))
        var x: CGFloat = 0
        while x <= W + 20 {
            track.addLine(to: CGPoint(x: x, y: ty + CGFloat(sin(Double(x / kx) + camX * 0.9 * 0.01) * 4)))
            x += 20
        }
        track.addLine(to: CGPoint(x: W + 20, y: ty + 7))
        track.addLine(to: CGPoint(x: 0, y: ty + 7))
        track.closeSubpath()
        ctx.fill(track, with: .color(mix("#5a2e1e", "#b8643a", p)))
        var tufts = Path()
        for i in 0..<70 {
            let tx = CGFloat(ScenePainter.pmod(Double(i) * 53.3 - camX * Double(kx) * 0.95, Double(W + 40))) - 20
            let y = gy + 6 + CGFloat(Double(i * 37 % 100) / 100) * gh * 0.9
            tufts.move(to: CGPoint(x: tx - 3, y: y)); tufts.addLine(to: CGPoint(x: tx - 1, y: y - 6))
            tufts.move(to: CGPoint(x: tx, y: y)); tufts.addLine(to: CGPoint(x: tx + 1, y: y - 7))
            tufts.move(to: CGPoint(x: tx + 3, y: y)); tufts.addLine(to: CGPoint(x: tx + 4, y: y - 5))
        }
        ctx.stroke(tufts, with: .color(mix("#3a3018", "#a08a3a", p)), lineWidth: 1.2)
        for i in 0..<4 {
            let mx = CGFloat(ScenePainter.pmod(Double(i) * 271 - camX * Double(kx) * 0.95, Double(W + 80))) - 40
            let my = gy + gh * (0.3 + CGFloat(i % 2) * 0.32)
            var m = Path()
            m.move(to: CGPoint(x: mx - 6, y: my))
            m.addQuadCurve(to: CGPoint(x: mx, y: my - 16), control: CGPoint(x: mx - 3, y: my - 14))
            m.addQuadCurve(to: CGPoint(x: mx + 6, y: my), control: CGPoint(x: mx + 4, y: my - 12))
            m.closeSubpath()
            ctx.fill(m, with: .color(mix("#4a2618", "#a85a34", p)))
        }
    }

    /// The rains: a grey veil and falling rain.
    static func rain(_ ctx: inout GraphicsContext, cam: SceneCamera, time T: Double) {
        let W = cam.size.width, H = cam.size.height
        rect(&ctx, 0, 0, W, cam.groundY, Color(red: 60 / 255, green: 70 / 255, blue: 90 / 255).opacity(0.14))
        var r = Path()
        for i in 0..<80 {
            let fi = Double(i)
            let x0 = CGFloat((fi * 97.3 + T * 40).truncatingRemainder(dividingBy: Double(W + 40))) - 20
            let y0 = CGFloat((fi * 53.7 + T * 420 * (1 + Double(i % 3) * 0.2)).truncatingRemainder(dividingBy: Double(H)))
            r.move(to: CGPoint(x: x0, y: y0)); r.addLine(to: CGPoint(x: x0 - 3, y: y0 + 12))
        }
        ctx.stroke(r, with: .color(Color(red: 220 / 255, green: 230 / 255, blue: 245 / 255).opacity(0.45)), lineWidth: 1)
    }

    // MARK: The flight line

    /// One animal of a herd standing on the ground at x (`maraBeast`), s ≈ px per metre.
    static func beast(_ ctx: inout GraphicsContext, _ k: HerdKind, x: CGFloat, y: CGFloat, d: CGFloat, s: CGFloat, p: Double, time t: Double) {
        let bob = CGFloat(sin(t * 2 + Double(x)) * 0.3)
        switch k {
        case .gnu:
            let c = mix("#1e1814", "#4a3e36", p)
            ell(&ctx, x, y - 3.2 * s + bob, 4.2 * s, 2.2 * s, c)
            rect(&ctx, x - 3 * s, y - 2 * s, 0.9 * s, 2 * s, c); rect(&ctx, x + 2.2 * s, y - 2 * s, 0.9 * s, 2 * s, c)
            poly(&ctx, [(x + d * 3 * s, y - 4.6 * s), (x + d * 6.4 * s, y - 2.6 * s), (x + d * 5.4 * s, y - 1.6 * s), (x + d * 2.4 * s, y - 3 * s)], c)
        case .zebra:
            let w = mix("#8a8a86", "#f6f2e8", p), blk = Color(hex: "#1a1614")
            ell(&ctx, x, y - 3.2 * s + bob, 4 * s, 2.1 * s, w)
            for j in -2...2 { rect(&ctx, x + CGFloat(j) * 1.5 * s - 0.3 * s, y - 5 * s, 0.7 * s, 3.6 * s, blk) }
            rect(&ctx, x - 2.8 * s, y - 1.6 * s, 0.8 * s, 1.6 * s, blk); rect(&ctx, x + 2.2 * s, y - 1.6 * s, 0.8 * s, 1.6 * s, blk)
            poly(&ctx, [(x + d * 3 * s, y - 4.4 * s), (x + d * 5.6 * s, y - 7 * s), (x + d * 6.6 * s, y - 6 * s), (x + d * 3.6 * s, y - 2.8 * s)], w)
        case .elephant:
            let c = mix("#2a2826", "#7a7470", p)
            ell(&ctx, x, y - 6 * s + bob, 7 * s, 4.6 * s, c)
            for dx: CGFloat in [-4.6, -1.8, 1.6, 4.2] { rect(&ctx, x + dx * s - s, y - 3 * s, 2 * s, 3 * s, c) }
            ell(&ctx, x + d * 6.4 * s, y - 7.4 * s, 3 * s, 2.8 * s, c)
            var trunk = Path()
            trunk.move(to: CGPoint(x: x + d * 8.4 * s, y: y - 7 * s))
            trunk.addQuadCurve(to: CGPoint(x: x + d * 8.8 * s, y: y - 0.6 * s), control: CGPoint(x: x + d * 9.6 * s, y: y - 3 * s))
            ctx.stroke(trunk, with: .color(c), lineWidth: 1.6 * s)
            ell(&ctx, x + d * 4.6 * s, y - 7.6 * s, 2 * s, 2.8 * s, mix("#24221f", "#6a6460", p))
        case .giraffe:
            let c = mix("#5a3a1a", "#d8a050", p)
            ell(&ctx, x, y - 8 * s + bob, 3.6 * s, 2.2 * s, c)
            for dx: CGFloat in [-2.4, -1, 1, 2.4] { rect(&ctx, x + dx * s - 0.4 * s, y - 7 * s, 0.8 * s, 7 * s, c) }
            poly(&ctx, [(x + d * 2 * s, y - 9 * s), (x + d * 4.8 * s, y - 17 * s), (x + d * 5.8 * s, y - 16.4 * s), (x + d * 3.4 * s, y - 8 * s)], c)
            ell(&ctx, x + d * 6 * s, y - 16.8 * s, 1.8 * s, 1 * s, c)
        }
    }

    /// The river, the herds and the vultures on today's line (`maraDraw`).
    static func world(_ ctx: inout GraphicsContext, cam: SceneCamera, _ M: MaraWorld, p: Double, time T: Double, flightTime ft: Double) {
        let W = cam.size.width, H = cam.size.height, gy = cam.groundY, gh = H - gy, kx = cam.kx
        let s = min(max(cam.ky * 1.1, 0.8), 1.5)
        if let r = M.river {
            let X0 = cam.sx(r.x0 - MaraWorld.bank), X1 = cam.sx(r.x1 + MaraWorld.bank)
            if X1 > -160 && X0 < W + 160 {
                let a = cam.sx(r.x0), b = cam.sx(r.x1), mid = (a + b) / 2, hw = (b - a) / 2
                var bank = Path()
                bank.move(to: CGPoint(x: X0, y: gy + 1)); bank.addLine(to: CGPoint(x: X1, y: gy + 1))
                bank.addQuadCurve(to: CGPoint(x: mid + hw * 2.2 + 40, y: H), control: CGPoint(x: mid + hw * 3, y: gy + gh * 0.5))
                bank.addLine(to: CGPoint(x: mid - hw * 2.2 - 70, y: H))
                bank.addQuadCurve(to: CGPoint(x: X0, y: gy + 1), control: CGPoint(x: mid - hw * 3.4, y: gy + gh * 0.5))
                ctx.fill(bank, with: .color(mix("#3a2418", "#9a6a44", p)))
                var water = Path()
                water.move(to: CGPoint(x: a, y: gy + 1)); water.addLine(to: CGPoint(x: b, y: gy + 1))
                water.addQuadCurve(to: CGPoint(x: mid + hw * 1.6 + 26, y: H), control: CGPoint(x: mid + hw * 2.2, y: gy + gh * 0.5))
                water.addLine(to: CGPoint(x: mid - hw * 1.6 - 50, y: H))
                water.addQuadCurve(to: CGPoint(x: a, y: gy + 1), control: CGPoint(x: mid - hw * 2.6, y: gy + gh * 0.5))
                ctx.fill(water, with: .color(mix("#2a3a3a", "#6a8a7a", p)))
                for i in 0..<6 {
                    let y = gy + 4 + CGFloat(i) * gh / 7
                    rect(&ctx, mid - hw * (1 + CGFloat(i) * 0.2) + CGFloat(i % 3) * 8, y, 14 + CGFloat(i) * 3, 1.4, Color.white.opacity(0.18))
                }
                for (dx, s2) in [(-hw - CGFloat(MaraWorld.bank) * kx * 0.7, CGFloat(1)), (hw + CGFloat(MaraWorld.bank) * kx * 0.8, 0.9)] {
                    let tx = mid + dx
                    ell(&ctx, tx, gy - 10 * s, 14 * s2 * s, 9 * s, mix("#1e2a14", "#4a6a2e", p))
                    rect(&ctx, tx - 1.2, gy - 4 * s, 2.4, 5 * s, mix("#2a1e14", "#5a4430", p))
                }
                for i in 0..<3 { // hippos
                    let hx = cam.sx(r.x0 + 18 + Double(i) * 34 + sin(T / 9 + Double(i)) * 4)
                    ell(&ctx, hx, gy + 2.5, 4.6 * s, 2.2 * s, mix("#2a2224", "#6a5a5a", p))
                    ell(&ctx, hx + 3 * s, gy + 1, 1.6 * s, 1.1 * s, mix("#2a2224", "#6a5a5a", p))
                }
                let cx = cam.sx(r.x1 + 14) // a crocodile on the bank
                poly(&ctx, [(cx - 9 * s, gy + 1), (cx + 9 * s, gy + 1), (cx + 12 * s, gy + 2.2), (cx - 9 * s, gy + 2.6)], mix("#2a3020", "#5a6a3a", p))
                dashed(&ctx, X0, X1, gy + 13, Color(hex: "#e5432f").opacity(0.55))
            }
        }
        for z in M.herds {
            let c = z.center(at: ft), X0 = cam.sx(c - z.half), X1 = cam.sx(c + z.half)
            if X1 < -40 || X0 > W + 40 { continue }
            dashed(&ctx, X0, X1, gy + 13, Color(hex: "#ffb02e").opacity(0.45))
            var r = Mulberry32(seed: UInt32(z.seed * 1000))
            let d: CGFloat = cos(ft / 20 + z.phase) >= 0 ? 1 : -1
            for i in 0..<z.count {
                let x = X0 + 6 + CGFloat(r.next()) * (X1 - X0 - 12), y = gy + 1 + CGFloat(r.next()) * 6
                let dd = r.next() < 0.8 ? d : -d
                beast(&ctx, z.kind, x: x, y: y, d: dd, s: s * CGFloat(0.85 + r.next() * 0.3), p: p, time: T + Double(i))
            }
        }
        var birds = Path()
        for b in M.birds {
            let a = T * 0.4 + b.phase
            let x = cam.sx(b.x + cos(a) * b.radius), y = cam.sy(b.alt + sin(a) * b.radius * 0.3), w = CGFloat(sin(T * 2 + b.phase) * 1.5)
            if x < -10 || x > W + 10 { continue }
            birds.move(to: CGPoint(x: x - 7, y: y - 2 - w))
            birds.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: x - 3, y: y - 3))
            birds.addQuadCurve(to: CGPoint(x: x + 7, y: y - 2 - w), control: CGPoint(x: x + 3, y: y - 3))
        }
        ctx.stroke(birds, with: .color(mix("#1a1410", "#3a2e26", p)), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
    }

    private static func dashed(_ ctx: inout GraphicsContext, _ x0: CGFloat, _ x1: CGFloat, _ y: CGFloat, _ c: Color) {
        var l = Path()
        l.move(to: CGPoint(x: x0, y: y)); l.addLine(to: CGPoint(x: x1, y: y))
        ctx.stroke(l, with: .color(c), style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
    }

    /// One Mara obstacle: a flat-topped acacia or a granite kopje (`maraObstacle`).
    static func obstacle(_ ctx: inout GraphicsContext, _ c: Obstacle, x: CGFloat, gy: CGFloat, cw: CGFloat, chh: CGFloat, p: Double) {
        if c.kind == .kopje {
            let r1 = mix("#3a3430", "#a8988a", p), r2 = mix("#2a2420", "#7a6c62", p)
            ell(&ctx, x - cw * 0.3, gy - chh * 0.22, cw * 0.42, chh * 0.24, r2)
            ell(&ctx, x + cw * 0.26, gy - chh * 0.26, cw * 0.4, chh * 0.28, r1)
            ell(&ctx, x - cw * 0.02, gy - chh * 0.55, cw * 0.34, chh * 0.3, r1)
            ell(&ctx, x + cw * 0.06, gy - chh * 0.86, cw * 0.2, chh * 0.16, r2)
            ell(&ctx, x - cw * 0.1, gy - chh * 0.66, cw * 0.18, chh * 0.08, Color(red: 1, green: 240 / 255, blue: 210 / 255).opacity(0.18))
            ell(&ctx, x + cw * 0.42, gy - chh * 0.12, cw * 0.14, chh * 0.12, mix("#1e2a14", "#5a7a32", p))
            return
        }
        let tr = mix("#2a1e14", "#5a4430", p)
        let cr = mix(ScenePainter.mixHex("#1e2a14", "#5a6e2a", p), "#7a8a3a", c.tone * 0.3), cw2 = cw * 1.1
        var t = Path()
        t.move(to: CGPoint(x: x, y: gy + 1)); t.addLine(to: CGPoint(x: x + cw * 0.02, y: gy - chh * 0.55)); t.addLine(to: CGPoint(x: x - cw2 * 0.35, y: gy - chh * 0.86))
        t.move(to: CGPoint(x: x + cw * 0.02, y: gy - chh * 0.55)); t.addLine(to: CGPoint(x: x + cw2 * 0.32, y: gy - chh * 0.88))
        t.move(to: CGPoint(x: x + cw * 0.02, y: gy - chh * 0.6)); t.addLine(to: CGPoint(x: x + cw * 0.04, y: gy - chh * 0.9))
        ctx.stroke(t, with: .color(tr), style: StrokeStyle(lineWidth: max(1.6, cw * 0.07), lineCap: .round))
        ell(&ctx, x, gy - chh * 0.9, cw2 * 0.62, chh * 0.1, cr)
        ell(&ctx, x - cw2 * 0.26, gy - chh * 0.95, cw2 * 0.36, chh * 0.08, cr)
        ell(&ctx, x + cw2 * 0.24, gy - chh * 0.97, cw2 * 0.34, chh * 0.07, cr)
        ell(&ctx, x - cw2 * 0.2, gy - chh * 0.99, cw2 * 0.3, chh * 0.035, Color(red: 1, green: 230 / 255, blue: 160 / 255).opacity(0.16))
    }
}
