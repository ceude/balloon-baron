import SwiftUI
import BalloonBaronCore

/// A struggling rival's take-over offer or a bankrupt rival's fleet sale (prototype `checkDeals`).
struct DealView: View {
    @Environment(GameStore.self) private var store
    let offer: DealOffer

    var body: some View {
        let s: GameState? = store.state
        let rival: Rival? = s.flatMap { st in st.rivals.indices.contains(offer.rival) ? st.rivals[offer.rival] : nil }
        let cash: Int = s?.cash ?? 0
        let price: Int = offer.bankrupt ? (rival?.forSale?.price ?? 0) : (rival?.offer ?? 0)
        let count: Int = offer.bankrupt ? (rival?.forSale?.sizes.count ?? 0) : (rival?.balloons.count ?? 0)
        let name: String = rival?.name ?? ""
        return ModalCard(onClose: later) {
            BalloonShape(colors: rivalColors(rival))
                .frame(width: 46, height: 58)
            CardText.title(loc(offer.bankrupt ? "deal.bankrupt.title" : "deal.sale.title", name))
            CardText.lead(loc(offer.bankrupt ? "deal.bankrupt.lead" : "deal.sale.lead", num(count), eur(price)))
            if cash < price {
                CardText.hint(loc("deal.short", eur(cash)))
            }
            Button(loc(offer.bankrupt ? "deal.buy" : "deal.takeOver", eur(price))) {
                SoundEngine.shared.play(.coin)
                store.answerDeal(offer, accept: true)
            }
            .buttonStyle(ChunkyButtonStyle(kind: .big))
            .disabled(cash < price || rival == nil)
            buttons
            CardText.hint(loc("deal.hint"))
        }
    }

    private var buttons: some View {
        HStack(spacing: 10) {
            Button {
                SoundEngine.shared.play(.click)
                store.answerDeal(offer, accept: false)
            } label: {
                Text(loc("deal.decline")).frame(maxWidth: .infinity)
            }
            .buttonStyle(ChunkyButtonStyle(kind: .ghost))
            Button {
                SoundEngine.shared.play(.click)
                later()
            } label: {
                Text(loc("deal.later")).frame(maxWidth: .infinity)
            }
            .buttonStyle(ChunkyButtonStyle(kind: .ghost))
        }
    }

    /// Later: the offer stays seen and waits on the Market page.
    private func later() {
        store.deal = nil
        store.showNextHezarfen()
    }

    private func rivalColors(_ r: Rival?) -> [String] {
        let c: [String] = r?.colors ?? []
        return [c.first ?? "#9a8fb8", c.count > 1 ? c[1] : "#ffffff"]
    }
}
