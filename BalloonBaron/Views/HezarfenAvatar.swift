import SwiftUI

/// Master Hezarfen's portrait: port of the prototype's `HEZ_AV` SVG (100×100 viewBox).
struct HezarfenAvatar: View {
    let size: CGFloat

    var body: some View {
        Canvas { ctx, sz in
            let k = sz.width / 100
            ctx.scaleBy(x: k, y: k)
            ctx.fill(Path(ellipseIn: CGRect(x: 0, y: 0, width: 100, height: 100)), with: .color(Color(hex: "#e8b04a")))
            var g = ctx
            g.clip(to: Path(ellipseIn: CGRect(x: 2, y: 2, width: 96, height: 96)))
            g.fill(Path(CGRect(x: 0, y: 0, width: 100, height: 100)),
                   with: .linearGradient(Self.background, startPoint: CGPoint(x: 50, y: 0), endPoint: CGPoint(x: 50, y: 100)))
            for item in Self.items { item.draw(in: &g) }
        }
        .frame(width: size, height: size)
        .shadow(color: Color(red: 15 / 255, green: 8 / 255, blue: 35 / 255).opacity(0.5), radius: size * 0.1, y: size * 0.095)
        .accessibilityElement()
        .accessibilityLabel(loc("hez.name"))
    }

    private static let background = Gradient(stops: [
        .init(color: Color(hex: "#2f2560"), location: 0),
        .init(color: Color(hex: "#b9506a"), location: 0.62),
        .init(color: Color(hex: "#ffae6a"), location: 1)
    ])

    private struct Item {
        var path: Path
        var fill: Color?
        var stroke: Color?
        var width: CGFloat = 1
        var opacity: Double = 1

        func draw(in ctx: inout GraphicsContext) {
            var c = ctx
            c.opacity = opacity
            if let fill { c.fill(path, with: .color(fill)) }
            if let stroke {
                c.stroke(path, with: .color(stroke), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
            }
        }
    }

    private static func fill(_ d: String, _ hex: String, opacity: Double = 1) -> Item {
        Item(path: svgPath(d), fill: Color(hex: hex), opacity: opacity)
    }

    private static func line(_ d: String, _ hex: String, _ w: CGFloat) -> Item {
        Item(path: svgPath(d), stroke: Color(hex: hex), width: w)
    }

    private static func oval(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ hex: String) -> Item {
        Item(path: Path(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2)), fill: Color(hex: hex))
    }

    private static let items: [Item] = [
        // Wings of the cloak, light then shaded, with feather lines.
        fill("M28 76 C10 68 1 46 4 24 C12 38 20 45 33 49 Z", "#f6ead6"),
        fill("M72 76 C90 68 99 46 96 24 C88 38 80 45 67 49 Z", "#f6ead6"),
        fill("M28 78 C14 72 7 58 7 42 C15 52 23 56 35 58 Z", "#dcc39a"),
        fill("M72 78 C86 72 93 58 93 42 C85 52 77 56 65 58 Z", "#dcc39a"),
        line("M9 30 C15 40 22 45 31 49", "#c9ad80", 1),
        line("M91 30 C85 40 78 45 69 49", "#c9ad80", 1),
        line("M8 48 C15 55 23 58 33 60", "#c9ad80", 1),
        line("M92 48 C85 55 77 58 67 60", "#c9ad80", 1),
        // Robe.
        fill("M14 100 C17 81 32 72 50 72 C68 72 83 81 86 100 Z", "#7e1b28"),
        fill("M14 100 C17 81 32 72 50 72 L50 100 Z", "#6c1622"),
        Item(path: svgPath("M50 73 L43 100 M50 73 L57 100"), stroke: Color(hex: "#e8b04a"), width: 2.6),
        line("M37 75 C43 81 57 81 63 75", "#e8b04a", 2.4),
        // Neck, face, ears.
        Item(path: Path(roundedRect: CGRect(x: 44.5, y: 58, width: 11, height: 15), cornerRadius: 3), fill: Color(hex: "#b9784f")),
        fill("M34 44 C34 31 41 25 50 25 C59 25 66 31 66 44 C66 56 59 66 50 66 C41 66 34 56 34 44 Z", "#d59468"),
        fill("M50 25 C59 25 66 31 66 44 C66 56 59 66 50 66 Z", "#c8865b", opacity: 0.55),
        oval(34, 46, 3, 4.6, "#c07d54"),
        oval(66, 46, 3, 4.6, "#b5734c"),
        // Beard, mustache, mouth, nose.
        fill("M35.5 50 C36 62 42 75 50 82 C58 75 64 62 64.5 50 C60.5 56 56 58 50 58 C44 58 39.5 56 35.5 50 Z", "#2a1b14"),
        fill("M50 82 C47 78 46 74 47 70 L50 72 L53 70 C54 74 53 78 50 82 Z", "#3b271d"),
        fill("M38.5 55.5 C42.5 50.5 47 50.5 50 53 C53 50.5 57.5 50.5 61.5 55.5 C57 56.2 53 56 50 54.8 C47 56 43 56.2 38.5 55.5 Z", "#1a110c"),
        line("M46.5 59.2 Q50 60.6 53.5 59.2", "#7b3b2a", 1.4),
        fill("M50.5 39 L47.2 49.5 Q50 51.4 53 49.8", "#bb7a50"),
        // Brows and eyes.
        line("M37.6 39.4 L46.4 37.6", "#1a110c", 2.8),
        line("M53.6 37.6 L62.4 39.4", "#1a110c", 2.8),
        fill("M39 43.2 Q42.5 41 46 43.2 Q42.5 44.6 39 43.2 Z", "#ffffff"),
        fill("M54 43.2 Q57.5 41 61 43.2 Q57.5 44.6 54 43.2 Z", "#ffffff"),
        oval(42.8, 43, 1.6, 1.6, "#1a110c"),
        oval(57.4, 43, 1.6, 1.6, "#1a110c"),
        // Turban, band, plume and jewel.
        fill("M35.5 31 C35.5 13 41.5 5 50 5 C58.5 5 64.5 13 64.5 31 Z", "#f6f1e7"),
        fill("M50 5 C58.5 5 64.5 13 64.5 31 L50 31 Z", "#e6ddcc"),
        fill("M31 33 C31 27 40 24 50 24 C60 24 69 27 69 33 C69 36.5 60 37.6 50 37.6 C40 37.6 31 36.5 31 33 Z", "#ece3d2"),
        line("M33 31 C42 27.4 58 27.4 67 31", "#cdbfa6", 1.5),
        line("M32 34.6 C43 31 57 31 68 34.6", "#cdbfa6", 1.5),
        fill("M50 27 C43.5 18 45.5 8 52.5 1 C51 11 56.5 19 50 27 Z", "#e8b04a"),
        Item(path: Path(ellipseIn: CGRect(x: 46.6, y: 26.1, width: 6.8, height: 6.8)), fill: Color(hex: "#b8263a"),
             stroke: Color(hex: "#e8b04a"), width: 1.5)
    ]

    /// Absolute M/L/C/Q/Z path data, as used by the avatar.
    private static func svgPath(_ d: String) -> Path {
        var tokens: [String] = []
        var cur = ""
        for ch in d {
            if ch.isLetter {
                if !cur.isEmpty { tokens.append(cur); cur = "" }
                tokens.append(String(ch))
            } else if ch == " " || ch == "," {
                if !cur.isEmpty { tokens.append(cur); cur = "" }
            } else {
                cur.append(ch)
            }
        }
        if !cur.isEmpty { tokens.append(cur) }

        var p = Path()
        var cmd = "M"
        var i = 0
        func num() -> CGFloat {
            guard i < tokens.count, let v = Double(tokens[i]) else { i += 1; return 0 }
            i += 1
            return CGFloat(v)
        }
        func pt() -> CGPoint { let x = num(); return CGPoint(x: x, y: num()) }
        while i < tokens.count {
            if let c = tokens[i].first, c.isLetter { cmd = String(c); i += 1 }
            switch cmd {
            case "M": p.move(to: pt()); cmd = "L"
            case "L": p.addLine(to: pt())
            case "C":
                let c1 = pt(), c2 = pt()
                p.addCurve(to: pt(), control1: c1, control2: c2)
            case "Q":
                let c1 = pt()
                p.addQuadCurve(to: pt(), control: c1)
            case "Z", "z": p.closeSubpath(); cmd = ""
            default: i += 1
            }
        }
        return p
    }
}
