import SwiftUI
import BalloonBaronCore

/// The opening screen's world: a dawn launch field in the region you're playing, with its own skyline, the last
/// stars, a rising sun, balloons already up, and the game's name in the sky.
/// Luxor's look is ready for when Egypt opens. Port of the prototype's `introScene`.
enum IntroScene {
    struct Look {
        let sky: [String], far: String, mid: String, midShade: String, cap: String, ground: [String], name: String
    }

    static func look(_ key: String) -> Look {
        switch key {
        case "abq": Look(sky: ["#0f1534", "#31275c", "#bc4e6a", "#ff8f4e", "#ffcf80"], far: "#5e345a", mid: "#a8503a", midShade: "#6a3022",
                         cap: "#3f7a3a", ground: ["#8a4e2c", "#28120a"], name: "ALBUQUERQUE")
        case "lux": Look(sky: ["#0d1836", "#2a3664", "#b0605a", "#f2a656", "#ffe2a0"], far: "#6a5260", mid: "#c89a62", midShade: "#8a6440",
                         cap: "#2e5a2a", ground: ["#a07a4a", "#30200e"], name: "LUXOR")
        default: Look(sky: ["#120d33", "#3a2460", "#a24e7a", "#f0875a", "#ffd59a"], far: "#4e3460", mid: "#c8866a", midShade: "#8a5060",
                      cap: "#4a2a2a", ground: ["#6e4a3a", "#2a1822"], name: "CAPPADOCIA")
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
        // Balloons already up, drifting, hazier the further they are.
        for i in 0..<11 {
            var r = Mulberry32(seed: UInt32(100 + i))
            let a = r.next(), d = r.next()
            let x = CGFloat((a * Double(W) * 1.4 + t * (3 + d * 9)).truncatingRemainder(dividingBy: Double(W) * 1.4)) - W * 0.2
            let y = max(H * 0.24, gy * CGFloat(0.24 + (1 - d) * 0.45)) + CGFloat(sin(t * 0.6 + Double(i))) * 4 + CGFloat(lift) * u * 0.25 * CGFloat(d)
            let c = cols[(i * 3) % 8]
            ScenePainter.balloon(&ctx, x: x, y: y, r: u * CGFloat(0.014 + d * 0.03),
                                 colors: [ScenePainter.mixHex(c, L.sky[3], (1 - d) * 0.55), ScenePainter.mixHex("#ffffff", L.sky[3], (1 - d) * 0.55)],
                                 burn: d > 0.7 && sin(t * 2 + Double(i)) > 0.6, alpha: 0.55 + d * 0.4, time: t)
        }
        // The far skyline.
        var far = Path()
        far.move(to: CGPoint(x: 0, y: gy))
        var x: CGFloat = 0
        while x <= W + 20 {
            var y = gy - u * (0.07 + 0.03 * CGFloat(sin(Double(x) * 0.011 + 1)) + 0.015 * CGFloat(sin(Double(x) * 0.037)))
            if key == "cap" { y -= max(0, u * 0.2 - abs(x - W * 0.3) * 0.55) } // Erciyes
            if key == "abq" { y -= u * 0.1 * (0.6 + 0.4 * CGFloat(sin(Double(x) * 0.006 + 2))) * min(1, x / (W * 0.4)) } // the Sandias
            far.addLine(to: CGPoint(x: x, y: y))
            x += 16
        }
        far.addLine(to: CGPoint(x: W, y: gy))
        ctx.fill(far, with: .color(hex(L.far)))
        if key == "cap" {
            var snow = Path()
            snow.move(to: CGPoint(x: W * 0.3 - u * 0.07, y: gy - u * 0.19))
            snow.addLine(to: CGPoint(x: W * 0.3, y: gy - u * 0.27))
            snow.addLine(to: CGPoint(x: W * 0.3 + u * 0.07, y: gy - u * 0.19))
            snow.addQuadCurve(to: CGPoint(x: W * 0.3 - u * 0.07, y: gy - u * 0.19), control: CGPoint(x: W * 0.3, y: gy - u * 0.2))
            ctx.fill(snow, with: .color(Color(red: 1, green: 240 / 255, blue: 235 / 255).opacity(0.55)))
        }
        if key == "lux" {
            for (px, ps) in [(W * 0.22, 1.0), (W * 0.34, 0.7), (W * 0.8, 0.55)] as [(CGFloat, CGFloat)] {
                var p = Path()
                p.move(to: CGPoint(x: px - u * 0.16 * ps, y: gy - u * 0.04))
                p.addLine(to: CGPoint(x: px, y: gy - u * 0.2 * ps))
                p.addLine(to: CGPoint(x: px + u * 0.16 * ps, y: gy - u * 0.04))
                ctx.fill(p, with: .color(ScenePainter.mix(L.far, "#000000", 0.1)))
            }
        }
        // The region's landmarks, in two rows.
        landmarks(&ctx, L, key: key, W: W, u: u, base: gy - u * 0.005, n: 9, h: (0.1, 0.2), seed: 11, haze: 0.55)
        landmarks(&ctx, L, key: key, W: W, u: u, base: gy + u * 0.02, n: 6, h: (0.18, 0.34), seed: 23, haze: 0.12)
        // The launch field and the morning mist over it.
        ctx.fill(Path(CGRect(x: 0, y: gy, width: W, height: H - gy)), with: .linearGradient(
            Gradient(colors: [hex(L.ground[0]), hex(L.ground[1])]), startPoint: CGPoint(x: 0, y: gy), endPoint: CGPoint(x: 0, y: H)))
        let mistC = Color(red: 1, green: 215 / 255, blue: 190 / 255)
        ctx.fill(Path(CGRect(x: 0, y: gy - u * 0.06, width: W, height: u * 0.11)), with: .linearGradient(
            Gradient(stops: [.init(color: mistC.opacity(0), location: 0), .init(color: mistC.opacity(0.28), location: 0.5), .init(color: mistC.opacity(0), location: 1)]),
            startPoint: CGPoint(x: 0, y: gy - u * 0.06), endPoint: CGPoint(x: 0, y: gy + u * 0.05)))
        // The game's name in the sky. It stays put; the hero balloon, drawn after the scene, rises past it in front.
        do {
            var title = ctx
            let ty = max(70, H * 0.14), fs = min(W * 0.13, 64)
            title.addFilter(.shadow(color: Color(red: 10 / 255, green: 4 / 255, blue: 24 / 255).opacity(0.6), radius: 12))
            let gold = LinearGradient(stops: [.init(color: .white, location: 0), .init(color: hex("#fff1d0"), location: 0.6), .init(color: hex("#ffc23d"), location: 1)],
                                      startPoint: .top, endPoint: .bottom)
            title.draw(Text("BALLOON BARON").font(Theme.font(fs, .heavy, condensed: true)).foregroundStyle(gold), at: CGPoint(x: W / 2, y: ty), anchor: .bottom)
            title.draw(Text(L.name).font(Theme.font(fs * 0.32, .bold, condensed: true)).tracking(fs * 0.12).foregroundStyle(hex("#ffcf7a")),
                       at: CGPoint(x: W / 2 + fs * 0.06, y: ty + fs * 0.52), anchor: .bottom)
        }
    }

    private static func landmarks(_ ctx: inout GraphicsContext, _ L: Look, key: String, W: CGFloat, u: CGFloat, base: CGFloat, n: Int,
                                  h: (Double, Double), seed: UInt32, haze k: Double) {
        var R = Mulberry32(seed: seed)
        let body = ScenePainter.mix(L.mid, L.far, k), shade = ScenePainter.mix(L.midShade, L.far, k), cap = ScenePainter.mix(L.cap, L.far, k)
        for i in 0..<n {
            let x = (CGFloat(i) + 0.2 + CGFloat(R.next()) * 0.6) * W / CGFloat(n)
            let hh = u * CGFloat(h.0 + R.next() * (h.1 - h.0)), s = R.next()
            switch key {
            case "abq":
                if s < 0.55 {
                    var m = Path()
                    m.move(to: CGPoint(x: x - hh * 0.9, y: base))
                    m.addLine(to: CGPoint(x: x - hh * 0.6, y: base - hh * 0.55))
                    m.addLine(to: CGPoint(x: x + hh * 0.6, y: base - hh * 0.55))
                    m.addLine(to: CGPoint(x: x + hh * 0.9, y: base))
                    ctx.fill(m, with: .color(body))
                    ctx.fill(Path(CGRect(x: x - hh * 0.6, y: base - hh * 0.55, width: hh * 1.2, height: hh * 0.07)), with: .color(shade))
                } else {
                    let w = hh * 0.09
                    for r in [CGRect(x: x - w / 2, y: base - hh * 0.6, width: w, height: hh * 0.6),
                              CGRect(x: x - w * 2.2, y: base - hh * 0.45, width: w * 0.8, height: hh * 0.25),
                              CGRect(x: x + w * 1.4, y: base - hh * 0.52, width: w * 0.8, height: hh * 0.22)] {
                        ctx.fill(Path(roundedRect: r, cornerRadius: r.width / 2), with: .color(cap))
                    }
                    ctx.fill(Path(CGRect(x: x - w * 2.2, y: base - hh * 0.24, width: w * 2, height: w * 0.7)), with: .color(cap))
                    ctx.fill(Path(CGRect(x: x + w * 0.4, y: base - hh * 0.32, width: w * 1.6, height: w * 0.7)), with: .color(cap))
                }
            case "lux":
                if s < 0.5 {
                    for c in -1...1 { ctx.fill(Path(CGRect(x: x + CGFloat(c) * hh * 0.22 - hh * 0.06, y: base - hh * 0.7, width: hh * 0.12, height: hh * 0.7)), with: .color(body)) }
                    ctx.fill(Path(CGRect(x: x - hh * 0.36, y: base - hh * 0.78, width: hh * 0.72, height: hh * 0.1)), with: .color(body))
                } else {
                    var trunk = Path()
                    trunk.move(to: CGPoint(x: x, y: base))
                    trunk.addQuadCurve(to: CGPoint(x: x + hh * 0.05, y: base - hh), control: CGPoint(x: x + hh * 0.1, y: base - hh * 0.5))
                    ctx.stroke(trunk, with: .color(cap), lineWidth: hh * 0.05)
                    for f in 0..<6 {
                        let a = Double(f) / 6 * Double.pi * 2
                        var leaf = ctx
                        leaf.translateBy(x: x + hh * 0.05 + CGFloat(cos(a)) * hh * 0.2, y: base - hh + CGFloat(sin(a)) * hh * 0.06 + hh * 0.04)
                        leaf.rotate(by: .radians(a))
                        leaf.fill(Path(ellipseIn: CGRect(x: -hh * 0.22, y: -hh * 0.05, width: hh * 0.44, height: hh * 0.1)), with: .color(cap))
                    }
                }
            default:
                ScenePainter.chimney(&ctx, x, base, hh * 0.36, hh, body: body, shade: shade, cap: cap)
            }
        }
    }
}
