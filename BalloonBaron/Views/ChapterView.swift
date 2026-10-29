import SwiftUI
import StoreKit
import BalloonBaronCore

/// Ceremony for a finished chapter, shown as soon as its goals are met. The last chapter crowns you baron.
struct ChapterView: View {
    @Environment(GameStore.self) private var store
    let news: ChapterNews
    @State private var shown = false
    /// Reduce Motion: the crown fades in without the bouncy zoom.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// After Devam: the chapter that starts now and its goals.
    @State private var showNext = false
    /// v123.1: Apple's rating prompt, once, when the second chapter starts.
    @Environment(\.requestReview) private var requestReview

    var body: some View {
        let chapters = news.region.chapters
        WorldPopup(topBar: Theme.sun, onClose: { close(chapters) }) {
            if let s = store.state, chapters.indices.contains(news.index) {
                if news.index == chapters.count - 1 {
                    baron(chapters[news.index], s)
                } else if showNext && chapters.indices.contains(news.index + 1) {
                    upcoming(chapters, s)
                } else {
                    finished(chapters, s)
                }
            } else {
                BigButton(title: loc("ceremony.continue")) { store.dismissPopup() }
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.4)) { shown = true }
            SoundEngine.shared.play(.fanfare)
            Haptics.success()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { SoundEngine.shared.play(.applause) }
        }
    }

    /// The ✕ does what the card's bottom button does: Devam goes on to the next chapter's goals, otherwise it closes.
    private func close(_ chapters: [Chapter]) {
        let finishedCard = news.index < chapters.count - 1 && !showNext
        if finishedCard && chapters.indices.contains(news.index + 1) {
            withAnimation(.easeOut(duration: 0.2)) { showNext = true }
        } else {
            start()
        }
    }

    /// "Başla" (or ✕) under the next chapter's goals. After the first chapter's ceremony, once and not on autopilot,
    /// Apple's rating prompt comes up (the prototype's `showRateMock`); the system decides whether it really shows.
    @MainActor private func start() {
        let ask = showNext && news.index == 0 && store.auto == nil && store.state?.rateAsked == nil
        if ask {
            store.act { $0.state.rateAsked = $0.state.day }
            requestReview()
        }
        store.dismissPopup()
    }

    private func baron(_ c: Chapter, _ s: GameState) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack {
                ChapterConfetti()
                    .frame(height: 110)
                CrownIcon()
                    .frame(width: 112, height: 84)
                    .scaleEffect(shown || reduceMotion ? 1 : 0.4)
                    .opacity(shown ? 1 : 0)
            }
            .frame(maxWidth: .infinity)
            tag(loc("ceremony.tag"))
            Text(c.title)
                .font(Theme.font(32, .heavy, condensed: true))
                .foregroundStyle(Theme.ink)
            Text(loc(news.region == .cap ? "ceremony.baronLead" : "ceremony.baronLead.\(news.region.rawValue)", num(s.day), news.region.title, s.company))
                .font(Theme.font(16, .medium))
                .foregroundStyle(Theme.ink)
            if news.region == .cap {
                // v121: Hasan's basket in its glass case, and Kenan's note under it
                VStack(spacing: 4) {
                    HasanBasketCase().frame(width: 150, height: 140)
                    Text(loc("ceremony.basket"))
                        .font(Theme.font(13)).foregroundStyle(Theme.ink2)
                        .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
            }
            HStack(alignment: .top, spacing: 10) {
                BossAvatar(region: news.region, size: 44)
                (Text((news.region == .cap ? loc("ceremony.bossNote", loc("boss.cap.name")) : loc("boss.\(news.region.rawValue).name")) + ": ").bold()
                 + Text(loc("boss.\(news.region.rawValue).baron")))
                    .font(Theme.font(13.5)).foregroundStyle(Theme.ink2).fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .background(Color(hex: "#f1edf8"), in: RoundedRectangle(cornerRadius: 14))
            Text(loc("ceremony.baronHint.\(news.region.rawValue)"))
                .font(Theme.font(14))
                .foregroundStyle(Theme.ink2)
            if news.region == .cap && !s.owned(.worldTour) {
                // v115: the free game ends here; the Grand Tour is offered right after the ceremony
                BigButton(title: loc("ceremony.next")) {
                    store.showTourOffer = true
                    store.dismissPopup()
                }
            } else {
                BigButton(title: loc("ceremony.openMap")) {
                    // The page goes up first so the next popup waits until the map is closed.
                    store.page = .map
                    store.dismissPopup()
                }
            }
            BigButton(title: loc("world.close"), style: .ghost) { store.dismissPopup() }
        }
    }

    /// The chapter just finished, every goal ticked. Devam moves on to the next chapter's goals.
    private func finished(_ chapters: [Chapter], _ s: GameState) -> some View {
        let c = chapters[news.index]
        let hasNext = chapters.indices.contains(news.index + 1)
        return VStack(alignment: .leading, spacing: 12) {
            ChapterConfetti()
                .frame(height: 60)
                .opacity(shown ? 1 : 0)
            tag(loc("ceremony.done", num(news.index + 1)))
            Text(c.title)
                .font(Theme.font(32, .heavy, condensed: true))
                .foregroundStyle(Theme.ink)
            Text(loc("ceremony.award", c.award, eur(c.reward)))
                .font(Theme.font(16, .medium))
                .foregroundStyle(Theme.ink)
            ForEach(c.goals.indices, id: \.self) { i in
                ChapterGoalRow(goal: c.goals[i], state: s, finished: true)
            }
            BigButton(title: loc("ceremony.continue")) {
                if hasNext {
                    withAnimation(.easeOut(duration: 0.2)) { showNext = true }
                } else {
                    store.dismissPopup()
                }
            }
            .padding(.top, 4)
        }
    }

    private func upcoming(_ chapters: [Chapter], _ s: GameState) -> some View {
        let next = chapters[news.index + 1]
        return VStack(alignment: .leading, spacing: 12) {
            ChapterHeading(region: news.region, number: news.index + 2, total: chapters.count, title: next.title)
            ForEach(next.goals.indices, id: \.self) { i in
                ChapterGoalRow(goal: next.goals[i], state: s)
            }
            BigButton(title: loc("ceremony.start")) { start() }
                .padding(.top, 4)
        }
    }

    private func tag(_ text: String) -> some View {
        Text(text)
            .font(Theme.font(14, .heavy, condensed: true))
            .tracking(0.8)
            .textCase(.uppercase)
            .foregroundStyle(Theme.coral)
    }
}

/// Scattered paper confetti, drawn the same every time.
struct ChapterConfetti: View {
    var body: some View {
        Canvas { ctx, size in
            let colors: [Color] = [Theme.coral, Theme.sun, Color(hex: "#3ad0c0"), Color(hex: "#9b7be0"), Theme.green, Color(hex: "#5aa9e6")]
            func fract(_ v: Double) -> Double { abs(v - v.rounded(.towardZero)) }
            for i in 0..<34 {
                let d = Double(i)
                let x = fract(sin(d * 12.9898) * 43758.5453) * Double(size.width)
                let y = fract(sin(d * 78.233) * 24634.6345) * Double(size.height)
                let angle = fract(sin(d * 3.7) * 9631.17) * Double.pi
                var piece = ctx
                piece.translateBy(x: CGFloat(x), y: CGFloat(y))
                piece.rotate(by: .radians(angle))
                let rect = i % 3 == 0 ? CGRect(x: -3, y: -3, width: 6, height: 6) : CGRect(x: -5, y: -2, width: 10, height: 4)
                piece.fill(Path(roundedRect: rect, cornerRadius: 1.5), with: .color(colors[i % colors.count]))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// v121: Hasan's old basket on a plinth behind glass, with a brass plate (the prototype's `VITRIN`, drawn in a 150×140 box).
struct HasanBasketCase: View {
    var body: some View {
        Canvas { ctx, size in
            let k = min(size.width / 150, size.height / 140)
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * k, y: y * k) }
            func r(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ c: CGFloat) -> Path {
                Path(roundedRect: CGRect(x: x * k, y: y * k, width: w * k, height: h * k), cornerRadius: c * k)
            }
            let lamp = Color(hex: "#ffe7a8")
            ctx.fill(r(22, 8, 106, 98, 4), with: .radialGradient(Gradient(colors: [lamp.opacity(0.55), lamp.opacity(0)]),
                                                                center: p(75, 8), startRadius: 0, endRadius: 95 * k))
            var basket = Path()
            basket.move(to: p(50, 96)); basket.addLine(to: p(56, 50))
            basket.addQuadCurve(to: p(94, 50), control: p(75, 44)); basket.addLine(to: p(100, 96))
            basket.addQuadCurve(to: p(50, 96), control: p(75, 102)); basket.closeSubpath()
            ctx.fill(basket, with: .linearGradient(Gradient(colors: [Color(hex: "#c98c4a"), Color(hex: "#7a4a22")]),
                                                   startPoint: p(75, 44), endPoint: p(75, 100)))
            var weave = Path()
            for (y, d) in [(62.0, 57.0), (72, 67), (82, 77), (91, 87)] as [(CGFloat, CGFloat)] {
                weave.move(to: p(52 - (y - 62) / 15, y)); weave.addQuadCurve(to: p(98 + (y - 62) / 15, y), control: p(75, d))
            }
            for (x0, y0, x1, y1) in [(62.0, 49.0, 59.0, 98.0), (72, 47, 71, 100), (82, 47, 83, 100), (91, 49, 94, 98)] as [(CGFloat, CGFloat, CGFloat, CGFloat)] {
                weave.move(to: p(x0, y0)); weave.addLine(to: p(x1, y1))
            }
            ctx.stroke(weave, with: .color(Color(hex: "#5a3214").opacity(0.75)), lineWidth: 1.1 * k)
            var rim = Path(); rim.move(to: p(54, 50)); rim.addQuadCurve(to: p(96, 50), control: p(75, 41))
            ctx.stroke(rim, with: .color(Color(hex: "#e3b27a")), lineWidth: 3 * k)
            var frame = Path(); frame.move(to: p(58, 49)); frame.addLine(to: p(60, 30)); frame.move(to: p(92, 49)); frame.addLine(to: p(90, 30))
            ctx.stroke(frame, with: .color(Color(hex: "#9a9a9a")), lineWidth: 1.6 * k)
            ctx.fill(r(58, 24, 34, 7, 2), with: .color(Color(hex: "#6d6d6d")))
            let glass = Color(hex: "#bfe3ff")
            ctx.fill(r(22, 8, 106, 98, 4), with: .linearGradient(Gradient(colors: [glass.opacity(0.28), .white.opacity(0.08), glass.opacity(0.22)]),
                                                                startPoint: p(22, 50), endPoint: p(128, 50)))
            ctx.stroke(r(22, 8, 106, 98, 4), with: .color(Color(hex: "#d8eeff").opacity(0.6)), lineWidth: 1.5 * k)
            var shine = Path(); shine.move(to: p(32, 14)); shine.addLine(to: p(44, 14)); shine.addLine(to: p(30, 70)); shine.addLine(to: p(26, 70)); shine.closeSubpath()
            ctx.fill(shine, with: .color(.white.opacity(0.18)))
            ctx.fill(r(14, 104, 122, 22, 3), with: .linearGradient(Gradient(colors: [Color(hex: "#6b3b22"), Color(hex: "#3e2112")]),
                                                                  startPoint: p(75, 104), endPoint: p(75, 126)))
            ctx.fill(r(10, 102, 130, 5, 2), with: .color(Color(hex: "#8a5232")))
            ctx.fill(r(52, 110, 46, 11, 2), with: .color(Color(hex: "#d9b25a")))
            ctx.draw(Text(verbatim: loc("ceremony.basketPlate")).font(.system(size: 7.5 * k, design: .serif)).foregroundColor(Color(hex: "#4a3210")),
                     at: p(75, 115.5))
        }
        .accessibilityHidden(true)
    }
}
