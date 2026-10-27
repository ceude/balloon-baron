import SwiftUI
import UIKit
import BalloonBaronCore

/// v116: the Balloon Show's highlights (prototype `SHOW_MOMENTS`, `showHighlights`, `showMomentCard`). Four moments
/// of the show: the burners all on the beat, the wave of light, the balloons holding their figure, and the finale.
/// The morning after, they come up as a card; each becomes a picture to share. A show skipped before a moment simply
/// has fewer. The pictures are the night painter drawn again at those seconds, off screen, on the show's own camera.
enum ShowMoments {
    /// Seconds into the show (after the dusk) of each moment. 8.5 lands on a beat, when every burner flashes.
    static let at: [Double] = [8.5, 10.3, 20.85, 22.9]

    /// The moments a show stopped at `st` seconds reached.
    static func reached(_ st: Double) -> [Int] { at.indices.filter { at[$0] <= st } }

    static func title(_ i: Int, _ shots: GameStore.ShowShots) -> String {
        switch i {
        case 0: return loc("show.hl.beat")
        case 1: return loc("show.hl.wave")
        case 2:
            // The bought figure, or the one the fleet's size makes (`BalloonShow.figure`): geese, a ring, a heart.
            if let f = shots.state.showFigure { return f.title }
            let n = min(shots.ids.count, BalloonShow.maxShown)
            return loc(n < 8 ? "show.hl.geese" : n < 16 ? "show.hl.ring" : "show.hl.heart")
        default: return loc("show.hl.final", num(shots.ids.count))
        }
    }
}

/// One moment of the show as a 4:5 picture around the balloons, as wide as the screen allows.
struct ShowMomentPicture: View {
    let shots: GameStore.ShowShots
    let index: Int

    var body: some View {
        Canvas { ctx, sz in
            let full = shots.size, w = full.width, h = full.height
            var v = BalloonShow.camera(full)
            NightCamera.clamp(&v, full)
            let hz = NightCamera.horizon(v, full)
            v.hzFix = hz
            v.noLabels = true
            let top = max(150, hz * 0.1), bot = max(top + 200, hz + (h - hz) * 0.14)
            let cw = min(w, h * 0.8), ch = cw * 1.25, cy = min(max((top + bot) / 2 - ch * 0.04, ch / 2), h - ch / 2)
            var c = ctx
            c.scaleBy(x: sz.width / cw, y: sz.height / ch)
            c.translateBy(x: -(w - cw) / 2, y: -(cy - ch / 2))
            let st = ShowMoments.at[index]
            _ = TownPainter.render(&c, state: shots.state, time: 1000 + st + 1.2, viewport: v, size: full,
                                   night: TownNight(k: 1, event: .show(balloons: shots.ids), t0: 1000))
        }
        .background(Color(hex: "#1b1840"))
    }

    @MainActor static func image(_ shots: GameStore.ShowShots, _ i: Int) -> UIImage? {
        let r = ImageRenderer(content: ShowMomentPicture(shots: shots, index: i).frame(width: 720, height: 900))
        r.scale = 1
        return r.uiImage
    }
}

/// A moment to post: 1080×1350, the night sky, the picture as a tilted print with its caption, the game's name below.
struct ShowShareArt: View {
    let picture: UIImage
    let caption: String
    let day: Int
    let company: String
    let colors: [String]

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#141238"), Color(hex: "#2b2350"), Color(hex: "#4a2f5c")], startPoint: .top, endPoint: .bottom)
            Canvas { ctx, _ in
                for i in 0..<70 {
                    let x = CGFloat(i * 397 % 1080), y = CGFloat(i * 211 % 560), r = CGFloat(1 + i % 3)
                    var c = ctx
                    c.opacity = 0.25 + Double(i % 5) * 0.1
                    c.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(.white))
                }
            }
            VStack(spacing: 0) {
                Text(loc("show.hl.kicker", num(day)))
                    .font(Theme.font(30, .semibold)).tracking(4).foregroundStyle(Color(hex: "#fff6e6").opacity(0.8))
                    .padding(.top, 78)
                Text(company)
                    .font(Theme.font(78, .heavy, condensed: true)).foregroundStyle(Color(hex: "#fff6e6"))
                    .lineLimit(1).minimumScaleFactor(0.5)
                    .padding(.horizontal, 60)
                Spacer()
                ShareBrand(colors: colors, dark: true)
            }
            VStack(spacing: 18) {
                Image(uiImage: picture).resizable()
                    .frame(width: 600, height: 750)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                Text(caption).font(Theme.font(52, .heavy, condensed: true)).foregroundStyle(Theme.ink)
                    .lineLimit(1).minimumScaleFactor(0.5)
            }
            .padding(.top, 30).padding(.bottom, 26).padding(.horizontal, 30)
            .background(Color(hex: "#fffaf3"), in: RoundedRectangle(cornerRadius: 22))
            .shadow(color: .black.opacity(0.5), radius: 25, y: 24)
            .rotationEffect(.radians(0.03))
            .offset(y: -35)
        }
        .frame(width: ShareCardArt.size.width, height: ShareCardArt.size.height)
    }

    @MainActor static func image(_ shots: GameStore.ShowShots, _ i: Int, picture: UIImage) -> UIImage? {
        let r = ImageRenderer(content: ShowShareArt(picture: picture, caption: ShowMoments.title(i, shots), day: shots.day,
                                                    company: shots.state.company, colors: shots.state.colors))
        r.scale = 1
        r.proposedSize = ProposedViewSize(ShareCardArt.size)
        return r.uiImage
    }
}

/// The morning card: the moments in a 2×2 grid of prints; a tap opens that one's share picture.
struct ShowHighlightsView: View {
    @Environment(GameStore.self) private var store
    let shots: GameStore.ShowShots
    @State private var pictures: [Int: UIImage] = [:]
    @State private var open: Int?
    @State private var shareImage: UIImage?

    var body: some View {
        ModalCard(onClose: close) {
            if let open {
                sharePage(open)
            } else {
                grid
            }
        }
        .task {
            for i in shots.moments where pictures[i] == nil {
                await Task.yield()
                pictures[i] = ShowMomentPicture.image(shots, i)
            }
        }
    }

    @MainActor private var grid: some View {
        VStack(spacing: 12) {
            Text(loc("show.title")).font(Theme.font(14, .heavy, condensed: true)).tracking(0.8).foregroundStyle(Theme.coral)
            CardText.title(loc("show.hl.title"))
            CardText.lead(loc("show.hl.lead"))
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 12) {
                ForEach(Array(shots.moments.enumerated()), id: \.element) { n, i in
                    Button {
                        SoundEngine.shared.play(.click)
                        shareImage = nil
                        open = i
                    } label: {
                        VStack(spacing: 5) {
                            Group {
                                if let p = pictures[i] { Image(uiImage: p).resizable() } else { Color(hex: "#141238") }
                            }
                            .aspectRatio(0.8, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                            Text(ShowMoments.title(i, shots)).font(Theme.font(15, .heavy, condensed: true)).foregroundStyle(Theme.ink)
                                .lineLimit(1).minimumScaleFactor(0.7)
                        }
                        .padding(6)
                        .background(Color(hex: "#fffaf3"), in: RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Theme.ink.opacity(0.22), radius: 7, y: 6)
                        .rotationEffect(.degrees(n % 2 == 0 ? -1.6 : 1.4))
                    }
                    .buttonStyle(.plain)
                    .disabled(pictures[i] == nil)
                }
            }
            Button {
                SoundEngine.shared.play(.click)
                close()
            } label: { Text(loc("ceremony.next")).frame(maxWidth: .infinity) }
            .buttonStyle(ChunkyButtonStyle(kind: .big, wide: true))
        }
    }

    @MainActor private func sharePage(_ i: Int) -> some View {
        VStack(spacing: 12) {
            Text(loc("share.button")).font(Theme.font(14, .heavy, condensed: true)).tracking(0.8).foregroundStyle(Theme.coral)
            Group {
                if let shareImage { Image(uiImage: shareImage).resizable() } else { Color(hex: "#2b2350") }
            }
            .aspectRatio(0.8, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Theme.ink.opacity(0.2), radius: 10, y: 8)
            if let shareImage {
                let title = ShowMoments.title(i, shots)
                ShareLink(item: Image(uiImage: shareImage), preview: SharePreview(title, image: Image(uiImage: shareImage))) {
                    Text(loc("share.button")).frame(maxWidth: .infinity)
                }
                .simultaneousGesture(TapGesture().onEnded {
                    SoundEngine.shared.play(.click)
                    Telemetry.send("show.shared", ["moment": String(i)])
                })
                .buttonStyle(ChunkyButtonStyle(kind: .big, wide: true))
            }
            Button {
                SoundEngine.shared.play(.click)
                open = nil
            } label: { Text(loc("show.hl.back")).frame(maxWidth: .infinity) }
            .buttonStyle(ChunkyButtonStyle(kind: .ghost, wide: true))
        }
        .task(id: i) { @MainActor in
            guard let p = pictures[i] ?? ShowMomentPicture.image(shots, i) else { return }
            shareImage = ShowShareArt.image(shots, i, picture: p)
        }
    }

    private func close() {
        store.showShots = nil
        store.showNextHezarfen()
    }
}
