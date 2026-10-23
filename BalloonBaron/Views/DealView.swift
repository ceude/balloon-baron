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
        let sizes: [BalloonSize] = offer.bankrupt ? (rival?.forSale?.sizes ?? []) : (rival?.balloons ?? [])
        let count = sizes.count
        let name: String = rival?.name ?? ""
        return ModalCard(onClose: later) {
            BalloonShape(colors: rivalColors(rival))
                .frame(width: 46, height: 58)
            CardText.title(loc(offer.bankrupt ? "deal.bankrupt.title" : "deal.sale.title", name))
            CardText.lead(loc(offer.bankrupt ? "deal.bankrupt.lead" : "deal.sale.lead", num(count), eur(price)))
            FleetMixList(sizes)
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

/// What a rival's fleet is made of, one line per basket size, biggest first: "Large basket, 24 seats × 2".
struct FleetMixList: View {
    let sizes: [BalloonSize]
    init(_ sizes: [BalloonSize]) { self.sizes = sizes }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(fleetMix(sizes), id: \.size) { row in
                HStack(spacing: 10) {
                    BalloonShape(colors: ["#cfc8dd", "#ffffff"])
                        .frame(width: 18, height: 23)
                    Text(loc("deal.fleetRow", row.size.title, num(row.size.capacity)))
                        .font(Theme.font(15, .semibold))
                        .foregroundStyle(Theme.ink)
                    Spacer(minLength: 4)
                    Text("× " + num(row.count))
                        .font(Theme.font(17, .heavy, condensed: true))
                        .foregroundStyle(Theme.ink)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.ink2.opacity(0.09), in: RoundedRectangle(cornerRadius: 14))
    }
}

/// Basket sizes counted, biggest first.
func fleetMix(_ sizes: [BalloonSize]) -> [(size: BalloonSize, count: Int)] {
    BalloonSize.allCases.reversed().compactMap { z in
        let n = sizes.filter { $0 == z }.count
        return n > 0 ? (z, n) : nil
    }
}
