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

        rig3d(&c, r: R, mouth: mouth, mouthW: mouthW, color: cols[0], flame: flame, flameScale: flameScale)
    }

    /// `rig3d(R, mouth, mouthW, col, flame, flameScale)`: skirt, ropes, burner, flame and wicker basket under a 3D envelope
    /// whose mouth is at `mouth` (the context's x = 0 is the balloon's axis). The flame rises into the mouth: only the part
    /// below the skirt shows, the rest burns inside the envelope. Its light spills softly round the burner instead of being
    /// cut off at the skirt. Returns the top of the basket.
    @discardableResult
    static func rig3d(_ c: inout GraphicsContext, r R: CGFloat, mouth: CGFloat, mouthW: CGFloat, color: String, flame: Bool,
                      flameScale: CGFloat, t: Double = Date.timeIntervalSinceReferenceDate) -> CGFloat {
        let by = mouth + R * 0.55, bw = R * 0.34, bh = R * 0.26
        var skirt = Path()
        skirt.move(to: CGPoint(x: -mouthW, y: mouth - 2))
        skirt.addLine(to: CGPoint(x: mouthW, y: mouth - 2))
        skirt.addLine(to: CGPoint(x: mouthW * 0.8, y: mouth + R * 0.12))
        skirt.addLine(to: CGPoint(x: -mouthW * 0.8, y: mouth + R * 0.12))
        skirt.closeSubpath()
        c.fill(skirt, with: .color(mix(color, "#1a0a14", 0.45)))
        let rope = rgba(50, 30, 25, 0.9), ropeW = max(1, R * 0.008)
        for s: CGFloat in [-1, -0.35, 0.35, 1] {
            var p = Path()
            p.move(to: CGPoint(x: s * mouthW * 0.8, y: mouth + R * 0.1))
            p.addLine(to: CGPoint(x: s * bw * 0.45, y: by))
            c.stroke(p, with: .color(rope), lineWidth: ropeW)
        }
        if flame {
            let fy = by - R * 0.2, k = R * 0.55 * CGFloat(1 + 0.08 * sin(t * 29) + 0.05 * sin(t * 53 + 1.1))
            var glow = c
            glow.blendMode = .plusLighter
            let g = Gradient(stops: [
                .init(color: rgba(255, 180, 80, 0.38), location: 0),
                .init(color: rgba(255, 130, 50, 0.12), location: 0.45),
                .init(color: rgba(255, 110, 40, 0), location: 1)
            ])
            let gc = CGPoint(x: 0, y: fy - R * 0.05)
            glow.fill(Path(CGRect(x: -k, y: gc.y - k, width: k * 2, height: k * 2)),
                      with: .radialGradient(g, center: gc, startRadius: 0, endRadius: k))
        }
        rect(&c, -R * 0.09, by - R * 0.2, R * 0.18, R * 0.08, Color(hex: "#2a2a30"))
        if flame {
            var f = c
            f.clip(to: Path(CGRect(x: -R, y: mouth + R * 0.11, width: R * 2, height: R * 2)))
            flame3d(&f, x: 0, y: by - R * 0.2, s: R * flameScale, glow: false, t: t)
        }
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
        return by
    }

    /// `designBalloon3d(...)`: a workshop design (pattern or special shape) in the same volume as the company balloon:
    /// the design painted on the envelope, then key light, core shadow, darker bottom, the flame's glow inside, seams and
    /// a rim light, and the 3D rig underneath. Same overall height as `balloon3d`; (x, y) is the bottom of the basket.
    static func designBalloon3d(_ ctx: inout GraphicsContext, x: CGFloat, y: CGFloat, r R: CGFloat, colors: [String], burn: Bool = false,
                                alpha: Double = 1, ad: Sponsor? = nil, design d: Design, region: RegionID = .cap) {
        guard R > 0.5 else { return }
        var c = ctx
        c.opacity = alpha
        let r = R * 0.86, mouth = y - r * 0.81, shape = d.shape
        let cy = mouth - r * (shape == nil ? 1.42 : 1.55), top = cy - r * (shape == nil ? 1.05 : 1)
        // The round envelope uses the company balloon's profile, so its gores curve with the volume.
        func half(_ yy: CGFloat) -> CGFloat {
            if yy <= cy {
                let t = min(max(Double((yy - top) / (cy - top)), 0), 1)
                return r * CGFloat(sin(Double.pi / 2 * pow(t, 0.62)))
            }
            let t = Double((yy - cy) / (mouth - cy))
            return (r + (r * 0.26 - r) * CGFloat(pow(t, 1.25))) * CGFloat(1 - 0.08 * sin(Double.pi * t))
        }
        func meridian(_ side: CGFloat) -> Path {
            var p = Path()
            for i in 0...40 {
                let yy = top + (mouth - top) * CGFloat(i) / 40, pt = CGPoint(x: x + half(yy) * side, y: yy)
                if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
            return p
        }
        let env: Path
        if let shape {
            env = BalloonPainter.envelope(shape, x: x, cy: cy, r: r)
        } else {
            var p = meridian(1)
            for i in stride(from: 40, through: 0, by: -1) {
                let yy = top + (mouth - top) * CGFloat(i) / 40
                p.addLine(to: CGPoint(x: x - half(yy), y: yy))
            }
            p.closeSubpath()
            env = p
        }
        let main = d.colors.first ?? colors.first ?? "#ff5e3a"
        c.fill(env, with: .color(Color(hex: main)))
        do {
            var inner = c
            inner.clip(to: env)
            if d.colors.count >= 3 {
                BalloonPainter.paint(&inner, pattern: d.pattern, colors: d.colors, x: x, cy: cy, r: r, top: top)
            } else {
                BalloonPainter.stripes(&inner, color: Color(hex: colors.count > 1 ? colors[1] : "#ffc23d"), x: x, cy: cy, r: r)
            }
            if let ad {
                rect(&inner, x - r * 1.4, cy + r * 0.12, r * 2.8, r * 0.52, Color(hex: ad.colors.bg))
                let text = Text(banner(ad, region: region))
                    .font(.custom("BarlowCondensed-ExtraBold", size: max(7, (r * 0.36).rounded())))
                    .foregroundColor(Color(hex: ad.colors.fg))
                inner.draw(text, at: CGPoint(x: x, y: cy + r * 0.38), anchor: .center)
            }
            // Seams on the round envelope; a special shape keeps its outline clean.
            if shape == nil {
                for k in 1..<12 {
                    inner.stroke(meridian(CGFloat(sin(-Double.pi / 2 + Double.pi * Double(k) / 12))),
                                 with: .color(rgba(40, 15, 30, 0.2)), lineWidth: max(1, r * 0.006))
                }
            }
            let W = r * 1.5, box = Path(CGRect(x: x - W, y: top - r * 0.3, width: W * 2, height: r * 3))
            let key = Gradient(stops: [
                .init(color: rgba(255, 248, 230, 0.5), location: 0),
                .init(color: rgba(255, 235, 210, 0.12), location: 0.35),
                .init(color: rgba(255, 235, 210, 0), location: 1)
            ])
            inner.fill(box, with: .radialGradient(key, center: CGPoint(x: x - r * 0.42, y: cy - r * 0.42), startRadius: r * 0.05, endRadius: r * 1.3))
            let core = Gradient(stops: [
                .init(color: rgba(20, 6, 30, 0), location: 0),
                .init(color: rgba(20, 6, 30, 0.12), location: 0.55),
                .init(color: rgba(20, 6, 30, 0.45), location: 0.85),
                .init(color: rgba(20, 6, 30, 0.58), location: 1)
            ])
            inner.fill(box, with: .linearGradient(core, startPoint: CGPoint(x: x - r * 1.1, y: 0), endPoint: CGPoint(x: x + r * 1.1, y: 0)))
            let bottom = Gradient(colors: [rgba(20, 6, 30, 0), rgba(20, 6, 30, 0.42)])
            inner.fill(Path(CGRect(x: x - W, y: cy + r * 0.2, width: W * 2, height: r * 1.5)),
                       with: .linearGradient(bottom, startPoint: CGPoint(x: 0, y: cy + r * 0.2), endPoint: CGPoint(x: 0, y: mouth)))
            if burn {
                var glow = inner
                glow.blendMode = .plusLighter
                let fg = Gradient(stops: [
                    .init(color: rgba(255, 170, 60, 0.45), location: 0),
                    .init(color: rgba(255, 120, 40, 0.12), location: 0.4),
                    .init(color: rgba(255, 120, 40, 0), location: 1)
                ])
                glow.fill(Path(CGRect(x: x - W, y: cy - r * 0.2, width: W * 2, height: r * 2)),
                          with: .radialGradient(fg, center: CGPoint(x: x, y: mouth), startRadius: 0, endRadius: r * 1.3))
            }
            // Rim light: the lit (left) edge of the outline.
            let rim = Gradient(colors: [rgba(255, 225, 180, 0.55), rgba(255, 225, 180, 0)])
            inner.stroke(env, with: .linearGradient(rim, startPoint: CGPoint(x: x - r * 1.1, y: 0), endPoint: CGPoint(x: x - r * 0.2, y: 0)),
                         lineWidth: max(2, r * 0.05))
        }
        if shape == .skull { BalloonPainter.skullFace(&c, x: x, cy: cy, r: r) }
        c.translateBy(x: x, y: 0)
        rig3d(&c, r: r, mouth: mouth, mouthW: r * (shape == nil ? 0.26 : 0.22), color: main, flame: burn, flameScale: 0.5)
    }

    /// `flame3d(x, y, s)`: the burner's flame, soft layered tongues that flicker. Each layer breathes at its own
    /// pace (a few sines that never line up, so it never looks like a loop), its tip leans with a little sway, the
    /// glow pulses with it and a few sparks lift off. `t` defaults to the clock, so a redrawing canvas animates it.
    static func flame3d(_ ctx: inout GraphicsContext, x: CGFloat, y: CGFloat, s: CGFloat, glow drawGlow: Bool = true,
                        t: Double = Date.timeIntervalSinceReferenceDate) {
        guard s > 0.1 else { return }
        func n(_ f: Double, _ ph: Double) -> CGFloat { CGFloat(sin(t * f + ph)) }
        let pulse: CGFloat = 1 + 0.1 * n(31, 0) + 0.06 * n(47, 1.7) + 0.04 * n(83, 4.1)
        if drawGlow {
            var glow = ctx
            glow.blendMode = .plusLighter
            let gy = y - s * 0.6, gr = s * 2.2 * (0.92 + 0.1 * pulse)
            let g = Gradient(stops: [
                .init(color: rgba(255, 190, 80, Double(0.62 + 0.12 * n(29, 0.4))), location: 0),
                .init(color: rgba(255, 120, 40, 0.22), location: 0.35),
                .init(color: rgba(255, 90, 30, 0), location: 1)
            ])
            glow.fill(Path(CGRect(x: x - gr, y: gy - gr, width: gr * 2, height: gr * 2)),
                      with: .radialGradient(g, center: CGPoint(x: x, y: gy), startRadius: 0, endRadius: gr))
        }
        let layers: [(String, CGFloat, CGFloat, Double)] = [("#ff5a1f", 1, 14, 0), ("#ffa531", 0.74, 9, 1.3), ("#ffe08a", 0.5, 6, 2.6), ("#fffbe8", 0.26, 3, 3.9)]
        for (col, k, blur, ph) in layers {
            // Inner layers flicker faster and less; the outer one stretches and sways the most.
            let wobble: CGFloat = 0.14 * n(27 + ph * 3, ph) + 0.08 * n(61 + ph * 5, ph * 2.3) + 0.05 * n(97, ph * 4)
            let fl: CGFloat = 1 + wobble * (1.2 - k * 0.5)
            let w: CGFloat = s * 0.3 * k * (1 + 0.05 * n(41, ph))
            let h: CGFloat = s * 1.25 * k * fl
            let sway: CGFloat = s * 0.07 * k * (n(9 + ph, ph) + 0.6 * n(17, ph * 1.7))
            let tip = x + sway, mid = x + sway * 0.5
            let shoulderL: CGFloat = 0.78 + 0.05 * n(53, ph), shoulderR: CGFloat = 0.86 + 0.05 * n(71, ph + 1)
            var p = Path()
            p.move(to: CGPoint(x: x - w, y: y))
            p.addCurve(to: CGPoint(x: mid - w * 0.35, y: y - h * shoulderL),
                       control1: CGPoint(x: x - w * 1.25, y: y - h * 0.35), control2: CGPoint(x: mid - w * 0.55, y: y - h * 0.55))
            p.addQuadCurve(to: CGPoint(x: tip - w * 0.05, y: y - h), control: CGPoint(x: tip - w * 0.15, y: y - h * 0.62))
            p.addQuadCurve(to: CGPoint(x: mid + w * 0.4, y: y - h * shoulderR), control: CGPoint(x: tip + w * 0.2, y: y - h * 0.7))
            p.addCurve(to: CGPoint(x: x + w, y: y),
                       control1: CGPoint(x: mid + w * 0.55, y: y - h * 0.55), control2: CGPoint(x: x + w * 1.25, y: y - h * 0.35))
            p.addQuadCurve(to: CGPoint(x: x - w, y: y), control: CGPoint(x: x, y: y + w * 0.5))
            p.closeSubpath()
            var layer = ctx
            layer.addFilter(.blur(radius: max(1, s * blur / 120)))
            layer.fill(p, with: .color(Color(hex: col)))
        }
        var sparks = ctx
        sparks.blendMode = .plusLighter
        for i in 0..<3 {
            let life = (t * (1.4 + Double(i) * 0.3) + Double(i) * 0.37).truncatingRemainder(dividingBy: 1)
            let a = (1 - life) * 0.7
            guard a > 0 else { continue }
            let sx: CGFloat = x + s * 0.12 * CGFloat(sin(Double(i) * 2.1 + t * 3))
            let sy: CGFloat = y - s * 1.1 - CGFloat(life) * s * 0.9
            let r: CGFloat = max(0.6, s * 0.025 * CGFloat(1 - life))
            sparks.fill(Path(ellipseIn: CGRect(x: sx - r, y: sy - r, width: r * 2, height: r * 2)), with: .color(rgba(255, 220, 140, a)))
        }
    }
}
