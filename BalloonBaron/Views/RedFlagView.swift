import SwiftUI
import BalloonBaronCore

/// The prototype's `.modal` + `.card`: dimmed backdrop with a white rounded card in the middle.
struct ModalCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            Color(red: 27 / 255, green: 24 / 255, blue: 64 / 255).opacity(0.55)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {}
            ViewThatFits(in: .vertical) {
                card
                ScrollView { card }
            }
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 14, content: content)
            .padding(.horizontal, 20)
            .padding(.vertical, 22)
            .frame(maxWidth: 420, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.35), radius: 25, y: 20)
            .padding(16)
            .frame(maxWidth: .infinity)
    }
}

/// Text styles of the prototype's cards.
enum CardText {
    /// `.card h1`.
    static func title(_ s: String) -> some View {
        Text(s).font(Theme.font(32, .heavy, condensed: true)).foregroundStyle(Theme.ink)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// `.lead`.
    static func lead(_ s: String) -> some View {
        Text(s).font(Theme.font(16)).foregroundStyle(Theme.ink2).fixedSize(horizontal: false, vertical: true)
    }

    /// `.hint`.
    static func hint(_ s: String) -> some View {
        Text(s).font(Theme.font(13.5)).foregroundStyle(Theme.ink2).fixedSize(horizontal: false, vertical: true)
    }

    /// `ul.ev`: one line per item with a coral dot.
    static func bullets(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, t in
                HStack(alignment: .top, spacing: 10) {
                    Circle().fill(Theme.coral).frame(width: 8, height: 8).padding(.top, 6)
                    Text(t).font(Theme.font(14)).foregroundStyle(Theme.ink).fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

/// `confirmRed()`: warns before launching on a red-flag day. Overlay it; `onClose` hides it.
struct RedFlagView: View {
    @Environment(GameStore.self) private var store
    let onClose: () -> Void

    var body: some View {
        let fl = store.state?.flyingToday ?? []
        let strikes = store.state?.strikes ?? 0
        let worst = fl.compactMap { b in store.game?.accidentChance(b) }.max() ?? 0
        return ModalCard {
            CardText.title(loc("red.title"))
            CardText.lead(loc("red.lead", num(fl.count)))
            CardText.bullets([
                loc("red.fine", percent(Rules.redCatch), eur(Rules.redFine), num(strikes)),
                loc("red.insurance"),
                loc("red.risk", percent(worst)),
                loc("red.reviews")
            ])
            CardText.lead(loc("red.sure"))
            buttons
        }
    }

    private var buttons: some View {
        HStack(spacing: 10) {
            Button(loc("red.skip")) {
                SoundEngine.shared.play(.click)
                onClose()
                store.fly(skip: true)
            }
            .buttonStyle(ChunkyButtonStyle(kind: .ghost))
            Button(loc("red.fly")) {
                SoundEngine.shared.play(.click)
                onClose()
                store.startCollect()
            }
            .buttonStyle(ChunkyButtonStyle(kind: .big))
        }
    }
}
