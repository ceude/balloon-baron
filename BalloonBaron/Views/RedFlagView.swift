import SwiftUI
import BalloonBaronCore

/// The prototype's `.modal` + `.card`: dimmed backdrop with a white rounded card in the middle.
/// A card that can be closed passes `onClose` (what its bottom close button does) and gets a ✕.
struct ModalCard<Content: View>: View {
    var onClose: (() -> Void)? = nil
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
            .overlay(alignment: .topTrailing) {
                if let onClose { CardCloseX(action: onClose) }
            }
            .compositingGroup()
            .shadow(color: .black.opacity(0.35), radius: 25, y: 20)
            .padding(16)
            .frame(maxWidth: .infinity)
    }
}

/// The prototype's `.cardx`: a ✕ in a closable card's top right corner, doing what its bottom button does.
struct CardCloseX: View {
    let action: () -> Void

    var body: some View {
        Button {
            SoundEngine.shared.play(.click)
            action()
        } label: {
            Text("✕")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Theme.ink)
                .frame(width: 38, height: 38)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                .compositingGroup()
                .shadow(color: Theme.line, radius: 0, y: 3)
        }
        .buttonStyle(.plain)
        .padding(12)
        .accessibilityLabel(loc("world.close"))
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

/// `pilotCheck()`: before collecting passengers, balloons you meant to fly that have no pilot stay on the ground.
/// Says which, with the way to the crew page or flying anyway.
struct GroundedView: View {
    @Environment(GameStore.self) private var store
    let onClose: () -> Void
    let onFly: () -> Void

    static func grounded(_ s: GameState) -> [Balloon] { s.sortedFleet.filter { $0.fly && s.status($0) == .noPilot } }

    var body: some View {
        let left = store.state.map(Self.grounded) ?? []
        ModalCard {
            CardText.title(left.count == 1 ? loc("grounded.one") : loc("grounded.many", num(left.count)))
            CardText.lead(loc("grounded.lead", left.map(\.name).joined(separator: ", ")))
            HStack(spacing: 10) {
                Button(loc("grounded.crew")) {
                    SoundEngine.shared.play(.click)
                    onClose()
                    store.page = .crew
                }
                .buttonStyle(ChunkyButtonStyle(kind: .ghost))
                Button(loc("grounded.fly")) {
                    SoundEngine.shared.play(.click)
                    onFly()
                }
                .buttonStyle(ChunkyButtonStyle(kind: .big))
            }
        }
    }
}

/// `confirmRed()`: warns before launching on a red-flag day. Overlay it; `onClose` hides it.
struct RedFlagView: View {
    @Environment(GameStore.self) private var store
    let onClose: () -> Void
    /// In the first 20 days Hezarfen asks once more before a red-flag take-off (`redSure`).
    @State private var sure = false

    var body: some View {
        if sure { secondThoughts } else { warning }
    }

    private var secondThoughts: some View {
        ModalCard {
            CardText.title(loc("red.sureTitle"))
            HStack(alignment: .top, spacing: 10) {
                HezarfenAvatar(size: 44)
                (Text(loc("hez.name") + ": ").bold() + Text(loc("red.sureHez")))
                    .font(Theme.font(14)).foregroundStyle(Theme.ink2).fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .background(Color(hex: "#f1edf8"), in: RoundedRectangle(cornerRadius: 14))
            Button(loc("red.sureSkip")) {
                SoundEngine.shared.play(.click)
                onClose()
                store.fly(skip: true)
            }
            .buttonStyle(ChunkyButtonStyle(kind: .big, wide: true))
            Button {
                SoundEngine.shared.play(.click)
                onClose()
                store.startCollect()
            } label: { Text(loc("red.sureFly")).frame(maxWidth: .infinity) }
            .buttonStyle(ChunkyButtonStyle(kind: .ghost))
        }
    }

    private var warning: some View {
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
                if (store.state?.day ?? 99) <= 20 {
                    withAnimation(.easeOut(duration: 0.2)) { sure = true }
                } else {
                    onClose()
                    store.startCollect()
                }
            }
            .buttonStyle(ChunkyButtonStyle(kind: .big))
        }
    }
}
