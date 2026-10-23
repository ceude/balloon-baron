import SwiftUI
import BalloonBaronCore

/// The company balloon in full volume, like the app icon: thirteen gores in the company colors, key light,
/// core shadow and the burner's glow. Port of the prototype's `balloon3d` / `balloon3dCore` / `flame3d`
/// (themselves copied from `tools/appstore/art.js`).
extension ScenePainter {
    private static func rgba(_ r: Double, _ g: Double, _ b: Double, _ a: Double) -> Color {
        Color(red: r / 255, green: g / 255, blue: b / 255).opacity(a)
    }

    /// `balloon3d(x, y, R, c1, c2, burn, alpha, ad)`: (x, y) is the bottom of the basket like `balloon()`, and the
    /// overall height is the same. Every fourth gore is the second color, the outermost two a little darker.
    static func balloon3d(_ ctx: inout GraphicsContext, x: CGFloat, y: CGFloat, r R: CGFloat, colors: [String], burn: Bool = false,
                          alpha: Double = 1, ad: Sponsor? = nil, region: RegionID = .cap) {
        guard R > 0.5 else { return }
        let r = R * 0.86
        let c1 = colors.first ?? "#ff5e3a", c2 = colors.count > 1 ? colors[1] : "#ffc23d"
        let dark = mixHex(c1, "#000000", 0.1)
        let cols: [String] = (0..<13).map { i in i % 4 == 2 ? c2 : (i == 0 || i == 12 ? dark : c1) }
        balloon3dCore(&ctx, x: x, y: y - r * 2.23, r: r, colors: cols, gores: 13, light: -1, flame: burn, flameScale: 0.5, alpha: alpha,
                      band: ad.map { $0.colors.bg }, text: ad.map { banner($0, region: region) }, textColor: ad.map { $0.colors.fg })
    }

    /// `balloon3dCore(x, y, R, cols, o)`: (x, y) is the envelope's equator.
    static func balloon3dCore(_ ctx: inout GraphicsContext, x: CGFloat, y: CGFloat, r R: CGFloat, colors cols: [String], gores nG: Int = 12,
                              light: CGFloat = -1, flame: Bool = false, flameScale: CGFloat = 0.55, alpha: Double = 1,
                              band: String? = nil, text: String? = nil, textColor: String? = nil) {
        guard R > 0.5, !cols.isEmpty, nG > 0 else { return }
        var c = ctx
        c.translateBy(x: x, y: y)
        c.opacity = alpha
        let topY = -R * 1.05, eq: CGFloat = 0, mouth = R * 1.42, mouthW = R * 0.26
        func half(_ yy: CGFloat) -> CGFloat {
            if yy <= eq {
                let t = min(max(Double((yy - topY) / (eq - topY)), 0), 1)
                return R * CGFloat(sin(Double.pi / 2 * pow(t, 0.62)))
            }
            let t = Double((yy - eq) / (mouth - eq))
            let k = CGFloat(pow(t, 1.25))
            return (R + (mouthW - R) * k) * CGFloat(1 - 0.08 * sin(Double.pi * t))
        }
        let steps = 40
        func lerpY(_ a: CGFloat, _ b: CGFloat, _ i: Int) -> CGFloat { a + (b - a) * CGFloat(i) / CGFloat(steps) }
        /// A meridian at `side` (sin of its angle) from `y0` to `y1`.
        func meridian(_ side: CGFloat, _ y0: CGFloat, _ y1: CGFloat) -> Path {
            var p = Path()
            for i in 0...steps {
                let yy = lerpY(y0, y1, i), pt = CGPoint(x: half(yy) * side, y: yy)
                if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
            return p
        }

        var env = Path()
        for i in 0...steps {
            let yy = lerpY(topY, mouth, i), pt = CGPoint(x: half(yy), y: yy)
            if i == 0 { env.move(to: pt) } else { env.addLine(to: pt) }
        }
        for i in stride(from: steps, through: 0, by: -1) {
            let yy = lerpY(topY, mouth, i)
            env.addLine(to: CGPoint(x: -half(yy), y: yy))
        }
        env.closeSubpath()

        do {
            var inner = c
            inner.clip(to: env)
            // Gores between meridians.
            for k in 0..<nG {
                let a0 = -Double.pi / 2 + Double.pi * Double(k) / Double(nG), a1 = -Double.pi / 2 + Double.pi * Double(k + 1) / Double(nG)
                let s0 = CGFloat(sin(a0)) * 1.002, s1 = CGFloat(sin(a1)) * 1.002
                var p = Path()
                for i in 0...steps {
                    let yy = lerpY(topY - 4, mouth + 4, i), pt = CGPoint(x: half(yy) * s0, y: yy)
                    if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                }
                for i in stride(from: steps, through: 0, by: -1) {
                    let yy = lerpY(topY - 4, mouth + 4, i)
                    p.addLine(to: CGPoint(x: half(yy) * s1, y: yy))
                }
                p.closeSubpath()
                inner.fill(p, with: .color(Color(hex: cols[k % cols.count])))
            }
            // A sponsor's band around the envelope.
            if let band {
                rect(&inner, -R, R * 0.38, R * 2, R * 0.2, Color(hex: band))
                rect(&inner, -R, R * 0.38, R * 2, R * 0.025, Color.white.opacity(0.5))
                rect(&inner, -R, R * 0.555, R * 2, R * 0.025, Color.white.opacity(0.5))
            }
            if let text, R * 0.2 >= 1 {
                let t = Text(verbatim: text)
                    .font(.custom("BarlowCondensed-ExtraBold", size: R * 0.2))
                    .foregroundColor(Color(hex: textColor ?? "#ffffff"))
                inner.draw(t, at: CGPoint(x: 0, y: R * 0.48), anchor: .center)
            }
            // Volume: key light, core shadow, darker bottom, and a glow from the flame.
            let full = Path(CGRect(x: -R * 1.2, y: topY, width: R * 2.4, height: mouth - topY))
            let key = Gradient(stops: [
                .init(color: rgba(255, 248, 230, 0.55), location: 0),
                .init(color: rgba(255, 235, 210, 0.12), location: 0.35),
                .init(color: rgba(255, 235, 210, 0), location: 1)
            ])
            // Canvas uses a two-circle gradient (focus at 0.45 R, outer circle at 0.3 R); a centered one at the focus is close.
            inner.fill(full, with: .radialGradient(key, center: CGPoint(x: light * R * 0.42, y: -R * 0.42), startRadius: R * 0.05, endRadius: R * 1.3))
            let core = Gradient(stops: [
                .init(color: rgba(20, 6, 30, 0), location: 0),
                .init(color: rgba(20, 6, 30, 0.12), location: 0.55),
                .init(color: rgba(20, 6, 30, 0.48), location: 0.85),
                .init(color: rgba(20, 6, 30, 0.6), location: 1)
            ])
            inner.fill(full, with: .linearGradient(core, startPoint: CGPoint(x: light * R, y: 0), endPoint: CGPoint(x: -light * R, y: 0)))
            let bottom = Gradient(colors: [rgba(20, 6, 30, 0), rgba(20, 6, 30, 0.45)])
            inner.fill(Path(CGRect(x: -R * 1.2, y: R * 0.2, width: R * 2.4, height: mouth)),
                       with: .linearGradient(bottom, startPoint: CGPoint(x: 0, y: R * 0.2), endPoint: CGPoint(x: 0, y: mouth)))
            if flame {
                var glow = inner
                glow.blendMode = .plusLighter
                let fg = Gradient(stops: [
                    .init(color: rgba(255, 170, 60, 0.45), location: 0),
                    .init(color: rgba(255, 120, 40, 0.12), location: 0.4),
                    .init(color: rgba(255, 120, 40, 0), location: 1)
                ])
                glow.fill(Path(CGRect(x: -R * 1.3, y: -R * 0.2, width: R * 2.6, height: R * 2)),
                          with: .radialGradient(fg, center: CGPoint(x: 0, y: mouth), startRadius: 0, endRadius: R * 1.3))
            }
            // Gore seams.
            let seam = rgba(40, 15, 30, 0.22), seamW = max(1, R * 0.006)
            for k in 1..<nG {
                let a = -Double.pi / 2 + Double.pi * Double(k) / Double(nG)
                inner.stroke(meridian(CGFloat(sin(a)), topY, mouth), with: .color(seam), lineWidth: seamW)
            }
        }
        // Rim light along the lit edge.
        do {
            var rim = c
            rim.clip(to: env)
            rim.stroke(meridian(light, topY, mouth * 0.7), with: .color(rgba(255, 225, 180, 0.45)), lineWidth: max(1.5, R * 0.018))
        }
        if alpha < 0.6 { return }

        // Skirt, ropes, burner, flame, basket.
        let by = mouth + R * 0.55, bw = R * 0.34, bh = R * 0.26
        var skirt = Path()
        skirt.move(to: CGPoint(x: -mouthW, y: mouth - 2))
        skirt.addLine(to: CGPoint(x: mouthW, y: mouth - 2))
        skirt.addLine(to: CGPoint(x: mouthW * 0.8, y: mouth + R * 0.12))
        skirt.addLine(to: CGPoint(x: -mouthW * 0.8, y: mouth + R * 0.12))
        skirt.closeSubpath()
        c.fill(skirt, with: .color(mix(cols[0], "#1a0a14", 0.45)))
        let rope = rgba(50, 30, 25, 0.9), ropeW = max(1, R * 0.008)
        for s: CGFloat in [-1, -0.35, 0.35, 1] {
            var p = Path()
            p.move(to: CGPoint(x: s * mouthW * 0.8, y: mouth + R * 0.1))
            p.addLine(to: CGPoint(x: s * bw * 0.45, y: by))
            c.stroke(p, with: .color(rope), lineWidth: ropeW)
        }
        rect(&c, -R * 0.09, by - R * 0.2, R * 0.18, R * 0.08, Color(hex: "#2a2a30"))
        if flame { flame3d(&c, x: 0, y: by - R * 0.2, s: R * flameScale) }
        var basket = Path()
        basket.move(to: CGPoint(x: -bw / 2, y: by))
        basket.addLine(to: CGPoint(x: bw / 2, y: by))
        basket.addLine(to: CGPoint(x: bw * 0.44, y: by + bh))
        basket.addLine(to: CGPoint(x: -bw * 0.44, y: by + bh))
        basket.closeSubpath()
        let wicker = Gradient(stops: [
            .init(color: Color(hex: "#4a2c18"), location: 0),
            .init(color: Color(hex: "#8a5a32"), location: 0.5),
            .init(color: Color(hex: "#3a2010"), location: 1)
        ])
        c.fill(basket, with: .linearGradient(wicker, startPoint: CGPoint(x: -bw / 2, y: 0), endPoint: CGPoint(x: bw / 2, y: 0)))
        let bandC = rgba(30, 15, 8, 0.35), bandW = max(1, R * 0.005)
        for i in 1..<6 {
            var p = Path()
            let yy = by + bh * CGFloat(i) / 6
            p.move(to: CGPoint(x: -bw / 2, y: yy))
            p.addLine(to: CGPoint(x: bw / 2, y: yy))
            c.stroke(p, with: .color(bandC), lineWidth: bandW)
        }
        rect(&c, -bw / 2 - 2, by - R * 0.02, bw + 4, R * 0.035, Color(hex: "#2a160c"))
    }

    /// `flame3d(x, y, s)`: an additive glow and four soft, blurred tongues of flame.
    static func flame3d(_ ctx: inout GraphicsContext, x: CGFloat, y: CGFloat, s: CGFloat) {
        guard s > 0.1 else { return }
        do {
            var glow = ctx
            glow.blendMode = .plusLighter
            let g = Gradient(stops: [
                .init(color: rgba(255, 190, 80, 0.7), location: 0),
                .init(color: rgba(255, 120, 40, 0.22), location: 0.35),
                .init(color: rgba(255, 90, 30, 0), location: 1)
            ])
            glow.fill(Path(CGRect(x: x - s * 2.2, y: y - s * 2.8, width: s * 4.4, height: s * 4.4)),
                      with: .radialGradient(g, center: CGPoint(x: x, y: y - s * 0.6), startRadius: 0, endRadius: s * 2.2))
        }
        let layers: [(String, CGFloat, CGFloat)] = [("#ff5a1f", 1, 14), ("#ffa531", 0.74, 9), ("#ffe08a", 0.5, 6), ("#fffbe8", 0.26, 3)]
        for (col, k, blur) in layers {
            let w = s * 0.3 * k, h = s * 1.25 * k
            var p = Path()
            p.move(to: CGPoint(x: x - w, y: y))
            p.addCurve(to: CGPoint(x: x - w * 0.35, y: y - h * 0.78),
                       control1: CGPoint(x: x - w * 1.25, y: y - h * 0.35), control2: CGPoint(x: x - w * 0.55, y: y - h * 0.55))
            p.addQuadCurve(to: CGPoint(x: x - w * 0.05, y: y - h), control: CGPoint(x: x - w * 0.15, y: y - h * 0.62))
            p.addQuadCurve(to: CGPoint(x: x + w * 0.4, y: y - h * 0.86), control: CGPoint(x: x + w * 0.2, y: y - h * 0.7))
            p.addCurve(to: CGPoint(x: x + w, y: y),
                       control1: CGPoint(x: x + w * 0.55, y: y - h * 0.55), control2: CGPoint(x: x + w * 1.25, y: y - h * 0.35))
            p.addQuadCurve(to: CGPoint(x: x - w, y: y), control: CGPoint(x: x, y: y + w * 0.5))
            p.closeSubpath()
            var layer = ctx
            layer.addFilter(.blur(radius: max(1, s * blur / 120)))
            layer.fill(p, with: .color(Color(hex: col)))
        }
    }
}
