import SwiftUI

/// Small line drawings that stand in for emoji (prototype `GLYPH`): 24×24, round strokes like `ProtoIcon`, drawn in
/// the colour of the text around them (`foregroundStyle`). The path data is the prototype's, so both draw the same.
struct LineGlyph: View {
    enum Kind: Hashable { case gift, sun, crown, bosphorus, liberty, namsan, skytree, burj, bigBen }
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
        // v137: Istanbul's Bosphorus Bridge over the water (it was a mosque)
        .bosphorus: ("M1.5 15 L22.5 15 M6 18.5 L6 4.5 M18 18.5 L18 4.5 M5 4.5 L7 4.5 M17 4.5 L19 4.5 M5.2 9 L6.8 9 "
                  + "M17.2 9 L18.8 9 M1.5 11 C3.5 10 5 8 6 5.5 C9 12.5 15 12.5 18 5.5 C19 8 20.5 10 22.5 11 "
                  + "M9 9.8 L9 15 M12 10.8 L12 15 M15 9.8 L15 15 "
                  + "M1.5 20.5 C3.5 19.3 5.5 19.3 7.5 20.5 C9.5 21.7 11.5 21.7 13.5 20.5 C15.5 19.3 17.5 19.3 19.5 20.5 C20.5 21.1 21.5 21.2 22.5 20.8", []),
        .liberty: ("M6.5 20.5 L17.5 20.5 M8.5 20.5 L8.5 16.5 L15.5 16.5 L15.5 20.5 "
                   + "M9.4 16.5 C9.8 13.5 9.6 12 10.5 10.8 L13.5 10.8 C14.4 12 14.2 13.5 14.6 16.5 M10.4 6.9 L9.3 5.7 M12 6.5 L12 4.9 "
                   + "M13.5 10.8 L17 4.6 M16 4.6 L18 4.6 M17 3.7 C16.2 3 16.6 2.1 17 1.5 C17.4 2.1 17.8 3 17 3.7 Z M10.5 12 L8.6 13.8", [(12, 8.5, 1.7)]),
        // v137: N Seoul Tower on its hill, a slim shaft and the observation pod (it read as a dome)
        .namsan: ("M2 20.5 L22 20.5 M2 20.5 C6 16.5 9 15.2 12 15.2 C15 15.2 18 16.5 22 20.5 M11.2 15.2 L11.4 9.5 "
                  + "M12.8 15.2 L12.6 9.5 M9.3 9.5 L14.7 9.5 L14 7.2 L10 7.2 Z M11 7.2 L11.3 5.2 L12.7 5.2 L13 7.2 "
                  + "M12 5.2 L12 1.5", []),
        // v137: the Dubai office (prototype `GLYPH.dxb`); v141: London's Big Ben (the Elizabeth Tower) in place of Paris'
        // Eiffel Tower (`GLYPH.par`): a square shaft, the wider clock stage, the pointed belfry and spire
        .burj: ("M3 20.5 L21 20.5 M12 1.5 L12 5 M10.8 5 L13.2 5 L13.2 9 L14.2 9 L14.2 13 L15.4 13 L15.4 17 L16.6 17 L16.6 20.5 "
                + "M10.8 5 L10.8 10 L9.8 10 L9.8 14 L8.6 14 L8.6 17.5 L7.4 17.5 L7.4 20.5", []),
        .bigBen: ("M6 20.5 L18 20.5 M9.8 20.5 L9.8 11.2 M14.2 20.5 L14.2 11.2 M8.9 11.2 L15.1 11.2 L15.1 5.8 L8.9 5.8 Z "
                  + "M9.5 5.8 L10.4 4.2 L13.6 4.2 L14.5 5.8 M10.4 4.2 L12 1.2 L13.6 4.2 M9.8 14.4 L14.2 14.4 M9.8 17.5 L14.2 17.5 "
                  + "M12 8.5 L12 7.3 M12 8.5 L12.9 8.9", [(12, 8.5, 1.9)]),
        // v137: Tokyo Skytree (Tokyo Tower looked like the Eiffel Tower): straight legs, the two decks, the mast
        .skytree: ("M8 20.5 L16 20.5 M9.6 20.5 L11.4 5.5 M14.4 20.5 L12.6 5.5 M8.6 13.4 L15.4 13.4 M9.4 12 L14.6 12 "
                   + "M10.2 8.6 L13.8 8.6 M12 5.5 L12 1.5", []),
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
