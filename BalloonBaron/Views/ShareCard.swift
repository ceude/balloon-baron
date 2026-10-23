import SwiftUI
import UIKit
import BalloonBaronCore

/// A postcard to post: 1080×1350 (4:5, Instagram's tallest), the card tilted on its own sky, company and day
/// above, the game's name below. Night cards stay dark all the way down. Port of the prototype's `shareCard`.
struct ShareCardArt: View {
    let achievement: Achievement
    let day: Int
    let colors: [String]
    let company: String

    static let size = CGSize(width: 1080, height: 1350)

    private var sky: [String] { achievement.sky }
    private var dark: Bool { Self.luminance(sky[0]) < 0.3 }
    private var ink: Color { Theme.ink }
    private var top: Color { dark ? Color(hex: "#fff6e6") : ink }

    var body: some View {
        ZStack {
            LinearGradient(stops: [.init(color: Color(hex: sky[0]), location: 0), .init(color: Color(hex: sky[1]), location: 0.5),
                                   .init(color: Color(hex: dark ? sky[2] : "#fff1dc"), location: 1)],
                           startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [Color(hex: "#fff0c8").opacity(dark ? 0.16 : 0.45), .clear], center: UnitPoint(x: 0.78, y: 0.185),
                           startRadius: 0, endRadius: 420)
            farBalloons
            VStack(spacing: 0) {
                Text(loc("share.kicker", num(day)))
                    .font(Theme.font(30, .semibold)).tracking(4).foregroundStyle(top.opacity(0.8))
                    .padding(.top, 98)
                Text(company)
                    .font(Theme.font(86, .heavy, condensed: true)).foregroundStyle(top)
                    .lineLimit(1).minimumScaleFactor(0.5)
                    .padding(.horizontal, 60)
                Spacer()
                HStack(spacing: 20) {
                    BalloonShape(colors: colors.isEmpty ? ["#ff5e3a", "#ffc23d"] : colors)
                        .frame(width: 56, height: 72)
                    Text("BALLOON BARON").font(Theme.font(64, .heavy, condensed: true)).foregroundStyle(top)
                }
                Text("Cappadocia")
                    .font(.system(size: 36, weight: .bold, design: .serif).italic())
                    .foregroundStyle(Color(hex: dark ? "#ffc23d" : "#c0582c"))
                    .padding(.bottom, 74)
            }
            PostcardArt(achievement: achievement, day: day, colors: colors)
                .frame(width: 900)
                .rotationEffect(.radians(-0.045))
                .shadow(color: Color(red: 43 / 255, green: 35 / 255, blue: 80 / 255).opacity(0.35), radius: 25, y: 24)
                .offset(y: -7)
        }
        .frame(width: Self.size.width, height: Self.size.height)
    }

    /// Far balloons drifting behind, in the company's colours and the valley's.
    private var farBalloons: some View {
        Canvas { ctx, _ in
            let main = colors.first ?? "#ff5e3a"
            for (x, y, r, c) in [(150.0, 330.0, 34.0, main), (930, 520, 26, "#14a39a"), (110, 1020, 22, "#ffc23d"), (990, 1110, 30, main)] {
                var b = ctx
                b.opacity = 0.28
                b.fill(BalloonPainter.envelope(x: x, cy: y, r: r), with: .color(Color(hex: c)))
                b.fill(Path(CGRect(x: x - r * 0.25, y: y + r * 1.75, width: r * 0.5, height: r * 0.32)), with: .color(Color(hex: c)))
            }
        }
    }

    static func luminance(_ hex: String) -> Double {
        let v = Int(hex.dropFirst(), radix: 16) ?? 0
        return (0.299 * Double(v >> 16 & 255) + 0.587 * Double(v >> 8 & 255) + 0.114 * Double(v & 255)) / 255
    }

    /// The picture, drawn off screen.
    @MainActor static func image(_ a: Achievement, day: Int, colors: [String], company: String) -> UIImage? {
        let r = ImageRenderer(content: ShareCardArt(achievement: a, day: day, colors: colors, company: company))
        r.scale = 1
        r.proposedSize = ProposedViewSize(size)
        return r.uiImage
    }
}

/// "Share": draws the picture once, then opens the system share sheet with it.
struct ShareCardButton: View {
    @Environment(GameStore.self) private var store
    let achievement: Achievement
    var big = false
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                ShareLink(item: Image(uiImage: image), preview: SharePreview(achievement.title, image: Image(uiImage: image))) {
                    Text(loc("share.button")).frame(maxWidth: .infinity)
                }
                .simultaneousGesture(TapGesture().onEnded { SoundEngine.shared.play(.click) })
            } else {
                Button {} label: { Text(loc("share.button")).frame(maxWidth: .infinity) }.disabled(true)
            }
        }
        .buttonStyle(ChunkyButtonStyle(kind: big ? .big : .ghost))
        .task(id: achievement) {
            guard let s = store.state else { return }
            image = ShareCardArt.image(achievement, day: s.achievements[achievement] ?? s.day, colors: s.colors, company: s.company)
        }
    }
}
