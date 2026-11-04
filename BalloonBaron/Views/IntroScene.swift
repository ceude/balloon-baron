import SwiftUI
import BalloonBaronCore

/// The opening screen's world: a dawn launch field in the region you're playing, with its own skyline, the last
/// stars, a rising sun, balloons already up, and the game's name in the sky.
/// v138: each region's land is a set of backlit layers (`Land`). Port of the prototype's `introScene` and `introLand`.
enum IntroScene {
    struct Look {
        let sky: [String], far: String, mid: String, midShade: String, cap: String, ground: [String], ink: String, name: String
    }

    static func look(_ key: String) -> Look {
        switch key {
        case "abq": Look(sky: ["#0f1534", "#31275c", "#bc4e6a", "#ff8f4e", "#ffcf80"], far: "#5e345a", mid: "#a8503a", midShade: "#6a3022",
                         cap: "#3f7a3a", ground: ["#8a4e2c", "#28120a"], ink: "#25121e", name: "ALBUQUERQUE")
        case "lux": Look(sky: ["#0d1836", "#2a3664", "#b0605a", "#f2a656", "#ffe2a0"], far: "#6a5260", mid: "#c89a62", midShade: "#8a6440",
                         cap: "#2e5a2a", ground: ["#a07a4a", "#30200e"], ink: "#261a22", name: "LUXOR")
        // v124: an overcast dawn over Bristol
        case "bri": Look(sky: ["#1a2236", "#3a4a66", "#8a8aa0", "#d8b49a", "#eee2cc"], far: "#4a5868", mid: "#cdb07a", midShade: "#8a7450",
                         cap: "#3a5a2e", ground: ["#4a6a34", "#1a2a14"], ink: "#1c2a24", name: "BRISTOL")
        // v141: the Maasai Mara's sunrise
        case "mara": Look(sky: ["#101634", "#2e2a5e", "#a8486a", "#f4863c", "#ffd690"], far: "#5a3a5a", mid: "#b8784a", midShade: "#7a4a2a",
                          cap: "#4a5a2a", ground: ["#9a6e3a", "#2a180c"], ink: "#22140c", name: "MAASAI MARA")
        default: Look(sky: ["#120d33", "#3a2460", "#a24e7a", "#f0875a", "#ffd59a"], far: "#4e3460", mid: "#c8866a", midShade: "#8a5060",
                      cap: "#4a2a2a", ground: ["#6e4a3a", "#2a1822"], ink: "#24152c", name: "CAPPADOCIA")
        }
    }

    private static let cols = ["#ff5e3a", "#ffc23d", "#14a39a", "#9b7be0", "#5aa9e6", "#ff6fa8", "#22a45d", "#e5432f"]

    /// Everything but the hero balloon. `lift` is 0 on the ground and 1 high up.
    static func draw(_ ctx: inout GraphicsContext, size: CGSize, region key: String, gy: CGFloat, t: Double, lift: Double) {
        let L = look(key), W = size.width, H = size.height, u = min(W, H)
        func hex(_ s: String) -> Color { Color(hex: s) }
        // Sky.
        ctx.fill(Path(CGRect(x: 0, y: 0, width: W, height: gy)), with: .linearGradient(
            Gradient(stops: zip([0, 0.32, 0.62, 0.85, 1] as [CGFloat], L.sky).map { Gradient.Stop(color: hex($1), location: $0) }),
            startPoint: .zero, endPoint: CGPoint(x: 0, y: gy)))
        // The last stars, fading towards the horizon.
        var R = Mulberry32(seed: 7)
        for i in 0..<80 {
            let x = CGFloat(R.next()) * W, y = CGFloat(R.next()) * gy * 0.55
            let a = (1 - Double(y / (gy * 0.55))) * (0.3 + 0.3 * sin(t * 1.3 + Double(i) * 2.1))
            if a > 0 { ctx.fill(Path(CGRect(x: x, y: y, width: 1.6, height: 1.6)), with: .color(Color(red: 1, green: 246 / 255, blue: 220 / 255).opacity(a))) }
        }
        // The sun on the horizon, its glow and slow rays.
        let sx = W * 0.66, sy = gy - u * 0.05
        var glow = ctx
        glow.blendMode = .plusLighter
        for (rr, a) in [(u * 1.1, 0.12), (u * 0.55, 0.2), (u * 0.22, 0.35)] {
            glow.fill(Path(ellipseIn: CGRect(x: sx - rr, y: sy - rr, width: rr * 2, height: rr * 2)), with: .radialGradient(
                Gradient(colors: [Color(red: 1, green: 205 / 255, blue: 140 / 255).opacity(a), .clear]), center: CGPoint(x: sx, y: sy), startRadius: 0, endRadius: rr))
        }
        for i in 0..<11 {
            let a0 = -Double.pi * (0.1 + Double(i) * 0.074) + sin(t * 0.15 + Double(i)) * 0.02
            let w = 0.012 + Double(i % 3) * 0.008, len = u * (1.2 + CGFloat(i % 4) * 0.25)
            var ray = Path()
            ray.move(to: CGPoint(x: sx, y: sy))
            ray.addLine(to: CGPoint(x: sx + CGFloat(cos(a0 - w)) * len, y: sy + CGFloat(sin(a0 - w)) * len))
            ray.addLine(to: CGPoint(x: sx + CGFloat(cos(a0 + w)) * len, y: sy + CGFloat(sin(a0 + w)) * len))
            glow.fill(ray, with: .radialGradient(Gradient(colors: [Color(red: 1, green: 215 / 255, blue: 160 / 255).opacity(0.09), .clear]),
                                                 center: CGPoint(x: sx, y: sy), startRadius: 0, endRadius: len))
        }
        ScenePainter.ell(&ctx, sx, sy, u * 0.055, u * 0.055, hex("#fff2cc"))
        // Soft cloud bands.
        for i in 0..<6 {
            var r = Mulberry32(seed: UInt32(40 + i))
            let cx = CGFloat((r.next() * Double(W) * 1.3 + t * (3 + r.next() * 4)).truncatingRemainder(dividingBy: Double(W) * 1.3)) - W * 0.15
            let cy = gy * CGFloat(0.42 + r.next() * 0.3), w = u * CGFloat(0.5 + r.next() * 0.5)
            ctx.fill(Path(ellipseIn: CGRect(x: cx - w / 2, y: cy - w * 0.06, width: w, height: w * 0.12)), with: .radialGradient(
                Gradient(colors: [Color(red: 1, green: 190 / 255, blue: 150 / 255).opacity(0.28), .clear]), center: CGPoint(x: cx, y: cy), startRadius: 0, endRadius: w / 2))
        }
        // Balloons already up, drifting, hazier the further they are. v139: Cappadocia fills its sky at every depth in its own land.
        for i in 0..<(key == "mara" ? 17 : 11) where ["lux", "abq", "bri", "mara"].contains(key) { // v141: the Mara's dawn sky is full of balloons
            var r = Mulberry32(seed: UInt32(100 + i))
            let a = r.next(), d = r.next()
            let x = CGFloat((a * Double(W) * 1.4 + t * (3 + d * 9)).truncatingRemainder(dividingBy: Double(W) * 1.4)) - W * 0.2
            let y = max(H * 0.24, gy * CGFloat(0.24 + (1 - d) * 0.45)) + CGFloat(sin(t * 0.6 + Double(i))) * 4 + CGFloat(lift) * u * 0.25 * CGFloat(d)
            let c = cols[(i * 3) % 8]
            ScenePainter.balloon(&ctx, x: x, y: y, r: u * CGFloat(0.014 + d * 0.03),
                                 colors: [ScenePainter.mixHex(c, L.sky[3], (1 - d) * 0.55), ScenePainter.mixHex("#ffffff", L.sky[3], (1 - d) * 0.55)],
                                 burn: d > 0.7 && sin(t * 2 + Double(i)) > 0.6, alpha: 0.55 + d * 0.4, time: t)
        }
        // v138: the land, in backlit layers (`introLand`).
        let land = Land(W: W, H: H, gy: gy, u: u, t: t, lift: lift, L: L)
        switch key {
        case "lux": land.lux(&ctx)
        case "abq": land.abq(&ctx)
        case "bri": land.bri(&ctx)
        case "mara": land.mara(&ctx)
        default: land.cap(&ctx)
        }
        // The game's name in the sky. It stays put; the hero balloon, drawn after the scene, rises past it in front.
        // As the balloon comes closer the title falls back: a little smaller, softer and fainter, as if far behind.
        do {
            var title = ctx
            let ty = max(70, H * 0.14), fs = min(W * 0.13, 64), back = CGFloat(min(1, lift * 1.4))
            title.translateBy(x: W / 2, y: ty)
            title.scaleBy(x: 1 - back * 0.06, y: 1 - back * 0.06)
            title.translateBy(x: -W / 2, y: -ty)
            // v138: no blur and no shadow blur: a crisp drop shadow, and the region's name between two thin gold rules.
            title.opacity = Double(1 - back * 0.3)
            let font = Theme.font(fs, .heavy, condensed: true)
            title.draw(Text("BALLOON BARON").font(font).foregroundStyle(Color(red: 14 / 255, green: 6 / 255, blue: 30 / 255).opacity(0.38)),
                       at: CGPoint(x: W / 2, y: ty + fs * 0.045), anchor: .bottom)
            let gold = LinearGradient(stops: [.init(color: .white, location: 0), .init(color: hex("#fff1d0"), location: 0.6), .init(color: hex("#ffc23d"), location: 1)],
                                      startPoint: .top, endPoint: .bottom)
            title.draw(Text("BALLOON BARON").font(font).foregroundStyle(gold), at: CGPoint(x: W / 2, y: ty), anchor: .bottom)
            let ss = fs * 0.32, sp = fs * 0.12, sy2 = ty + fs * 0.52
            let name = title.resolve(Text(L.name).font(Theme.font(ss, .bold, condensed: true)).tracking(sp).foregroundStyle(hex("#ffcf7a")))
            let tw = max(0, name.measure(in: CGSize(width: W, height: 200)).width - sp)
            title.draw(name, at: CGPoint(x: W / 2 + sp / 2, y: sy2), anchor: .bottom)
            let rl = fs * 0.55, rg = fs * 0.22, ry = sy2 - ss * 0.36
            for side in [-1.0, 1.0] as [CGFloat] {
                let x0 = W / 2 + side * (tw / 2 + rg), x1 = x0 + side * rl
                title.fill(Path(CGRect(x: min(x0, x1), y: ry - 0.75, width: rl, height: 1.5)), with: .linearGradient(
                    Gradient(colors: [hex("#ffcf7a").opacity(0.85), hex("#ffcf7a").opacity(0)]), startPoint: CGPoint(x: x0, y: 0), endPoint: CGPoint(x: x1, y: 0)))
            }
        }
    }
}

/// v138 (developer): the title screen's landscape (`introLand`). The sun is behind everything, so the land is a set of
/// backlit silhouettes: darker the nearer, softer and warmer the further, a haze pooling between the layers, each layer
/// lit towards the sun and edged with a thin rim of light. The middle stays clear for the balloon.
private struct Land {
    let W: CGFloat, H: CGFloat, gy: CGFloat, u: CGFloat, t: Double, lift: Double, L: IntroScene.Look
    let sx: CGFloat, sun: String, haze: String, rimC: String, rw: CGFloat, step: CGFloat

    init(W: CGFloat, H: CGFloat, gy: CGFloat, u: CGFloat, t: Double, lift: Double, L: IntroScene.Look) {
        self.W = W; self.H = H; self.gy = gy; self.u = u; self.t = t; self.lift = lift; self.L = L
        sx = W * 0.66; sun = L.sky[4]; haze = ScenePainter.mixHex(L.sky[3], L.sky[4], 0.55)
        rimC = ScenePainter.mixHex(sun, "#ffffff", 0.45); rw = max(1, u * 0.0035); step = max(3, W / 180)
    }

    private func c(_ h: String, _ a: Double = 1) -> Color { Color(hex: h).opacity(a) }
    private func dc(_ k: Double) -> String { ScenePainter.mixHex(L.ink, haze, k) }
    private func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }
    private func wave(_ x: CGFloat, _ a: CGFloat, _ b: CGFloat, _ c: CGFloat) -> CGFloat { sin(x * a + c) * b }

    /// A horizontal light towards the sun: `c0` at the sides, `c1` at the sun.
    private func across(_ c0: Color, _ c1: Color) -> GraphicsContext.Shading {
        .linearGradient(Gradient(stops: [.init(color: c0, location: 0), .init(color: c1, location: 0.5), .init(color: c0, location: 1)]),
                        startPoint: pt(sx - W * 0.8, 0), endPoint: pt(sx + W * 0.8, 0))
    }
    private func lit(_ k: Double, _ glow: Double) -> GraphicsContext.Shading { across(c(dc(k)), ScenePainter.mix(dc(k), sun, glow)) }

    /// A silhouette at depth k (0 near, 1 far), lit towards the sun by `glow`, with a rim of light `rim` along its top.
    private func sil(_ ctx: inout GraphicsContext, _ k: Double, _ glow: Double, _ rim: Double, _ build: (inout Path) -> Void) {
        var p = Path()
        build(&p)
        if rim > 0 { ctx.fill(p.offsetBy(dx: 0, dy: -rw), with: across(c(rimC, rim * 0.2), c(rimC, rim))) }
        ctx.fill(p, with: lit(k, glow))
    }
    private func ridge(_ p: inout Path, bot: CGFloat, _ f: (CGFloat) -> CGFloat) {
        p.move(to: pt(-4, bot))
        var x: CGFloat = -4
        while x <= W + 8 { p.addLine(to: pt(x, f(x))); x += step }
        p.addLine(to: pt(W + 8, bot))
        p.closeSubpath()
    }
    private func hump(_ p: inout Path, _ x0: CGFloat, _ x1: CGFloat, _ b: CGFloat, _ hh: CGFloat) {
        p.move(to: pt(x0, b)); p.addQuadCurve(to: pt(x1, b), control: pt((x0 + x1) / 2, b - hh * 2)); p.closeSubpath()
    }
    private func circle(_ p: inout Path, _ x: CGFloat, _ y: CGFloat, _ r: CGFloat) { p.addEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)) }
    private func hazeBand(_ ctx: inout GraphicsContext, _ top: CGFloat, _ a: Double) {
        ctx.fill(Path(CGRect(x: 0, y: top, width: W, height: gy - top + 1)), with: .linearGradient(
            Gradient(colors: [c(haze, 0), c(haze, a)]), startPoint: pt(0, top), endPoint: pt(0, gy)))
    }
    private func soft(_ ctx: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ c0: Color, _ c1: Color) {
        var g = ctx
        g.translateBy(x: x, y: y)
        g.scaleBy(x: 1, y: 0.1)
        g.fill(Path(ellipseIn: CGRect(x: -r, y: -r, width: r * 2, height: r * 2)), with: .radialGradient(Gradient(colors: [c0, c1]), center: .zero, startRadius: 0, endRadius: r))
    }

    /// The launch field: warm where the sun skims it, darkening towards you, with long low swells.
    private func ground(_ ctx: inout GraphicsContext) {
        ctx.fill(Path(CGRect(x: 0, y: gy, width: W, height: H - gy)), with: .linearGradient(Gradient(stops: [
            .init(color: ScenePainter.mix(L.ground[0], haze, 0.3), location: 0), .init(color: ScenePainter.mix(L.ground[0], L.ink, 0.3), location: 0.3),
            .init(color: c(L.ground[1]), location: 1)]), startPoint: pt(0, gy), endPoint: pt(0, H)))
        for i in 0..<3 {
            let y0 = gy + (H - gy) * (0.16 + CGFloat(i) * 0.26), hh = (H - gy) * 0.07
            var p = Path()
            p.move(to: pt(-4, y0 + hh))
            p.addQuadCurve(to: pt(W + 4, y0 + hh * (i % 2 == 1 ? 0.2 : 1.4)), control: pt(W * (0.25 + CGFloat(i) * 0.25), y0 - hh))
            p.addLine(to: pt(W + 4, H)); p.addLine(to: pt(-4, H)); p.closeSubpath()
            ctx.fill(p, with: .color(c(L.ink, 0.1 + Double(i) * 0.04)))
        }
        soft(&ctx, sx, gy, W * 0.7, c(sun, 0.5), c(sun, 0))
    }
    /// Morning mist lying on the horizon.
    private func mist(_ ctx: inout GraphicsContext, _ a: Double) {
        ctx.fill(Path(CGRect(x: 0, y: gy - u * 0.05, width: W, height: u * 0.09)), with: .linearGradient(
            Gradient(stops: [.init(color: c(haze, 0), location: 0), .init(color: c(haze, a), location: 0.55), .init(color: c(haze, 0), location: 1)]),
            startPoint: pt(0, gy - u * 0.05), endPoint: pt(0, gy + u * 0.04)))
    }
    /// Flat-topped land with sloping shoulders: [x0, x1, height] in screen widths and u.
    private func tableland(_ x: CGFloat, base: CGFloat, _ list: [(CGFloat, CGFloat, CGFloat)], edge e: CGFloat, smooth: Bool) -> CGFloat {
        var hh = base
        for (a, b, m) in list {
            let x0 = W * a, x1 = W * b
            let k = x < x0 ? 1 - (x0 - x) / e : x > x1 ? 1 - (x - x1) / e : 1
            guard k > 0 else { continue }
            hh = max(hh, smooth ? u * m * (k >= 1 ? 1 : k * k * (3 - 2 * k)) : u * m * min(1, k * 1.6) - (k < 1 ? u * 0.01 * (1 - k) : 0))
        }
        return gy - hh
    }

    // MARK: Cappadocia (v139): the famous sunrise over Göreme, full of balloons

    /// v139 (developer): Cappadocia, the game's home. Erciyes's snows far off in the haze, the Uçhisar rock with its flag
    /// on the horizon, the Göreme rim with its banded tuff, a Love Valley field of slender chimneys, poplars, and near
    /// chimneys in cream, apricot and rose tuff, lit on the side facing the sun, with cave windows and doors cut into them.
    /// Vineyard rows and a track lead in to the balloon, and the sky is full of balloons at every depth.
    func cap(_ ctx: inout GraphicsContext) {
        let TUFF = "#dc9a7c", ROSE = "#c8787a", CREAM = "#f8dcb4", BASALT = "#4a2c36", POPLAR = "#56603a", ink = L.ink
        // A colour at depth k: near it is the rock's own shade, far it melts into the haze.
        func tone(_ base: String, _ k: Double) -> String { ScenePainter.mixHex(ScenePainter.mixHex(base, "#4e202e", 0.56 * (1 - k)), haze, k * 0.8) }
        let litC = ScenePainter.mixHex(sun, CREAM, 0.3)
        // A flat layer lit towards the sun, with a rim of light along its top.
        func layer(_ ctx: inout GraphicsContext, _ k: Double, _ base: String, _ glow: Double, _ rim: Double, _ build: (inout Path) -> Void) {
            var p = Path(); build(&p)
            if rim > 0 { ctx.fill(p.offsetBy(dx: 0, dy: -rw), with: across(c(rimC, rim * 0.2), c(rimC, rim))) }
            let col = tone(base, k)
            ctx.fill(p, with: across(c(col), ScenePainter.mix(col, sun, glow)))
        }
        // A rounded rock lit from its side facing the sun: shadow side, body, a warm lit flank and a rim of light.
        func solid(_ ctx: inout GraphicsContext, _ x: CGFloat, _ w: CGFloat, _ k: Double, _ base: String, _ glow: Double, _ rim: Double, _ build: (inout Path) -> Void) {
            var p = Path(); build(&p)
            let s: CGFloat = x < sx ? 1 : -1, col = tone(base, k), sh = ScenePainter.mixHex(col, ink, 0.42 * (1 - k)), lc = ScenePainter.mixHex(col, litC, glow)
            if rim > 0 { ctx.fill(p.offsetBy(dx: s * rw * 1.2, dy: -rw * 0.5), with: .color(c(rimC, rim * 0.75))) }
            ctx.fill(p, with: .linearGradient(Gradient(stops: [.init(color: c(sh), location: 0), .init(color: c(col), location: 0.5), .init(color: c(lc), location: 0.85),
                                                               .init(color: ScenePainter.mix(lc, rimC, 0.3), location: 1)]),
                                              startPoint: pt(x - s * w * 0.5, 0), endPoint: pt(x + s * w * 0.5, 0)))
        }
        // A fairy chimney's tuff cone, pinched under its cap or worn to a point.
        func cone(_ p: inout Path, _ x: CGFloat, _ b: CGFloat, _ h: CGFloat, _ w: CGFloat, _ capped: Bool) {
            let nw = capped ? w * 0.16 : w * 0.06, top = b - h * (capped ? 0.86 : 1)
            p.move(to: pt(x - w * 0.5, b))
            p.addCurve(to: pt(x - nw, top), control1: pt(x - w * 0.38, b - h * 0.32), control2: pt(x - nw * 1.8, top + h * 0.28))
            if capped { p.addLine(to: pt(x + nw, top)) } else { p.addQuadCurve(to: pt(x + nw, top), control: pt(x, top - h * 0.04)) }
            p.addCurve(to: pt(x + w * 0.5, b), control1: pt(x + nw * 1.8, top + h * 0.28), control2: pt(x + w * 0.38, b - h * 0.32))
            p.closeSubpath()
        }
        // The basalt cap: a flat, slightly tilted hat.
        func hat(_ p: inout Path, _ x: CGFloat, _ b: CGFloat, _ h: CGFloat, _ w: CGFloat) {
            let y0 = b - h * 0.86, cw = w * 0.3, ch = h * 0.12
            p.move(to: pt(x - cw, y0 + ch * 0.1))
            p.addQuadCurve(to: pt(x - cw * 0.35, y0 - ch), control: pt(x - cw * 1.08, y0 - ch * 0.55))
            p.addQuadCurve(to: pt(x + cw * 0.4, y0 - ch * 0.96), control: pt(x, y0 - ch * 1.12))
            p.addQuadCurve(to: pt(x + cw, y0 + ch * 0.1), control: pt(x + cw * 1.06, y0 - ch * 0.5))
            p.addQuadCurve(to: pt(x - cw, y0 + ch * 0.1), control: pt(x, y0 + ch * 0.32))
            p.closeSubpath()
        }
        func chimney(_ ctx: inout GraphicsContext, _ x: CGFloat, _ b: CGFloat, _ h: CGFloat, _ w: CGFloat, _ k: Double, _ capped: Bool, _ glow: Double, _ rim: Double, _ base: String = "#dc9a7c") {
            solid(&ctx, x, w, k, base, glow, rim) { cone(&$0, x, b, h, w, capped) }
            if capped { solid(&ctx, x, w * 0.6, k, BASALT, glow * 0.5, rim) { hat(&$0, x, b, h, w) } }
        }
        // The tuff's bands, inside a shape.
        func strata(_ ctx: inout GraphicsContext, _ top: CGFloat, _ bot: CGFloat, _ a: Double, _ build: (inout Path) -> Void) {
            var p = Path(); build(&p)
            var g = ctx
            g.clip(to: p)
            var y = bot, i = 0
            while y > top {
                g.fill(Path(CGRect(x: 0, y: y - u * 0.0022, width: W, height: u * 0.0022)), with: .color(i % 2 == 1 ? c(CREAM, a) : c(ink, a * 0.7)))
                y -= u * (0.007 + 0.005 * CGFloat((i * 7) % 3)); i += 1
            }
        }
        // Windows and doors cut in the rock: dark arches with a sill catching the light.
        func caves(_ ctx: inout GraphicsContext, _ list: [(CGFloat, CGFloat, CGFloat, Bool)], _ k: Double) {
            let dark = ScenePainter.mix(tone(TUFF, k), ink, 0.6)
            for (x, y, s, door) in list {
                let hh = s * (door ? 1.5 : 0.75)
                var p = Path()
                p.move(to: pt(x - s / 2, y)); p.addLine(to: pt(x - s / 2, y - hh + s / 2))
                p.addArc(center: pt(x, y - hh + s / 2), radius: s / 2, startAngle: .radians(.pi), endAngle: .radians(0), clockwise: false)
                p.addLine(to: pt(x + s / 2, y)); p.closeSubpath()
                ctx.fill(p, with: .color(dark))
                ctx.fill(Path(CGRect(x: x - s * 0.65, y: y, width: s * 1.3, height: max(1, s * 0.14))), with: .color(c(litC, 0.55)))
            }
        }
        // The balloons already up: (x, how high: 0 horizon, 1 top of the sky, depth: 0 far, 1 near).
        let cols = ["#ff5e3a", "#ffc23d", "#14a39a", "#9b7be0", "#5aa9e6", "#ff6fa8", "#22a45d", "#e5432f"]
        let ttop = max(70, H * 0.14) + min(W * 0.13, 64) * 0.75 + 10
        func skyB(_ ctx: inout GraphicsContext, _ list: [(CGFloat, CGFloat, CGFloat)], _ seed: Int) {
            for (i, (fx, f, d)) in list.enumerated() {
                let r = u * (0.0065 + pow(d, 1.4) * 0.036), drift = CGFloat(t) * u * (0.004 + d * 0.014) * (i % 2 == 1 ? 1 : 0.7)
                let x = (W * fx + drift).truncatingRemainder(dividingBy: W * 1.2) - W * 0.1
                let bob: CGFloat = CGFloat(sin(t * 0.5 + Double(i + seed))) * u * 0.004, rise: CGFloat = CGFloat(lift) * u * 0.25 * d
                let y: CGFloat = max(ttop + r * 2.6, gy - (gy - ttop) * f) + bob + rise
                let col = cols[(i * 3 + seed) % 8], hz = ScenePainter.mixHex(haze, L.sky[2], Double(f) * 0.7), k = Double(1 - d) * 0.72
                ScenePainter.balloon(&ctx, x: x, y: y, r: r, colors: [ScenePainter.mixHex(col, hz, k), ScenePainter.mixHex("#fff6e8", hz, k)],
                                     burn: d > 0.6 && sin(t * 1.8 + Double(i) * 2.3) > 0.55, alpha: Double(0.7 + d * 0.3), time: t)
            }
        }

        // Erciyes: a far volcano, broad-shouldered, its summit a little ragged and deep in snow.
        let X = W * 0.23
        func erc(_ x: CGFloat) -> CGFloat {
            let d = abs(x - X) / (u * 0.52), d2 = abs(x - X - u * 0.09) / (u * 0.2)
            let m1: CGFloat = d >= 1 ? 0 : u * 0.25 * pow(1 - d, 1.6), m2: CGFloat = d2 >= 1 ? 0 : u * 0.165 * pow(1 - d2, 1.5), m = max(m1, m2)
            guard m > u * 0.2 else { return m }
            return m - (m - u * 0.2) * 0.5 + u * 0.003 * sin((x - X) / u * 70)
        }
        func farY(_ x: CGFloat) -> CGFloat { gy - u * 0.05 - wave(x, 0.013, u * 0.012, 1) - wave(x, 0.041, u * 0.005, 0) - erc(x) }
        layer(&ctx, 0.86, "#8a6a9a", 0.22, 0.45) { ridge(&$0, bot: gy, farY) }
        // The snow above a snowline, pink in the dawn, running down in gullies, its west side in shade.
        do {
            let snowC = ScenePainter.mixHex("#ffffff", sun, 0.3)
            func line(_ x: CGFloat) -> CGFloat {
                let q: CGFloat = (x - X) / (u * 0.02) + 40, i = Int(floor(q)), f: CGFloat = q - CGFloat(i)
                let h: CGFloat = CGFloat((i * 7919) % 17) / 17, len: CGFloat = 0.006 + 0.055 * h * h
                let base: CGFloat = gy - u * 0.22 + u * 0.01 * sin((x - X) / u * 9)
                let tongue: CGFloat = pow(max(0, 1 - abs(f - 0.5) * 2), 1.6)
                return base + u * len * tongue
            }
            var mountain = Path(); ridge(&mountain, bot: gy, farY)
            var g = ctx
            g.clip(to: mountain)
            var snow = Path()
            snow.move(to: pt(X - u * 0.4, gy - u * 0.5))
            var x = X - u * 0.4
            while x <= X + u * 0.4 { snow.addLine(to: pt(x, line(x))); x += step / 3 }
            snow.addLine(to: pt(X + u * 0.4, gy - u * 0.5)); snow.closeSubpath()
            g.fill(snow, with: across(c(snowC, 0.82), c(snowC, 0.95)))
            g.clip(to: snow)
            g.fill(Path(CGRect(x: X - u * 0.4, y: gy - u * 0.5, width: u * 0.41, height: u * 0.5)), with: .linearGradient(
                Gradient(colors: [c("#8a6aa8", 0.38), c("#8a6aa8", 0)]), startPoint: pt(X - u * 0.14, 0), endPoint: pt(X + u * 0.01, 0)))
        }
        hazeBand(&ctx, gy - u * 0.24, 0.42)
        // The far balloons, tiny over other valleys; one hangs against the sun.
        skyB(&ctx, [(0.04, 0.12, 0.04), (0.1, 0.22, 0.1), (0.17, 0.09, 0), (0.23, 0.3, 0.14), (0.29, 0.16, 0.05), (0.36, 0.25, 0.12), (0.41, 0.1, 0.02),
                    (0.46, 0.34, 0.18), (0.52, 0.2, 0.08), (0.58, 0.13, 0.03), (0.72, 0.18, 0.06), (0.78, 0.28, 0.13), (0.84, 0.11, 0.02), (0.89, 0.21, 0.09),
                    (0.95, 0.32, 0.15), (0.62, 0.38, 0.2), (0.27, 0.42, 0.22), (0.08, 0.38, 0.2)], 1)
        ScenePainter.balloon(&ctx, x: sx + u * 0.035 + CGFloat(sin(t * 0.2)) * u * 0.004, y: gy - u * 0.1 + CGFloat(sin(t * 0.5)) * u * 0.003, r: u * 0.014,
                             colors: [ScenePainter.mixHex("#7a2a3a", sun, 0.2), ScenePainter.mixHex("#7a2a3a", sun, 0.45)], time: t)
        // Uçhisar: the castle rock over its village, the flag on top.
        let Ux = W * 0.345, Ub = gy - u * 0.03, Uw = u * 0.1, Uh = u * 0.13
        let UP: [(CGFloat, CGFloat)] = [(-1.3, 0), (-1, 0.1), (-0.75, 0.17), (-0.55, 0.24), (-0.44, 0.36), (-0.4, 0.55), (-0.34, 0.72), (-0.24, 0.84), (-0.14, 0.88),
                                        (-0.07, 0.97), (0.02, 1), (0.12, 0.96), (0.18, 0.9), (0.26, 0.92), (0.33, 0.82), (0.38, 0.66), (0.44, 0.46), (0.56, 0.3),
                                        (0.78, 0.2), (1.05, 0.12), (1.4, 0)]
        func uch(_ p: inout Path) {
            p.move(to: pt(Ux + UP[0].0 * Uw, Ub))
            for i in 1..<UP.count {
                let (a, b) = UP[i - 1], (cc, d) = UP[i]
                p.addQuadCurve(to: pt(Ux + (a + cc) / 2 * Uw, Ub - (b + d) / 2 * Uh), control: pt(Ux + a * Uw, Ub - b * Uh))
            }
            p.addLine(to: pt(Ux + 1.4 * Uw, Ub)); p.addLine(to: pt(Ux + 1.4 * Uw, gy)); p.addLine(to: pt(Ux - 1.3 * Uw, gy)); p.closeSubpath()
            // The village's houses stepping up its foot.
            for (hx, hy, hw) in [(-1.05, 0.07, 0.14), (-0.86, 0.12, 0.12), (-0.66, 0.18, 0.13), (-0.5, 0.25, 0.1), (0.5, 0.26, 0.11), (0.66, 0.2, 0.14), (0.86, 0.15, 0.12), (1.05, 0.08, 0.14)] as [(CGFloat, CGFloat, CGFloat)] {
                p.addRect(CGRect(x: Ux + hx * Uw - hw * Uw / 2, y: Ub - hy * Uh - u * 0.012, width: hw * Uw, height: u * 0.014))
            }
            p.addRect(CGRect(x: Ux - u * 0.0012, y: Ub - Uh - u * 0.028, width: u * 0.0024, height: u * 0.028))
        }
        // The valley rim: Göreme's tablelands with banded tuff.
        let mesas: [(CGFloat, CGFloat, CGFloat)] = [(-0.1, 0.12, 0.06), (0.42, 0.55, 0.045), (0.6, 0.78, 0.05), (0.86, 1.15, 0.085)]
        func rimY(_ x: CGFloat) -> CGFloat { tableland(x, base: u * 0.03 + wave(x, 0.02, u * 0.005, 2), mesas, edge: u * 0.045, smooth: true) }
        layer(&ctx, 0.6, ROSE, 0.32, 0.6) { p in ridge(&p, bot: gy, rimY); uch(&p) }
        strata(&ctx, gy - u * 0.1, gy, 0.07) { ridge(&$0, bot: gy, rimY) }
        // The castle's caves, and its flag.
        for (hx, hy) in [(-0.16, 0.74), (0.08, 0.7), (-0.24, 0.5), (0.02, 0.52), (0.22, 0.56), (-0.1, 0.34), (0.3, 0.38)] as [(CGFloat, CGFloat)] {
            ctx.fill(Path(ellipseIn: CGRect(x: Ux + hx * Uw - u * 0.0024, y: Ub - hy * Uh - u * 0.0034, width: u * 0.0048, height: u * 0.0068)),
                     with: .color(ScenePainter.mix(tone(ROSE, 0.6), ink, 0.35)))
        }
        do {
            let fx = Ux + u * 0.0012, fy = Ub - Uh - u * 0.028, fl = CGFloat(sin(t * 3)) * u * 0.0015
            var p = Path()
            p.move(to: pt(fx, fy)); p.addLine(to: pt(fx + u * 0.016, fy + fl)); p.addLine(to: pt(fx + u * 0.016, fy + u * 0.011 + fl)); p.addLine(to: pt(fx, fy + u * 0.011)); p.closeSubpath()
            ctx.fill(p, with: .color(ScenePainter.mix("#e30a17", haze, 0.25)))
        }
        hazeBand(&ctx, gy - u * 0.12, 0.34)
        // The Love Valley: a field of slender chimneys across the valley floor, poplars between them.
        do {
            var G = Mulberry32(seed: 77)
            let fb = gy - u * 0.006
            for i in 0..<26 {
                let x = W * (CGFloat(i) + CGFloat(G.next()) * 0.7) / 26
                let h = u * (0.022 + CGFloat(G.next()) * 0.045) * (abs(x - W * 0.5) < W * 0.12 ? 0.7 : 1)
                let w = h * (0.3 + CGFloat(G.next()) * 0.12), b = fb + u * 0.004 * CGFloat(G.next()), capped = G.next() > 0.35
                chimney(&ctx, x, b, h, w, 0.5, capped, 0.35, 0.45, i % 3 == 0 ? ROSE : TUFF)
            }
            for (px, ph) in [(0.38, 0.05), (0.4, 0.065), (0.42, 0.045), (0.58, 0.055), (0.6, 0.07), (0.625, 0.05), (0.68, 0.045)] as [(CGFloat, CGFloat)] {
                let x = W * px, h = u * ph, b = gy - u * 0.002
                solid(&ctx, x, h * 0.3, 0.48, POPLAR, 0.35, 0.4) { p in
                    p.move(to: pt(x, b - h)); p.addQuadCurve(to: pt(x + h * 0.06, b - h * 0.08), control: pt(x + h * 0.17, b - h * 0.55))
                    p.addLine(to: pt(x - h * 0.06, b - h * 0.08)); p.addQuadCurve(to: pt(x, b - h), control: pt(x - h * 0.17, b - h * 0.55)); p.closeSubpath()
                    p.addRect(CGRect(x: x - h * 0.012, y: b - h * 0.1, width: h * 0.024, height: h * 0.1))
                }
            }
        }
        // Balloons rising from the valley, some still behind the chimneys.
        skyB(&ctx, [(0.12, 0.1, 0.32), (0.33, 0.06, 0.3), (0.67, 0.08, 0.34), (0.86, 0.14, 0.38), (0.5, 0.48, 0.4), (0.2, 0.52, 0.42), (0.75, 0.56, 0.46),
                    (0.94, 0.5, 0.44), (0.42, 0.62, 0.38)], 3)
        hazeBand(&ctx, gy - u * 0.08, 0.18)
        // Chimneys at middle distance, in clusters left and right.
        do {
            let b1 = gy + u * 0.006
            layer(&ctx, 0.36, ROSE, 0.3, 0.55) { p in hump(&p, -W * 0.05, W * 0.38, b1, u * 0.02); hump(&p, W * 0.62, W * 1.05, b1, u * 0.018) }
            for (x, h, cpd, base) in [(0.24, 0.14, true, TUFF), (0.3, 0.09, false, ROSE), (0.35, 0.06, true, TUFF), (0.04, 0.1, false, ROSE), (0.16, 0.12, true, ROSE),
                                      (0.66, 0.08, true, TUFF), (0.71, 0.13, true, ROSE), (0.76, 0.09, false, TUFF), (0.8, 0.16, true, TUFF), (0.97, 0.11, true, ROSE)] as [(CGFloat, CGFloat, Bool, String)] {
                chimney(&ctx, W * x, b1 - u * 0.008, u * h, u * h * 0.36, 0.34, cpd, 0.45, 0.7, base)
            }
        }
        hazeBand(&ctx, gy - u * 0.04, 0.22)
        ground(&ctx); mist(&ctx, 0.26)
        // Vineyard rows and a track leading in to the balloon.
        do {
            let vy = gy - u * 0.03, y0 = gy + u * 0.012, y1 = gy + (H - gy) * 0.24
            for i in -16...16 where abs(i) >= 3 {
                let bx = W * 0.5 + CGFloat(i) * W * 0.07
                var p = Path()
                let fx: CGFloat = W * 0.5 + (bx - W * 0.5) * (y0 - vy) / (y1 - vy)
                p.move(to: pt(fx, y0)); p.addLine(to: pt(bx, y1))
                ctx.stroke(p, with: .linearGradient(Gradient(colors: [c(ink, 0), c(ink, 0.2)]), startPoint: pt(0, y0), endPoint: pt(0, y1)),
                           style: StrokeStyle(lineWidth: max(1.2, u * 0.005), lineCap: .round, dash: [max(1, u * 0.004), max(1.5, u * 0.006)]))
            }
            var tr = Path()
            tr.move(to: pt(W * 0.494, gy + u * 0.006))
            tr.addCurve(to: pt(W * 0.1, H + 2), control1: pt(W * 0.46, gy + (H - gy) * 0.2), control2: pt(W * 0.24, gy + (H - gy) * 0.35))
            tr.addLine(to: pt(W * 0.1 + u * 0.07, H + 2))
            tr.addCurve(to: pt(W * 0.506, gy + u * 0.006), control1: pt(W * 0.3, gy + (H - gy) * 0.36), control2: pt(W * 0.5, gy + (H - gy) * 0.2))
            tr.closeSubpath()
            ctx.fill(tr, with: .linearGradient(Gradient(stops: [.init(color: c(litC, 0.5), location: 0), .init(color: c(litC, 0.14), location: 0.5), .init(color: c(litC, 0.04), location: 1)]),
                                               startPoint: pt(0, gy), endPoint: pt(0, H)))
        }
        // The nearest chimneys frame the edges, cave windows and doors cut in them.
        do {
            let b0 = gy + u * 0.03
            layer(&ctx, 0.12, TUFF, 0.25, 0.7) { p in hump(&p, -W * 0.2, W * 0.26, b0, u * 0.045); hump(&p, W * 0.74, W * 1.2, b0, u * 0.042) }
            let lx = W * 0.035
            chimney(&ctx, lx, b0 - u * 0.015, u * 0.36, u * 0.15, 0.1, true, 0.55, 0.8)
            strata(&ctx, b0 - u * 0.36, b0, 0.05) { cone(&$0, lx, b0 - u * 0.015, u * 0.36, u * 0.15, true) }
            caves(&ctx, [(lx + u * 0.02, b0 - u * 0.03, u * 0.024, true), (lx - u * 0.01, b0 - u * 0.13, u * 0.012, false), (lx + u * 0.024, b0 - u * 0.16, u * 0.011, false)], 0.1)
            chimney(&ctx, W * 0.15, b0 - u * 0.012, u * 0.24, u * 0.1, 0.12, true, 0.55, 0.8, ROSE)
            chimney(&ctx, W * 0.23, b0 - u * 0.005, u * 0.12, u * 0.055, 0.16, true, 0.5, 0.7)
            let R0 = W * 0.94, Rh = u * 0.3, Rw = u * 0.2
            solid(&ctx, R0, Rw, 0.1, TUFF, 0.55, 0.8) { cone(&$0, R0, b0, Rh, Rw, false) }
            strata(&ctx, b0 - Rh, b0, 0.05) { cone(&$0, R0, b0, Rh, Rw, false) }
            caves(&ctx, [(R0 - Rw * 0.12, b0 - u * 0.022, u * 0.026, true), (R0 - Rw * 0.22, b0 - Rh * 0.42, u * 0.013, false),
                         (R0 + Rw * 0.02, b0 - Rh * 0.47, u * 0.012, false), (R0 - Rw * 0.1, b0 - Rh * 0.68, u * 0.011, false)], 0.1)
            chimney(&ctx, W * 0.81, b0 - u * 0.012, u * 0.17, u * 0.07, 0.13, true, 0.55, 0.8, ROSE)
            chimney(&ctx, W * 0.75, b0 - u * 0.004, u * 0.09, u * 0.045, 0.17, false, 0.5, 0.7)
        }
        // The near balloons, high and crisp.
        skyB(&ctx, [(0.13, 0.8, 0.72), (0.82, 0.74, 0.78), (0.36, 0.92, 0.6), (0.64, 0.95, 0.66), (0.97, 0.9, 0.9), (0.05, 0.62, 0.62)], 5)
    }

    // MARK: Luxor: the Theban hills across the Nile, a pylon, an obelisk, a colonnade, date palms

    func lux(_ ctx: inout GraphicsContext) {
        let Q = W * 0.3
        func qurn(_ x: CGFloat) -> CGFloat { let d = abs(x - Q) / (u * 0.4); return d >= 1 ? 0 : u * 0.12 * pow(1 - d, 1.25) }
        sil(&ctx, 0.82, 0.25, 0.45) { p in
            ridge(&p, bot: gy) { x in gy - u * 0.075 - wave(x, 0.011, u * 0.012, 2) - wave(x, 0.033, u * 0.005, 0) - qurn(x) - max(0, u * 0.035 - abs(x - W * 0.08) * 0.3) }
        }
        hazeBand(&ctx, gy - u * 0.22, 0.45)
        // The west bank, a line of tiny palms on it.
        let nTop = gy - u * 0.062, nBot = gy - u * 0.036
        let bankPalms: [(CGFloat, CGFloat, CGFloat)] = (0..<16).compactMap { i in
            let x = W * (CGFloat(i) + 0.5) / 16 + sin(CGFloat(i) * 7.3) * W * 0.02
            return abs(x - sx) < W * 0.07 ? nil : (x, u * (0.022 + 0.01 * CGFloat((i * 5) % 3) / 2), i % 2 == 1 ? 0.12 : -0.1)
        }
        sil(&ctx, 0.62, 0.3, 0.4) { p in
            p.move(to: pt(-4, gy)); p.addLine(to: pt(-4, nTop - u * 0.006))
            var x: CGFloat = 0
            while x <= W + 8 { p.addLine(to: pt(x, nTop - u * 0.006 - wave(x, 0.05, u * 0.002, 0))); x += step }
            p.addLine(to: pt(W + 8, gy)); p.closeSubpath()
            for (x, h, lean) in bankPalms { Land.palm(&p, x, nTop - u * 0.004, h, lean, full: false, strokes: false) }
        }
        var leaflets = Path()
        for (x, h, lean) in bankPalms { Land.palm(&leaflets, x, nTop - u * 0.004, h, lean, full: false, strokes: true) }
        ctx.stroke(leaflets, with: lit(0.62, 0.3), style: StrokeStyle(lineWidth: max(0.6, u * 0.0012), lineCap: .round))
        // The Nile: the sky in it, the sun's path glittering across.
        ctx.fill(Path(CGRect(x: 0, y: nTop, width: W, height: nBot - nTop + 1)), with: .linearGradient(
            Gradient(colors: [ScenePainter.mix(L.sky[3], haze, 0.4), ScenePainter.mix(L.sky[2], L.ink, 0.2)]), startPoint: pt(0, nTop), endPoint: pt(0, nBot)))
        do {
            var g = ctx
            g.blendMode = .plusLighter
            g.fill(Path(CGRect(x: sx - u * 0.2, y: nTop, width: u * 0.4, height: nBot - nTop)), with: .linearGradient(
                Gradient(stops: [.init(color: c(sun, 0), location: 0), .init(color: c(sun, 0.6), location: 0.5), .init(color: c(sun, 0), location: 1)]),
                startPoint: pt(sx - u * 0.2, 0), endPoint: pt(sx + u * 0.2, 0)))
            var G = Mulberry32(seed: 5)
            for i in 0..<26 {
                let yy = nTop + CGFloat(G.next()) * (nBot - nTop), spread = u * (0.04 + (yy - nTop) / (nBot - nTop) * 0.12)
                let xx = sx + CGFloat(G.next() - 0.5) * 2 * spread, a = 0.5 + 0.5 * sin(t * 2.4 + Double(i) * 1.9)
                if a < 0.25 { continue }
                let k = CGFloat(a)
                g.fill(Path(CGRect(x: xx - u * 0.012 * k, y: yy, width: u * 0.024 * k, height: max(1, u * 0.0028))), with: .color(c("#fff4d6", 0.8 * a)))
            }
        }
        // A felucca sailing down the river.
        do {
            let fx = W * 0.47 - CGFloat((t * Double(u) * 0.003).truncatingRemainder(dividingBy: Double(W) * 0.08)), fy = nTop + (nBot - nTop) * 0.55, fs = u * 0.055
            sil(&ctx, 0.38, 0.3, 0.6) { p in
                p.move(to: pt(fx - fs * 0.35, fy - fs * 0.06)); p.addQuadCurve(to: pt(fx + fs * 0.4, fy - fs * 0.08), control: pt(fx, fy + fs * 0.1))
                p.addLine(to: pt(fx + fs * 0.3, fy - fs * 0.1)); p.closeSubpath()
                p.move(to: pt(fx - fs * 0.02, fy - fs * 0.1)); p.addLine(to: pt(fx + fs * 0.04, fy - fs * 0.1)); p.addLine(to: pt(fx + fs * 0.02, fy - fs * 0.85)); p.closeSubpath()
                p.move(to: pt(fx - fs * 0.4, fy - fs * 0.2)); p.addLine(to: pt(fx + fs * 0.1, fy - fs * 1.05))
                p.addQuadCurve(to: pt(fx + fs * 0.02, fy - fs * 0.14), control: pt(fx + fs * 0.2, fy - fs * 0.5)); p.closeSubpath()
            }
        }
        // The east bank.
        sil(&ctx, 0.42, 0.3, 0.5) { p in
            p.move(to: pt(-4, gy + 2)); p.addLine(to: pt(-4, nBot))
            var x: CGFloat = 0
            while x <= W + 8 { p.addLine(to: pt(x, nBot + wave(x, 0.03, u * 0.002, 1))); x += step }
            p.addLine(to: pt(W + 8, gy + 2)); p.closeSubpath()
        }
        hazeBand(&ctx, gy - u * 0.1, 0.22)
        // The temple: a pylon with its gate, an obelisk, a colonnade with papyrus capitals.
        let b = gy - u * 0.004, P = W * 0.19, tw = u * 0.125, th = u * 0.17, gap = u * 0.045
        sil(&ctx, 0.26, 0.32, 0.8) { p in
            for s in [-1.0, 1.0] as [CGFloat] {
                let ix = P + s * gap / 2, ox = P + s * (gap / 2 + tw)
                p.move(to: pt(ix, b)); p.addLine(to: pt(ox, b)); p.addLine(to: pt(ox - s * u * 0.014, b - th)); p.addLine(to: pt(ox - s * u * 0.008, b - th))
                p.addLine(to: pt(ox - s * u * 0.008, b - th - u * 0.012)); p.addLine(to: pt(ix + s * u * 0.004, b - th - u * 0.012))
                p.addLine(to: pt(ix + s * u * 0.004, b - th)); p.addLine(to: pt(ix + s * u * 0.008, b - th)); p.closeSubpath()
            }
            p.addRect(CGRect(x: P - gap / 2 - 1, y: b - th * 0.66, width: gap + 2, height: th * 0.66)) // the gate's lintel block
            let ox = W * 0.36, ow = u * 0.024, oh = u * 0.2
            p.move(to: pt(ox - ow / 2, b)); p.addLine(to: pt(ox - ow * 0.32, b - oh)); p.addLine(to: pt(ox, b - oh - u * 0.022))
            p.addLine(to: pt(ox + ow * 0.32, b - oh)); p.addLine(to: pt(ox + ow / 2, b)); p.closeSubpath()
            p.addRect(CGRect(x: W * 0.02, y: b - u * 0.012, width: W * 0.38, height: u * 0.012))
            let c0 = W * 0.61, c1 = W * 0.97, n = 6, cw = u * 0.024, ch = u * 0.14
            for i in 0..<n {
                let cx = c0 + (c1 - c0) * CGFloat(i) / CGFloat(n - 1), top = b - ch * (i == n - 1 ? 0.72 : 1)
                p.move(to: pt(cx - cw * 0.55, b)); p.addLine(to: pt(cx - cw * 0.5, top + u * 0.022))
                p.addQuadCurve(to: pt(cx - cw * 0.9, top), control: pt(cx - cw * 0.95, top + u * 0.01)); p.addLine(to: pt(cx + cw * 0.9, top))
                p.addQuadCurve(to: pt(cx + cw * 0.5, top + u * 0.022), control: pt(cx + cw * 0.95, top + u * 0.01)); p.addLine(to: pt(cx + cw * 0.55, b)); p.closeSubpath()
            }
            p.addRect(CGRect(x: c0 - cw, y: b - ch - u * 0.02, width: (c1 - c0) * 0.8 + cw * 2, height: u * 0.02))
            p.addRect(CGRect(x: c0 - cw * 1.4, y: b - u * 0.01, width: c1 - c0 + cw * 2.8, height: u * 0.01))
        }
        // The flagpole recesses in the pylon's face, and the gate's opening showing the light behind.
        for s in [-1.0, 1.0] as [CGFloat] {
            for f in [0.3, 0.62] as [CGFloat] {
                let fx = P + s * (gap / 2 + tw * f)
                ctx.fill(Path(CGRect(x: fx - u * 0.004, y: b - th * 0.92, width: u * 0.008, height: th * 0.92)), with: .color(ScenePainter.mix(dc(0.26), L.ink, 0.25)))
            }
        }
        ctx.fill(Path(CGRect(x: P - gap * 0.3, y: b - th * 0.5, width: gap * 0.6, height: th * 0.5)), with: .color(ScenePainter.mix(dc(0.26), sun, 0.25)))
        ground(&ctx); mist(&ctx, 0.22)
        // Date palms frame the edges.
        let palms: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [(0.05, 0.01, 0.4, 0.14), (0.17, 0.015, 0.27, -0.12), (0.95, 0.01, 0.35, -0.16), (0.85, 0.02, 0.21, 0.08)]
        sil(&ctx, 0.05, 0.16, 0.85) { p in
            hump(&p, -W * 0.2, W * 0.26, gy + u * 0.035, u * 0.04); hump(&p, W * 0.76, W * 1.2, gy + u * 0.035, u * 0.035)
            for (x, by, hh, ln) in palms { Land.palm(&p, W * x, gy + u * by, u * hh, ln, full: true, strokes: false) }
        }
        for (x, by, hh, ln) in palms {
            var p = Path()
            Land.palm(&p, W * x, gy + u * by, u * hh, ln, full: true, strokes: true)
            ctx.stroke(p, with: lit(0.05, 0.16), style: StrokeStyle(lineWidth: max(0.8, u * hh * 0.0075), lineCap: .round))
        }
    }

    // MARK: Albuquerque: the Sandias, mesas, the Fiesta's balloons, yuccas

    func abq(_ ctx: inout GraphicsContext) {
        func crest(_ x: CGFloat) -> CGFloat { let p = W * 0.36; return x < p ? u * (0.1 + 0.065 * pow(max(0, x) / p, 0.7)) : u * max(0.035, 0.165 - (x - p) / W * 0.2) }
        func farY(_ x: CGFloat) -> CGFloat { gy - u * 0.035 - crest(x) - wave(x, 0.09, u * 0.004, 0) - wave(x, 0.23, u * 0.0025, 1) }
        sil(&ctx, 0.78, 0.3, 0.55) { ridge(&$0, bot: gy, farY) }
        // The Sandias' west face goes pink at dawn ("sandía": watermelon).
        do {
            var range = Path()
            ridge(&range, bot: gy, farY)
            var g = ctx
            g.clip(to: range)
            g.fill(Path(CGRect(x: 0, y: gy - u * 0.22, width: W, height: u * 0.22)), with: .linearGradient(
                Gradient(colors: [c("#ff7a8a", 0.22), c("#ff7a8a", 0)]), startPoint: pt(0, gy - u * 0.2), endPoint: pt(0, gy)))
        }
        hazeBand(&ctx, gy - u * 0.22, 0.42)
        let mesas: [(CGFloat, CGFloat, CGFloat)] = [(0.05, 0.2, 0.055), (0.55, 0.86, 0.075), (0.9, 1.1, 0.05)]
        sil(&ctx, 0.54, 0.32, 0.6) { p in ridge(&p, bot: gy) { x in tableland(x, base: u * 0.025 + wave(x, 0.017, u * 0.005, 3), mesas, edge: u * 0.035, smooth: false) } }
        hazeBand(&ctx, gy - u * 0.12, 0.3)
        // The Fiesta's mass ascension, low over the field.
        let cols = ["#ff5e3a", "#ffc23d", "#14a39a", "#9b7be0", "#5aa9e6", "#ff6fa8", "#22a45d", "#e5432f"]
        for i in 0..<12 {
            var G = Mulberry32(seed: UInt32(300 + i))
            let x = W * (0.04 + 0.92 * (CGFloat(i) + CGFloat(G.next()) * 0.6) / 12), d = G.next()
            if abs(x - W * 0.5) < u * 0.1 { continue }
            let y = gy - u * CGFloat(0.05 + d * 0.09) + CGFloat(sin(t * 0.7 + Double(i))) * 2, col = cols[(i * 5 + 1) % 8]
            ScenePainter.balloon(&ctx, x: x, y: y, r: u * CGFloat(0.012 + (1 - d) * 0.012),
                                 colors: [ScenePainter.mixHex(col, haze, 0.3 + d * 0.3), ScenePainter.mixHex("#ffffff", haze, 0.3 + d * 0.3)],
                                 burn: sin(t * 1.7 + Double(i) * 2) > 0.7, alpha: 0.95, time: t)
        }
        ground(&ctx); mist(&ctx, 0.25)
        // Yuccas and low desert scrub frame the edges.
        func yucca(_ p: inout Path, _ x: CGFloat, _ b: CGFloat, _ h: CGFloat) {
            for i in 0..<15 {
                let a = -CGFloat.pi * (0.06 + 0.88 * CGFloat(i) / 14), l = h * (0.24 + 0.08 * sin(CGFloat(i) * 2.7)), by = b - h * 0.06
                let ex = x + cos(a) * l, ey = by + sin(a) * l * 0.9, nx = -sin(a) * h * 0.018, ny = cos(a) * h * 0.018
                p.move(to: pt(x - nx, by - ny)); p.addLine(to: pt(ex, ey)); p.addLine(to: pt(x + nx, by + ny)); p.closeSubpath()
            }
            p.move(to: pt(x - h * 0.012, b - h * 0.2)); p.addQuadCurve(to: pt(x + h * 0.045, b - h), control: pt(x + h * 0.02, b - h * 0.6))
            p.addLine(to: pt(x + h * 0.055, b - h * 0.99)); p.addQuadCurve(to: pt(x + h * 0.012, b - h * 0.2), control: pt(x + h * 0.035, b - h * 0.6)); p.closeSubpath()
            for j in 0..<12 {
                let k = 0.64 + CGFloat(j) * 0.029, px = x + h * (0.012 + 0.045 * k), py = b - h * k, s: CGFloat = j % 2 == 1 ? 1 : -1, r = h * (0.016 - CGFloat(j) * 0.0008)
                p.move(to: pt(px, py)); p.addLine(to: pt(px + s * h * 0.03, py + h * 0.008))
                p.addEllipse(in: CGRect(x: px + s * h * 0.034 - r, y: py + h * 0.016 - r * 1.3, width: r * 2, height: r * 2.6))
            }
        }
        sil(&ctx, 0.05, 0.18, 0.85) { p in
            hump(&p, -W * 0.25, W * 0.32, gy + u * 0.035, u * 0.035); hump(&p, W * 0.7, W * 1.25, gy + u * 0.035, u * 0.03)
            for (x, s) in [(0.03, 0.9), (0.2, 0.55), (0.83, 0.45), (0.95, 0.7)] as [(CGFloat, CGFloat)] { hump(&p, W * x - u * 0.08 * s, W * x + u * 0.08 * s, gy + u * 0.006, u * 0.03 * s) }
            yucca(&p, W * 0.09, gy + u * 0.005, u * 0.3); yucca(&p, W * 0.91, gy + u * 0.005, u * 0.26); yucca(&p, W * 0.22, gy + u * 0.012, u * 0.15)
        }
    }

    // MARK: Bristol: Clifton and Cabot Tower, the Suspension Bridge over the Avon Gorge, fog, oaks

    // MARK: Maasai Mara (v141)

    /// v141: the Maasai Mara at sunrise: the long flat wall of the Oloololo escarpment far off, soft hills in the haze,
    /// the plains running out to the sun, a line of wildebeest crossing and two giraffes against the light, flat-topped
    /// acacias framing the field, the dry grass catching the rim of the sun.
    func mara(_ ctx: inout GraphicsContext) {
        func acac(_ p: inout Path, _ x: CGFloat, _ b: CGFloat, _ h: CGFloat, _ lean: CGFloat = 0) {
            p.move(to: pt(x - h * 0.025, b)); p.addLine(to: pt(x - h * 0.018 + lean * h * 0.05, b - h * 0.5)); p.addLine(to: pt(x - h * 0.3, b - h * 0.78))
            p.addLine(to: pt(x - h * 0.27, b - h * 0.8)); p.addLine(to: pt(x + lean * h * 0.05, b - h * 0.58)); p.addLine(to: pt(x + h * 0.26, b - h * 0.82))
            p.addLine(to: pt(x + h * 0.29, b - h * 0.8)); p.addLine(to: pt(x + h * 0.025 + lean * h * 0.05, b - h * 0.5)); p.addLine(to: pt(x + h * 0.025, b)); p.closeSubpath()
            for (dx, dy, rx, ry) in [(0.0, 0.84, 0.62, 0.07), (-0.3, 0.87, 0.34, 0.055), (0.28, 0.88, 0.36, 0.055), (-0.05, 0.92, 0.4, 0.05)] as [(CGFloat, CGFloat, CGFloat, CGFloat)] {
                p.addEllipse(in: CGRect(x: x + h * dx - h * rx, y: b - h * dy - h * ry, width: h * rx * 2, height: h * ry * 2))
            }
        }
        func esc(_ x: CGFloat) -> CGFloat { let k = min(max((W * 0.62 - x) / (W * 0.22), 0), 1); return gy - u * (0.03 + 0.1 * (k * k * (3 - 2 * k))) - wave(x, 0.02, u * 0.003, 1) }
        sil(&ctx, 0.86, 0.15, 0.3) { p in ridge(&p, bot: gy) { x in gy - u * 0.05 - wave(x, 0.006, u * 0.025, 2) - wave(x, 0.017, u * 0.01, 0) } }
        hazeBand(&ctx, gy - u * 0.16, 0.45)
        sil(&ctx, 0.68, 0.22, 0.5) { p in ridge(&p, bot: gy, esc) }
        hazeBand(&ctx, gy - u * 0.08, 0.4)
        sil(&ctx, 0.5, 0.25, 0.45) { p in
            var r = Mulberry32(seed: 41)
            for _ in 0..<16 {
                let x = CGFloat(r.next()) * W, h = u * CGFloat(0.03 + r.next() * 0.025)
                if abs(x - W * 0.5) < u * 0.1 { continue }
                acac(&p, x, gy - u * 0.012, h)
            }
        }
        sil(&ctx, 0.3, 0.25, 0.6) { p in
            for i in 0..<26 { // wildebeest in a long line, heads down
                let fi = CGFloat(i), step = W * 0.021
                let x = W * 0.04 + fi * step + CGFloat(sin(Double(i) * 2.3)) * u * 0.006 + CGFloat((t * Double(u) * 0.004).truncatingRemainder(dividingBy: Double(step)))
                let b = gy - u * (0.004 + 0.003 * CGFloat(sin(Double(i)))), s = u * (0.007 + 0.002 * CGFloat(i % 3))
                if abs(x - W * 0.5) < u * 0.05 { continue }
                p.addEllipse(in: CGRect(x: x - s * 1.4, y: b - s * 1.8, width: s * 2.8, height: s * 1.4))
                p.addRect(CGRect(x: x - s * 1.1, y: b - s * 0.6, width: s * 0.28, height: s * 0.6)); p.addRect(CGRect(x: x + s * 0.8, y: b - s * 0.6, width: s * 0.28, height: s * 0.6))
                p.move(to: pt(x + s * 1.1, b - s * 1.5)); p.addLine(to: pt(x + s * 2.1, b - s * 0.7)); p.addLine(to: pt(x + s * 1.7, b - s * 0.4)); p.addLine(to: pt(x + s * 0.8, b - s * 0.9)); p.closeSubpath()
            }
            for (x, s) in [(W * 0.78, u * 0.05), (W * 0.84, u * 0.042)] { // two giraffes against the sun
                let b = gy - u * 0.004
                for dx: CGFloat in [-0.3, -0.12, 0.14, 0.3] { p.addRect(CGRect(x: x + s * dx, y: b - s * 0.9, width: s * 0.06, height: s * 0.9)) }
                p.addEllipse(in: CGRect(x: x - s * 0.42, y: b - s * 1.18, width: s * 0.84, height: s * 0.36))
                p.move(to: pt(x + s * 0.2, b - s * 1.1)); p.addLine(to: pt(x + s * 0.52, b - s * 2)); p.addLine(to: pt(x + s * 0.66, b - s * 1.96)); p.addLine(to: pt(x + s * 0.4, b - s * 1)); p.closeSubpath()
                p.addEllipse(in: CGRect(x: x + s * 0.5, y: b - s * 2.09, width: s * 0.28, height: s * 0.14))
            }
        }
        hazeBand(&ctx, gy - u * 0.03, 0.25)
        ground(&ctx); mist(&ctx, 0.3)
        // tufts of dry grass on the near field, lit by the low sun
        var tufts = Path()
        var r = Mulberry32(seed: 17)
        for _ in 0..<90 {
            let x = CGFloat(r.next()) * W, b = gy + (H - gy) * CGFloat(0.08 + r.next() * 0.5), hh = u * CGFloat(0.012 + r.next() * 0.02)
            if abs(x - W / 2) < u * 0.14 && b < gy + (H - gy) * 0.3 { continue }
            for d: CGFloat in [-1, 0, 1] { tufts.move(to: pt(x + d * hh * 0.2, b)); tufts.addLine(to: pt(x + d * hh * 0.45, b - hh)) }
        }
        ctx.stroke(tufts, with: across(c(ScenePainter.mixHex(L.ground[0], L.ink, 0.2), 0.7), c(ScenePainter.mixHex(sun, "#ffffff", 0.2), 0.55)), lineWidth: max(1, u * 0.0022))
        // the big acacias framing the field, near and dark
        sil(&ctx, 0.1, 0.18, 0.85) { p in acac(&p, W * 0.08, gy + u * 0.03, u * 0.34, -0.2); acac(&p, W * 0.97, gy + u * 0.025, u * 0.26, 0.2); acac(&p, W * 0.24, gy + u * 0.006, u * 0.13) }
    }

    func bri(_ ctx: inout GraphicsContext) {
        sil(&ctx, 0.82, 0.2, 0.35) { p in ridge(&p, bot: gy) { x in gy - u * 0.075 - wave(x, 0.008, u * 0.025, 1) - wave(x, 0.021, u * 0.012, 0) } }
        hazeBand(&ctx, gy - u * 0.2, 0.5)
        // Clifton on its hill: a roofline of terraces, Cabot Tower.
        func cY(_ x: CGFloat) -> CGFloat { gy - u * (0.03 + 0.06 * max(0, 1 - pow((x - W * 0.16) / (W * 0.36), 2))) }
        sil(&ctx, 0.6, 0.25, 0.45) { p in
            ridge(&p, bot: gy) { x in cY(x) - (x < W * 0.4 ? (Int(floor(x / (u * 0.018))) % 3 == 0 ? u * 0.004 : u * 0.009) : 0) }
            let cx = W * 0.21, cb = cY(cx) - u * 0.006
            p.addRect(CGRect(x: cx - u * 0.009, y: cb - u * 0.07, width: u * 0.018, height: u * 0.07))
            p.move(to: pt(cx - u * 0.012, cb - u * 0.07)); p.addLine(to: pt(cx, cb - u * 0.1)); p.addLine(to: pt(cx + u * 0.012, cb - u * 0.07)); p.closeSubpath()
        }
        hazeBand(&ctx, gy - u * 0.12, 0.35)
        // The Avon Gorge and the bridge across it.
        let deck = gy - u * 0.125, L0 = W * 0.6, L1 = W * 0.92, tw = u * 0.03, th = u * 0.085
        sil(&ctx, 0.36, 0.3, 0.7) { p in
            p.move(to: pt(W * 0.4, gy + 2)); p.addQuadCurve(to: pt(L0 - tw, deck), control: pt(W * 0.48, deck - u * 0.002)); p.addLine(to: pt(L0 + tw * 0.3, deck))
            p.addQuadCurve(to: pt(L0 + u * 0.045, gy - u * 0.01), control: pt(L0 + u * 0.02, deck + u * 0.05)); p.addLine(to: pt(L0 + u * 0.06, gy + 2)); p.closeSubpath()
            p.move(to: pt(L1 - u * 0.06, gy + 2)); p.addLine(to: pt(L1 - u * 0.045, gy - u * 0.01))
            p.addQuadCurve(to: pt(L1 - tw * 0.3, deck), control: pt(L1 - u * 0.02, deck + u * 0.05)); p.addLine(to: pt(W + 8, deck - u * 0.01)); p.addLine(to: pt(W + 8, gy + 2)); p.closeSubpath()
            for i in 0..<8 { // Leigh Woods
                let x = L1 + u * 0.01 + CGFloat(i) * u * 0.03
                p.move(to: pt(x - u * 0.02, deck - u * 0.008))
                p.addArc(center: pt(x, deck - u * 0.008 - u * 0.004 * CGFloat(i % 3)), radius: u * 0.02, startAngle: .radians(.pi), endAngle: .radians(0), clockwise: false)
                p.closeSubpath()
            }
            for x in [L0, L1] {
                let top = deck - th
                p.move(to: pt(x - tw / 2, deck)); p.addLine(to: pt(x - tw * 0.42, top)); p.addLine(to: pt(x + tw * 0.42, top)); p.addLine(to: pt(x + tw / 2, deck)); p.closeSubpath()
                p.addRect(CGRect(x: x - tw * 0.55, y: top - u * 0.006, width: tw * 1.1, height: u * 0.006))
            }
            p.addRect(CGRect(x: L0, y: deck - u * 0.004, width: L1 - L0, height: u * 0.006))
        }
        // The openings through the towers.
        for x in [L0, L1] {
            var p = Path()
            p.move(to: pt(x - tw * 0.17, deck)); p.addLine(to: pt(x - tw * 0.17, deck - th * 0.55))
            p.addArc(center: pt(x, deck - th * 0.55), radius: tw * 0.17, startAngle: .radians(.pi), endAngle: .radians(0), clockwise: false)
            p.addLine(to: pt(x + tw * 0.17, deck)); p.closeSubpath()
            ctx.fill(p, with: .color(ScenePainter.mix(dc(0.36), sun, 0.3)))
        }
        // Chains and hangers.
        let top = deck - th + u * 0.006, mid = (L0 + L1) / 2, cy = 2 * (deck - u * 0.006) - top
        var chain = Path()
        chain.move(to: pt(L0, top)); chain.addQuadCurve(to: pt(L1, top), control: pt(mid, cy))
        chain.move(to: pt(L0, top)); chain.addLine(to: pt(L0 - u * 0.05, deck + u * 0.004))
        chain.move(to: pt(L1, top)); chain.addLine(to: pt(L1 + u * 0.05, deck - u * 0.004))
        ctx.stroke(chain, with: .color(c(dc(0.36))), lineWidth: max(1, u * 0.0035))
        var hangers = Path()
        var hx = L0 + u * 0.015
        while hx < L1 - u * 0.01 {
            let k = (hx - L0) / (L1 - L0), y = (1 - k) * (1 - k) * top + 2 * k * (1 - k) * cy + k * k * top
            hangers.move(to: pt(hx, y)); hangers.addLine(to: pt(hx, deck))
            hx += u * 0.015
        }
        ctx.stroke(hangers, with: .color(c(dc(0.36))), lineWidth: max(0.6, u * 0.0013))
        // The river below, catching the sun.
        ctx.fill(Path(CGRect(x: L0 + u * 0.05, y: gy - u * 0.012, width: L1 - L0 - u * 0.1, height: u * 0.01)),
                 with: across(c(haze, 0.3), ScenePainter.mix(sun, "#ffffff", 0.4).opacity(0.8)))
        // Fog lying in the valley, drifting.
        for i in 0..<5 {
            let fx = CGFloat((Double(W) * Double(i) * 0.27 + t * Double(u) * 0.006 * Double(1 + i % 2)).truncatingRemainder(dividingBy: Double(W) * 1.4)) - W * 0.2
            let fy = gy - u * (0.02 + 0.02 * CGFloat(i % 3)), fw = u * (0.5 + 0.1 * CGFloat(i % 2))
            soft(&ctx, fx, fy, fw, ScenePainter.mix(haze, "#ffffff", 0.4).opacity(0.5), c(haze, 0))
        }
        hazeBand(&ctx, gy - u * 0.06, 0.3)
        ground(&ctx); mist(&ctx, 0.4)
        // Green hills and oaks.
        func oak(_ p: inout Path, _ x: CGFloat, _ b: CGFloat, _ h: CGFloat) {
            let blobs: [(CGFloat, CGFloat, CGFloat)] = [(0, 0.66, 0.22), (-0.2, 0.56, 0.17), (0.21, 0.55, 0.18), (-0.33, 0.44, 0.12), (0.34, 0.43, 0.13),
                                                        (-0.09, 0.82, 0.14), (0.11, 0.8, 0.15), (0, 0.47, 0.16), (-0.16, 0.4, 0.12), (0.18, 0.4, 0.12)]
            for (dx, dy, r) in blobs { circle(&p, x + h * dx, b - h * dy, h * r) }
            p.move(to: pt(x - h * 0.04, b)); p.addQuadCurve(to: pt(x - h * 0.1, b - h * 0.42), control: pt(x - h * 0.02, b - h * 0.2))
            p.addLine(to: pt(x + h * 0.1, b - h * 0.42)); p.addQuadCurve(to: pt(x + h * 0.04, b), control: pt(x + h * 0.02, b - h * 0.2)); p.closeSubpath()
        }
        sil(&ctx, 0.14, 0.2, 0.8) { p in
            hump(&p, -W * 0.35, W * 0.38, gy + u * 0.04, u * 0.06); hump(&p, W * 0.68, W * 1.3, gy + u * 0.04, u * 0.05)
            oak(&p, W * 0.07, gy - u * 0.04, u * 0.22); oak(&p, W * 0.21, gy - u * 0.012, u * 0.13); oak(&p, W * 1.0, gy - u * 0.035, u * 0.19)
        }
    }

    /// A date palm (`palmShape`): a curved trunk and a crown of drooping fronds. Without `strokes` it adds the trunk and
    /// the fronds' tapering spines (to fill); with `strokes` the leaflets (to stroke thin), so each frond reads as a feather.
    static func palm(_ p: inout Path, _ x: CGFloat, _ b: CGFloat, _ h: CGFloat, _ lean: CGFloat, full: Bool, strokes: Bool) {
        let Tx = x + lean * h, Ty = b - h, Cx = x + lean * h * 0.15, Cy = b - h * 0.5, wb = h * 0.05, wt = h * 0.028
        if !strokes {
            p.move(to: CGPoint(x: x - wb / 2, y: b)); p.addQuadCurve(to: CGPoint(x: Tx - wt / 2, y: Ty), control: CGPoint(x: Cx - (wb + wt) / 4, y: Cy))
            p.addLine(to: CGPoint(x: Tx + wt / 2, y: Ty)); p.addQuadCurve(to: CGPoint(x: x + wb / 2, y: b), control: CGPoint(x: Cx + (wb + wt) / 4, y: Cy)); p.closeSubpath()
        }
        let angles: [CGFloat] = full ? [-3.35, -3.0, -2.6, -2.2, -1.8, -1.35, -0.95, -0.55, -0.15, 0.2] : [-3.1, -2.4, -1.6, -0.8, -0.05]
        for (i, a) in angles.enumerated() {
            let ca = cos(a), sa = sin(a), len = h * (full ? 0.34 + 0.07 * CGFloat((i * 7) % 3) / 2 : 0.42) * (0.75 + 0.25 * abs(ca))
            let Ex = Tx + ca * len, Ey = Ty + sa * len * 0.7 + len * (0.45 * abs(ca) + 0.14), Qx = Tx + ca * len * 0.55, Qy = Ty + sa * len * 0.7 - len * 0.1
            func P(_ k: CGFloat) -> CGPoint { CGPoint(x: (1 - k) * (1 - k) * Tx + 2 * k * (1 - k) * Qx + k * k * Ex, y: (1 - k) * (1 - k) * Ty + 2 * k * (1 - k) * Qy + k * k * Ey) }
            func D(_ k: CGFloat) -> CGPoint {
                let dx = 2 * (1 - k) * (Qx - Tx) + 2 * k * (Ex - Qx), dy = 2 * (1 - k) * (Qy - Ty) + 2 * k * (Ey - Qy), m = max(0.0001, hypot(dx, dy))
                return CGPoint(x: dx / m, y: dy / m)
            }
            if !strokes { // the spine, tapering
                var l: [CGPoint] = [], r: [CGPoint] = []
                for j in 0...8 {
                    let k = CGFloat(j) / 8, q = P(k), d = D(k), w = len * 0.035 * (1 - k * 0.85)
                    l.append(CGPoint(x: q.x - d.y * w, y: q.y + d.x * w)); r.append(CGPoint(x: q.x + d.y * w, y: q.y - d.x * w))
                }
                p.move(to: l[0]); for q in l { p.addLine(to: q) }; for q in r.reversed() { p.addLine(to: q) }; p.closeSubpath()
            } else if full { // the leaflets, both sides, angled towards the tip and hanging a little
                var k: CGFloat = 0.1
                while k < 0.97 {
                    let q = P(k), d = D(k), lp = len * 0.19 * (1 - k * 0.6)
                    for s in [-1.0, 1.0] as [CGFloat] {
                        var vx = d.x * 0.8 - d.y * s, vy = d.y * 0.8 + d.x * s + 0.3
                        let m = hypot(vx, vy); vx /= m; vy /= m
                        p.move(to: q); p.addLine(to: CGPoint(x: q.x + vx * lp, y: q.y + vy * lp))
                    }
                    k += 0.07
                }
            } else {
                var k: CGFloat = 0.15
                while k < 0.97 {
                    let q = P(k), d = D(k), lp = len * 0.25 * (1 - k * 0.5)
                    for s in [-1.0, 1.0] as [CGFloat] { p.move(to: q); p.addLine(to: CGPoint(x: q.x + (d.x * 0.5 - d.y * s) * lp, y: q.y + (d.y * 0.5 + d.x * s + 0.5) * lp)) }
                    k += 0.2
                }
            }
        }
        if !strokes && full { p.addEllipse(in: CGRect(x: Tx - h * 0.035, y: Ty + h * 0.02 - h * 0.035, width: h * 0.07, height: h * 0.07)) }
    }
}
