import SwiftUI
import BalloonBaronCore

/// Ceremony for a finished chapter, shown the morning after. The last chapter crowns you baron.
struct ChapterView: View {
    @Environment(GameStore.self) private var store
    let news: ChapterNews
    @State private var shown = false

    var body: some View {
        let chapters = news.region.chapters
        WorldPopup(topBar: Theme.sun) {
            if let s = store.state, chapters.indices.contains(news.index) {
                if news.index == chapters.count - 1 {
                    baron(chapters[news.index], s)
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { SoundEngine.shared.play(.applause) }
        }
    }

    private func baron(_ c: Chapter, _ s: GameState) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack {
                ChapterConfetti()
                    .frame(height: 110)
                CrownIcon()
                    .frame(width: 112, height: 84)
                    .scaleEffect(shown ? 1 : 0.4)
                    .opacity(shown ? 1 : 0)
            }
            .frame(maxWidth: .infinity)
            tag(loc("ceremony.tag"))
            Text(c.title)
                .font(Theme.font(32, .heavy, condensed: true))
                .foregroundStyle(Theme.ink)
            Text(loc("ceremony.baronLead", num(s.day), news.region.title, s.company))
                .font(Theme.font(16, .medium))
                .foregroundStyle(Theme.ink)
            Text(loc(news.region == .cap ? "ceremony.baronHint.cap" : "ceremony.baronHint.abq"))
                .font(Theme.font(14))
                .foregroundStyle(Theme.ink2)
            BigButton(title: loc("ceremony.openMap")) {
                // The page goes up first so the next popup waits until the map is closed.
                store.page = .map
                store.dismissPopup()
            }
            BigButton(title: loc("world.close"), style: .ghost) { store.dismissPopup() }
        }
    }

    private func finished(_ chapters: [Chapter], _ s: GameState) -> some View {
        let c = chapters[news.index]
        let next: Chapter? = chapters.indices.contains(news.index + 1) ? chapters[news.index + 1] : nil
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
            if let next {
                tag(loc("ceremony.next", num(news.index + 2), next.title))
                    .padding(.top, 4)
                ForEach(next.goals.indices, id: \.self) { i in
                    ChapterGoalRow(goal: next.goals[i], state: s)
                }
            }
            BigButton(title: loc("ceremony.continue")) { store.dismissPopup() }
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
    }
}
