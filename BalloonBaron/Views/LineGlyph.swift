import SwiftUI

/// Small line drawings that stand in for emoji (prototype `GLYPH`): 24×24, round strokes like `ProtoIcon`, drawn in
/// the colour of the text around them (`foregroundStyle`). The path data is the prototype's, so both draw the same.
struct LineGlyph: View {
    enum Kind: Hashable { case gift, sun, crown, mosque, liberty, namsan, tokyoTower }
    let kind: Kind
    var size: CGFloat = 14
    /// Stroke width in the 24-unit grid; small glyphs take a heavier line so they still read next to bold text.
    var weight: CGFloat = 1.9
    /// Fills the closed shapes (the crown's gold) under the stroke.
    var fill: Color? = nil

    var body: some View {
        Canvas { ctx, sz in
            let k = min(sz.width, sz.height) / 24
            let path = Self.paths[kind, default: Path()].applying(CGAffineTransform(scaleX: k, y: k))
            if let fill { ctx.fill(path, with: .color(fill)) }
            ctx.stroke(path, with: .foreground, style: StrokeStyle(lineWidth: weight * k, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    /// SVG path data (absolute M, L, C, Q, Z only) and circles (x, y, r).
    private static let source: [Kind: (String, [(CGFloat, CGFloat, CGFloat)])] = [
        .gift: ("M3.5 8 L20.5 8 L20.5 11.5 L3.5 11.5 Z M5 11.5 L5 20.5 L19 20.5 L19 11.5 M12 8 L12 20.5 "
                + "M12 8 C9.5 8 6.5 6.8 7.2 4.6 C7.9 2.6 10.8 4 12 8 M12 8 C14.5 8 17.5 6.8 16.8 4.6 C16.1 2.6 13.2 4 12 8", []),
        .sun: ("M12 2.5 L12 4.5 M12 19.5 L12 21.5 M2.5 12 L4.5 12 M19.5 12 L21.5 12 M5.3 5.3 L6.7 6.7 "
               + "M17.3 17.3 L18.7 18.7 M5.3 18.7 L6.7 17.3 M17.3 6.7 L18.7 5.3", [(12, 12, 4.2)]),
        .crown: ("M4.5 17.5 L3 7.5 L8.5 11.5 L12 5 L15.5 11.5 L21 7.5 L19.5 17.5 Z M4.5 20.5 L19.5 20.5", []),
        .mosque: ("M2 20.5 L22 20.5 M6.5 14 C6.5 10.5 9 8.3 12 7.5 C15 8.3 17.5 10.5 17.5 14 Z M12 7.5 L12 5 "
                  + "M7 14 L7 20.5 M17 14 L17 20.5 M10.5 20.5 L10.5 18 C10.5 16.6 13.5 16.6 13.5 18 L13.5 20.5 "
                  + "M3.5 20.5 L3.5 8.5 M2.6 8.5 L3.5 4.5 L4.4 8.5 M2.6 12 L4.4 12 "
                  + "M20.5 20.5 L20.5 8.5 M19.6 8.5 L20.5 4.5 L21.4 8.5 M19.6 12 L21.4 12", []),
        .liberty: ("M6.5 20.5 L17.5 20.5 M8.5 20.5 L8.5 16.5 L15.5 16.5 L15.5 20.5 "
                   + "M9.4 16.5 C9.8 13.5 9.6 12 10.5 10.8 L13.5 10.8 C14.4 12 14.2 13.5 14.6 16.5 M10.4 6.9 L9.3 5.7 M12 6.5 L12 4.9 "
                   + "M13.5 10.8 L17 4.6 M16 4.6 L18 4.6 M17 3.7 C16.2 3 16.6 2.1 17 1.5 C17.4 2.1 17.8 3 17 3.7 Z M10.5 12 L8.6 13.8", [(12, 8.5, 1.7)]),
        .namsan: ("M2 20.5 L22 20.5 M2 20.5 C6 15.8 9 14.5 12 14.5 C15 14.5 18 15.8 22 20.5 "
                  + "M11 14.5 L11.3 10.5 M13 14.5 L12.7 10.5 M9.5 10.5 L14.5 10.5 L13.8 7.8 L10.2 7.8 Z M12 7.8 L12 2.5", []),
        .tokyoTower: ("M5.5 20.5 C8.5 16 10 11 11 5 M18.5 20.5 C15.5 16 14 11 13 5 M10.6 5 L13.4 5 M12 5 L12 1.8 "
                      + "M7.8 14.6 L16.2 14.6 L15.7 12.4 L8.3 12.4 Z M9.8 9.8 L14.2 9.8 L13.9 8.3 L10.1 8.3 Z M8.4 20.5 Q12 16.2 15.6 20.5", []),
    ]

    private static let paths: [Kind: Path] = source.mapValues { v in
        var p = parse(v.0)
        for (x, y, r) in v.1 { p.addEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)) }
        return p
    }

    private static func parse(_ d: String) -> Path {
        var path = Path()
        // Command letters are tokens of their own, even when glued to their first number ("M12").
        var list: [String] = []
        for part in d.split(separator: " ") {
            if let c = part.first, c.isLetter {
                list.append(String(c))
                if part.count > 1 { list.append(String(part.dropFirst())) }
            } else {
                list.append(String(part))
            }
        }
        var tokens = list[...]
        func num() -> CGFloat { CGFloat(Double(tokens.popFirst() ?? "0") ?? 0) }
        func pt() -> CGPoint { let x = num(); return CGPoint(x: x, y: num()) }
        var cmd = "M"
        while let t = tokens.first {
            if let c = t.first, c.isLetter {
                tokens.removeFirst()
                cmd = String(c)
                if cmd == "Z" { path.closeSubpath(); continue }
            }
            switch cmd {
            case "M": path.move(to: pt()); cmd = "L"
            case "L": path.addLine(to: pt())
            case "Q": let c = pt(); path.addQuadCurve(to: pt(), control: c)
            case "C": let c1 = pt(), c2 = pt(); path.addCurve(to: pt(), control1: c1, control2: c2)
            default: tokens.removeFirst()
            }
        }
        return path
    }
}
