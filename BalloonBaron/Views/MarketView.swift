import SwiftUI
import BalloonBaronCore

/// One slice of yesterday's market share bar.
private struct ShareSlice: Identifiable {
    let id: Int
    let pax: Int
    let color: String
    let name: String
}

/// Market page (`tabMarket`): today's numbers, yesterday's share, you and your rivals,
/// rival deals, hotels and marketing.
struct MarketView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        if let game = store.game {
            FleetUI.PageFrame(title: loc("marketPage.title"), cash: game.state.cash, close: { store.closePage() }) {
                todayCard(game)
                shareCard(game.state)
                companiesCard(game.state)
                    .id(PageSection.rivals)
                hotelsCard(game)
                    .id(PageSection.hotels)
                marketingCard(game.state)
            }
        }
    }

    // MARK: Today

    private func todayCard(_ game: Game) -> some View {
        let s = game.state
        let rivalSeats = s.rivals.filter(\.alive).reduce(0) { acc, r in
            acc + r.flyToday.reduce(0) { $0 + (r.balloons.indices.contains($1) ? r.balloons[$1].capacity : 0) }
        }
        return FleetUI.Card(loc("marketPage.today")) {
            HStack(spacing: 6) {
                bigStat(loc("home.tourists"), num(game.touristsToday()))
                bigStat(loc("home.seats"), num(s.capacityToday))
                bigStat(loc("home.rivalSeats"), num(rivalSeats))
            }
        }
    }

    private func bigStat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(Theme.font(26, .heavy, condensed: true)).foregroundStyle(Theme.ink)
            Text(label).font(Theme.font(12, .semibold)).foregroundStyle(Theme.ink2).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Yesterday's share

    private func total(_ ls: MarketShare) -> Int { ls.me + ls.rivals.reduce(0, +) }

    /// Share of yesterday's passengers; nil before the first day or when nobody flew.
    private func share(_ n: Int, _ s: GameState) -> Double? {
        guard let ls = s.lastShare else { return nil }
        let t = total(ls)
        return t > 0 ? Double(n) / Double(t) : nil
    }

    private func slices(_ ls: MarketShare, _ s: GameState) -> [ShareSlice] {
        var out = [ShareSlice(id: -1, pax: ls.me, color: s.colors.first ?? "#ff5e3a", name: s.company)]
        for (i, r) in s.rivals.enumerated() {
            let n = i < ls.rivals.count ? ls.rivals[i] : 0
            if r.alive || n > 0 { out.append(ShareSlice(id: i, pax: n, color: r.colors.first ?? "#7a7f8c", name: r.name)) }
        }
        return out
    }

    private func shareCard(_ s: GameState) -> some View {
        FleetUI.Card(loc("marketPage.yesterday")) {
            if let ls = s.lastShare {
                let parts = slices(ls, s)
                let t = max(1, total(ls))
                shareBar(parts, total: t)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], alignment: .leading, spacing: 6) {
                    ForEach(parts) { p in
                        legend(p, total: t)
                    }
                }
                FleetUI.Hint(ls.extra > 0
                             ? loc("marketPage.yesterdayExtra", num(ls.demand + ls.extra), num(ls.extra), num(total(ls)))
                             : loc("marketPage.yesterdayPlain", num(ls.demand), num(total(ls))))
            } else {
                FleetUI.Hint(loc("marketPage.noShareYet"))
            }
        }
    }

    private func shareBar(_ parts: [ShareSlice], total: Int) -> some View {
        GeometryReader { g in
            HStack(spacing: 0) {
                ForEach(parts) { p in
                    Rectangle()
                        .fill(Color(hex: p.color))
                        .frame(width: g.size.width * CGFloat(p.pax) / CGFloat(total))
                }
                Spacer(minLength: 0)
            }
        }
        .frame(height: 16)
        .background(Theme.line)
        .clipShape(Capsule())
    }

    private func legend(_ p: ShareSlice, total: Int) -> some View {
        HStack(spacing: 6) {
            Circle().fill(Color(hex: p.color)).frame(width: 10, height: 10)
            Text(p.name)
                .font(Theme.font(13))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
            Text(percent(Double(p.pax) / Double(total)))
                .font(Theme.font(13, .bold))
                .foregroundStyle(Theme.ink)
        }
    }

    // MARK: You and your rivals

    private func companiesCard(_ s: GameState) -> some View {
        FleetUI.Card(loc("marketPage.youAndRivals")) {
            myCard(s)
            ForEach(s.rivals.indices, id: \.self) { i in
                rivalCard(i, s)
            }
            FleetUI.Hint(loc("marketPage.rivalsHint"))
            FleetUI.SmallButton(title: loc("marketPage.rivalTips"), ghost: true) {
                store.act { $0.replayRivalTips() }
                store.closePage()
            }
        }
    }

    private func statBox(_ value: String, _ label: String) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(Theme.font(17, .heavy, condensed: true))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(Theme.font(11))
                .foregroundStyle(Theme.ink2)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
        .padding(.horizontal, 4)
        .background(Theme.line.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))
    }

    private func stats(balloons: Int, price: Int, rep: Double, load: String) -> some View {
        HStack(spacing: 4) {
            statBox(num(balloons), loc("marketPage.stat.balloons"))
            statBox(eur(price), loc("marketPage.stat.price"))
            statBox(starsText(rep), loc("marketPage.stat.popularity"))
            statBox(load, loc("marketPage.stat.load"))
        }
    }

    private func shareTag(_ n: Int, _ s: GameState) -> some View {
        Group {
            if let sh = share(n, s) {
                FleetUI.Tag(text: loc("marketPage.share", percent(sh)))
            }
        }
    }

    private func myCard(_ s: GameState) -> some View {
        let ls = s.lastShare
        let load: String = ls.map { $0.cap > 0 ? percent(Double($0.me) / Double($0.cap)) : "–" } ?? "–"
        return FleetUI.Item(highlight: true) {
            HStack(alignment: .top, spacing: 12) {
                DesignBalloon(colors: s.colors)
                    .frame(width: 38, height: 48)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        FleetUI.Title(s.company)
                        FleetUI.Tag(text: loc("marketPage.you"), color: Theme.green)
                        shareTag(ls?.me ?? 0, s)
                    }
                    FleetUI.Detail(loc("marketPage.basedOnYesterday"))
                }
            }
            stats(balloons: s.balloons.count, price: s.price, rep: s.rep, load: load)
        }
    }

    private func rivalCard(_ i: Int, _ s: GameState) -> some View {
        let r = s.rivals[i]
        return VStack(spacing: 8) {
            FleetUI.Item {
                HStack(alignment: .top, spacing: 12) {
                    DesignBalloon(colors: r.colors)
                        .frame(width: 38, height: 48)
                        .opacity(r.alive ? 1 : 0.5)
                    VStack(alignment: .leading, spacing: 4) {
                        rivalHeader(i, r, s)
                        rivalDetail(r)
                    }
                }
                if r.alive {
                    stats(balloons: r.balloons.count, price: r.price, rep: r.rep,
                          load: r.lastCap > 0 ? percent(Double(r.lastPax) / Double(r.lastCap)) : "–")
                }
            }
            if r.alive, let offer = r.offer {
                callout(loc("marketPage.offerBody", r.name, eur(offer), num(r.balloons.count)), color: Theme.yellow) {
                    FleetUI.SmallButton(title: loc("marketPage.takeOver", eur(offer)), disabled: s.cash < offer) {
                        store.act { _ = $0.takeOver(i) }
                    }
                }
            }
            if let sale = r.forSale {
                let sizes = sale.sizes.map(\.title).joined(separator: ", ")
                callout(loc("marketPage.saleBody", r.name, sizes), color: Theme.green) {
                    FleetUI.SmallButton(title: loc("marketPage.buy", eur(sale.price)), disabled: s.cash < sale.price) {
                        store.act { _ = $0.buyBankruptFleet(i) }
                    }
                }
            }
        }
    }

    /// Rival's passengers yesterday.
    private func rivalPax(_ i: Int, _ s: GameState) -> Int {
        guard let ls = s.lastShare, i < ls.rivals.count else { return 0 }
        return ls.rivals[i]
    }

    private func rivalHeader(_ i: Int, _ r: Rival, _ s: GameState) -> some View {
        HStack(spacing: 6) {
            FleetUI.Title(r.name)
            if r.alive {
                shareTag(rivalPax(i, s), s)
                if r.offer != nil {
                    FleetUI.Tag(text: loc("marketPage.struggling"), color: Theme.yellow)
                }
            } else if r.mergedInto != nil {
                FleetUI.Tag(text: loc("marketPage.merged"), color: Theme.yellow)
            } else {
                FleetUI.Tag(text: loc("marketPage.bankrupt"), color: Theme.red)
            }
        }
    }

    private func rivalDetail(_ r: Rival) -> some View {
        let text: String
        if r.alive {
            text = loc("marketPage.style.\(r.style.rawValue)")
        } else if let m = r.mergedInto {
            text = loc("marketPage.mergedInto", m)
        } else {
            text = loc(r.forSale != nil ? "marketPage.fleetForSale" : "marketPage.fleetSold")
        }
        return FleetUI.Detail(text)
    }

    private func callout<B: View>(_ text: String, color: Color, @ViewBuilder button: () -> B) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            FleetUI.Detail(text, color: Theme.ink)
            button()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(color, lineWidth: 1.5))
    }

    // MARK: Hotels

    private func hotelsCard(_ game: Game) -> some View {
        FleetUI.Card(loc("marketPage.hotels")) {
            FleetUI.Hint(loc("marketPage.hotelsHint"))
            ForEach(Hotel.allCases, id: \.self) { h in
                hotelRow(h, game)
            }
            FleetUI.Hint(loc("marketPage.hotelsFootnote"))
        }
    }

    /// "0.03★": hotel popularity per day, two decimals.
    private func starsPerDay(_ rep: Double) -> String {
        rep.formatted(.number.precision(.fractionLength(2))) + "★"
    }

    private func hotelBody(_ h: Hotel, own: Bool, _ s: GameState) -> String {
        guard own else {
            return loc("marketPage.hotelBody", starsValue(h.minStars), eur(h.dailyFee), num(h.guests),
                       starsPerDay(h.repPerDay * 4), eur(Int(h.priceCenter)))
        }
        var t = loc("marketPage.hotelOwnBody", eur(s.hotelIncome(h)), num(Int((Double(h.guests) * 1.5).rounded())),
                    starsPerDay(h.repPerDay * 6))
        if s.stars < h.minStars { t += " " + loc("marketPage.hotelHalf") }
        if s.winter != nil { t += " " + loc("marketPage.hotelWinter") }
        return t
    }

    private func hotelIcon(_ h: Hotel) -> some View {
        let n = max(1, Int(h.minStars.rounded()) - 1)
        return Text(String(repeating: "★", count: n))
            .font(.system(size: n > 2 ? 9 : 12, weight: .bold))
            .foregroundStyle(Theme.sun)
            .frame(width: 40, height: 40)
            .background(Theme.ink, in: RoundedRectangle(cornerRadius: 10))
    }

    private func hotelRow(_ h: Hotel, _ game: Game) -> some View {
        let s = game.state
        let own = s.ownHotels.contains(h)
        let has = s.hotelDeals.contains(h)
        let lock = game.hotelLockedByRival(h)
        let ok = s.stars >= h.minStars && lock == nil
        return FleetUI.Item {
            HStack(alignment: .top, spacing: 12) {
                hotelIcon(h)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        FleetUI.Title(h.title)
                        if own {
                            FleetUI.Tag(text: loc("marketPage.hotelOwnTag"), color: Theme.green)
                        } else if has {
                            FleetUI.Tag(text: loc("marketPage.hotelDealTag"), color: Theme.green)
                        }
                    }
                    if let lock {
                        Text(loc("marketPage.hotelLocked", lock.rival, num(lock.until - s.day)))
                            .font(Theme.font(14, .bold))
                            .foregroundStyle(Theme.red)
                    }
                    FleetUI.Detail(hotelBody(h, own: own, s))
                }
            }
            if !own {
                hotelActions(h, has: has, ok: ok, s)
            }
        }
        .opacity(!ok && !has && !own ? 0.7 : 1)
    }

    private func hotelActions(_ h: Hotel, has: Bool, ok: Bool, _ s: GameState) -> some View {
        let fee = h.dailyFee * 3
        return FleetUI.ButtonGrid {
            if has {
                FleetUI.SmallButton(title: loc("marketPage.endDeal"), ghost: true) {
                    store.act { $0.endHotelDeal(h) }
                }
            } else if ok {
                FleetUI.SmallButton(title: loc("marketPage.sign", eur(fee)), note: loc("marketPage.signNote"), ghost: true,
                                    disabled: s.cash < fee) {
                    store.act { _ = $0.signHotel(h) }
                }
            } else {
                FleetUI.SmallButton(title: loc("fleetPage.locked"), ghost: true, disabled: true) {}
            }
            FleetUI.SmallButton(title: loc("marketPage.buy", eur(h.buyPrice)), note: loc("marketPage.buyNote", eur(h.roomIncome)),
                                disabled: s.stars < h.minStars || s.cash < h.buyPrice) {
                store.act { _ = $0.buyHotel(h) }
            }
        }
    }

    // MARK: Marketing

    private func marketingCard(_ s: GameState) -> some View {
        let ads = s.balloons.filter { $0.ad != nil }.count
        let icd = s.influencerCooldown - s.day
        let gcd = s.guideCooldown - s.day
        let influText = icd > 0 ? loc("marketPage.wait", num(icd))
            : s.day <= s.influencerUntil ? loc("marketPage.running") : loc("marketPage.influencerBody")
        let guideText = gcd > 0 ? loc("marketPage.wait", num(gcd)) : loc("marketPage.guideBody")
        return FleetUI.Card(loc("marketPage.marketing")) {
            if ads > 0 {
                marketingRow(loc("marketPage.removeAds"), loc("marketPage.removeAdsBody", num(ads)), button: loc("marketPage.remove"),
                             disabled: false) {
                    store.act { $0.removeAllAds() }
                }
            }
            marketingRow(loc("marketPage.influencer"), influText, button: eur(s.influencerCost),
                         disabled: icd > 0 || s.cash < s.influencerCost) {
                store.act { _ = $0.runInfluencer() }
            }
            marketingRow(loc("marketPage.guide"), guideText, button: eur(Rules.guideCost),
                         disabled: gcd > 0 || s.cash < Rules.guideCost) {
                store.act { _ = $0.runGuideFlight() }
            }
        }
    }

    private func marketingRow(_ title: String, _ detail: String, button: String, disabled: Bool,
                              action: @escaping () -> Void) -> some View {
        FleetUI.Item {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    FleetUI.Title(title)
                    FleetUI.Detail(detail)
                }
                Spacer(minLength: 4)
                FleetUI.SmallButton(title: button, disabled: disabled, action: action)
                    .frame(width: 110)
            }
        }
    }
}
