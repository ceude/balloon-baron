import SwiftUI
import BalloonBaronCore

/// Each region's guide speaks through Hezarfen's bubble with their own face: Hezarfen in Cappadocia, Ben Franklin in
/// Albuquerque (he watched the first balloons rise over Paris in 1783), Imhotep in Luxor, Maggie Holloway (a retired
/// balloon-envelope seamstress) in Bristol. Ports of `FRANKLIN_AV`, `IMHOTEP_AV` and `MAGGIE_AV`.
struct GuideAvatar: View {
    let region: RegionID
    let size: CGFloat

    var body: some View {
        if region == .cap {
            HezarfenAvatar(size: size)
        } else {
            let look = Self.look(region)
            PortraitCanvas(rim: look.rim, background: look.background, items: look.items, size: size)
                .accessibilityLabel(guideName(region))
        }
    }

    private static func look(_ r: RegionID) -> (rim: String, background: [String], items: [ArtItem]) {
        switch r {
        case .abq: ("#5aa9e6", ["#2a3a6a", "#c06a5a", "#f6c08a"], franklin)
        case .bri: ("#c86a7a", ["#6a86a8", "#c8a0a8", "#f2d8b8"], maggie)
        default: ("#c9a040", ["#1f4f6b", "#c88a4a", "#f2d69a"], imhotep)
        }
    }

    /// v124: Maggie Holloway: grey bun, reading glasses, a cardigan and a tape measure round her neck.
    private static let maggie: [ArtItem] = [
        .fill("M12 100 C15 79 30 70 50 70 C70 70 85 79 88 100Z", "#b84a5a"),
        .fill("M40 70 L50 90 L60 70Z", "#f6efe4"),
        .dot(45, 80, 1.3, "#f6efe4"), .dot(46, 88, 1.3, "#f6efe4"),
        .line("M34 72 C38 82 40 92 40 100 M66 72 C62 82 60 92 60 100", "#ffd27a", 3.2),
        .line("M35 76 L37.6 75 M36.6 80 L39 79.4 M37.8 84 L40.2 83.6 M38.6 88 L41 87.8 M65 76 L62.4 75 M63.4 80 L61 79.4 M62.2 84 L59.8 83.6", "#8a6a30", 0.7),
        .box(43, 58, 14, 14, 4, "#e8b494"),
        .oval(50, 46, 17, 20, "#f4c8a8"),
        .dot(50, 20, 9, "#e6e2e8"),
        .fill("M33 44 C31 28 40 24 50 24 C60 24 69 28 67 44 C64 36 58 32 50 32 C42 32 36 36 33 44Z", "#e6e2e8"),
        .line("M43 18 Q50 14 57 18", "#c8c2cc", 1.4),
        ArtItem(path: Path(roundedRect: CGRect(x: 37.5, y: 43, width: 10, height: 7), cornerRadius: 3), fill: Color.white.opacity(0.3),
                stroke: Color(hex: "#8a4a5a"), width: 1.3),
        ArtItem(path: Path(roundedRect: CGRect(x: 52.5, y: 43, width: 10, height: 7), cornerRadius: 3), fill: Color.white.opacity(0.3),
                stroke: Color(hex: "#8a4a5a"), width: 1.3),
        .line("M47.5 46 L52.5 46", "#8a4a5a", 1.3),
        .line("M40.5 46.5 Q42.5 45 44.5 46.5 M55.5 46.5 Q57.5 45 59.5 46.5", "#2a2030", 1.6),
        ArtItem(path: Path(ellipseIn: CGRect(x: 35.6, y: 52, width: 6.8, height: 4)), fill: Color(hex: "#f0a0a0").opacity(0.55)),
        ArtItem(path: Path(ellipseIn: CGRect(x: 57.6, y: 52, width: 6.8, height: 4)), fill: Color(hex: "#f0a0a0").opacity(0.55)),
        .fill("M50 48 L48.5 53.5 Q50 54.6 51.6 53.8", "#e8b494"),
        .line("M43 58 Q50 63.5 57 58", "#a0505a", 1.9)
    ]

    private static let franklin: [ArtItem] = [
        .fill("M12 100 C15 79 30 70 50 70 C70 70 85 79 88 100Z", "#6a4a2e"),
        .fill("M38 70 L50 92 L62 70Z", "#f4eee2"),
        .fill("M42 71 C46 76 54 76 58 71 L56 80 C52 82 48 82 44 80Z", "#ffffff"),
        .fill("M26 40 C24 56 26 70 34 76 L40 70 C36 62 35 52 35 44Z M74 40 C76 56 74 70 66 76 L60 70 C64 62 65 52 65 44Z", "#d8d4cc"),
        .box(43, 58, 14, 14, 4, "#e0a98a"),
        .oval(50, 46, 17, 20, "#f0bea0"),
        .fill("M33 40 C33 26 41 22 50 22 C59 22 67 26 67 40 C63 32 58 30 50 30 C42 30 37 32 33 40Z", "#f6cdb0"),
        .fill("M33 42 C31 34 34 27 38 25 C36 31 36 36 37 42Z M67 42 C69 34 66 27 62 25 C64 31 64 36 63 42Z", "#e6e2da"),
        ArtItem(path: Path(roundedRect: CGRect(x: 38, y: 44, width: 10, height: 6), cornerRadius: 1.5), fill: Color.white.opacity(0.25),
                stroke: Color(hex: "#6a5030"), width: 1.4),
        ArtItem(path: Path(roundedRect: CGRect(x: 52, y: 44, width: 10, height: 6), cornerRadius: 1.5), fill: Color.white.opacity(0.25),
                stroke: Color(hex: "#6a5030"), width: 1.4),
        .line("M48 46 L52 46", "#6a5030", 1.4),
        .dot(43, 47, 1.6, "#2a2030"), .dot(57, 47, 1.6, "#2a2030"),
        .fill("M50 49 L48 55 Q50 56.5 52 55.5Z", "#dca084"),
        .line("M43 60 Q50 64 57 60", "#8a4a3a", 1.8)
    ]

    private static let imhotep: [ArtItem] = [
        .fill("M12 100 C15 80 30 72 50 72 C70 72 85 80 88 100Z", "#f6f0e2"),
        .fill("M22 86 C30 74 40 70 50 70 C60 70 70 74 78 86 C70 82 60 80 50 80 C40 80 30 82 22 86Z", "#2a9a9a"),
        .line("M26 82 C34 74 42 72 50 72 C58 72 66 74 74 82", "#e8b23a", 2.4),
        .line("M24 88 C32 80 41 77 50 77 C59 77 68 80 76 88", "#1f5fa8", 2.4),
        .box(43, 58, 14, 14, 4, "#a8683e"),
        .oval(50, 44, 17, 20, "#bf7f52"),
        .fill("M33 40 C33 26 41 23 50 23 C59 23 67 26 67 40 C62 30 57 28 50 28 C43 28 38 30 33 40Z", "#cf9264"),
        .oval(33.5, 46, 2.6, 4.2, "#a86c44"), .oval(66.5, 46, 2.6, 4.2, "#a86c44"),
        .line("M38 42 Q43 40 47 42 M53 42 Q57 40 62 42", "#2a1a10", 2),
        ArtItem(path: HezarfenAvatar.svgPath("M38 46.5 Q43 44 47 46.5 Q43 48.2 38 46.5Z M53 46.5 Q57 44 62 46.5 Q57 48.2 53 46.5Z"),
                fill: .white, stroke: Color(hex: "#1a1010"), width: 1.2),
        .dot(43, 46.5, 1.5, "#1a1010"), .dot(57, 46.5, 1.5, "#1a1010"),
        .line("M47 46.5 L50 47.5 M62 46.5 L65 47.5", "#1a1010", 1.2),
        .fill("M50 48 L48 54 Q50 55.5 52 54.5Z", "#a86c44"),
        .line("M44 59 Q50 62.5 56 59", "#6a3020", 1.8)
    ]
}

/// The civil aviation inspector who comes about worn envelopes. Port of `INSP_AV`.
struct InspectorAvatar: View {
    let size: CGFloat

    var body: some View {
        PortraitCanvas(rim: "#2b3a5a", background: ["#6a7a90", "#d8e0ea"], items: Self.items, size: size)
            .accessibilityLabel(loc("insp.name.\(currentRegion.rawValue)"))
    }

    private static let clipboard = CGAffineTransform(translationX: 66, y: 84).rotated(by: -12 * .pi / 180).translatedBy(x: -66, y: -84)

    private static let items: [ArtItem] = [
        .fill("M12 100 C15 79 30 70 50 70 C70 70 85 79 88 100Z", "#23304e"),
        .fill("M42 70 L50 84 L58 70Z", "#ffffff"),
        .fill("M48 72 L52 72 L51 86 L49 86Z", "#23304e"),
        .box(62, 80, 5, 3, 0, "#e8b23a"),
        ArtItem(path: Path(roundedRect: CGRect(x: 66, y: 84, width: 22, height: 18), cornerRadius: 2).applying(clipboard), fill: Color(hex: "#c89a5a")),
        ArtItem(path: Path(CGRect(x: 69, y: 88, width: 16, height: 14)).applying(clipboard), fill: .white),
        .box(43, 58, 14, 14, 4, "#d8a080"),
        .oval(50, 46, 16, 19, "#e8b494"),
        .fill("M30 33 C32 22 68 22 70 33 L72 36 L28 36Z", "#23304e"),
        .box(28, 34, 44, 5, 2, "#18203a"),
        .dot(50, 29, 3, "#e8b23a"),
        .dot(44, 47, 1.6, "#2a2030"), .dot(56, 47, 1.6, "#2a2030"),
        .line("M40 43 L47 43 M53 43 L60 43", "#4a3020", 1.8),
        .line("M44 58 L56 58", "#8a4a3a", 1.8)
    ]
}

/// A round portrait drawn from a 100×100 viewBox, like Hezarfen's and the bosses'.
private struct PortraitCanvas: View {
    let rim: String
    let background: [String]
    let items: [ArtItem]
    let size: CGFloat

    var body: some View {
        Canvas { ctx, sz in
            let k = sz.width / 100
            ctx.scaleBy(x: k, y: k)
            ctx.fill(Path(ellipseIn: CGRect(x: 0, y: 0, width: 100, height: 100)), with: .color(Color(hex: rim)))
            var g = ctx
            g.clip(to: Path(ellipseIn: CGRect(x: 2, y: 2, width: 96, height: 96)))
            g.fill(Path(CGRect(x: 0, y: 0, width: 100, height: 100)),
                   with: .linearGradient(Gradient(colors: background.map(Color.init(hex:))), startPoint: CGPoint(x: 50, y: 0), endPoint: CGPoint(x: 50, y: 100)))
            for item in items { item.draw(in: &g) }
        }
        .frame(width: size, height: size)
        .shadow(color: Color(red: 15 / 255, green: 8 / 255, blue: 35 / 255).opacity(0.5), radius: size * 0.1, y: size * 0.095)
        .accessibilityElement()
    }
}

/// The guide's name as shown under the portrait.
func guideName(_ r: RegionID) -> String { r == .cap ? loc("hez.name") : loc("guide.\(r.rawValue).name") }
