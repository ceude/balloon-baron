import SwiftUI
import BalloonBaronCore

/// v114: the workshop's own page (`tabWorkshop`): its level and the next one, the production line, a rival's order, and
/// your designs (moved here from the fleet page).
struct WorkshopView: View {
    @Environment(GameStore.self) private var store
    @State private var studioOpen = false

    var body: some View {
        if let game = store.game {
            let s = game.state
            FleetUI.PageFrame(title: loc("town.b.workshop"), cash: s.cash, close: { store.closePage() }) {
                if s.workshopDay == nil {
                    foundCard(s)
                } else {
                    levelCard(s)
                    if s.factoryLevel >= 2 { lineCard(s) }
                    designsCard(game)
                }
            }
            .sheet(isPresented: $studioOpen) {
                DesignStudioView().environment(store)
            }
        }
    }

    private func foundCard(_ s: GameState) -> some View {
        FleetUI.Card(loc("fleetPage.workshop")) {
            FleetUI.Item {
                FleetUI.Title(loc("fleetPage.workshopBuild"))
                FleetUI.Detail(loc("fleetPage.workshopDesc"))
                FleetUI.SmallButton(title: eur(Studio.workshopCost), disabled: s.cash < Studio.workshopCost) {
                    store.act { _ = $0.buildWorkshop() }
                    store.showNextHezarfen()
                }
            }
        }
    }

    // MARK: Levels

    private func levelCard(_ s: GameState) -> some View {
        let lv = s.factoryLevel
        return FleetUI.Card(loc("factory.levelHead", num(lv), Factory.levelTitle(lv))) {
            HStack(spacing: 6) {
                ForEach(1...4, id: \.self) { i in
                    VStack(spacing: 0) {
                        Text(num(i)).font(Theme.font(20, .heavy, condensed: true))
                        Text(i == 1 ? loc("factory.step.design") : BalloonSize.shop[i - 2].title)
                            .font(Theme.font(11)).lineLimit(1).minimumScaleFactor(0.7)
                    }
                    .foregroundStyle(i <= lv ? Color.white : Theme.ink2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(i <= lv ? Theme.ink : Color(hex: "#efe9f6"), in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(loc("factory.levelHead", num(lv), Factory.levelTitle(lv)))
            if let cost = s.factoryNextCost {
                let z = BalloonSize.shop[lv - 1]
                FleetUI.Item {
                    FleetUI.Title(loc("factory.next", num(lv + 1), Factory.levelTitle(lv + 1)))
                    FleetUI.Detail(loc(lv == 1 ? "factory.nextFirst" : "factory.nextMore", z.title, percent(Rules.factoryDiscount), num(Rules.factoryDays(z))))
                    FleetUI.SmallButton(title: eur(cost), disabled: s.cash < cost) {
                        SoundEngine.shared.play(.coin)
                        store.act { _ = $0.upgradeFactory() }
                    }
                }
            } else {
                FleetUI.Hint(loc("factory.top"))
            }
        }
    }

    // MARK: Production

    private func lineCard(_ s: GameState) -> some View {
        FleetUI.Card(loc("factory.line")) {
            if let j = s.factory?.job {
                let left = max(0, j.done - s.day), all = Rules.factoryDays(j.size)
                FleetUI.Item(highlight: true) {
                    HStack(alignment: .center, spacing: 12) {
                        DesignBalloon(colors: j.rival == nil ? s.colors : ["#cfc8dd", "#ffffff"]).frame(width: 38, height: 48)
                        VStack(alignment: .leading, spacing: 4) {
                            FleetUI.Title(j.rival.map { loc("factory.jobFor", j.size.title, $0) } ?? j.size.title)
                            FleetUI.Detail((left > 0 ? loc("factory.daysLeft", num(left)) : loc("factory.tonight")) + " "
                                           + (j.rival == nil ? loc("factory.joinsFleet") : loc("factory.paysOnDelivery", eur(j.price))))
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color(hex: "#eadff2"))
                                    Capsule().fill(Theme.coral).frame(width: geo.size.width * CGFloat(1 - Double(left) / Double(all)))
                                }
                            }
                            .frame(height: 8)
                        }
                    }
                }
            } else {
                FleetUI.Hint(loc("factory.idle"))
            }
            ForEach(s.factorySizes, id: \.self) { z in
                FleetUI.Item {
                    HStack(alignment: .center, spacing: 12) {
                        DesignBalloon(colors: s.colors).frame(width: 38, height: 48)
                        VStack(alignment: .leading, spacing: 3) {
                            FleetUI.Title(loc("factory.sizeLine", z.title, num(z.capacity)))
                            HStack(spacing: 4) {
                                Text(eur(z.cost)).strikethrough().foregroundStyle(Theme.ink2)
                                Text("→ " + eur(s.factoryCost(z))).bold()
                                Text("· " + loc("factory.days", num(Rules.factoryDays(z))))
                            }
                            .font(Theme.font(13)).foregroundStyle(Theme.ink)
                        }
                        Spacer(minLength: 4)
                        FleetUI.SmallButton(title: loc("factory.build"), disabled: s.factoryBusy || s.cash < s.factoryCost(z)) {
                            SoundEngine.shared.play(.coin)
                            store.act { _ = $0.buildBalloon(z) }
                        }
                        .frame(width: 96)
                    }
                }
            }
            if let o = s.factory?.order, o.until >= s.day {
                FleetUI.Item(highlight: true) {
                    FleetUI.Title(loc("factory.orderRow", o.rival, o.size.title))
                    FleetUI.Detail(loc("factory.orderDetail", eur(o.price), eur(s.factoryCost(o.size)), eur(o.price - s.factoryCost(o.size)),
                                       num(Rules.factoryDays(o.size)), o.rival))
                    HStack(spacing: 8) {
                        FleetUI.SmallButton(title: loc("factory.accept"), disabled: s.factoryBusy) {
                            SoundEngine.shared.play(.coin)
                            store.act { _ = $0.acceptFactoryOrder() }
                        }
                        FleetUI.SmallButton(title: loc("factory.decline"), ghost: true) {
                            store.act { $0.declineFactoryOrder() }
                        }
                    }
                }
            }
            if let f = s.factory, f.built + f.orders > 0 {
                FleetUI.Hint(loc("factory.tally", num(f.built), num(f.orders), eur(f.saved), eur(f.earned)))
            }
        }
    }

    // MARK: Designs

    private func designsCard(_ game: Game) -> some View {
        let s = game.state
        return FleetUI.Card(loc("factory.designs")) {
            if s.designs.isEmpty {
                FleetUI.Hint(loc("fleetPage.noDesigns"))
                // v114.1: three grey samples above the button, so it's clear what a design is before the first one
                HStack(spacing: 8) {
                    ForEach([Pattern.stars, .zigzag, .sunburst], id: \.self) { p in
                        VStack(spacing: 4) {
                            DesignBalloon(pattern: p, colors: [s.colors.first ?? "#ff5e3a", s.colors.count > 1 ? s.colors[1] : "#ffc23d", "#ffffff"])
                                .frame(width: 44, height: 56)
                                .saturation(0)
                                .opacity(0.55)
                            Text(loc("factory.sample", p.title)).font(Theme.font(11)).foregroundStyle(Theme.ink2).lineLimit(1).minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                        .background(Color(hex: "#efecf3"), in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color(hex: "#cfc8dd"), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])))
                    }
                }
                .accessibilityHidden(true)
            }
            ForEach(s.designs) { d in
                let fresh = game.freshness(d), faded = Int((fresh * 100).rounded()) <= 20
                let count = s.balloons.filter { $0.design == d.id }.count
                FleetUI.Item {
                    HStack(spacing: 12) {
                        DesignBalloon(colors: d.colors, design: d).frame(width: 44, height: 56)
                        VStack(alignment: .leading, spacing: 3) {
                            FleetUI.Title(d.title)
                            FleetUI.Detail(loc(faded ? "fleetPage.designLineFaded" : "fleetPage.designLine", num(d.score), percent(fresh), num(count)))
                        }
                    }
                }
            }
            BigButton(title: loc("fleetPage.newDesign")) { studioOpen = true }
        }
    }
}

/// v114: a rival's order in the morning (`showOrder`): what they pay, what it costs you, and that the rival grows.
struct FactoryOrderView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        ModalCard {
            if let s = store.state, let o = s.factory?.order {
                let cost = s.factoryCost(o.size)
                Text(loc("town.b.workshop")).font(Theme.font(14, .heavy, condensed: true)).tracking(0.8).textCase(.uppercase).foregroundStyle(Theme.coral)
                CardText.title(loc("factory.orderTitle", o.rival))
                CardText.lead(loc("factory.orderLead", o.rival, o.size.title))
                Grid(alignment: .leading, verticalSpacing: 4) {
                    GridRow { Text(loc("factory.theyPay")); Text(eur(o.price)).bold().gridColumnAlignment(.trailing) }
                    GridRow { Text(loc("factory.yourCost")); Text(eur(cost)).bold() }
                    Divider().gridCellUnsizedAxes(.horizontal)
                    GridRow { Text(loc("factory.profit")).bold(); Text(eur(o.price - cost)).font(Theme.font(15, .heavy)) }
                }
                .font(Theme.font(14)).foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Theme.sun.opacity(0.2), in: RoundedRectangle(cornerRadius: 14))
                Text(loc("factory.orderNote", num(Rules.factoryDays(o.size)), o.rival))
                    .font(Theme.font(12.5)).foregroundStyle(Theme.ink2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                Button(loc("factory.acceptOrder")) {
                    SoundEngine.shared.play(.coin)
                    store.answerFactoryOrder(true)
                }
                .buttonStyle(ChunkyButtonStyle(kind: .big, wide: true))
                Button {
                    SoundEngine.shared.play(.click)
                    store.answerFactoryOrder(false)
                } label: { Text(loc("factory.decline")).frame(maxWidth: .infinity) }
                .buttonStyle(ChunkyButtonStyle(kind: .ghost, wide: true))
            }
        }
    }
}
