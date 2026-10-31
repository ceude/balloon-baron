import SwiftUI
import BalloonBaronCore

// Building upgrades, the bazaar and its purchase sheet (prototype v77–v85).

/// v127: a purchase left balloons outside the full hangar (prototype `hangarFullCard`): how many, why it matters, and the
/// way to the hangar's upgrade.
struct HangarFullView: View {
    @Environment(GameStore.self) private var store
    let outside: Int

    var body: some View {
        ModalCard(onClose: { store.closeHangarFull(upgrade: false) }) {
            CardText.title(loc("hangar.full.title"))
            CardText.lead(loc("hangar.full.body", num(outside)))
            CardText.hint(loc("hangar.full.hint"))
            BigButton(title: loc("hangar.upgrade")) { store.closeHangarFull(upgrade: true) }
            BigButton(title: loc("hangar.ok"), style: .ghost) { store.closeHangarFull(upgrade: false) }
        }
    }
}

/// A building's card: the levels it has, the next one, and the way into its page. Port of `buildingCard`.
struct BuildingCardView: View {
    @Environment(GameStore.self) private var store
    let building: Building

    var body: some View {
        let s = store.state
        let n = s?.level(building) ?? 1
        let cost = building.upgradeCost(from: n)
        return ModalCard(onClose: { store.closeBuildingCard() }) {
            Text(loc("building.level", num(n), num(building.maxLevel)))
                .font(Theme.font(14, .heavy, condensed: true)).tracking(0.8).textCase(.uppercase).foregroundStyle(Theme.coral)
            CardText.title(building.title)
            if building == .hangar, let s { capacityBox(s) }
            ForEach(Array(2...building.maxLevel), id: \.self) { lv in
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
                .tutSpot(d.1 == .fleet ? "ga.toFleet" : d.1 == .crew ? "ga.toCrew" : "ga.toMarket") // v122
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

    /// v127: the hangar's room now, and how many balloons stand outside.
    private func capacityBox(_ s: GameState) -> some View {
        let out = s.outsideCount, n = s.local.balloons.count
        return VStack(alignment: .leading, spacing: 2) {
            Text(loc("hangar.capacity", num(s.hangarCapacity))).font(Theme.font(15, .bold)).foregroundStyle(out > 0 ? Theme.red : Theme.green)
            Text(out > 0 ? loc("hangar.fleetOut", num(n), num(out)) : loc("hangar.fleet", num(n)))
                .font(Theme.font(13)).foregroundStyle(Theme.ink).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background((out > 0 ? Theme.red : Theme.green).opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
    }

    /// A level's line; the hangar's say its room first (levels 4 to 8 only add room).
    private func detail(_ lv: Int) -> String {
        guard building == .hangar else { return building.levelDetail(lv) }
        let cap = loc("hangar.capacity", num(Hangar.capacity[min(lv, Hangar.maxLevel)])) + "."
        return lv <= 3 ? cap + " " + building.levelDetail(lv) : cap
    }

    private func levelRow(_ lv: Int, built: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text((built ? "✓ " : "") + building.levelTitle(lv)).font(Theme.font(15, .bold)).foregroundStyle(built ? Theme.green : Theme.ink)
            Text(detail(lv)).font(Theme.font(13)).foregroundStyle(Theme.ink2).fixedSize(horizontal: false, vertical: true)
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
    var company = ""

    var body: some View {
        switch item.kind {
        case .figure:
            FigureThumb(item: item, colors: colors, company: company).clipShape(RoundedRectangle(cornerRadius: 10))
        case .unlock, .supporter:
            Canvas { ctx, size in
                let k = min(size.width / 64, size.height / 72)
                var c = ctx
                c.translateBy(x: (size.width - 64 * k) / 2, y: (size.height - 72 * k) / 2)
                c.scaleBy(x: k, y: k)
                if item.kind == .unlock { StoreThumb.worldTour(&c, colors: colors) } else { StoreThumb.plaque(&c, company: company) }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
        case .pack:
            // the pack's items in a little grid
            let items = item.packItems
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: items.count > 4 ? 3 : 2), spacing: 3) {
                ForEach(items, id: \.self) { q in StoreThumb(item: q, colors: colors, company: company).aspectRatio(64 / 72, contentMode: .fit) }
            }
        case .bundle:
            StoreThumb(item: .heart, colors: colors)
        case .pattern:
            DesignBalloon(pattern: item.pattern ?? .stripes, colors: [colors.first ?? "#ff5e3a", colors.count > 1 ? colors[1] : "#ffc23d", "#ffffff"])
        case .shape:
            DesignBalloon(pattern: .stripes, colors: [colors.first ?? "#ff5e3a", colors.count > 1 ? colors[1] : "#ffc23d", "#ffffff"], shape: item.shape)
        case .decoration where [.pigeons, .arch, .cafe, .rugs].contains(item):
            Canvas { ctx, size in
                let k = min(size.width / 64, size.height / 72)
                var c = ctx
                c.translateBy(x: (size.width - 64 * k) / 2, y: (size.height - 72 * k) / 2)
                c.scaleBy(x: k, y: k)
                if item != .pigeons { c.fill(Path(ellipseIn: CGRect(x: 2, y: 47, width: 60, height: 22)), with: .color(Color(hex: "#ecd6b0"))) }
                var g = c, d = DecorPainter(c: c)
                switch item {
                case .pigeons: d.dovecote()
                case .arch: g.translateBy(x: 32, y: 62); g.scaleBy(x: 0.62, y: 0.62); d = DecorPainter(c: g); d.arch(CGPoint(x: -40, y: -10), CGPoint(x: 40, y: 10), 1, colors, company.isEmpty ? "Balon" : company)
                case .cafe: g.translateBy(x: 32, y: 56); g.scaleBy(x: 0.32, y: 0.32); d = DecorPainter(c: g); d.cafe(.zero, 1)
                default: g.translateBy(x: 32, y: 60); g.scaleBy(x: 0.36, y: 0.36); d = DecorPainter(c: g); d.rugs(.zero, 1)
                }
            }
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

    /// v115, the Grand Tour: dawn over a desert mesa and a pyramid, your balloon on a dotted route between them (64 × 72).
    static func worldTour(_ c: inout GraphicsContext, colors: [String]) {
        func fill(_ pts: [CGPoint], _ hex: String) { var p = Path(); p.move(to: pts[0]); for q in pts.dropFirst() { p.addLine(to: q) }; p.closeSubpath(); c.fill(p, with: .color(Color(hex: hex))) }
        func box(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ hex: String) { c.fill(Path(CGRect(x: x, y: y, width: w, height: h)), with: .color(Color(hex: hex))) }
        c.fill(Path(CGRect(x: 0, y: 0, width: 64, height: 72)), with: .linearGradient(Gradient(stops: [.init(color: Color(hex: "#7fb2e0"), location: 0), .init(color: Color(hex: "#f6c98a"), location: 0.55), .init(color: Color(hex: "#e8b07a"), location: 1)]),
                                                                                    startPoint: .zero, endPoint: CGPoint(x: 0, y: 72)))
        c.fill(Path(ellipseIn: CGRect(x: 23, y: 37, width: 18, height: 18)), with: .color(Color(hex: "#fff4d0")))
        fill([CGPoint(x: 0, y: 60), CGPoint(x: 3, y: 44), CGPoint(x: 19, y: 44), CGPoint(x: 23, y: 60)], "#b5552e"); box(2, 43, 18, 2.5, "#8f3f22")
        fill([CGPoint(x: 40, y: 60), CGPoint(x: 53, y: 42), CGPoint(x: 66, y: 60)], "#c98a4a"); fill([CGPoint(x: 53, y: 42), CGPoint(x: 66, y: 60), CGPoint(x: 56, y: 60)], "#a86a34")
        box(0, 60, 64, 12, "#d9a46a"); box(38, 62, 26, 3, "#4aa0c0")
        var route = Path(); route.move(to: CGPoint(x: 11, y: 40)); route.addQuadCurve(to: CGPoint(x: 53, y: 38), control: CGPoint(x: 32, y: 2))
        c.stroke(route, with: .color(.white.opacity(0.9)), style: StrokeStyle(lineWidth: 1.1, dash: [1.5, 2.5]))
        c.fill(Path(ellipseIn: CGRect(x: 25, y: 5.5, width: 14, height: 17)), with: .color(Color(hex: colors.first ?? "#ff5e3a")))
        box(30.5, 5.5, 3, 17, colors.count > 1 ? colors[1] : "#ffc23d"); box(30, 24, 4, 3.5, "#6a4020")
    }

    /// v115, the supporter plaque: brass on dark wood, a heart and your company's name (64 × 72).
    static func plaque(_ c: inout GraphicsContext, company: String) {
        c.fill(Path(CGRect(x: 0, y: 0, width: 64, height: 72)), with: .linearGradient(Gradient(colors: [Color(hex: "#3b2a4f"), Color(hex: "#2b2350")]), startPoint: .zero, endPoint: CGPoint(x: 0, y: 72)))
        c.fill(Path(roundedRect: CGRect(x: 8, y: 14, width: 48, height: 40), cornerRadius: 5), with: .color(Color(hex: "#6a4024")))
        c.fill(Path(roundedRect: CGRect(x: 12, y: 18, width: 40, height: 32), cornerRadius: 3),
               with: .linearGradient(Gradient(colors: [Color(hex: "#ffe39a"), Color(hex: "#e8b04a"), Color(hex: "#b07a1e")]), startPoint: CGPoint(x: 0, y: 18), endPoint: CGPoint(x: 0, y: 50)))
        var heart = Path()
        heart.move(to: CGPoint(x: 32, y: 32))
        heart.addCurve(to: CGPoint(x: 32, y: 24.5), control1: CGPoint(x: 26, y: 27), control2: CGPoint(x: 27, y: 21))
        heart.addCurve(to: CGPoint(x: 32, y: 32), control1: CGPoint(x: 37, y: 21), control2: CGPoint(x: 38, y: 27))
        c.fill(heart, with: .color(Color(hex: "#c2401f")))
        c.draw(Text(loc("store.plaque")).font(.custom("BarlowCondensed-ExtraBold", fixedSize: 6)).foregroundColor(Color(hex: "#5a3a10")), at: CGPoint(x: 32, y: 39))
        c.draw(Text(company).font(.custom("Barlow-Bold", fixedSize: 5.5)).foregroundColor(Color(hex: "#5a3a10")), at: CGPoint(x: 32, y: 45.5))
    }

    /// Egypt: the Nile at dawn, a pyramid, an obelisk and a balloon in your colours over them (64 × 72 units).
    static func egypt(_ c: inout GraphicsContext, colors: [String]) {
        func fill(_ pts: [CGPoint], _ hex: String) { var p = Path(); p.move(to: pts[0]); for q in pts.dropFirst() { p.addLine(to: q) }; p.closeSubpath(); c.fill(p, with: .color(Color(hex: hex))) }
        func box(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ hex: String) { c.fill(Path(CGRect(x: x, y: y, width: w, height: h)), with: .color(Color(hex: hex))) }
        c.fill(Path(CGRect(x: 0, y: 0, width: 64, height: 72)), with: .linearGradient(Gradient(stops: [.init(color: Color(hex: "#f6c98a"), location: 0), .init(color: Color(hex: "#f3a96a"), location: 0.6), .init(color: Color(hex: "#e8c08a"), location: 1)]),
                                                                                    startPoint: .zero, endPoint: CGPoint(x: 0, y: 72)))
        c.fill(Path(ellipseIn: CGRect(x: 39, y: 23, width: 14, height: 14)), with: .color(Color(hex: "#fff4d0")))
        fill([CGPoint(x: 4, y: 52), CGPoint(x: 24, y: 30), CGPoint(x: 44, y: 52)], "#c98a4a")
        fill([CGPoint(x: 24, y: 30), CGPoint(x: 44, y: 52), CGPoint(x: 30, y: 52)], "#a86a34")
        fill([CGPoint(x: 50, y: 52), CGPoint(x: 52, y: 30), CGPoint(x: 53.5, y: 27), CGPoint(x: 55, y: 30), CGPoint(x: 57, y: 52)], "#b07840")
        box(0, 52, 64, 9, "#4aa0c0"); box(8, 55, 10, 1, "#a5d0e0"); box(36, 57, 12, 1, "#a5d0e0"); box(0, 61, 64, 11, "#d9b47a")
        c.fill(Path(ellipseIn: CGRect(x: 11, y: 5.5, width: 14, height: 17)), with: .color(Color(hex: colors.first ?? "#ff5e3a")))
        box(16.5, 5.5, 3, 17, colors.count > 1 ? colors[1] : "#ffc23d"); box(16, 24, 4, 3.5, "#6a4020")
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
                if s.bundleWorth { founderCard(s) }
                if !s.ownedDecorations.isEmpty { myDecorations(s) }
                section(.decoration, "bazaar.decor", s)
                section(.figure, "bazaar.figures", s)
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
        .onAppear {
            Telemetry.storeViewed("bazaar", s)
            if s?.bundleWorth == true { Telemetry.offer("founder", "shown", s) }
        }
    }

    /// v125.7: the decorations you own, each in town or put away in storage, with a toggle; put away it stays yours
    /// (prototype `showBazaar`, "Süslerin").
    @MainActor private func myDecorations(_ s: GameState) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(loc("bazaar.mine")).font(Theme.font(13, .bold)).foregroundStyle(Theme.ink2)
            CardText.hint(loc("bazaar.mine.hint"))
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], spacing: 8) {
                ForEach(s.ownedDecorations, id: \.self) { k in
                    let on = s.placed(k)
                    VStack(spacing: 2) {
                        StoreThumb(item: k, colors: s.colors, company: s.company).frame(width: 60, height: 68)
                            .opacity(on ? 1 : 0.45).saturation(on ? 1 : 0.4).accessibilityHidden(true)
                        Text(k.title).font(Theme.font(14, .bold, condensed: true)).foregroundStyle(Theme.ink)
                            .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.8)
                            .frame(height: 34)
                        Text(loc(on ? "bazaar.inTown" : "bazaar.stored"))
                            .font(Theme.font(12, .bold)).foregroundStyle(on ? Theme.green : Color(hex: "#8a7a66"))
                            .lineLimit(1).minimumScaleFactor(0.8)
                        Button {
                            SoundEngine.shared.play(.click)
                            store.act { $0.toggleDecoration(k) }
                        } label: {
                            Text(loc(on ? "bazaar.putAway" : "bazaar.place"))
                                .font(Theme.font(13, .heavy)).foregroundStyle(.white)
                                .lineLimit(1).minimumScaleFactor(0.7)
                                .frame(maxWidth: .infinity).padding(.vertical, 5)
                                .background(on ? Theme.ink : Theme.green, in: RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(k.title), \(loc(on ? "bazaar.inTown" : "bazaar.stored")): \(loc(on ? "bazaar.putAway" : "bazaar.place"))")
                        .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 6).padding(.vertical, 8)
                    .background(LinearGradient(colors: [Color(hex: "#fff6e6"), Color(hex: "#f3e2c4")], startPoint: .top, endPoint: .bottom),
                                in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#e6cfa6"), lineWidth: 1.5))
                }
            }
        }
    }

    @MainActor private func section(_ kind: StoreItem.Kind, _ key: String, _ s: GameState) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(loc(key)).font(Theme.font(13, .bold)).foregroundStyle(Theme.ink2)
            CardText.hint(loc(key == "bazaar.decor" ? "bazaar.decor.hint2" : key + ".hint"))
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], spacing: 8) {
                // v115: the small decorations and the figures are sold as packs, the rest one by one
                ForEach(StoreItem.allCases.filter { kind == .figure ? $0 == .figurePack : (($0.kind == kind && ($0.isProduct || $0.gift)) || (kind == .decoration && $0 == .decorPack)) }, id: \.self) { k in // TestFlight: Hezarfen's gift lanterns were filtered out
                    let own = k.kind == .pack ? (s.owned(k) || k.packItems.allSatisfy(s.owned)) : s.owned(k), locked = false
                    Button {
                        SoundEngine.shared.play(.click)
                        store.storeItem = k
                    } label: {
                        VStack(spacing: 2) {
                            // A pack's count sits on its picture, so every card has the same rows and the prices line up.
                            StoreThumb(item: k, colors: s.colors, company: s.company).frame(width: 60, height: 68).accessibilityHidden(true)
                                .overlay(alignment: .topTrailing) {
                                    if k.kind == .pack {
                                        Text(loc("bazaar.packParts", num(k.packItems.count)))
                                            .font(Theme.font(10.5, .heavy, condensed: true)).foregroundStyle(.white)
                                            .padding(.horizontal, 6).padding(.vertical, 1)
                                            .background(Theme.coral, in: RoundedRectangle(cornerRadius: 8))
                                            .fixedSize()
                                            .offset(x: 12, y: -4)
                                    }
                                }
                            Text(k.title).font(Theme.font(14, .bold, condensed: true)).foregroundStyle(Theme.ink)
                                .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.8)
                                .frame(height: 34)
                            HStack(spacing: 3) {
                                if locked && !own && !k.gift { LockGlyph(size: 11) }
                                if k.gift && !own { LineGlyph(kind: .gift, size: 13, weight: 2.6) }
                                Text(own ? loc("bazaar.yours") : k.gift ? loc("bazaar.gift") : locked ? loc("bazaar.locked") : storePrice(k))
                            }
                                .font(Theme.font(13, .heavy)).foregroundStyle(.white)
                                .padding(.horizontal, 9).padding(.vertical, 2)
                                .background(own ? Theme.green : k.gift ? Theme.coral : locked ? Color(hex: "#8a8398") : Theme.ink, in: Capsule())
                                .padding(.top, 3)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 6).padding(.vertical, 8)
                        .background(LinearGradient(colors: [Color(hex: "#fff6e6"), Color(hex: "#f3e2c4")], startPoint: .top, endPoint: .bottom),
                                    in: RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: k.gift && !own ? "#ff9a7a" : "#e6cfa6"), lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    .disabled(own || locked)
                    .opacity(locked ? 0.6 : 1)
                    .tutTargetIf(k == .lanterns && !own, "ga.gift") // v122: Hezarfen's gift
                }
            }
        }
    }

    /// v113: the Founder Pack on top of the bazaar: a few of what's in it, how many, the price struck through and the pack's.
    private func founderCard(_ s: GameState) -> some View {
        let left = s.bundleLeft
        var peek: [StoreItem] = []
        for kind in [StoreItem.Kind.shape, .figure, .decoration, .pattern, .shape, .figure] {
            if let q = left.first(where: { $0.kind == kind && !peek.contains($0) }) { peek.append(q) }
        }
        for q in left where peek.count < 6 && !peek.contains(q) { peek.append(q) }
        return Button {
            SoundEngine.shared.play(.click)
            store.storeItem = .founder
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(StoreItem.founder.title).font(Theme.font(22, .heavy, condensed: true)).foregroundStyle(Color(hex: "#ffd27a"))
                    Spacer()
                    Text(loc("store.off", StoreItem.percent(s.bundleOff))).font(Theme.font(13, .heavy)).foregroundStyle(.white)
                        .padding(.horizontal, 9).padding(.vertical, 3).background(Theme.coral, in: Capsule())
                }
                HStack(spacing: 5) {
                    ForEach(peek.prefix(6), id: \.self) { q in
                        StoreThumb(item: q, colors: s.colors, company: s.company).frame(width: 36, height: 40)
                            .background(Color.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 9))
                    }
                    if left.count > 6 {
                        Text("+\(left.count - 6)").font(Theme.font(12, .heavy)).foregroundStyle(Theme.ink)
                            .padding(.horizontal, 7).padding(.vertical, 3).background(Color(hex: "#ffd27a"), in: Capsule())
                    }
                }
                .accessibilityHidden(true)
                HStack(alignment: .firstTextBaseline) {
                    Text(loc("bazaar.founderLeft", num(left.count))).font(Theme.font(13)).foregroundStyle(.white.opacity(0.85))
                    Spacer()
                    Text(StoreItem.price(of: s.bundleWas)).font(Theme.font(13)).strikethrough().foregroundStyle(.white.opacity(0.6))
                    Text(storePrice(.founder)).font(Theme.font(20, .heavy, condensed: true)).foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(LinearGradient(colors: [Color(hex: "#2b2350"), Color(hex: "#4a2f6a")], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(hex: "#e8b04a"), lineWidth: 2))
        }
        .buttonStyle(.plain)
    }
}

extension StoreItem {
    /// Shown until the App Store's localized price is loaded: tier 1 €0,99, tier 2 €1,99.
    static func price(_ k: StoreItem) -> String { price(of: k.euro) }
    static func price(of euro: Double) -> String { euro.formatted(.currency(code: "EUR")) }
    /// The pack's discount, "60%" written the local way ("%60" in Turkish).
    static func percent(_ v: Int) -> String { (Double(v) / 100).formatted(.percent.precision(.fractionLength(0))) }
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
                Text(loc(item == .pigeons ? "store.dayPreview" : "store.nightPreview")).font(Theme.font(13, .bold)).foregroundStyle(Theme.ink2)
                DecorNightPreview(item: item, state: s)
            } else if item == .founder || item.kind == .pack, let s {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5), spacing: 6) {
                    ForEach(item == .founder ? s.bundleLeft : item.packItems, id: \.self) { q in
                        StoreThumb(item: q, colors: s.colors, company: s.company).aspectRatio(64 / 72, contentMode: .fit)
                            .background(Color.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 10))
                    }
                }
                .accessibilityHidden(true)
                .padding(8)
                .background(LinearGradient(colors: [Color(hex: "#bfe0f2"), Color(hex: "#ffe6c4")], startPoint: .top, endPoint: .bottom),
                            in: RoundedRectangle(cornerRadius: 16))
            } else {
                StoreThumb(item: item, colors: s?.colors ?? [], company: s?.company ?? "")
                    .accessibilityHidden(true)
                    .frame(width: 96, height: 108)
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(LinearGradient(colors: [Color(hex: "#bfe0f2"), Color(hex: "#ffe6c4")], startPoint: .top, endPoint: .bottom),
                                in: RoundedRectangle(cornerRadius: 16))
            }
            CardText.lead(lead(s))
            if item == .founder, let s {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(StoreItem.price(of: s.bundleWas)).font(Theme.font(16)).strikethrough().foregroundStyle(Theme.ink2)
                    Text(shop.price(.founder)).font(Theme.font(28, .heavy, condensed: true)).foregroundStyle(Theme.ink)
                    Text(loc("store.off", StoreItem.percent(s.bundleOff))).font(Theme.font(13, .heavy)).foregroundStyle(.white)
                        .padding(.horizontal, 9).padding(.vertical, 3).background(Theme.coral, in: Capsule())
                }
                .frame(maxWidth: .infinity)
            }
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
            .tutTargetIf(item.gift, "ga.takeGift") // v122
            // every single cosmetic also points at the pack while the pack saves money
            if let s, [.pattern, .shape, .decoration, .pack].contains(item.kind), item.isProduct, s.bundleWorth {
                Button {
                    SoundEngine.shared.play(.click)
                    store.storeItem = .founder
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(loc("store.orAll", StoreItem.founder.title)).font(Theme.font(13, .bold)).foregroundStyle(Theme.ink)
                        HStack(spacing: 4) {
                            Text(StoreItem.price(of: s.bundleWas)).strikethrough().foregroundStyle(Theme.ink2)
                            Text(shop.price(.founder)).bold()
                            Text("· " + loc("store.off", StoreItem.percent(s.bundleOff)))
                        }
                        .font(Theme.font(13)).foregroundStyle(Theme.ink)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12).padding(.vertical, 9)
                    .background(Color(hex: "#fff8ea"), in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#c99a4a"), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])))
                }
                .buttonStyle(.plain)
            }
            Button {
                SoundEngine.shared.play(.click)
                store.storeItem = nil
            } label: {
                Text(loc("store.cancel")).frame(maxWidth: .infinity)
            }
            .buttonStyle(ChunkyButtonStyle(kind: .ghost))
        }
        .onAppear {
            shop.note = nil
            Telemetry.storeViewed(item.rawValue, store.state)
        }
    }

    private func lead(_ s: GameState?) -> String {
        switch item.kind {
        case .decoration: loc("store.lead.decor")
        case .shape: loc("store.lead.shape")
        case .pattern: loc("store.lead.pattern")
        case .figure: item == .figInitial ? loc("store.lead.figInitial", ShowCardView.initial(s?.company ?? "")) : loc("store.lead.figure")
        case .pack: loc(item == .figurePack ? "store.lead.figurePack" : "store.lead.decorPack")
        case .unlock: loc("store.lead.worldTour")
        case .supporter: loc("store.lead.supporter")
        case .bundle: loc("store.lead.bundle", num(s?.bundleLeft.count ?? 0))
        }
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
        case .pigeons: (7.5, 3.5, 0.3)
        case .arch: (8, 15.57, 0.75)
        case .cafe: (DecorPainter.cafeAt.0, DecorPainter.cafeAt.1, 0.7)
        case .rugs: (DecorPainter.rugsAt.0, DecorPainter.rugsAt.1, 0.75)
        case .statue: (6.9, 8.9, 0.6)
        case .lanterns: (7.4, 7.6, 0.3)
        case .flags: (7.5, 9, 0.26)
        default: (8, 8, 0.55)
        }
    }

    var body: some View {
        var s = state
        s.store = (s.store ?? [:]).merging([item: s.day]) { old, _ in old }
        s.storedDecor?.remove(item) // v125.7: the preview shows it even if it's put away
        return TimelineView(.animation) { tl in
            Canvas { ctx, sz in
                let (gx, gy, z) = spot, c = TownGeo.iso(gx, gy)
                var v = TownViewport(z: z, ox: sz.width / 2 - c.x * z, oy: sz.height * 0.62 - c.y * z)
                v.noLabels = true
                v.hzFix = sz.height * 0.12
                var g = ctx
                _ = TownPainter.render(&g, state: s, time: 1000 + tl.date.timeIntervalSince(start), viewport: v, size: sz,
                                       night: item == .pigeons ? nil : TownNight(k: 1, event: nil, t0: 1000))
            }
        }
        .frame(height: 220)
        .background(Color(hex: "#1b1840"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityHidden(true)
    }
}

/// v115: after the Baron of Cappadocia ceremony (or when a new region is out of reach): the Grand Tour, or the Supporter
/// Edition when the Founder Pack isn't yours yet (`showTourOffer`).
@MainActor
struct TourOfferView: View {
    @Environment(GameStore.self) private var store
    private var shop: Shop { Shop.shared }

    var body: some View {
        let s = store.state
        ModalCard(onClose: close) {
            Text(loc("store.worldTour")).font(Theme.font(14, .heavy, condensed: true)).tracking(0.8).textCase(.uppercase).foregroundStyle(Theme.coral)
            CardText.title(loc("tour.title"))
            StoreThumb(item: .worldTour, colors: s?.colors ?? [])
                .accessibilityHidden(true)
                .frame(width: 140, height: 158)
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(LinearGradient(colors: [Color(hex: "#bfe0f2"), Color(hex: "#ffe6c4")], startPoint: .top, endPoint: .bottom), in: RoundedRectangle(cornerRadius: 16))
            CardText.lead(loc("tour.lead"))
            option(.worldTour, sub: loc("tour.worldSub"), was: nil, main: true)
            if let s, !s.owned(.founder) {
                option(.supporter, sub: loc("tour.supporterSub", StoreItem.founder.title), was: StoreItem.price(of: StoreItem.worldTour.euro + StoreItem.founder.euro), main: false)
            }
            if let note = shop.note { CardText.hint(note) }
            Button {
                SoundEngine.shared.play(.click)
                Telemetry.offer("grandTour", "declined", store.state)
                close()
            } label: { Text(loc("tour.later")).frame(maxWidth: .infinity) }
            .buttonStyle(ChunkyButtonStyle(kind: .ghost, wide: true))
        }
        .onAppear { Telemetry.offer("grandTour", "shown", store.state) }
    }

    private func option(_ k: StoreItem, sub: String, was: String?, main: Bool) -> some View {
        // v124.7 (TestFlight): the choice buys at once; it used to open a second purchase card first
        Button {
            SoundEngine.shared.play(.click)
            Telemetry.offer("grandTour", "chose." + k.rawValue, store.state)
            Task {
                if await shop.buy(k) { close() }
            }
        } label: {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(k.title).font(Theme.font(20, .heavy, condensed: true)).foregroundStyle(Theme.ink)
                    Text(sub).font(Theme.font(12.5)).foregroundStyle(Theme.ink2).fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 6)
                if let was { Text(was).font(Theme.font(13)).strikethrough().foregroundStyle(Theme.ink2) }
                if shop.buying == k {
                    ProgressView().tint(Theme.ink)
                } else {
                    Text(storePrice(k)).font(Theme.font(17, .heavy)).foregroundStyle(Theme.ink)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(main ? Color(hex: "#fff6f2") : Color.white, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(main ? Theme.coral : Theme.line, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .disabled(shop.buying != nil)
    }

    private func close() {
        store.showTourOffer = false
        store.showNextHezarfen()
    }
}
