import SwiftUI
import BalloonBaronCore

/// v125: the contract companies' owners, three per region. Ports of `ROSA_AV`, `HANK_AV`, `LINDA_AV`, `FAROUK_AV`,
/// `DALIA_AV`, `HAMZA_AV`, `NIGEL_AV`, `PRIYA_AV` and `FIONA_AV` (100×100 viewBox: a ring, a gradient, the figure).
struct ContractAvatar: View {
    let owner: ContractOwner
    let size: CGFloat

    var body: some View {
        let look = Self.look(owner)
        Canvas { ctx, sz in
            let k = sz.width / 100
            ctx.scaleBy(x: k, y: k)
            ctx.fill(Path(ellipseIn: CGRect(x: 0, y: 0, width: 100, height: 100)), with: .color(Color(hex: look.ring)))
            var g = ctx
            g.clip(to: Path(ellipseIn: CGRect(x: 2, y: 2, width: 96, height: 96)))
            let stops = look.background.map { Gradient.Stop(color: Color(hex: $0.0), location: $0.1) }
            g.fill(Path(CGRect(x: 0, y: 0, width: 100, height: 100)),
                   with: .linearGradient(Gradient(stops: stops), startPoint: CGPoint(x: 50, y: 0), endPoint: CGPoint(x: 50, y: 100)))
            for item in look.items { item.draw(in: &g) }
        }
        .frame(width: size, height: size)
        .shadow(color: Color(red: 15 / 255, green: 8 / 255, blue: 35 / 255).opacity(0.5), radius: size * 0.1, y: size * 0.095)
        .accessibilityElement()
        .accessibilityLabel(owner.title)
    }

    private static func look(_ o: ContractOwner) -> (ring: String, background: [(String, CGFloat)], items: [ArtItem]) {
        switch o {
        case .rosa: ("#2ab0b0", [("#2a8a9a", 0), ("#e0905a", 0.62), ("#f8d89a", 1)], [
            ArtItem(path: HezarfenAvatar.svgPath("M60 30 C72 34 74 52 70 70 C68 80 64 90 60 96 L56 96 C60 84 62 72 62 60 C62 48 60 38 56 32Z"), fill: Color(hex: "#2a1a14")),
            ArtItem(path: HezarfenAvatar.svgPath("M12 100 C15 79 30 70 50 70 C70 70 85 79 88 100Z"), fill: Color(hex: "#4a6e9a")),
            ArtItem(path: HezarfenAvatar.svgPath("M12 100 C15 79 30 70 50 70 L44 100Z"), fill: Color(hex: "#567ca8")),
            ArtItem(path: HezarfenAvatar.svgPath("M40 70 L50 84 L60 70Z"), fill: Color(hex: "#f4e6d0")),
            ArtItem(path: HezarfenAvatar.svgPath("M34 72 L40 70 L44 82Z M66 72 L60 70 L56 82Z"), fill: Color(hex: "#3a5a84")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 46.6, y: 82.6, width: 6.8, height: 6.8)), fill: Color(hex: "#2ab0a8"), stroke: Color(hex: "#e8e0c8"), width: 0.8),
            ArtItem(path: Path(ellipseIn: CGRect(x: 40.8, y: 80.3, width: 4.4, height: 4.4)), fill: Color(hex: "#2ab0a8"), stroke: Color(hex: "#e8e0c8"), width: 0.8),
            ArtItem(path: Path(ellipseIn: CGRect(x: 54.8, y: 80.3, width: 4.4, height: 4.4)), fill: Color(hex: "#2ab0a8"), stroke: Color(hex: "#e8e0c8"), width: 0.8),
            ArtItem(path: Path(roundedRect: CGRect(x: 43, y: 58, width: 14, height: 14), cornerRadius: 4), fill: Color(hex: "#b8784e")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 33, y: 25, width: 34, height: 40)), fill: Color(hex: "#c98a5e")),
            ArtItem(path: HezarfenAvatar.svgPath("M32 46 C28 26 40 18 51 18 C63 18 72 26 68 46 C66 34 60 28 50 28 C42 30 36 34 32 46Z"), fill: Color(hex: "#2a1a14")),
            ArtItem(path: HezarfenAvatar.svgPath("M33 30 C40 22 60 22 67 30 L66 34 C58 28 42 28 34 34Z"), fill: Color(hex: "#e5432f")),
            ArtItem(path: HezarfenAvatar.svgPath("M35 31 L37 31 M39 31 L41 31 M43 31 L45 31 M47 31 L49 31 M51 31 L53 31 M55 31 L57 31 M59 31 L61 31 M63 31 L65 31"), fill: Color(hex: "#000"), stroke: Color(hex: "#ffd27a"), width: 1),
            ArtItem(path: Path(ellipseIn: CGRect(x: 31.3, y: 49.8, width: 4.4, height: 4.4)), fill: Color(hex: "#2ab0a8"), stroke: Color(hex: "#e8e0c8"), width: 0.7),
            ArtItem(path: Path(ellipseIn: CGRect(x: 64.3, y: 49.8, width: 4.4, height: 4.4)), fill: Color(hex: "#2ab0a8"), stroke: Color(hex: "#e8e0c8"), width: 0.7),
            ArtItem(path: HezarfenAvatar.svgPath("M38 41 Q43 38.5 47 41 M53 41 Q57 38.5 62 41"), stroke: Color(hex: "#2a1a14"), width: 2.2),
            ArtItem(path: Path(ellipseIn: CGRect(x: 41.2, y: 44.2, width: 3.6, height: 3.6)), fill: Color(hex: "#1f1b2e")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 55.2, y: 44.2, width: 3.6, height: 3.6)), fill: Color(hex: "#1f1b2e")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 35.8, y: 51.2, width: 6.4, height: 3.6)), fill: Color(hex: "#e07a6a").opacity(0.5)),
            ArtItem(path: Path(ellipseIn: CGRect(x: 57.8, y: 51.2, width: 6.4, height: 3.6)), fill: Color(hex: "#e07a6a").opacity(0.5)),
            ArtItem(path: HezarfenAvatar.svgPath("M50 48 L48.5 53 Q50 54.4 51.6 53.6"), fill: Color(hex: "#b8784e")),
            ArtItem(path: HezarfenAvatar.svgPath("M42 57.5 Q50 64 58 57.5 Q50 60.5 42 57.5Z"), fill: Color(hex: "#a8302a"))
        ])
        case .hank: ("#8a5aa8", [("#6a4a8a", 0), ("#d0785a", 0.6), ("#f0c890", 1)], [
            ArtItem(path: HezarfenAvatar.svgPath("M12 100 C15 79 30 70 50 70 C70 70 85 79 88 100Z"), fill: Color(hex: "#3a3a44")),
            ArtItem(path: HezarfenAvatar.svgPath("M38 70 L50 80 L62 70 L60 100 L40 100Z"), fill: Color(hex: "#c8a070")),
            ArtItem(path: HezarfenAvatar.svgPath("M50 80 L50 100"), fill: Color(hex: "#000"), stroke: Color(hex: "#8a6a40"), width: 1),
            ArtItem(path: HezarfenAvatar.svgPath("M44 72 C47 75 53 75 56 72 L54 77 L50 79 L46 77Z"), fill: Color(hex: "#2ab0a8"), stroke: Color(hex: "#d8d8d8"), width: 1),
            ArtItem(path: HezarfenAvatar.svgPath("M47 76 L44 84 M53 76 L56 84"), fill: Color(hex: "#000"), stroke: Color(hex: "#2a2a2a"), width: 1.2),
            ArtItem(path: Path(roundedRect: CGRect(x: 43, y: 58, width: 14, height: 14), cornerRadius: 4), fill: Color(hex: "#9a6440")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 33, y: 26, width: 34, height: 40)), fill: Color(hex: "#ab7248")),
            ArtItem(path: HezarfenAvatar.svgPath("M33 46 C33 50 34 56 36 60 L33 62 C31 56 30 50 31 44Z M67 46 C67 50 66 56 64 60 L67 62 C69 56 70 50 69 44Z"), fill: Color(hex: "#1f1a1a")),
            ArtItem(path: HezarfenAvatar.svgPath("M14 38 C24 34 76 34 86 38 C86 42 76 42 50 42 C24 42 14 42 14 38Z"), fill: Color(hex: "#2a2a30")),
            ArtItem(path: HezarfenAvatar.svgPath("M30 39 C30 22 40 15 50 15 C60 15 70 22 70 39Z"), fill: Color(hex: "#33333a")),
            ArtItem(path: HezarfenAvatar.svgPath("M30 34 L70 34 L70 38 L30 38Z"), fill: Color(hex: "#c0c6cc")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 60, y: 34, width: 4, height: 4)), fill: Color(hex: "#2ab0a8")),
            ArtItem(path: HezarfenAvatar.svgPath("M38 45 L47 45 M53 45 L62 45"), fill: Color(hex: "#000"), stroke: Color(hex: "#1f1a1a"), width: 2.4),
            ArtItem(path: Path(ellipseIn: CGRect(x: 41.3, y: 47.3, width: 3.4, height: 3.4)), fill: Color(hex: "#1f1b2e")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 55.3, y: 47.3, width: 3.4, height: 3.4)), fill: Color(hex: "#1f1b2e")),
            ArtItem(path: HezarfenAvatar.svgPath("M50 50 L48 56 Q50 57.4 52 56.4"), fill: Color(hex: "#9a6440")),
            ArtItem(path: HezarfenAvatar.svgPath("M44 61 Q50 63 56 61"), stroke: Color(hex: "#5a2a1a"), width: 1.9),
            ArtItem(path: HezarfenAvatar.svgPath("M38 57 Q39 60 41 61 M62 57 Q61 60 59 61"), stroke: Color(hex: "#8a5434"), width: 1)
        ])
        case .linda: ("#e0408a", [("#3a6aa8", 0), ("#e09aa0", 0.6), ("#fbe2b8", 1)], [
            ArtItem(path: HezarfenAvatar.svgPath("M12 100 C15 79 30 70 50 70 C70 70 85 79 88 100Z"), fill: Color(hex: "#f6efe2")),
            ArtItem(path: HezarfenAvatar.svgPath("M28 78 C34 72 42 70 46 70 L50 100 L24 100Z M72 78 C66 72 58 70 54 70 L50 100 L76 100Z"), fill: Color(hex: "#e0408a")),
            ArtItem(path: HezarfenAvatar.svgPath("M44 72 L50 78 L56 72"), stroke: Color(hex: "#c8306a"), width: 1.4),
            ArtItem(path: Path(roundedRect: CGRect(x: 58, y: 82, width: 10, height: 7), cornerRadius: 1), fill: Color(hex: "#fff"), stroke: Color(hex: "#c8306a"), width: 0.8),
            ArtItem(path: HezarfenAvatar.svgPath("M60 85 L66 85"), fill: Color(hex: "#000"), stroke: Color(hex: "#2b2350"), width: 0.9),
            ArtItem(path: Path(roundedRect: CGRect(x: 43, y: 58, width: 14, height: 14), cornerRadius: 4), fill: Color(hex: "#e6b890")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 33, y: 26, width: 34, height: 40)), fill: Color(hex: "#f2c8a0")),
            ArtItem(path: HezarfenAvatar.svgPath("M31 50 C27 30 38 20 50 20 C62 20 73 30 69 50 C68 60 66 64 64 66 C65 56 65 44 62 36 C56 34 46 34 40 34 C36 40 35 52 36 66 C34 64 32 60 31 50Z"), fill: Color(hex: "#1a1414")),
            ArtItem(path: HezarfenAvatar.svgPath("M38 32 C44 26 58 26 64 34 C56 31 46 31 38 32Z"), fill: Color(hex: "#2a2222")),
            ArtItem(path: Path(roundedRect: CGRect(x: 36, y: 42, width: 12, height: 7), cornerRadius: 3.4), fill: Color(red: 255/255, green: 255/255, blue: 255/255).opacity(0.2), stroke: Color(hex: "#2b2350"), width: 1.5),
            ArtItem(path: Path(roundedRect: CGRect(x: 52, y: 42, width: 12, height: 7), cornerRadius: 3.4), fill: Color(red: 255/255, green: 255/255, blue: 255/255).opacity(0.2), stroke: Color(hex: "#2b2350"), width: 1.5),
            ArtItem(path: HezarfenAvatar.svgPath("M48 45 L52 45"), fill: Color(hex: "#000"), stroke: Color(hex: "#2b2350"), width: 1.5),
            ArtItem(path: Path(ellipseIn: CGRect(x: 40.4, y: 44, width: 3.2, height: 3.2)), fill: Color(hex: "#1f1b2e")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 56.4, y: 44, width: 3.2, height: 3.2)), fill: Color(hex: "#1f1b2e")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 36, y: 51.3, width: 6, height: 3.4)), fill: Color(hex: "#f09aa0").opacity(0.55)),
            ArtItem(path: Path(ellipseIn: CGRect(x: 58, y: 51.3, width: 6, height: 3.4)), fill: Color(hex: "#f09aa0").opacity(0.55)),
            ArtItem(path: HezarfenAvatar.svgPath("M50 48 L48.6 53 Q50 54.2 51.5 53.5"), fill: Color(hex: "#e6b890")),
            ArtItem(path: HezarfenAvatar.svgPath("M43 58 Q50 63 57 58"), stroke: Color(hex: "#c0405a"), width: 1.9)
        ])
        case .farouk: ("#1f6f8b", [("#1f6f8b", 0), ("#e8c47a", 1)], [
            ArtItem(path: HezarfenAvatar.svgPath("M12 100 C15 79 30 70 50 70 C70 70 85 79 88 100Z"), fill: Color(hex: "#1f2a50")),
            ArtItem(path: HezarfenAvatar.svgPath("M41 70 L50 82 L59 70Z"), fill: Color(hex: "#f4efe4")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 38.4, y: 82.4, width: 3.2, height: 3.2)), fill: Color(hex: "#d8b040")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 38.4, y: 90.4, width: 3.2, height: 3.2)), fill: Color(hex: "#d8b040")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 58.4, y: 82.4, width: 3.2, height: 3.2)), fill: Color(hex: "#d8b040")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 58.4, y: 90.4, width: 3.2, height: 3.2)), fill: Color(hex: "#d8b040")),
            ArtItem(path: HezarfenAvatar.svgPath("M22 78 L34 74 M78 78 L66 74"), fill: Color(hex: "#000"), stroke: Color(hex: "#d8b040"), width: 2.4),
            ArtItem(path: Path(roundedRect: CGRect(x: 43, y: 58, width: 14, height: 14), cornerRadius: 4), fill: Color(hex: "#a8683e")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 33, y: 26, width: 34, height: 40)), fill: Color(hex: "#b97a50")),
            ArtItem(path: HezarfenAvatar.svgPath("M30 34 C30 22 40 18 50 18 C60 18 70 22 70 34Z"), fill: Color(hex: "#f6f6f2")),
            ArtItem(path: HezarfenAvatar.svgPath("M27 34 L73 34 L72 39 L28 39Z"), fill: Color(hex: "#1f2a50")),
            ArtItem(path: HezarfenAvatar.svgPath("M28 39 C40 44 60 44 72 39 L74 41 C60 47 40 47 26 41Z"), fill: Color(hex: "#1a1a24")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 46.6, y: 24.6, width: 6.8, height: 6.8)), fill: Color(hex: "#d8b040")),
            ArtItem(path: HezarfenAvatar.svgPath("M33 44 C32 40 33 38 34 38 L35 46Z M67 44 C68 40 67 38 66 38 L65 46Z"), fill: Color(hex: "#d0d0d4")),
            ArtItem(path: HezarfenAvatar.svgPath("M38 45 Q43 43 47 45 M53 45 Q57 43 62 45"), stroke: Color(hex: "#e8e8ea"), width: 2.2),
            ArtItem(path: Path(ellipseIn: CGRect(x: 41.3, y: 47.3, width: 3.4, height: 3.4)), fill: Color(hex: "#1f1b2e")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 55.3, y: 47.3, width: 3.4, height: 3.4)), fill: Color(hex: "#1f1b2e")),
            ArtItem(path: HezarfenAvatar.svgPath("M50 50 L48 56 Q50 57.4 52 56.4"), fill: Color(hex: "#a8683e")),
            ArtItem(path: HezarfenAvatar.svgPath("M38 59 C43 55 47 57 50 57 C53 57 57 55 62 59 C57 61 54 60 50 60 C46 60 43 61 38 59Z"), fill: Color(hex: "#e6e6ea"))
        ])
        case .dalia: ("#c9a040", [("#c9a040", 0), ("#f6e2b0", 1)], [
            ArtItem(path: HezarfenAvatar.svgPath("M12 100 C15 79 30 70 50 70 C70 70 85 79 88 100Z"), fill: Color(hex: "#2a3a5a")),
            ArtItem(path: HezarfenAvatar.svgPath("M44 70 L50 78 L56 70"), stroke: Color(hex: "#f4efe4"), width: 3),
            ArtItem(path: HezarfenAvatar.svgPath("M28 52 C24 30 36 16 50 16 C64 16 76 30 72 52 C72 64 66 72 60 76 L40 76 C34 72 28 64 28 52Z"), fill: Color(hex: "#14a39a")),
            ArtItem(path: HezarfenAvatar.svgPath("M30 46 C34 40 40 38 42 44 M70 46 C66 40 60 38 58 44"), stroke: Color(hex: "#0e7a72"), width: 2),
            ArtItem(path: Path(ellipseIn: CGRect(x: 32.7, y: 28.7, width: 2.6, height: 2.6)), fill: Color(hex: "#ffd27a")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 40.7, y: 20.7, width: 2.6, height: 2.6)), fill: Color(hex: "#ffd27a")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 56.7, y: 20.7, width: 2.6, height: 2.6)), fill: Color(hex: "#ffd27a")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 64.7, y: 28.7, width: 2.6, height: 2.6)), fill: Color(hex: "#ffd27a")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 29.7, y: 42.7, width: 2.6, height: 2.6)), fill: Color(hex: "#ffd27a")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 67.7, y: 42.7, width: 2.6, height: 2.6)), fill: Color(hex: "#ffd27a")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 35, y: 30, width: 30, height: 36)), fill: Color(hex: "#c99470")),
            ArtItem(path: HezarfenAvatar.svgPath("M39 45 Q43 43 47 45 M53 45 Q57 43 61 45"), stroke: Color(hex: "#2a1a14"), width: 2),
            ArtItem(path: Path(ellipseIn: CGRect(x: 41.3, y: 47.3, width: 3.4, height: 3.4)), fill: Color(hex: "#1f1b2e")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 55.3, y: 47.3, width: 3.4, height: 3.4)), fill: Color(hex: "#1f1b2e")),
            ArtItem(path: HezarfenAvatar.svgPath("M41 47.5 L39 46 M59 47.5 L61 46"), fill: Color(hex: "#000"), stroke: Color(hex: "#1f1b2e"), width: 1),
            ArtItem(path: HezarfenAvatar.svgPath("M50 51 L48.6 56 Q50 57 51.5 56.3"), fill: Color(hex: "#b07c58")),
            ArtItem(path: HezarfenAvatar.svgPath("M44 60 Q50 64.5 56 60"), stroke: Color(hex: "#a83a4a"), width: 2)
        ])
        case .hamza: ("#e0408a", [("#e0408a", 0), ("#ffd8a8", 1)], [
            ArtItem(path: HezarfenAvatar.svgPath("M12 100 C15 79 30 70 50 70 C70 70 85 79 88 100Z"), fill: Color(hex: "#f6f2e8")),
            ArtItem(path: HezarfenAvatar.svgPath("M50 72 L50 96"), fill: Color(hex: "#000"), stroke: Color(hex: "#d8d0c0"), width: 1.4),
            ArtItem(path: HezarfenAvatar.svgPath("M45 72 L50 78 L55 72"), stroke: Color(hex: "#c9a040"), width: 1.6),
            ArtItem(path: Path(roundedRect: CGRect(x: 43, y: 58, width: 14, height: 14), cornerRadius: 4), fill: Color(hex: "#9a6440")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 33, y: 26, width: 34, height: 40)), fill: Color(hex: "#a87048")),
            ArtItem(path: HezarfenAvatar.svgPath("M32 40 C30 24 40 17 50 17 C61 17 70 24 68 40 C66 32 60 28 50 28 C41 28 35 32 32 40Z"), fill: Color(hex: "#1a1414")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 32, y: 22, width: 8, height: 8)), fill: Color(hex: "#1a1414")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 39.6, y: 15.6, width: 8.8, height: 8.8)), fill: Color(hex: "#1a1414")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 49.6, y: 14.6, width: 8.8, height: 8.8)), fill: Color(hex: "#1a1414")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 59, y: 20, width: 8, height: 8)), fill: Color(hex: "#1a1414")),
            ArtItem(path: HezarfenAvatar.svgPath("M34 52 C36 64 44 68 50 68 C56 68 64 64 66 52 C62 58 58 60 50 60 C42 60 38 58 34 52Z"), fill: Color(hex: "#2a1e18")),
            ArtItem(path: HezarfenAvatar.svgPath("M38 43 Q43 41 47 43 M53 43 Q57 41 62 43"), stroke: Color(hex: "#1a1414"), width: 2.2),
            ArtItem(path: Path(ellipseIn: CGRect(x: 41.2, y: 45.2, width: 3.6, height: 3.6)), fill: Color(hex: "#1f1b2e")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 55.2, y: 45.2, width: 3.6, height: 3.6)), fill: Color(hex: "#1f1b2e")),
            ArtItem(path: HezarfenAvatar.svgPath("M50 48 L48 54 Q50 55.4 52 54.4"), fill: Color(hex: "#966040")),
            ArtItem(path: HezarfenAvatar.svgPath("M43 58 Q50 63 57 58"), stroke: Color(hex: "#fff"), width: 2.4)
        ])
        case .nigel: ("#2a5a3a", [("#3a5a4a", 0), ("#c8d4c0", 1)], [
            ArtItem(path: HezarfenAvatar.svgPath("M12 100 C15 79 30 70 50 70 C70 70 85 79 88 100Z"), fill: Color(hex: "#3a4a3a")),
            ArtItem(path: HezarfenAvatar.svgPath("M40 70 L50 84 L60 70Z"), fill: Color(hex: "#f4efe6")),
            ArtItem(path: HezarfenAvatar.svgPath("M47 72 L53 72 L52 80 L50 84 L48 80Z"), fill: Color(hex: "#2a5a3a")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 33, y: 78, width: 4, height: 4)), fill: Color(hex: "#c9a040")),
            ArtItem(path: HezarfenAvatar.svgPath("M35 82 Q32 88 36 92"), stroke: Color(hex: "#c9a040"), width: 1),
            ArtItem(path: Path(roundedRect: CGRect(x: 43, y: 58, width: 14, height: 14), cornerRadius: 4), fill: Color(hex: "#e0b090")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 33, y: 26, width: 34, height: 40)), fill: Color(hex: "#f0c4a2")),
            ArtItem(path: HezarfenAvatar.svgPath("M24 34 C30 31 70 31 76 34 C76 37 70 37 50 37 C30 37 24 37 24 34Z"), fill: Color(hex: "#1a1a1e")),
            ArtItem(path: HezarfenAvatar.svgPath("M33 34 C33 18 41 13 50 13 C59 13 67 18 67 34Z"), fill: Color(hex: "#22222a")),
            ArtItem(path: HezarfenAvatar.svgPath("M33 31 L67 31 L67 34 L33 34Z"), fill: Color(hex: "#5a1a24")),
            ArtItem(path: HezarfenAvatar.svgPath("M38 43 Q43 41 47 43 M53 43 Q57 41 62 43"), stroke: Color(hex: "#7a6a5a"), width: 2.2),
            ArtItem(path: Path(ellipseIn: CGRect(x: 41.4, y: 45.4, width: 3.2, height: 3.2)), fill: Color(hex: "#1f1b2e")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 55.4, y: 45.4, width: 3.2, height: 3.2)), fill: Color(hex: "#1f1b2e")),
            ArtItem(path: HezarfenAvatar.svgPath("M50 48 L48 54 Q50 55.4 52 54.4"), fill: Color(hex: "#e0aa88")),
            ArtItem(path: HezarfenAvatar.svgPath("M38 58 C42 54 47 57 50 56 C53 57 58 54 62 58 C60 60 55 59 50 59 C45 59 40 60 38 58Z"), fill: Color(hex: "#8a6a50")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 36, y: 51.3, width: 6, height: 3.4)), fill: Color(hex: "#f0a0a0").opacity(0.5)),
            ArtItem(path: Path(ellipseIn: CGRect(x: 58, y: 51.3, width: 6, height: 3.4)), fill: Color(hex: "#f0a0a0").opacity(0.5))
        ])
        case .priya: ("#7a2a8a", [("#5a3a8a", 0), ("#e8c8e8", 1)], [
            ArtItem(path: HezarfenAvatar.svgPath("M12 100 C15 79 30 70 50 70 C70 70 85 79 88 100Z"), fill: Color(hex: "#2b2350")),
            ArtItem(path: HezarfenAvatar.svgPath("M42 70 L50 86 L58 70Z"), fill: Color(hex: "#f6f2ea")),
            ArtItem(path: HezarfenAvatar.svgPath("M30 76 L42 70 L46 88Z M70 76 L58 70 L54 88Z"), fill: Color(hex: "#3a3270")),
            ArtItem(path: Path(roundedRect: CGRect(x: 43, y: 58, width: 14, height: 14), cornerRadius: 4), fill: Color(hex: "#b0784e")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 33, y: 26, width: 34, height: 40)), fill: Color(hex: "#c08458")),
            ArtItem(path: HezarfenAvatar.svgPath("M30 56 C26 32 36 18 50 18 C64 18 74 32 70 56 C68 52 67 44 66 38 C60 32 46 30 36 36 C34 44 33 52 30 56Z"), fill: Color(hex: "#14101a")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 48.4, y: 29.4, width: 3.2, height: 3.2)), fill: Color(hex: "#e0408a")),
            ArtItem(path: Path(roundedRect: CGRect(x: 36.5, y: 43, width: 11, height: 7.5), cornerRadius: 2), fill: Color(red: 255/255, green: 255/255, blue: 255/255).opacity(0.2), stroke: Color(hex: "#e0408a"), width: 1.5),
            ArtItem(path: Path(roundedRect: CGRect(x: 52.5, y: 43, width: 11, height: 7.5), cornerRadius: 2), fill: Color(red: 255/255, green: 255/255, blue: 255/255).opacity(0.2), stroke: Color(hex: "#e0408a"), width: 1.5),
            ArtItem(path: HezarfenAvatar.svgPath("M47.5 46 L52.5 46"), fill: Color(hex: "#000"), stroke: Color(hex: "#e0408a"), width: 1.5),
            ArtItem(path: Path(ellipseIn: CGRect(x: 40.4, y: 45, width: 3.2, height: 3.2)), fill: Color(hex: "#1f1b2e")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 56.4, y: 45, width: 3.2, height: 3.2)), fill: Color(hex: "#1f1b2e")),
            ArtItem(path: HezarfenAvatar.svgPath("M50 49 L48.6 54 Q50 55 51.5 54.3"), fill: Color(hex: "#a87048")),
            ArtItem(path: HezarfenAvatar.svgPath("M43 58 Q50 63.5 57 58"), stroke: Color(hex: "#a8304a"), width: 2)
        ])
        case .fiona: ("#c0392b", [("#8a3a2a", 0), ("#f6d8b0", 1)], [
            ArtItem(path: HezarfenAvatar.svgPath("M24 50 C16 34 30 14 50 14 C70 14 84 34 76 50 C80 62 74 72 70 76 L30 76 C26 72 20 62 24 50Z"), fill: Color(hex: "#d0602a")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 20, y: 38, width: 12, height: 12)), fill: Color(hex: "#e07a3a")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 68, y: 38, width: 12, height: 12)), fill: Color(hex: "#e07a3a")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 22, y: 54, width: 12, height: 12)), fill: Color(hex: "#e07a3a")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 66, y: 54, width: 12, height: 12)), fill: Color(hex: "#e07a3a")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 34, y: 12, width: 12, height: 12)), fill: Color(hex: "#e07a3a")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 54, y: 12, width: 12, height: 12)), fill: Color(hex: "#e07a3a")),
            ArtItem(path: HezarfenAvatar.svgPath("M12 100 C15 79 30 70 50 70 C70 70 85 79 88 100Z"), fill: Color(hex: "#2a4a6a")),
            ArtItem(path: HezarfenAvatar.svgPath("M28 74 C38 82 62 82 72 74 L74 82 C62 90 38 90 26 82Z"), fill: Color(hex: "#c0392b")),
            ArtItem(path: HezarfenAvatar.svgPath("M30 78 L70 78 M34 74 L34 86 M44 76 L44 88 M56 76 L56 88 M66 74 L66 86"), fill: Color(hex: "#000"), stroke: Color(hex: "#2a5a3a"), width: 1.6),
            ArtItem(path: HezarfenAvatar.svgPath("M60 82 L64 98 L70 96 L66 82Z"), fill: Color(hex: "#c0392b")),
            ArtItem(path: Path(roundedRect: CGRect(x: 43, y: 58, width: 14, height: 14), cornerRadius: 4), fill: Color(hex: "#ecc0a0")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 34, y: 27, width: 32, height: 38)), fill: Color(hex: "#f6d2b4")),
            ArtItem(path: HezarfenAvatar.svgPath("M34 40 C36 28 44 24 50 24 C58 24 64 28 66 40 C62 33 56 31 50 31 C44 31 38 33 34 40Z"), fill: Color(hex: "#d0602a")),
            ArtItem(path: HezarfenAvatar.svgPath("M39 43 Q43 41 47 43 M53 43 Q57 41 61 43"), stroke: Color(hex: "#a0481e"), width: 2),
            ArtItem(path: Path(ellipseIn: CGRect(x: 41.3, y: 45.3, width: 3.4, height: 3.4)), fill: Color(hex: "#2a5a3a")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 55.3, y: 45.3, width: 3.4, height: 3.4)), fill: Color(hex: "#2a5a3a")),
            ArtItem(path: Path(ellipseIn: CGRect(x: 39.1, y: 51.1, width: 1.8, height: 1.8)), fill: Color(hex: "#c87a50").opacity(0.7)),
            ArtItem(path: Path(ellipseIn: CGRect(x: 42.1, y: 52.6, width: 1.8, height: 1.8)), fill: Color(hex: "#c87a50").opacity(0.7)),
            ArtItem(path: Path(ellipseIn: CGRect(x: 56.1, y: 52.6, width: 1.8, height: 1.8)), fill: Color(hex: "#c87a50").opacity(0.7)),
            ArtItem(path: Path(ellipseIn: CGRect(x: 59.1, y: 51.1, width: 1.8, height: 1.8)), fill: Color(hex: "#c87a50").opacity(0.7)),
            ArtItem(path: Path(ellipseIn: CGRect(x: 45.2, y: 51.2, width: 1.6, height: 1.6)), fill: Color(hex: "#c87a50").opacity(0.7)),
            ArtItem(path: Path(ellipseIn: CGRect(x: 53.2, y: 51.2, width: 1.6, height: 1.6)), fill: Color(hex: "#c87a50").opacity(0.7)),
            ArtItem(path: HezarfenAvatar.svgPath("M50 49 L48.6 54 Q50 55 51.5 54.3"), fill: Color(hex: "#e8b494")),
            ArtItem(path: HezarfenAvatar.svgPath("M42 58 Q50 64 58 58"), stroke: Color(hex: "#b0404a"), width: 2)
        ])
        }
    }
}
