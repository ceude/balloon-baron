import SwiftUI
import BalloonBaronCore

// Building upgrades, the bazaar and its purchase sheet (prototype v77–v85).

/// A building's card: the levels it has, the next one, and the way into its page. Port of `buildingCard`.
struct BuildingCardView: View {
    @Environment(GameStore.self) private var store
    let building: Building

    var body: some View {
        let s = store.state
        let n = s?.level(building) ?? 1
        let cost = building.upgradeCost(from: n)
        return ModalCard(onClose: { store.closeBuildingCard() }) {
            Text(loc("building.level", num(n), num(Building.maxLevel)))
                .font(Theme.font(14, .heavy, condensed: true)).tracking(0.8).textCase(.uppercase).foregroundStyle(Theme.coral)
            CardText.title(building.title)
            ForEach(Array(2...Building.maxLevel), id: \.self) { lv in
                if lv <= n { levelRow(lv, built: true) }
            }
            if building == .mast && n >= 2, let fc = s?.local.forecast, let day = s?.day {
                forecastBox(fc, day: day, count: n - 1)
            }
            if let cost {
                levelRow(n + 1, built: false)
                Button(loc("building.upgrade", eur(cost))) {
                    SoundEngine.shared.play(.coin)
                    store.act { _ = $0.upgrade(building); _ = $0.forecast() }
                }
                .buttonStyle(ChunkyButtonStyle(kind: .big))
                .disabled((s?.cash ?? 0) < cost)
            } else {
                CardText.hint(loc("building.top"))
            }
            if let d = destination {
                ghost(d.0) {
                    store.buildingCard = nil
                    store.pageSection = d.2
                    store.page = d.1
                }
            }
            ghost(loc("world.close")) { store.closeBuildingCard() }
        }
    }

    /// The page each building leads to.
    private var destination: (String, Page, PageSection?)? {
        switch building {
        case .hangar: (loc("building.toFleet"), .fleet, nil)
        case .office: (loc("building.toCrew"), .crew, nil)
        case .sales: (loc("building.toMarket"), .market, .rivals)
        case .mast: nil
        }
    }

    private func levelRow(_ lv: Int, built: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text((built ? "✓ " : "") + building.levelTitle(lv)).font(Theme.font(15, .bold)).foregroundStyle(built ? Theme.green : Theme.ink)
            Text(building.levelDetail(lv)).font(Theme.font(13)).foregroundStyle(Theme.ink2).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(built ? Theme.green.opacity(0.1) : Color(hex: "#f1edf8"), in: RoundedRectangle(cornerRadius: 14))
    }

    /// Tomorrow's flag (and with the radar the day after's), read off the wind mast.
    private func forecastBox(_ fc: [Int: Flag], day: Int, count: Int) -> some View {
        HStack(spacing: 8) {
            ForEach(1...max(1, count), id: \.self) { d in
                let f = fc[day + d] ?? .green
                VStack(alignment: .leading, spacing: 3) {
                    Text(loc(d == 1 ? "forecast.tomorrow" : "forecast.dayAfter")).font(Theme.font(12)).foregroundStyle(Theme.ink2)
                    RoundedRectangle(cornerRadius: 3).fill(Theme.flagColor(f)).frame(width: 22, height: 14)
                    Text(f.title).font(Theme.font(17, .bold, condensed: true)).foregroundStyle(Theme.ink)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12).padding(.vertical, 10)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line, lineWidth: 2))
            }
        }
    }

    private func ghost(_ title: String, _ action: @escaping () -> Void) -> some View {
        Button {
            SoundEngine.shared.play(.click)
            action()
        } label: {
            Text(title).frame(maxWidth: .infinity)
        }
        .buttonStyle(ChunkyButtonStyle(kind: .ghost))
    }
}

/// The picture of a store item: a decoration on a patch of sand, or a pattern or shape on a balloon.
struct StoreThumb: View {
    let item: StoreItem
    let colors: [String]

    var body: some View {
        switch item.kind {
        case .pattern:
            DesignBalloon(pattern: item.pattern ?? .stripes, colors: [colors.first ?? "#ff5e3a", colors.count > 1 ? colors[1] : "#ffc23d", "#ffffff"])
        case .shape:
            DesignBalloon(pattern: .stripes, colors: [colors.first ?? "#ff5e3a", colors.count > 1 ? colors[1] : "#ffc23d", "#ffffff"], shape: item.shape)
        case .decoration:
            Canvas { ctx, size in
                let k = min(size.width / 64, size.height / 72)
                ctx.translateBy(x: (size.width - 64 * k) / 2, y: (size.height - 72 * k) / 2)
                ctx.scaleBy(x: k, y: k)
                ctx.fill(Path(ellipseIn: CGRect(x: 2, y: 47, width: 60, height: 22)), with: .color(Color(hex: "#ecd6b0")))
                StoreThumb.decoration(item, &ctx, colors: colors)
            }
        }
    }

    /// Small pictures of the four decorations (the town draws the big ones).
    static func decoration(_ k: StoreItem, _ ctx: inout GraphicsContext, colors: [String]) {
        func fill(_ p: Path, _ hex: String) { ctx.fill(p, with: .color(Color(hex: hex))) }
        func oval(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ hex: String) { fill(Path(ellipseIn: CGRect(x: x - rx, y: y - ry, width: rx * 2, height: ry * 2)), hex) }
        func box(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ hex: String) { fill(Path(CGRect(x: x, y: y, width: w, height: h)), hex) }
        switch k {
        case .fountain:
            oval(32, 56, 27, 13, "#d9c2a0"); box(5, 50, 54, 6, "#b89a74"); oval(32, 50, 27, 13, "#e8d6b6"); oval(32, 49, 22, 10, "#4ab8d0")
            box(29, 33, 6, 17, "#d9c2a0"); oval(32, 33, 10, 4, "#d9c2a0")
            var jets = Path()
            for i in 0..<6 {
                let a = Double(i) / 6 * Double.pi * 2 + 1, ex = 32 + CGFloat(cos(a)) * 18, ey = 49 + CGFloat(sin(a)) * 7
                jets.move(to: CGPoint(x: 32, y: 30)); jets.addQuadCurve(to: CGPoint(x: ex, y: ey), control: CGPoint(x: (32 + ex) / 2, y: 22))
            }
            ctx.stroke(jets, with: .color(Color(red: 200 / 255, green: 240 / 255, blue: 1).opacity(0.85)), lineWidth: 1.3)
        case .statue:
            box(21, 38, 22, 24, "#c8b090"); box(34, 38, 9, 24, "#a8906e")
            box(28.5, 14, 7, 24, "#8a6a3a"); oval(32, 10, 5, 5, "#8a6a3a"); oval(32, 5, 5.5, 3.3, "#f2eee6")
            for sg: CGFloat in [-1, 1] {
                var w = Path(); w.move(to: CGPoint(x: 32, y: 18)); w.addLine(to: CGPoint(x: 32 + sg * 28, y: 5)); w.addLine(to: CGPoint(x: 32 + sg * 24, y: 22)); w.closeSubpath()
                fill(w, "#a07c44")
            }
        case .lanterns:
            for (x, y) in [(20.0, 66.0), (44, 60)] as [(CGFloat, CGFloat)] {
                box(x - 1.3, y - 34, 2.6, 34, "#3a2a20"); box(x - 5, y - 35, 10, 2, "#3a2a20")
                ctx.fill(Path(ellipseIn: CGRect(x: x - 14, y: y - 53, width: 28, height: 28)), with: .radialGradient(
                    Gradient(colors: [Color(red: 1, green: 190 / 255, blue: 90 / 255).opacity(0.45), .clear]), center: CGPoint(x: x, y: y - 39), startRadius: 0, endRadius: 14))
                oval(x, y - 39, 3.4, 5, "#ffcf6a"); box(x - 3.4, y - 45, 6.8, 2, "#b8582e")
            }
        case .flags:
            for (x, y) in [(14.0, 66.0), (40, 60)] as [(CGFloat, CGFloat)] {
                var pole = Path(); pole.move(to: CGPoint(x: x, y: y)); pole.addLine(to: CGPoint(x: x, y: y - 56))
                ctx.stroke(pole, with: .color(Color(hex: "#4a3a2a")), lineWidth: 1.6)
                box(x, y - 56, 20, 13, colors.first ?? "#ff5e3a")
                box(x + 6, y - 52, 8, 4, colors.count > 1 ? colors[1] : "#ffc23d")
            }
        default: break
        }
    }
}

/// The bazaar: everything sold for real money, in one place. Port of `showBazaar`.
struct BazaarView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        let s = store.state
        return ModalCard(onClose: { store.closeBazaar() }) {
            CardText.title(loc("bazaar.title"))
            CardText.lead(loc("bazaar.lead"))
            if let s {
                section(.decoration, "bazaar.decor", s)
                section(.shape, "bazaar.shapes", s)
                section(.pattern, "bazaar.patterns", s)
            }
            CardText.hint(loc("bazaar.localPrices"))
            Button {
                SoundEngine.shared.play(.click)
                Task { await Shop.shared.restore() }
            } label: {
                Text(loc("store.restore")).frame(maxWidth: .infinity)
            }
            .buttonStyle(ChunkyButtonStyle(kind: .ghost))
            Button(loc("world.close")) {
                SoundEngine.shared.play(.click)
                store.closeBazaar()
            }
            .buttonStyle(ChunkyButtonStyle(kind: .big))
        }
    }

    @MainActor private func section(_ kind: StoreItem.Kind, _ key: String, _ s: GameState) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(loc(key)).font(Theme.font(13, .bold)).foregroundStyle(Theme.ink2)
            CardText.hint(loc(key + ".hint"))
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], spacing: 8) {
                ForEach(StoreItem.allCases.filter { $0.kind == kind }, id: \.self) { k in
                    let own = s.owned(k)
                    Button {
                        SoundEngine.shared.play(.click)
                        store.storeItem = k
                    } label: {
                        VStack(spacing: 2) {
                            StoreThumb(item: k, colors: s.colors).frame(width: 60, height: 68).accessibilityHidden(true)
                            Text(k.title).font(Theme.font(14, .bold, condensed: true)).foregroundStyle(Theme.ink)
                                .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.8)
                            Text(own ? loc("bazaar.yours") : k.gift ? loc("bazaar.gift") : Shop.shared.price(k))
                                .font(Theme.font(13, .heavy)).foregroundStyle(.white)
                                .padding(.horizontal, 9).padding(.vertical, 2)
                                .background(own ? Theme.green : k.gift ? Theme.coral : Theme.ink, in: Capsule())
                                .padding(.top, 3)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 6).padding(.vertical, 8)
                        .background(LinearGradient(colors: [Color(hex: "#fff6e6"), Color(hex: "#f3e2c4")], startPoint: .top, endPoint: .bottom),
                                    in: RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: k.gift && !own ? "#ff9a7a" : "#e6cfa6"), lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    .disabled(own)
                }
            }
        }
    }
}

extension StoreItem {
    /// Shown until the App Store's localized price is loaded: tier 1 €0,99, tier 2 €1,99.
    static func price(_ k: StoreItem) -> String {
        (k.tier == 2 ? 1.99 : 0.99).formatted(.currency(code: "EUR"))
    }
}

/// The purchase card for one item; Buy opens the App Store's own sheet (`Shop`).
struct StoreItemView: View {
    @Environment(GameStore.self) private var store
    let item: StoreItem
    @MainActor private var shop: Shop { Shop.shared }

    var body: some View {
        let s = store.state
        return ModalCard(onClose: { store.storeItem = nil }) {
            Text(loc("store.tag")).font(Theme.font(14, .heavy, condensed: true)).tracking(0.8).textCase(.uppercase).foregroundStyle(Theme.coral)
            CardText.title(item.title)
            if item.kind == .decoration, let s {
                Text(loc("store.nightPreview")).font(Theme.font(13, .bold)).foregroundStyle(Theme.ink2)
                DecorNightPreview(item: item, state: s)
            } else {
                StoreThumb(item: item, colors: s?.colors ?? [])
                    .accessibilityHidden(true)
                    .frame(width: 96, height: 108)
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(LinearGradient(colors: [Color(hex: "#bfe0f2"), Color(hex: "#ffe6c4")], startPoint: .top, endPoint: .bottom),
                                in: RoundedRectangle(cornerRadius: 16))
            }
            CardText.lead(loc(item.kind == .decoration ? "store.lead.decor" : item.kind == .shape ? "store.lead.shape" : "store.lead.pattern"))
            if item.gift { CardText.hint(loc("store.giftNote")) }
            if let note = shop.note { CardText.hint(note) }
            Button(item.gift ? loc("store.takeGift") : shop.buying == item ? loc("store.buying") : loc("store.buy", shop.price(item))) {
                if item.gift {
                    store.takeGift(item)
                } else {
                    SoundEngine.shared.play(.click)
                    Task { _ = await shop.buy(item) }
                }
            }
            .buttonStyle(ChunkyButtonStyle(kind: .big))
            .disabled(shop.buying != nil)
            Button {
                SoundEngine.shared.play(.click)
                store.storeItem = nil
            } label: {
                Text(loc("store.cancel")).frame(maxWidth: .infinity)
            }
            .buttonStyle(ChunkyButtonStyle(kind: .ghost))
        }
        .onAppear { shop.note = nil }
    }
}

/// `nightPreview`: a live picture of your town at night with this decoration, for the purchase card.
struct DecorNightPreview: View {
    let item: StoreItem
    let state: GameState
    @State private var start = Date()

    /// Where the camera looks for each decoration, and how close (`DECOR_AT`).
    private var spot: (Double, Double, CGFloat) {
        switch item {
        case .statue: (6.9, 8.9, 0.6)
        case .lanterns: (7.4, 7.6, 0.3)
        case .flags: (7.5, 9, 0.26)
        default: (8, 8, 0.55)
        }
    }

    var body: some View {
        var s = state
        s.store = (s.store ?? [:]).merging([item: s.day]) { old, _ in old }
        return TimelineView(.animation) { tl in
            Canvas { ctx, sz in
                let (gx, gy, z) = spot, c = TownGeo.iso(gx, gy)
                var v = TownViewport(z: z, ox: sz.width / 2 - c.x * z, oy: sz.height * 0.62 - c.y * z)
                v.noLabels = true
                v.hzFix = sz.height * 0.12
                var g = ctx
                _ = TownPainter.render(&g, state: s, time: 1000 + tl.date.timeIntervalSince(start), viewport: v, size: sz,
                                       night: TownNight(k: 1, event: nil, t0: 1000))
            }
        }
        .frame(height: 220)
        .background(Color(hex: "#1b1840"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityHidden(true)
    }
}
