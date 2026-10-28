import SwiftUI
import BalloonBaronCore

/// v121.13: who comes with a rival's fleet, and what they cost a day.
func crewNote(_ crew: [Pilot]) -> String {
    func n(_ l: PilotLevel) -> String { num(crew.filter { $0.level == l }.count) }
    return loc("deal.crew", num(crew.count), n(.senior), n(.experienced), n(.rookie), eur(crew.reduce(0) { $0 + $1.wage }))
}

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
            if let s { CardText.hint(crewNote(s.dealCrew(offer.rival, bankrupt: offer.bankrupt))) }
            CardText.hint(loc("deal.used", percent(Rules.usedSellShare), percent(Rules.sellShare)))
            let terms = cash < price ? store.game?.buyLoanTerms(price: price) : nil
            if cash < price {
                let fleet = store.game?.state.balloons.count ?? 0
                if terms == nil, store.game?.state.unlocked.contains(.bank) == true, fleet < Rules.buyLoanBalloons {
                    CardText.hint(loc("deal.shortFew", eur(cash), num(Rules.buyLoanBalloons), num(fleet)))
                } else {
                    CardText.hint(loc(terms == nil ? "deal.short" : "deal.shortLoan", eur(cash)))
                }
            }
            if let terms {
                Button(loc("buyLoan.button", eur(terms.financed))) {
                    SoundEngine.shared.play(.click)
                    store.buyLoan = offer
                }
                .buttonStyle(ChunkyButtonStyle(kind: .big))
            } else {
                Button(loc(offer.bankrupt ? "deal.buy" : "deal.takeOver", eur(price))) {
                    SoundEngine.shared.play(.coin)
                    store.answerDeal(offer, accept: true)
                }
                .buttonStyle(ChunkyButtonStyle(kind: .big))
                .disabled(cash < price || rival == nil)
            }
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

/// The purchase loan's terms, like a mortgage: the bank pays the seller what you're short and nothing goes into your
/// till. Warns about winter and the new fleet's running costs before you sign.
struct BuyLoanView: View {
    @Environment(GameStore.self) private var store
    let offer: DealOffer

    var body: some View {
        let s = store.state, g = store.game
        let rival: Rival? = s.flatMap { st in st.rivals.indices.contains(offer.rival) ? st.rivals[offer.rival] : nil }
        let price = g?.dealPrice(offer.rival, bankrupt: offer.bankrupt) ?? 0
        let sizes: [BalloonSize] = offer.bankrupt ? (rival?.forSale?.sizes ?? []) : (rival?.balloons ?? [])
        let upkeep = sizes.reduce(0) { $0 + $1.upkeep }
        return ModalCard(onClose: { store.buyLoan = nil }) {
            Text(loc("buyLoan.kicker"))
                .font(Theme.font(14, .heavy, condensed: true)).tracking(0.8).textCase(.uppercase).foregroundStyle(Theme.coral)
            CardText.title(rival?.name ?? "")
            if let t = g?.buyLoanTerms(price: price) {
                CardText.lead(loc("buyLoan.lead", eur(t.financed), eur(t.own), eur((s?.cash ?? 0) - t.own)))
                VStack(spacing: 6) {
                    row(loc("buyLoan.price"), eur(price))
                    row(loc("buyLoan.own"), eur(t.own))
                    row(loc("buyLoan.bank"), eur(t.financed))
                    row(loc("buyLoan.installment", num(t.days)), loc("crew.wage", eur(t.installment)))
                    row(loc("buyLoan.total", percent(Rules.buyLoanRate)), eur(t.total))
                }
                .padding(12)
                .background(Theme.ink2.opacity(0.09), in: RoundedRectangle(cornerRadius: 14))
                HStack(alignment: .top, spacing: 10) {
                    RoundedRectangle(cornerRadius: 3).fill(Theme.yellow).frame(width: 6)
                    Text(loc("buyLoan.warning", eur(upkeep), eur(Rules.seizeBelow)))
                        .font(Theme.font(14))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .background(Theme.yellow.opacity(0.14), in: RoundedRectangle(cornerRadius: 14))
                Button(loc(offer.bankrupt ? "buyLoan.confirmFleet" : "buyLoan.confirm")) {
                    SoundEngine.shared.play(.coin)
                    store.buyWithLoan(offer)
                }
                .buttonStyle(ChunkyButtonStyle(kind: .big))
            }
            Button {
                SoundEngine.shared.play(.click)
                store.buyLoan = nil
            } label: {
                Text(loc("buyLoan.cancel")).frame(maxWidth: .infinity)
            }
            .buttonStyle(ChunkyButtonStyle(kind: .ghost))
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(Theme.font(15)).foregroundStyle(Theme.ink2)
            Spacer(minLength: 8)
            Text(value).font(Theme.font(17, .heavy, condensed: true)).foregroundStyle(Theme.ink)
        }
        .accessibilityElement(children: .combine)
    }
}
