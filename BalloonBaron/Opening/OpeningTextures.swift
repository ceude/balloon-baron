import CoreGraphics
import Foundation
import UIKit

/// The film's textures, painted in code like the prototype's canvas `tex()` calls: the same strokes in the same order, so
/// they use the seeded generator the same way. Drawn with a top-left origin, as a canvas is.
enum OpeningTextures {
    private static let space = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()

    /// A canvas of `w`×`h`: optional raw pixels first (`putImageData`), then drawing.
    static func canvas(_ w: Int, _ h: Int, pixels: (UnsafeMutablePointer<UInt8>) -> Void = { _ in },
                       _ draw: (CGContext, CGFloat, CGFloat) -> Void = { _, _, _ in }) -> CGImage? {
        guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4, space: space,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
              let data = ctx.data?.bindMemory(to: UInt8.self, capacity: w * h * 4) else { return nil }
        // Rows in memory run top-down, like a canvas's image data.
        pixels(data)
        ctx.translateBy(x: 0, y: CGFloat(h))
        ctx.scaleBy(x: 1, y: -1)
        ctx.interpolationQuality = .high
        draw(ctx, CGFloat(w), CGFloat(h))
        return ctx.makeImage()
    }

    static func rgba(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> CGColor {
        CGColor(colorSpace: space, components: [CGFloat(r / 255), CGFloat(g / 255), CGFloat(b / 255), CGFloat(max(0, min(1, a)))])
            ?? CGColor(gray: 0, alpha: 1)
    }

    static func hex(_ s: String, _ a: Double = 1) -> CGColor {
        let v = UInt32(s.hasPrefix("#") ? String(s.dropFirst()) : s, radix: 16) ?? 0
        return rgba(Double((v >> 16) & 0xff), Double((v >> 8) & 0xff), Double(v & 0xff), a)
    }

    /// CSS `hsl(h, s%, l%)`.
    static func hsl(_ h: Double, _ s: Double, _ l: Double) -> CGColor {
        let s = s / 100, l = l / 100
        func f(_ n: Double) -> Double {
            let k = (n + h / 30).truncatingRemainder(dividingBy: 12), a = s * min(l, 1 - l)
            return l - a * max(-1, min(k - 3, min(9 - k, 1)))
        }
        return rgba(f(0) * 255, f(8) * 255, f(4) * 255)
    }

    static func fillRect(_ c: CGContext, _ col: CGColor, _ x: Double, _ y: Double, _ w: Double, _ h: Double) {
        c.setFillColor(col)
        c.fill(CGRect(x: x, y: y, width: w, height: h))
    }

    /// `ellipse(x, y, rx, ry, rotation)` filled.
    static func ellipse(_ c: CGContext, _ col: CGColor, _ x: Double, _ y: Double, _ rx: Double, _ ry: Double, _ rot: Double = 0) {
        c.saveGState()
        c.translateBy(x: x, y: y)
        c.rotate(by: rot)
        c.setFillColor(col)
        c.fillEllipse(in: CGRect(x: -rx, y: -ry, width: rx * 2, height: ry * 2))
        c.restoreGState()
    }

    /// A rectangle filled with a vertical linear gradient between two points.
    static func gradientRect(_ c: CGContext, _ rect: CGRect, from: CGPoint, to: CGPoint, _ stops: [(CGFloat, CGColor)]) {
        guard let g = CGGradient(colorsSpace: space, colors: stops.map(\.1) as CFArray, locations: stops.map(\.0)) else { return }
        c.saveGState()
        c.clip(to: rect)
        c.drawLinearGradient(g, start: from, end: to, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        c.restoreGState()
    }

    /// `glowTex`: a soft white dot, tinted (three.js multiplies the sprite's color in; here it's baked).
    static func glow(_ tint: F3 = F3(1, 1, 1)) -> CGImage? {
        canvas(128, 128) { c, w, _ in
            let col = { (a: Double) in rgba(Double(tint.x) * 255, Double(tint.y) * 255, Double(tint.z) * 255, a) }
            guard let g = CGGradient(colorsSpace: space, colors: [col(1), col(0.5), col(0)] as CFArray, locations: [0, 0.25, 1]) else { return }
            c.drawRadialGradient(g, startCenter: CGPoint(x: w / 2, y: w / 2), startRadius: 0, endCenter: CGPoint(x: w / 2, y: w / 2),
                                 endRadius: w / 2, options: [])
        }
    }

    /// Tuff mottled with pocks and faint drip stains.
    static func mottle(_ rnd: inout Mulberry32) -> CGImage? {
        let w = 512, h = 512
        var r = rnd
        let img = canvas(w, h, pixels: { d in
            for j in 0..<h {
                for i in 0..<w {
                    let x = Double(i), y = Double(j)
                    let v = 0.86 + n3(x * 0.02, y * 0.02, 1) * 0.16 + n3(x * 0.09, y * 0.09, 4) * 0.06 + n3(x * 0.3, y * 0.05, 7) * 0.04
                    let o = (j * w + i) * 4, b = UInt8(max(0, min(1, v)) * 255)
                    d[o] = b; d[o + 1] = b; d[o + 2] = b; d[o + 3] = 255
                }
            }
        }) { c, w, hh in
            for _ in 0..<1400 {
                let a = r.next() * 0.18, x = r.next() * Double(w), y = r.next() * Double(hh), rad = r.next() * 2.6
                ellipse(c, rgba(70, 45, 35, a), x, y, rad, rad)
            }
            for _ in 0..<70 {
                let sx = r.next() * Double(w), sy = r.next() * Double(hh), len = 30 + r.next() * 140
                let x0 = sx - 2 - r.next() * 4, ww = 4 + r.next() * 8
                gradientRect(c, CGRect(x: x0, y: sy, width: ww, height: len), from: CGPoint(x: sx, y: sy), to: CGPoint(x: sx, y: sy + len),
                             [(0, rgba(90, 60, 45, 0.12)), (1, rgba(90, 60, 45, 0))])
            }
        }
        rnd = r
        return img
    }

    /// The ground: grit and small stones on white (the terrain's vertex colors tint it).
    static func grit(_ rnd: inout Mulberry32) -> CGImage? {
        var r = rnd
        let img = canvas(256, 256) { c, w, hh in
            fillRect(c, rgba(255, 255, 255), 0, 0, Double(w), Double(hh))
            for _ in 0..<2600 {
                let v = Double(Int(150 + r.next() * 105)), a = 0.12 + r.next() * 0.2
                let x = r.next() * Double(w), y = r.next() * Double(hh), ww = 1 + r.next() * 3, h2 = 1 + r.next() * 2
                fillRect(c, rgba(v, v - 20, v - 40, a), x, y, ww, h2)
            }
            for _ in 0..<90 {
                let a = 0.15 + r.next() * 0.2
                let x = r.next() * Double(w), y = r.next() * Double(hh), rx = 2 + r.next() * 4, ry = 1.5 + r.next() * 3, rot = r.next() * 3
                ellipse(c, rgba(110, 80, 60, a), x, y, rx, ry, rot)
            }
        }
        rnd = r
        return img
    }

    /// A house front: plaster (mottled, patched, cracked) or cut stone, windows with sills and shutters, a door or an arcade.
    static func facade(_ kind: Int, _ rnd: inout Mulberry32) -> CGImage? {
        var r = rnd
        let img = canvas(512, 512) { c, wf, hf in
            let w = Double(wf), hh = Double(hf)
            fillRect(c, hex(["#f4e8d4", "#ead6b6", "#f2e2c6", "#efdcc0", "#f6ecdc"][kind]), 0, 0, w, hh)
            if kind == 1 || kind == 3 {
                var yy = 0.0
                while yy < hh {
                    let ch = 22 + r.next() * 16
                    var xx = -r.next() * 40
                    while xx < w {
                        let cw = 34 + r.next() * 46
                        let col = hsl(30 + r.next() * 10, 28 + r.next() * 14, 72 + r.next() * 12)
                        fillRect(c, col, xx + 1.5, yy + 1.5, cw - 3, ch - 3)
                        xx += cw
                    }
                    yy += ch
                }
            } else {
                for _ in 0..<70 {
                    let col = rgba(150 + r.next() * 60, 120 + r.next() * 50, 90 + r.next() * 40, 0.06 + r.next() * 0.1)
                    let x = r.next() * w, y = r.next() * hh, rx = 10 + r.next() * 60, ry = 6 + r.next() * 40, rot = r.next() * 3
                    ellipse(c, col, x, y, rx, ry, rot)
                }
                c.setStrokeColor(rgba(110, 80, 60, 0.25))
                c.setLineWidth(1)
                for _ in 0..<8 {
                    var cx = r.next() * w, cy = r.next() * hh
                    c.beginPath()
                    c.move(to: CGPoint(x: cx, y: cy))
                    for _ in 0..<6 {
                        cx += (r.next() - 0.5) * 30
                        cy += 6 + r.next() * 16
                        c.addLine(to: CGPoint(x: cx, y: cy))
                    }
                    c.strokePath()
                }
            }
            for _ in 0..<2500 {
                let a = r.next() * 0.08, x = r.next() * w, y = r.next() * hh
                fillRect(c, rgba(90, 60, 40, a), x, y, 2, 2)
            }
            // dust at the foot
            gradientRect(c, CGRect(x: 0, y: 0, width: w, height: hh), from: CGPoint(x: 0, y: hh * 0.75), to: CGPoint(x: 0, y: hh),
                         [(0, rgba(120, 80, 50, 0)), (1, rgba(120, 80, 50, 0.28))])
            let shutter = hex(["#3d6a7a", "#6a4a2e", "#5a7a4a", "#8a3a2a"][kind % 4])
            func win(_ wx: Double, _ wy: Double, _ ww: Double, _ wh: Double, _ arch: Bool) {
                c.setFillColor(hex("#2a1c16"))
                c.beginPath()
                c.move(to: CGPoint(x: wx, y: wy + wh))
                c.addLine(to: CGPoint(x: wx, y: wy + (arch ? ww / 2 : 0)))
                if arch {
                    c.addArc(center: CGPoint(x: wx + ww / 2, y: wy + ww / 2), radius: ww / 2, startAngle: .pi, endAngle: 2 * .pi, clockwise: false)
                } else {
                    c.addLine(to: CGPoint(x: wx + ww, y: wy))
                }
                c.addLine(to: CGPoint(x: wx + ww, y: wy + wh))
                c.closePath()
                c.fillPath()
                fillRect(c, hex("#d8c2a0"), wx - 6, wy + wh, ww + 12, 7)
                if !arch {
                    fillRect(c, shutter, wx - ww * 0.45, wy, ww * 0.42, wh)
                    fillRect(c, shutter, wx + ww * 1.03, wy, ww * 0.42, wh)
                }
            }
            func archDoor(_ ax: Double, _ top: Double, _ rad: Double, _ col: CGColor) {
                c.setFillColor(col)
                c.beginPath()
                c.move(to: CGPoint(x: ax, y: hh))
                c.addLine(to: CGPoint(x: ax, y: top))
                c.addArc(center: CGPoint(x: ax + rad, y: top), radius: rad, startAngle: .pi, endAngle: 2 * .pi, clockwise: false)
                c.addLine(to: CGPoint(x: ax + rad * 2, y: hh))
                c.closePath()
                c.fillPath()
            }
            if kind == 4 {
                for i in 0..<4 { archDoor(24 + Double(i) * 122, hh - 110, 46, hex("#3a2a20")) }
                win(90, 120, 46, 70, true)
                win(330, 120, 46, 70, true)
            } else {
                win(70, 110, 52, 74, kind == 2)
                win(380, 110, 52, 74, kind == 2)
                win(70, 300, 52, 74, kind != 0)
                archDoor(250, hh - 120, 40, hex("#4a3020"))
                fillRect(c, hex("#6a4428"), 256, hh - 116, 68, 116)
            }
        }
        rnd = r
        return img
    }

    /// The kilim on the terrace: red field, gold border, lozenges.
    static func kilim() -> CGImage? {
        canvas(512, 320) { c, wf, hf in
            let w = Double(wf), hh = Double(hf)
            fillRect(c, hex("#9c2a22"), 0, 0, w, hh)
            c.setStrokeColor(hex("#e8c070"))
            c.setLineWidth(10)
            c.stroke(CGRect(x: 14, y: 14, width: w - 28, height: hh - 28))
            func lozenge(_ cx: Double, _ cy: Double, _ rx: Double, _ ry: Double, _ col: CGColor) {
                c.setFillColor(col)
                c.beginPath()
                c.move(to: CGPoint(x: cx, y: cy - ry))
                c.addLine(to: CGPoint(x: cx + rx, y: cy))
                c.addLine(to: CGPoint(x: cx, y: cy + ry))
                c.addLine(to: CGPoint(x: cx - rx, y: cy))
                c.closePath()
                c.fillPath()
            }
            for i in 0..<5 {
                let cx = 70 + Double(i) * 93, cy = hh / 2
                lozenge(cx, cy, 36, 70, hex(["#1f3a5a", "#e8c070", "#f2ead8", "#1f3a5a", "#e8c070"][i]))
                lozenge(cx, cy, 15, 30, hex("#9c2a22"))
            }
            for i in 0..<40 {
                let col = hex(i % 2 == 1 ? "#e8c070" : "#1f3a5a")
                fillRect(c, col, 30 + Double(i) * 11.5, 26, 6, 10)
                fillRect(c, col, 30 + Double(i) * 11.5, hh - 36, 6, 10)
            }
        }
    }

    static func wicker() -> CGImage? {
        canvas(256, 256) { c, w, hh in
            fillRect(c, hex("#7a4e2a"), 0, 0, Double(w), Double(hh))
            for j in 0..<32 {
                for i in 0..<16 { fillRect(c, hex((i + j) % 2 == 1 ? "#8c5c32" : "#5e3a1e"), Double(i * 16 + (j % 2) * 8), Double(j * 8), 14, 7) }
            }
        }
    }

    /// The old envelope on the field, faded stripes.
    static func oldCloth(_ rnd: inout Mulberry32) -> CGImage? {
        var r = rnd
        let img = canvas(512, 128) { c, wf, hf in
            let w = Double(wf), hh = Double(hf)
            for i in 0..<12 { fillRect(c, hex(["#b0563a", "#d8b47a"][i % 2]), 0, Double(i) * hh / 12, w, hh / 12 + 1) }
            gradientRect(c, CGRect(x: 0, y: 0, width: w, height: hh), from: .zero, to: CGPoint(x: w, y: 0),
                         [(0, rgba(240, 220, 190, 0.35)), (1, rgba(60, 30, 20, 0.15))])
            for _ in 0..<500 {
                let x = r.next() * w, y = r.next() * hh
                fillRect(c, rgba(60, 30, 20, 0.25), x, y, 2, 2)
            }
        }
        rnd = r
        return img
    }

    /// An envelope's gores: sixteen stripes cycling the colors, darker at the crown.
    static func gores(_ cols: [String]) -> CGImage? {
        canvas(512, 256) { c, wf, hf in
            let w = Double(wf), hh = Double(hf)
            for i in 0..<16 { fillRect(c, hex(cols[i % cols.count]), Double(i) * w / 16, 0, w / 16 + 1, hh) }
            gradientRect(c, CGRect(x: 0, y: 0, width: w, height: hh), from: .zero, to: CGPoint(x: 0, y: hh),
                         [(0, rgba(0, 0, 0, 0.28)), (0.22, rgba(0, 0, 0, 0))])
        }
    }

    /// The company's envelope: its two colors in gores, a band round the middle with the company's name on both sides.
    static func hero(colors: [String], name: String) -> CGImage? {
        let c0 = colors.first ?? "#ff5e3a", c1 = colors.count > 1 ? colors[1] : "#ffc23d"
        return canvas(1024, 512) { c, wf, hf in
            let w = Double(wf), hh = Double(hf)
            for i in 0..<16 { fillRect(c, hex(i % 2 == 1 ? c1 : c0), Double(i) * w / 16, 0, w / 16 + 1, hh) }
            fillRect(c, hex(c0), 0, hh * 0.5, w, hh * 0.12)
            let font = UIFont(name: "BarlowCondensed-ExtraBold", size: hh * 0.09) ?? UIFont.systemFont(ofSize: hh * 0.09, weight: .heavy)
            let text = NSAttributedString(string: name, attributes: [.font: font, .foregroundColor: UIColor(cgColor: hex(c1))])
            let size = text.size()
            UIGraphicsPushContext(c)
            for u in [0.25, 0.75] {
                text.draw(at: CGPoint(x: w * u - size.width / 2, y: hh * 0.56 - size.height / 2))
            }
            UIGraphicsPopContext()
        }
    }

    /// Valley mist: a soft, cloudy blot (white, its alpha the shape).
    static func mist(_ fbm: (Double, Double, Int) -> Double) -> CGImage? {
        let w = 256, h = 256
        return canvas(w, h, pixels: { d in
            for j in 0..<h {
                for i in 0..<w {
                    let dd = hypot(Double(i) - Double(w) / 2, Double(j) - Double(h) / 2) / (Double(w) / 2)
                    let v = max(0, min(1, (1 - dd) * (0.55 + fbm(Double(i) * 0.03, Double(j) * 0.03, 4) * 1.4)))
                    let o = (j * w + i) * 4, a = UInt8(v * 255)
                    // premultiplied white
                    d[o] = a; d[o + 1] = a; d[o + 2] = a; d[o + 3] = a
                }
            }
        })
    }
}
