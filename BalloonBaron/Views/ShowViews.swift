import SwiftUI
import BalloonBaronCore

/// v111: the Balloon Show's card (`showCard`): what it costs (every balloon that can fly), what it brings, and the
/// wait until the next one. Booked, it plays over the town that night.
struct ShowCardView: View {
    @Environment(GameStore.self) private var store
    /// Booked in this card: it now says when the show starts.
    @State private var booked = false

    var body: some View {
        ModalCard {
            if let g = store.game {
                if booked { done(g) } else { offer(g) }
            }
        }
    }

    @ViewBuilder
    private func offer(_ g: Game) -> some View {
        let st = g.showState, n = g.showFleet.count
        CardText.title(loc("show.openTitle"))
        CardText.lead(loc("show.intro"))
        VStack(alignment: .leading, spacing: 4) {
            Text(loc("show.gainsTitle")).font(Theme.font(14, .bold)).foregroundStyle(Theme.ink)
            ForEach([loc("show.gainRep"), loc("show.gainPax", num(Int(Rules.showPax)), num(Int(Rules.showPax) * n)),
                     loc("show.gainCap"), loc("show.gainPaper")], id: \.self) { line in
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("•").foregroundStyle(Theme.coral)
                    Text(line).fixedSize(horizontal: false, vertical: true)
                }
                .font(Theme.font(13.5)).foregroundStyle(Theme.ink)
            }
            Text(loc("show.gainNote", num(Rules.showCooldown))).font(Theme.font(12)).foregroundStyle(Theme.ink2).padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(hex: "#f4f0fb"), in: RoundedRectangle(cornerRadius: 14))
        if st == .ok {
            Grid(alignment: .leading, verticalSpacing: 4) {
                GridRow { Text(loc("show.calcBalloons")); Text(num(n)).bold().gridColumnAlignment(.trailing) }
                GridRow { Text(loc("show.calcEach")); Text(eur(Rules.showPerBalloon)).bold() }
                Divider().gridCellUnsizedAxes(.horizontal)
                GridRow {
                    Text(loc("show.calcTotal", num(n), eur(Rules.showPerBalloon))).bold()
                    Text(eur(g.showCost)).font(Theme.font(15, .heavy))
                }
            }
            .font(Theme.font(14)).foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Theme.sun.opacity(0.2), in: RoundedRectangle(cornerRadius: 14))
            Button(loc("show.confirm", eur(g.showCost))) {
                SoundEngine.shared.play(.coin)
                store.act { _ = $0.bookShow() }
                withAnimation(.easeOut(duration: 0.2)) { booked = true }
            }
            .buttonStyle(ChunkyButtonStyle(kind: .big, wide: true))
            Button {
                SoundEngine.shared.play(.click)
                store.closeShowCard()
            } label: { Text(loc("show.cancelBtn")).frame(maxWidth: .infinity) }
            .buttonStyle(ChunkyButtonStyle(kind: .ghost, wide: true))
        } else {
            Text(ShowCardView.why(st, g))
                .font(Theme.font(14, .bold)).foregroundStyle(Theme.red)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Theme.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
            Button(loc("home.close")) {
                SoundEngine.shared.play(.click)
                store.closeShowCard()
            }
            .buttonStyle(ChunkyButtonStyle(kind: .big, wide: true))
        }
    }

    @ViewBuilder
    private func done(_ g: Game) -> some View {
        CardText.title(loc("show.doneTitle"))
        CardText.lead(loc("show.doneBody", num(g.state.local.showIDs?.count ?? 0)))
        Text(loc("show.doneNote", num(Rules.showMinBalloons)))
            .font(Theme.font(12.5)).foregroundStyle(Theme.ink2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
        Button(loc("show.ok")) {
            SoundEngine.shared.play(.click)
            store.closeShowCard()
        }
        .buttonStyle(ChunkyButtonStyle(kind: .big, wide: true))
    }

    /// Why the show can't be booked now; also the short status on the entry rows.
    static func why(_ st: ShowState, _ g: Game) -> String {
        switch st {
        case .locked: loc("show.locked")
        case .booked: loc("show.booked")
        case .wait(let d): loc("show.wait", num(d))
        case .few: loc("show.few", num(Rules.showMinBalloons), num(g.showFleet.count))
        case .cash: loc("show.cash", eur(g.showCost))
        case .ok: loc("show.ready", num(g.showFleet.count), eur(g.showCost))
        }
    }

    /// Whether the show is worth a row on the pages: the market is open and the fleet is big enough.
    static func offered(_ g: Game) -> Bool { g.state.unlocked.contains(.market) && g.state.balloons.count >= Rules.showMinBalloons }
}
