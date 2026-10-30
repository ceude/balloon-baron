import SwiftUI
import BalloonBaronCore

/// v122: the guide office's screen (`showGuides`): three guides to fly for free, each recommending you to their clients
/// for a few days. Opened by the guide office in town and by the popularity card.
struct GuideOfficeView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        if let s = store.state {
            let wait = s.local.guideCooldown - s.day
            let busy = s.day <= s.local.guideUntil ? loc("guides.busy", num(s.local.guideUntil - s.day + 1)) : nil
            // The guided action lights the first guide you can afford, else Sena (id mehmet).
            let tagged = GuideOffer.allCases.first { wait <= 0 && s.cash >= $0.cost } ?? .mehmet
            OfferScreen(title: loc("town.b.guide"), sub: loc("guides.sub"), busy: busy, wait: wait, color: Color(hex: "#3ad0c0")) {
                ForEach(GuideOffer.allCases, id: \.self) { g in
                    OfferRow(initial: g.name(s.region), color: Color(hex: "#3ad0c0"),
                             name: g.name(s.region), tag: g.title(s.region),
                             detail: loc("guides.row", "+" + starsValue(g.rep * 4), num(g.pax), num(g.days), num(g.cooldown)),
                             price: eur(g.cost), disabled: wait > 0 || s.cash < g.cost, spot: g == tagged ? "ga.guide" : nil) {
                        SoundEngine.shared.play(.coin)
                        store.act { _ = $0.runGuideFlight(g) }
                    }
                }
            }
        }
    }
}

/// v122: the influencer agency's screen (`showAgency`): three influencers, from the cheap local traveller to the famous
/// one. Opened by the agency in town and by the popularity card.
struct AgencyView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        if let s = store.state {
            let wait = s.local.influencerCooldown - s.day
            let busy = s.day <= s.local.influencerUntil ? loc("agency.busy", num(s.local.influencerUntil - s.day + 1)) : nil
            // The guided action lights the local traveller, the cheapest.
            let tagged = InfluencerOffer.local
            OfferScreen(title: loc("town.b.influencer"), sub: loc("agency.sub", "+" + starsValue(0.1)), busy: busy, wait: wait,
                        color: Color(hex: "#ff6fa8")) {
                ForEach(InfluencerOffer.allCases, id: \.self) { i in
                    let cost = i.cost(s)
                    OfferRow(initial: loc("influ.\(i.rawValue).name"), color: Color(hex: "#ff6fa8"),
                             name: loc("influ.\(i.rawValue).name"), tag: nil,
                             detail: loc("agency.row", loc("influ.\(i.rawValue).title"), "+" + starsValue(i.rep * 4), num(i.pax), num(i.days), num(i.cooldown)),
                             price: eur(cost), disabled: wait > 0 || s.cash < cost, spot: i == tagged ? "ga.influ" : nil) {
                        SoundEngine.shared.play(.coin)
                        store.act { _ = $0.runInfluencer(i) }
                    }
                }
            }
        }
    }
}

extension GuideOffer {
    /// v124 (`GUIDE_NAMES`): the guides are local. Ayşe, Sena and Ekin work in Cappadocia (`guide.<id>.name`); every
    /// other region has its own three (`guidePick.<region>.<id>`, from `tools/strings/s42_port.py`), same ids and deals.
    func name(_ r: RegionID) -> String { r == .cap ? loc("guide.\(rawValue).name") : loc("guidePick.\(r.rawValue).\(rawValue)") }
    /// The title agrees with the local guide's gender in German and Spanish.
    func title(_ r: RegionID) -> String { r == .cap ? loc("guide.\(rawValue).title") : loc("guidePick.\(r.rawValue).\(rawValue).title") }
}

/// `pickScreen`: a card with a small heading, a title, what's running, the wait, the rows and Close.
private struct OfferScreen<Rows: View>: View {
    @Environment(GameStore.self) private var store
    let title: String
    let sub: String
    let busy: String?
    let wait: Int
    let color: Color
    @ViewBuilder let rows: () -> Rows

    var body: some View {
        ModalCard(onClose: { store.closeOffers() }) {
            Text(sub)
                .font(Theme.font(13, .heavy, condensed: true))
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundStyle(Theme.coral)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.trailing, 40)
            CardText.title(title)
            if let busy { callout(busy, Theme.green) }
            if wait > 0 { callout(loc("offers.wait", num(wait)), Theme.yellow) }
            VStack(spacing: 10, content: rows)
            Button(loc("fleetPage.close")) { store.closeOffers() }
                .buttonStyle(ChunkyButtonStyle(kind: .big))
                .frame(maxWidth: .infinity)
        }
    }

    private func callout(_ text: String, _ c: Color) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 3).fill(c).frame(width: 5)
            Text(text).font(Theme.font(14, .semibold)).foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(10)
        .fixedSize(horizontal: false, vertical: true)
        .background(c.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    }
}

/// One guide or influencer: a coloured initial, the name (and title), what they bring, and the price button.
private struct OfferRow: View {
    let initial: String
    let color: Color
    let name: String
    let tag: String?
    let detail: String
    let price: String
    let disabled: Bool
    let spot: String?
    let action: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Text(String(initial.prefix(1)))
                .font(Theme.font(18, .heavy, condensed: true))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(color, in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(name).font(Theme.font(16, .bold)).foregroundStyle(Theme.ink)
                    if let tag { PlanTag(text: tag) }
                }
                Text(detail).font(Theme.font(13)).foregroundStyle(Theme.ink2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 4)
            button
        }
        .padding(10)
        .background(Color(hex: "#f7f4fb"), in: RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder private var button: some View {
        let b = PlanSmallButton(title: price, disabled: disabled, sound: nil, action: action)
        if let spot { b.tutTarget(spot, disabled: disabled) } else { b }
    }
}
