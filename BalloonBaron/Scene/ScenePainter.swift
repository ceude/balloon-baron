import SwiftUI
import BalloonBaronCore

/// A balloon drifting in the background (rivals, your own fleet, Fiesta crowds). Positions in meters.
struct BackgroundBalloon {
    var x: Double
    var alt: Double
    var colors: [String]
    var phase: Double
    var scale: Double
}

/// Maps world meters to screen points, like the prototype's `sx` / `sy`.
struct SceneCamera {
    let size: CGSize
    let groundY: CGFloat
    let topY: CGFloat
    let camX: Double
    let kx: CGFloat
    var ky: CGFloat { (groundY - topY) / 650 }
    var viewHeight: CGFloat { groundY - topY }

    init(size: CGSize, groundY: CGFloat, topY: CGFloat, focusX: Double, focusAt: CGFloat = 0.36) {
        self.size = size
        self.groundY = groundY
        self.topY = topY
        kx = min(max(size.width / 900, 0.4), 1.4)
        camX = focusX - Double(size.width * focusAt / kx)
    }

    func sx(_ wx: Double) -> CGFloat { CGFloat(wx - camX) * kx }
    func sy(_ alt: Double) -> CGFloat { groundY - CGFloat(alt) * ky }
}

/// Port of the prototype's canvas drawing: sky, sun, ridges, fairy chimneys (mesas and cottonwoods
/// in Albuquerque, temples, date palms and the Nile in Luxor), power lines, snow, and balloons with designs
/// and sponsor banners.
enum ScenePainter {
    // MARK: Colors

    static func rgb(_ hex: String) -> (Double, Double, Double) {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let v = UInt64(s, radix: 16) ?? 0
        return (Double((v >> 16) & 0xff), Double((v >> 8) & 0xff), Double(v & 0xff))
    }

    /// `mix(a, b, k)`: blend two hex colors.
    static func mix(_ a: String, _ b: String, _ k: Double) -> Color {
        let k = min(max(k, 0), 1), x = rgb(a), y = rgb(b)
        return Color(red: (x.0 + (y.0 - x.0) * k) / 255, green: (x.1 + (y.1 - x.1) * k) / 255, blue: (x.2 + (y.2 - x.2) * k) / 255)
    }

    static func mixHex(_ a: String, _ b: String, _ k: Double) -> String {
        let k = min(max(k, 0), 1), x = rgb(a), y = rgb(b)
        let r = Int((x.0 + (y.0 - x.0) * k).rounded()), g = Int((x.1 + (y.1 - x.1) * k).rounded()), bl = Int((x.2 + (y.2 - x.2) * k).rounded())
        return String(format: "#%02x%02x%02x", r, g, bl)
    }

    // MARK: Shapes

    static func ell(_ ctx: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ c: Color) {
        let rx = max(0.1, rx), ry = max(0.1, ry)
        ctx.fill(Path(ellipseIn: CGRect(x: x - rx, y: y - ry, width: rx * 2, height: ry * 2)), with: .color(c))
    }

    static func rect(_ ctx: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ c: Color) {
        ctx.fill(Path(CGRect(x: x, y: y, width: w, height: h)), with: .color(c))
    }

    static func chimney(_ ctx: inout GraphicsContext, _ x: CGFloat, _ base: CGFloat, _ w: CGFloat, _ hgt: CGFloat,
                        body: Color, shade: Color?, cap: Color) {
        var p = Path()
        p.move(to: CGPoint(x: x - w / 2, y: base))
        p.addQuadCurve(to: CGPoint(x: x - w * 0.12, y: base - hgt), control: CGPoint(x: x - w * 0.32, y: base - hgt * 0.55))
        p.addLine(to: CGPoint(x: x + w * 0.12, y: base - hgt))
        p.addQuadCurve(to: CGPoint(x: x + w / 2, y: base), control: CGPoint(x: x + w * 0.32, y: base - hgt * 0.55))
        p.closeSubpath()
        ctx.fill(p, with: .color(body))
        if let shade {
            var s = Path()
            s.move(to: CGPoint(x: x + w * 0.05, y: base - hgt))
            s.addLine(to: CGPoint(x: x + w * 0.12, y: base - hgt))
            s.addQuadCurve(to: CGPoint(x: x + w / 2, y: base), control: CGPoint(x: x + w * 0.32, y: base - hgt * 0.55))
            s.addLine(to: CGPoint(x: x + w * 0.1, y: base))
            s.closeSubpath()
            ctx.fill(s, with: .color(shade))
        }
        ell(&ctx, x, base - hgt, w * 0.25, w * 0.1, cap)
        ell(&ctx, x, base - hgt - w * 0.07, w * 0.15, w * 0.09, cap)
    }

    static func mesa(_ ctx: inout GraphicsContext, _ x: CGFloat, _ base: CGFloat, _ w: CGFloat, _ hgt: CGFloat, body: Color, cap: Color) {
        var p = Path()
        p.move(to: CGPoint(x: x - w / 2, y: base))
        p.addLine(to: CGPoint(x: x - w * 0.32, y: base - hgt))
        p.addLine(to: CGPoint(x: x + w * 0.3, y: base - hgt))
        p.addLine(to: CGPoint(x: x + w / 2, y: base))
        p.closeSubpath()
        ctx.fill(p, with: .color(body))
        rect(&ctx, x - w * 0.33, base - hgt - 2, w * 0.64, 4, cap)
    }

    static func tree(_ ctx: inout GraphicsContext, _ x: CGFloat, _ base: CGFloat, _ w: CGFloat, _ hgt: CGFloat, crown: Color, trunk: Color) {
        rect(&ctx, x - w * 0.07, base - hgt * 0.45, w * 0.14, hgt * 0.45, trunk)
        ell(&ctx, x, base - hgt * 0.62, w * 0.5, hgt * 0.3, crown)
        ell(&ctx, x - w * 0.22, base - hgt * 0.5, w * 0.3, hgt * 0.2, crown)
        ell(&ctx, x + w * 0.2, base - hgt * 0.78, w * 0.3, hgt * 0.2, crown)
    }

    /// `datePalm()`: a gently curved trunk and a crown of drooping fronds (Luxor).
    static func datePalm(_ ctx: inout GraphicsContext, _ x: CGFloat, _ base: CGFloat, _ hgt: CGFloat, leaf: Color, trunk: Color) {
        let top = CGPoint(x: x + hgt * 0.08, y: base - hgt)
        var t = Path()
        t.move(to: CGPoint(x: x, y: base))
        t.addQuadCurve(to: top, control: CGPoint(x: x + hgt * 0.14, y: base - hgt * 0.5))
        ctx.stroke(t, with: .color(trunk), style: StrokeStyle(lineWidth: max(1.5, hgt * 0.06), lineCap: .round))
        let len = hgt * 0.42
        for i in 0..<7 {
            var g = ctx
            g.translateBy(x: top.x, y: top.y)
            g.rotate(by: .radians(-Double.pi * (0.08 + Double(i) * 0.14)))
            var f = Path()
            f.move(to: .zero)
            f.addQuadCurve(to: CGPoint(x: len, y: len * 0.25), control: CGPoint(x: len * 0.5, y: -len * 0.18))
            f.addQuadCurve(to: .zero, control: CGPoint(x: len * 0.5, y: len * 0.02))
            g.fill(f, with: .color(leaf))
        }
    }

    /// `temple()`: two pylons and a row of columns under a lintel (Luxor).
    static func temple(_ ctx: inout GraphicsContext, _ x: CGFloat, _ base: CGFloat, _ w: CGFloat, _ hgt: CGFloat, _ col: Color) {
        var p = Path()
        p.move(to: CGPoint(x: x - w / 2, y: base))
        p.addLine(to: CGPoint(x: x - w * 0.44, y: base - hgt))
        p.addLine(to: CGPoint(x: x - w * 0.2, y: base - hgt))
        p.addLine(to: CGPoint(x: x - w * 0.16, y: base))
        p.closeSubpath()
        p.move(to: CGPoint(x: x + w / 2, y: base))
        p.addLine(to: CGPoint(x: x + w * 0.44, y: base - hgt))
        p.addLine(to: CGPoint(x: x + w * 0.2, y: base - hgt))
        p.addLine(to: CGPoint(x: x + w * 0.16, y: base))
        p.closeSubpath()
        for i in 0..<3 {
            p.addRect(CGRect(x: x - w * 0.12 + CGFloat(i) * w * 0.1 - w * 0.02, y: base - hgt * 0.7, width: w * 0.04, height: hgt * 0.7))
        }
        p.addRect(CGRect(x: x - w * 0.16, y: base - hgt * 0.76, width: w * 0.32, height: hgt * 0.08))
        ctx.fill(p, with: .color(col))
    }

    /// JavaScript's `((a % m) + m) % m`.
    static func pmod(_ a: Double, _ m: Double) -> Double {
        let r = a.truncatingRemainder(dividingBy: m)
        return r < 0 ? r + m : r
    }

    static func heart(_ ctx: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ c: Color) {
        ctx.fill(BalloonPainter.heart(x, y, s), with: .color(c))
    }

    /// Sponsor banner text and colors, per region.
    static func banner(_ sp: Sponsor, region: RegionID) -> String {
        let i = Sponsor.allCases.firstIndex(of: sp) ?? 0
        let texts: [String]
        switch region {
        case .cap: texts = ["HALI EVİ", "BAĞLAR", "PERİ BANK", "TURBO!"]
        case .abq: texts = ["GREEN CHILE", "WINERY", "TURQUOISE", "ROUTE 66!"]
        case .lux: texts = ["KARKADE", "PAPYRUS", "NILE CRUISE", "SCARAB"]
        }
        return texts[min(i, texts.count - 1)]
    }

    /// `balloon(x, y, R, …)`: y is the bottom of the basket.
    static func balloon(_ ctx: inout GraphicsContext, x: CGFloat, y: CGFloat, r R: CGFloat, colors: [String], burn: Bool = false,
                        alpha: Double = 1, ad: Sponsor? = nil, design: Design? = nil, region: RegionID = .cap, time T: Double = 0) {
        guard R > 0.5 else { return }
        var c = ctx
        c.opacity = alpha
        let top = y - R * 2.55, cy = top + R
        let main = Color(hex: design?.colors.first ?? colors.first ?? "#ff5e3a")
        let env = design?.shape.map { BalloonPainter.envelope($0, x: x, cy: cy, r: R) } ?? BalloonPainter.envelope(x: x, cy: cy, r: R)
        c.fill(env, with: .color(main))
        var inner = c
        inner.clip(to: env)
        if let d = design, d.colors.count >= 3 {
            BalloonPainter.paint(&inner, pattern: d.pattern, colors: d.colors, x: x, cy: cy, r: R, top: top)
        } else {
            BalloonPainter.stripes(&inner, color: Color(hex: colors.count > 1 ? colors[1] : "#ffc23d"), x: x, cy: cy, r: R)
        }
        if let ad {
            let col = ad.colors
            rect(&inner, x - R, cy + R * 0.12, R * 2, R * 0.52, Color(hex: col.bg))
            let text = Text(banner(ad, region: region))
                .font(.custom("BarlowCondensed-ExtraBold", size: max(7, (R * 0.36).rounded())))
                .foregroundColor(Color(hex: col.fg))
            inner.draw(text, at: CGPoint(x: x, y: cy + R * 0.38), anchor: .center)
        }
        let shade = Gradient(stops: [
            .init(color: Color.white.opacity(0.18), location: 0),
            .init(color: Color.black.opacity(0), location: 0.6),
            .init(color: Color(red: 40 / 255, green: 10 / 255, blue: 40 / 255).opacity(0.35), location: 1)
        ])
        inner.fill(Path(CGRect(x: x - R, y: top, width: R * 2, height: R * 3)),
                   with: .linearGradient(shade, startPoint: CGPoint(x: x - R, y: 0), endPoint: CGPoint(x: x + R, y: 0)))
        if design?.shape == .skull { BalloonPainter.skullFace(&c, x: x, cy: cy, r: R) }
        let by = cy + R * 1.55, bb = y - R * 0.32
        var ropes = Path()
        ropes.move(to: CGPoint(x: x - R * 0.22, y: by)); ropes.addLine(to: CGPoint(x: x - R * 0.24, y: bb))
        ropes.move(to: CGPoint(x: x + R * 0.22, y: by)); ropes.addLine(to: CGPoint(x: x + R * 0.24, y: bb))
        c.stroke(ropes, with: .color(Color(red: 60 / 255, green: 35 / 255, blue: 30 / 255).opacity(0.8)), lineWidth: 1)
        rect(&c, x - R * 0.3, bb, R * 0.6, R * 0.32, Color(hex: "#6b4426"))
        if burn {
            let f = 1 + sin(T * 40) * 0.2
            ell(&c, x, by + R * 0.02, R * 0.1, R * 0.28 * f, Color(red: 1, green: 200 / 255, blue: 90 / 255).opacity(0.95))
            ell(&c, x, by + R * 0.06, R * 0.05, R * 0.14 * f, Color(hex: "#fff4cc"))
        }
    }

    // MARK: Scenery

    /// `scenery()`: sky, sun, distant ridges and chimneys, background balloons, ground, river and snow.
    /// `p` is time of day, 0 = dawn, 1 = bright morning. Returns the view height above the ground.
    @discardableResult
    static func scenery(_ ctx: inout GraphicsContext, cam: SceneCamera, p: Double, region: RegionID, winter: Bool,
                        time T: Double, background: [BackgroundBalloon], inFlight: Bool) -> CGFloat {
        let W = cam.size.width, H = cam.size.height, groundY = cam.groundY, topY = cam.topY, kx = cam.kx, camX = cam.camX
        let desert = region == .abq, nile = region == .lux
        let sky = nile
            ? Gradient(stops: [.init(color: mix("#14203f", "#6aa8d8", p), location: 0), .init(color: mix("#6a4a6a", "#f8c890", p), location: 0.55),
                               .init(color: mix("#f2a050", "#fff0c0", p), location: 1)])
            : desert
            ? Gradient(stops: [.init(color: mix("#1d2450", "#6aa5d8", p), location: 0), .init(color: mix("#7a4a6a", "#f6c08a", p), location: 0.55),
                               .init(color: mix("#f39a5a", "#ffe6b0", p), location: 1)])
            : Gradient(stops: [.init(color: mix("#1b1840", "#5f8fc6", p), location: 0), .init(color: mix("#6b3e6e", "#f0b48c", p), location: 0.55),
                               .init(color: mix("#f08a4a", "#ffe2ac", p), location: 1)])
        ctx.fill(Path(CGRect(x: 0, y: 0, width: W, height: groundY)),
                 with: .linearGradient(sky, startPoint: .zero, endPoint: CGPoint(x: 0, y: groundY)))

        let sunX = W * 0.7 - CGFloat(camX) * kx * 0.02, sunY = groundY - (groundY - topY) * (0.04 + CGFloat(p) * 0.5), sr = min(W, H) * 0.05
        let glow = Gradient(colors: [Color(red: 1, green: 220 / 255, blue: 150 / 255).opacity(0.55), Color(red: 1, green: 200 / 255, blue: 140 / 255).opacity(0)])
        ctx.fill(Path(CGRect(x: sunX - sr * 6, y: sunY - sr * 6, width: sr * 12, height: sr * 12)),
                 with: .radialGradient(glow, center: CGPoint(x: sunX, y: sunY), startRadius: 0, endRadius: sr * 6))
        ell(&ctx, sunX, sunY, sr, sr, Color(hex: "#fff0c8"))

        let vh = groundY - topY
        if desert {
            // Sandia mountains, watermelon pink at sunrise.
            var m = Path()
            m.move(to: CGPoint(x: W * 0.15, y: groundY))
            var x = W * 0.15
            while x <= W + 40 {
                let wx = Double(x / kx + CGFloat(camX) * 0.08) * 0.006
                let k = min(max((x - W * 0.15) / (W * 0.3), 0), 1)
                m.addLine(to: CGPoint(x: x, y: groundY - vh * CGFloat(0.13 + 0.05 * sin(wx * 1.3 + 1) + 0.02 * sin(wx * 5.1)) * k))
                x += 18
            }
            m.addLine(to: CGPoint(x: W + 40, y: groundY))
            m.closeSubpath()
            ctx.fill(m, with: .color(mix("#4e2c4c", "#d98a96", p)))
        }
        if nile {
            // The Theban hills: flat-topped cliffs with the pyramid-shaped peak of al-Qurn.
            var m = Path()
            m.move(to: CGPoint(x: -20, y: groundY))
            var x: CGFloat = -20
            while x <= W + 40 {
                let w0 = Double(x / kx) + camX * 0.08
                let wx = w0 * 0.005, qx = w0.truncatingRemainder(dividingBy: 2400)
                let k = 0.12 + 0.015 * sin(wx * 7.3) + max(0, 0.09 - abs(qx - 1200) / 1200 * 0.25)
                m.addLine(to: CGPoint(x: x, y: groundY - vh * CGFloat(k)))
                x += 14
            }
            m.addLine(to: CGPoint(x: W + 40, y: groundY))
            m.closeSubpath()
            ctx.fill(m, with: .color(mix("#5a3a4a", "#e0a87c", p)))
        }
        var ridge = Path()
        ridge.move(to: CGPoint(x: 0, y: groundY))
        var rx: CGFloat = -20
        while rx <= W + 40 {
            let wx = Double(rx / kx + CGFloat(camX) * 0.15) * 0.01
            ridge.addLine(to: CGPoint(x: rx, y: groundY - vh * CGFloat(0.11 + 0.06 * sin(wx * 1.7) + 0.035 * sin(wx * 4.3))))
            rx += 40
        }
        ridge.addLine(to: CGPoint(x: W, y: groundY))
        ridge.closeSubpath()
        ctx.fill(ridge, with: .color(nile ? mix("#4a4038", "#c8a070", p) : desert ? mix("#5a3a40", "#c99a74", p) : mix("#4a3050", "#c9967e", p)))

        var r = Mulberry32(seed: 5)
        for i in 0..<40 {
            let wx = Double(i) * 130 + r.next() * 60 - 600
            let x = CGFloat(wx - camX * 0.45) * kx
            let hh = vh * CGFloat(0.07 + r.next() * 0.1), ww = hh * CGFloat(0.4 + r.next() * 0.2)
            if x < -60 || x > W + 60 { continue }
            let snow = Color(hex: "#eef2f8")
            if nile {
                if i % 5 == 2 {
                    temple(&ctx, x, groundY + 2, ww * 3, hh * 0.55, mix("#6a5040", "#e2c08a", p))
                } else {
                    datePalm(&ctx, x, groundY + 2, hh * 0.9, leaf: mix("#1e3a22", "#4a7a3a", p), trunk: mix("#3a2a1e", "#8a6a44", p))
                }
            } else if desert {
                mesa(&ctx, x, groundY + 2, ww * 2.6, hh * 0.6, body: mix("#5e3a3a", "#c98a5e", p), cap: winter ? snow : mix("#4a2c2c", "#a86a44", p))
            } else {
                chimney(&ctx, x, groundY + 2, ww, hh, body: mix("#5c3a4a", "#d9a07a", p), shade: nil, cap: winter ? snow : mix("#3e2836", "#9a6448", p))
            }
        }

        let par = inFlight ? 0.7 : 1.0
        for b in background {
            let xx = CGFloat(b.x - camX * par) * kx
            guard xx > -50 && xx < W + 50 else { continue }
            let yy = cam.sy(b.alt + sin(T * 0.4 + b.phase) * 6)
            balloon(&ctx, x: xx, y: yy, r: max(6, vh * 0.045 * CGFloat(b.scale) * (inFlight ? 0.75 : 1)), colors: b.colors,
                    alpha: inFlight ? 0.45 : 0.92, region: region)
        }

        let ground = winter
            ? Gradient(colors: [mix("#c9d3e2", "#eef3fa", p), mix("#7d879c", "#b9c4d6", p)])
            : nile ? Gradient(colors: [mix("#3a4a2a", "#9ab85a", p), mix("#22301a", "#6a8a3a", p)])
            : desert ? Gradient(colors: [mix("#6a4a30", "#d8b07a", p), mix("#3a2a1e", "#a07848", p)])
            : Gradient(colors: [mix("#5a3a32", "#c48a62", p), mix("#2e1e22", "#7a5040", p)])
        ctx.fill(Path(CGRect(x: 0, y: groundY, width: W, height: H - groundY)),
                 with: .linearGradient(ground, startPoint: CGPoint(x: 0, y: groundY), endPoint: CGPoint(x: 0, y: H)))
        if desert {
            // Rio Grande.
            rect(&ctx, 0, groundY + (H - groundY) * 0.42, W, max(3, (H - groundY) * 0.07), mix("#2e4a66", "#7fb6d6", p))
        }
        if nile {
            // The Nile across the floodplain, a felucca on it, sugar cane rows on the near bank.
            let ny = groundY + (H - groundY) * 0.3, nh = max(6, (H - groundY) * 0.16)
            rect(&ctx, 0, ny, W, nh, mix("#1e4a6a", "#5aa8d0", p))
            var glints = Path()
            for i in 0..<12 {
                let gx = CGFloat(pmod(Double(i) * 137 - camX * Double(kx) * 0.6, Double(W + 60))) - 30
                glints.addRect(CGRect(x: gx, y: ny + nh * (0.3 + CGFloat(i % 3) * 0.2), width: 18, height: 1.5))
            }
            ctx.fill(glints, with: .color(Color.white.opacity(0.18)))
            let fx = CGFloat(pmod(Double(W) * 0.3 - camX * Double(kx) * 0.6, Double(W + 200))) - 100, fy = ny + nh * 0.55
            var sail = Path()
            sail.move(to: CGPoint(x: fx, y: fy))
            sail.addLine(to: CGPoint(x: fx + 4, y: fy - 22))
            sail.addLine(to: CGPoint(x: fx + 16, y: fy))
            sail.closeSubpath()
            ctx.fill(sail, with: .color(Color(hex: "#f2eee6")))
            rect(&ctx, fx - 6, fy, 26, 4, Color(hex: "#6b4426"))
            var cane = Path()
            var cx = CGFloat(pmod(-camX * Double(kx), 9))
            while cx < W {
                cane.move(to: CGPoint(x: cx, y: H))
                cane.addLine(to: CGPoint(x: cx + 3, y: ny + nh + 8))
                cx += 9
            }
            ctx.stroke(cane, with: .color(mix("#2a3a1a", "#5a7a2a", p)), lineWidth: 2)
        }
        if winter {
            rect(&ctx, 0, 0, W, groundY, Color(red: 200 / 255, green: 220 / 255, blue: 1).opacity(0.12))
            for i in 0..<90 {
                let fi = Double(i)
                let sx2 = CGFloat((fi * 97.3 + T * (14 + Double(i % 4) * 6)).truncatingRemainder(dividingBy: Double(W + 20))) - 10 + CGFloat(sin(T + fi) * 6)
                let sy2 = CGFloat((fi * 53.7 + T * (26 + Double(i % 5) * 9)).truncatingRemainder(dividingBy: Double(H)))
                let rr = 1 + CGFloat(i % 3) * 0.6
                ell(&ctx, sx2, sy2, rr, rr, Color.white.opacity(0.85))
            }
        }
        return vh
    }

    /// Moves background balloons with the wind and wraps them around the view.
    static func drift(_ bg: inout [BackgroundBalloon], weather: Weather, cam: SceneCamera, dt: Double, time T: Double, inFlight: Bool) {
        let par = inFlight ? 0.7 : 1.0, cx = cam.camX * par, span = Double(cam.size.width / cam.kx)
        for i in bg.indices {
            bg[i].x += FlightWorld.wind(at: bg[i].alt, time: T * 6, weather) * dt * (inFlight ? FlightWorld.timeScale : 2)
            if bg[i].x > cx + span + 900 { bg[i].x = cx - 600 }
            if bg[i].x < cx - 900 { bg[i].x = cx + span + 500 }
        }
    }

    /// `buildWorld()`'s background balloons: rivals' fleets, the rest of yours, and Fiesta crowds.
    static func backgroundBalloons(_ s: GameState) -> [BackgroundBalloon] {
        var owners: [[String]] = []
        for r in s.rivals where r.alive { for _ in r.balloons { owners.append(r.colors) } }
        for _ in 0..<max(0, s.balloons.count - 1) { owners.append(s.colors) }
        if s.fiesta != nil {
            let sw = Studio.swatches
            for i in 0..<30 { owners.append([sw[i % sw.count], sw[(i + 3) % sw.count]]) }
        }
        var r = Mulberry32(seed: UInt32(truncatingIfNeeded: s.weather?.seed ?? 1) &+ 99)
        let n = min(s.fiesta != nil ? Rules.fiestaBalloons : 18, owners.count)
        return (0..<n).map { i in
            BackgroundBalloon(x: -400 + r.next() * 3800, alt: 60 + r.next() * 500, colors: owners[i % owners.count],
                              phase: r.next() * 6, scale: 0.55 + r.next() * 0.3)
        }
    }

    /// The landing field: green strip, two flags, the chase truck and trailer.
    static func landingField(_ ctx: inout GraphicsContext, cam: SceneCamera, target tx: Double, p: Double) {
        let gy = cam.groundY
        let x0 = cam.sx(tx - FlightWorld.landingZone), x1 = cam.sx(tx + FlightWorld.landingZone)
        rect(&ctx, x0, gy - 2, x1 - x0, 7, mix("#4b5a34", "#a7b46a", p))
        for fx in [tx - FlightWorld.landingZone, tx + FlightWorld.landingZone] { flag(&ctx, cam.sx(fx), gy, 22) }
        let trx = cam.sx(tx + 35)
        rect(&ctx, trx, gy - 13, 22, 9, Color(hex: "#f2eee6"))
        rect(&ctx, trx + 14, gy - 18, 9, 6, Color(hex: "#f2eee6"))
        rect(&ctx, trx - 18, gy - 10, 16, 6, Color(hex: "#7b5a3c"))
        for wx in [trx + 4, trx + 18, trx - 10] { ell(&ctx, wx, gy - 3, 3, 3, Color(hex: "#1d1418")) }
    }

    static func flag(_ ctx: inout GraphicsContext, _ X: CGFloat, _ gy: CGFloat, _ h: CGFloat) {
        var pole = Path()
        pole.move(to: CGPoint(x: X, y: gy)); pole.addLine(to: CGPoint(x: X, y: gy - h))
        ctx.stroke(pole, with: .color(Color(hex: "#2a1a14")), lineWidth: 1.5)
        var f = Path()
        f.move(to: CGPoint(x: X, y: gy - h)); f.addLine(to: CGPoint(x: X + 11, y: gy - h + 4)); f.addLine(to: CGPoint(x: X, y: gy - h + 8))
        f.closeSubpath()
        ctx.fill(f, with: .color(Color(hex: "#ffc23d")))
    }

    /// Power lines across the fields: two poles with crossarms, three sagging wires and an orange marker ball.
    static func powerLines(_ ctx: inout GraphicsContext, cam: SceneCamera, _ lines: [PowerLine], p: Double) {
        let W = cam.size.width, gy = cam.groundY, ky = cam.ky, sag = CGFloat(PowerLine.sag)
        let pole = mix("#8a8e98", "#e4e6ea", p), wire = mix("#c8cdd7", "#3c3c46", p)
        for wr in lines {
            let X0 = cam.sx(wr.x0), X1 = cam.sx(wr.x1)
            if X1 < -40 || X0 > W + 40 { continue }
            let top = gy - CGFloat(wr.h) * ky
            var poles = Path()
            poles.move(to: CGPoint(x: X0, y: gy)); poles.addLine(to: CGPoint(x: X0, y: top - 4))
            poles.move(to: CGPoint(x: X1, y: gy)); poles.addLine(to: CGPoint(x: X1, y: top - 4))
            ctx.stroke(poles, with: .color(pole), lineWidth: 3)
            var arms = Path()
            arms.move(to: CGPoint(x: X0 - 9, y: top)); arms.addLine(to: CGPoint(x: X0 + 9, y: top))
            arms.move(to: CGPoint(x: X1 - 9, y: top)); arms.addLine(to: CGPoint(x: X1 + 9, y: top))
            ctx.stroke(arms, with: .color(pole), lineWidth: 2)
            var wires = Path()
            for dx: CGFloat in [-8, 0, 8] {
                let y = top + (dx == 0 ? -4 : 0)
                wires.move(to: CGPoint(x: X0 + dx, y: y))
                wires.addQuadCurve(to: CGPoint(x: X1 + dx, y: y), control: CGPoint(x: (X0 + X1) / 2 + dx, y: y + sag * 2 * ky))
            }
            ctx.stroke(wires, with: .color(wire), lineWidth: 1.4)
            ell(&ctx, (X0 + X1) / 2, top + sag * ky, 3.2, 3.2, Color(hex: "#ff5e3a"))
        }
    }

    /// Fairy chimneys (or cottonwoods, or date palms) along the flight path, in front of the far scenery.
    static func obstacles(_ ctx: inout GraphicsContext, cam: SceneCamera, _ obs: [Obstacle], region: RegionID, p: Double) {
        let W = cam.size.width
        for c in obs {
            let x = cam.sx(c.x)
            if x < -80 || x > W + 80 { continue }
            switch region {
            case .abq:
                tree(&ctx, x, cam.groundY + 1, CGFloat(c.w) * cam.kx * 1.4, CGFloat(c.h) * cam.ky,
                     crown: mix(mixHex("#2e4a2a", "#7a9a52", p), "#9ab060", c.tone * 0.3), trunk: mix("#3a2a1e", "#6a4a30", p))
            case .lux:
                datePalm(&ctx, x, cam.groundY + 1, CGFloat(c.h) * cam.ky,
                         leaf: mix(mixHex("#1e3a22", "#4a7a3a", p), "#6a9a4a", c.tone * 0.3), trunk: mix("#3a2a1e", "#8a6a44", p))
            case .cap:
                chimney(&ctx, x, cam.groundY + 1, CGFloat(c.w) * cam.kx, CGFloat(c.h) * cam.ky,
                        body: mix(mixHex("#6a4038", "#e2b48a", p), "#d6a27a", c.tone * 0.3),
                        shade: mix("#4a2c2a", "#b07a58", p), cap: mix("#3a2420", "#7e5038", p))
            }
        }
    }
}
