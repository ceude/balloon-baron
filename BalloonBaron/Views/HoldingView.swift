import SwiftUI
import BalloonBaronCore

/// The holding's boardroom: cash flow, money from the region, regions, campaigns and city offices.
/// A desk of the holding office and the part of the holding it opens. Names: `hq.<rawValue>`.
enum HoldingUnit: String, CaseIterable, Identifiable {
    case board, window, marketing, deals, research, offices, records, shapes
    /// v140: the International Balloon Festival and the Hot Air Foundation, a fourth row of desks.
    case festival, foundation
    var id: String { rawValue }
}

struct HoldingView: View {
    @Environment(GameStore.self) private var store
    /// One desk's part of the holding (in the office), or nil for all of it.
    var unit: HoldingUnit?
    var onClose: (() -> Void)?

    var body: some View {
        ZStack {
            HoldingLux.background.ignoresSafeArea()
            if let game = store.game {
                VStack(spacing: 0) {
                    WorldPageHeader(title: unit.map { loc("hq.\($0.rawValue)") } ?? loc("holding.title", game.state.company)) {
                        if let onClose { onClose() } else { store.closePage() }
                    }
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            sections(game)
                        }
                        .padding(16)
                    }
                }
            }
        }
        .foregroundStyle(HoldingLux.text)
    }

    @ViewBuilder
    private func sections(_ game: Game) -> some View {
        let s = game.state
        if unit == nil || unit == .board {
            HoldingCashBox(holding: s.holding)
            if !s.isBaron(), let c = s.currentChapter { goalsCallout(c, s) }
            holdingGoals(s)
            withdrawSection(s)
        }
        if unit == nil || unit == .window { regionsSection(game) }
        if unit == nil { dealsSection(game) }
        if unit == .marketing {
            sectionTitle(loc("hq.campaigns"))
            hint(loc("holding.mkt.hint"))
            tvCard(game)
            billboardCard(game)
            documentaryCard(game)
        }
        if unit == .deals {
            hint(loc("holding.deals.hint"))
            celebrityCard(s)
            jerseyCard(s)
            worldGamesCard(game)
        }
        if unit == .festival {
            sectionTitle(loc("holding.fest.section"))
            hint(loc("holding.fest.hint"))
            festivalCard(game)
        }
        if unit == .foundation {
            sectionTitle(loc("holding.fdn.section"))
            hint(loc("holding.fdn.hint"))
            foundationCard(game)
        }
        if unit == .research {
            sectionTitle(loc("hq.lab"))
            researchCard(s)
            labCard(Holding.radarLevel, s)
            labCard(Holding.compositeLevel, s)
        }
        if unit == nil || unit == .offices { officesSection(s) }
        if unit == .records {
            sectionTitle(loc("hq.recordsTitle"))
            hint(loc(s.recordsOpen ? "holding.rec.hint" : "holding.rec.locked"))
            ForEach(RecordAttempt.allCases, id: \.self) { recordCard($0, s) }
        }
        if unit == .shapes {
            sectionTitle(loc("hq.shapesTitle"))
            hint(loc("holding.shape.hint"))
            ForEach(AdShape.allCases, id: \.self) { shapeCard($0, s) }
        }
    }

    /// Desk 5: a sponsored world record. The first attempt at the first two always works; the odds shown apply to beating
    /// your own. v137: the round-the-world flight, the ladder's top, has odds that are the odds every time and opens after
    /// the Pacific crossing.
    private func recordCard(_ k: RecordAttempt, _ s: GameState) -> some View {
        let h = s.holding, run = h.record, now = run?.kind == k, set = s.recordSet(k), cost = h.recordCost(k)
        var chips = [loc("holding.chip.prep", num(k.days)), loc("holding.chip.odds", percent(k.odds)), loc("holding.chip.allDemandLasting", percent(k.boost))]
        if k.ceilingRaise > 0 {
            chips.append(loc("holding.chip.recCeiling", percent(RecordAttempt.maxBoost), percent(RecordAttempt.maxBoost + k.ceilingRaise)))
        }
        let lock: String? = !s.recordsOpen ? loc("holding.rec.lockNote")
            : s.recordLocked(k) ? loc("holding.rec.after", (k.after ?? .world).title)
            : run != nil && !now ? loc("holding.rec.oneAtATime") : nil
        return HoldingDealCard(art: k == .pacific ? .pacific : k == .world ? .globe : .record, kicker: loc("holding.rec.kicker"), title: k.title, detail: k.detail, chips: chips,
                               price: cost, cta: loc(set ? "holding.rec.again" : "holding.rec.cta"),
                               enabled: lock == nil && h.cash >= cost, lockNote: lock ?? (set ? loc("holding.rec.yours") : nil),
                               active: now ? loc("holding.rec.active", num((run?.done ?? s.day) - s.day)) : nil,
                               action: { store.act { g in _ = g.startRecord(k) } })
    }

    /// Desk 6: a brand pays the holding to fly its product-shaped balloon over this region; tourists like you a little less.
    private func shapeCard(_ k: AdShape, _ s: GameState) -> some View {
        let a = s.holding.adShape, running = a.map { $0.until >= s.day } ?? false, now = running && a?.shape == k
        let fee = store.game?.adBreakFee ?? 0
        let chips = [loc("holding.chip.perDay", eurH(k.pay)), loc("holding.chip.days", num(k.days)),
                     loc("holding.chip.repDay", (k.repLoss * 4).formatted(.number.precision(.fractionLength(3))) + "★")]
        return HoldingDealCard(art: .shape(k), kicker: loc("holding.shape.kicker"), title: k.title, detail: loc("holding.shape.desc"),
                               chips: chips, price: k.pay * k.days, cta: loc("holding.shape.cta"),
                               enabled: !running, lockNote: running && !now ? loc("holding.shape.oneAtATime") : nil,
                               priceNote: loc("holding.shape.terms", eurH(k.pay), num(k.days)),
                               active: now ? loc("holding.shape.active", (a?.region ?? s.region).title, num((a?.until ?? s.day) - s.day)) : nil,
                               breakTitle: now ? loc("holding.shape.break", eurH(fee)) : nil,
                               breakNote: now ? loc("holding.shape.breakNote") : nil,
                               breakEnabled: s.holding.cash >= fee,
                               breakAction: now ? { store.act { g in _ = g.breakAdShape() } } : nil,
                               action: { store.act { g in _ = g.signAdShape(k) } })
    }

    /// The holding's own goals; all seven make you World Baron.
    private func holdingGoals(_ s: GameState) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                sectionTitle(loc(s.holding.worldBaron != nil ? "hgoal.worldTitle" : "hgoal.title"))
                if s.holding.worldBaron != nil {
                    LineGlyph(kind: .crown, size: 24, weight: 2, fill: Theme.sun).foregroundStyle(Color(hex: "#c98a00"))
                }
            }
            ForEach(HoldingGoal.allCases, id: \.self) { g in
                let d = s.done(g)
                HStack(spacing: 10) {
                    Image(systemName: d ? "checkmark.square.fill" : "square")
                        .foregroundStyle(d ? HoldingLux.income : HoldingLux.sub)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(g.title).font(Theme.font(15, .semibold)).strikethrough(d)
                        // v132 (TestFlight): what the million goal measures, and that it stays met once reached
                        if let note = Self.goalNote(g, s) {
                            Text(note).font(Theme.font(12)).foregroundStyle(HoldingLux.sub)
                        }
                    }
                    Spacer()
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(g.title)
                .accessibilityValue([d ? loc("goals.finished") : nil, Self.goalNote(g, s)].compactMap { $0 }.joined(separator: ", "))
            }
            hint(loc("hgoal.hint"))
        }
    }

    /// v132: under the million goal, the holding's cash now (what it measures), or the day it was reached.
    static func goalNote(_ g: HoldingGoal, _ s: GameState) -> String? {
        guard s.holding.worldBaron == nil else { return nil }
        // v137: how far the two longer goals have come
        if g == .offices, !s.done(g) { return loc("hgoal.officesNow", num(s.holding.offices.count), num(Office.allCases.count)) }
        if g == .research, !s.done(g) { return loc("hgoal.researchNow", num(s.holding.research), num(Holding.researchLevels.count)) }
        guard g == .million else { return nil }
        if let d = s.holding.millionOn { return loc("hgoal.millionOn", num(d)) }
        return s.done(g) ? nil : loc("hgoal.millionNow", eurH(s.holding.cash))
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(Theme.font(22, .heavy, condensed: true))
            .foregroundStyle(HoldingLux.heading)
    }

    private func hint(_ text: String) -> some View {
        Text(text)
            .font(Theme.font(14))
            .foregroundStyle(HoldingLux.sub)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: Goals and withdrawals

    private func goalsCallout(_ c: Chapter, _ s: GameState) -> some View {
        let done = c.goals.filter { s.done($0) }.count
        return VStack(alignment: .leading, spacing: 8) {
            Text(loc("holding.goalsCallout", s.region.title, c.title, "\(done)/\(c.goals.count)"))
                .font(Theme.font(14, .semibold))
            HoldingPill(title: loc("holding.goals"), style: .ink) { store.page = .goals }
        }
        .foregroundStyle(Color(hex: "#6b4c00"))
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "#fff3cf"), in: RoundedRectangle(cornerRadius: 14))
    }

    private func withdrawSection(_ s: GameState) -> some View {
        let canTake = s.cash > Holding.withdrawKeep
        let hintKey = s.region == .bri ? "holding.withdrawHintFx.bri" : s.region.fx != 1 ? "holding.withdrawHintFx" : "holding.withdrawHint" // v124: pounds
        return VStack(alignment: .leading, spacing: 10) {
            sectionTitle(loc("holding.withdrawTitle", s.region.title))
            hint(loc(hintKey, s.region.title, eur(s.cash)))
            HStack(spacing: 8) {
                HoldingPill(title: percent(0.25), enabled: canTake) { take(0.25) }
                HoldingPill(title: percent(0.5), enabled: canTake) { take(0.5) }
                HoldingPill(title: loc("holding.withdrawAll", eur(Holding.withdrawKeep)), enabled: canTake) { take(1) }
            }
        }
    }

    private func take(_ share: Double) {
        store.act { g in _ = g.withdraw(share: share) }
    }

    // MARK: Regions

    private func regionsSection(_ game: Game) -> some View {
        let s = game.state
        let list = RegionID.allCases.filter { s.owns($0) || ($0 != .cap && s.regionOpen($0)) }
        return VStack(alignment: .leading, spacing: 8) {
            sectionTitle(loc("holding.regions"))
            ForEach(list, id: \.self) { r in
                regionRow(r, game)
            }
            HoldingPill(title: loc("map.title")) { store.page = .map }
                .padding(.top, 2)
        }
    }

    private func regionRow(_ r: RegionID, _ game: Game) -> some View {
        let s = game.state
        let here = r == s.region
        let auto = s.parked[r]?.auto
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(r.title)
                            .font(Theme.font(19, .heavy, condensed: true))
                            .foregroundStyle(HoldingLux.title)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        regionTag(here: here, auto: auto)
                        if s.isBaron(r) {
                            WorldTag(text: loc("map.baron"), kind: .green)
                        }
                    }
                    Text(regionSubtitle(r, here: here, auto: auto, game))
                        .font(Theme.font(13))
                        .foregroundStyle(HoldingLux.sub)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                regionActions(r, here: here, auto: auto, game)
            }
            if here || auto != nil { sendControls(r, s, here: here) }
        }
        .padding(12)
        .background(HoldingLux.card, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(HoldingLux.border, lineWidth: 2))
        .compositingGroup()
        .shadow(color: HoldingLux.border, radius: 0, y: 3)
    }

    /// v131 (TestFlight): a parked region's daily delivery to the holding, on (the default) or off. Off, the profit
    /// stays in the region's cash box and a button moves it to the holding, leaving `Holding.withdrawKeep`.
    /// v134 (TestFlight): the region you're in has the switch too (it had none, so the choice looked lost after
    /// travelling). Nothing flows while you play there; the choice applies once it is parked on autopilot.
    @ViewBuilder
    private func sendControls(_ r: RegionID, _ s: GameState, here: Bool) -> some View {
        let on = s.holding.sends(r)
        let note = here ? (on ? "holding.sendHereOn" : "holding.sendHereOff") : (on ? "holding.sendOn" : "holding.sendOff")
        Rectangle().fill(HoldingLux.border).frame(height: 1)
        Button {
            SoundEngine.shared.play(.click)
            store.act { $0.setSendsToHolding(r, !on) }
        } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(loc("holding.sendTitle"))
                        .font(Theme.font(15, .bold))
                        .foregroundStyle(HoldingLux.title)
                    Text(loc(note))
                        .font(Theme.font(13))
                        .foregroundStyle(HoldingLux.sub)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                SettingsSwitch(on: on)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(loc("holding.sendTitle"))
        .accessibilityValue(loc(on ? "a11y.on" : "a11y.off"))
        .accessibilityHint(loc(note))
        .accessibilityAddTraits(.isButton)
        if !on, !here, let cash = s.parked[r]?.state.cash {
            let amount = max(0, cash - Holding.withdrawKeep)
            HStack(alignment: .center, spacing: 10) {
                Text(loc("holding.moveHint", money(Holding.withdrawKeep, in: r)))
                    .font(Theme.font(13))
                    .foregroundStyle(HoldingLux.sub)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HoldingPill(title: loc("holding.moveOut", money(amount, in: r)), style: .ink, enabled: amount > 0) {
                    SoundEngine.shared.play(.coin)
                    store.act { _ = $0.withdraw(from: r, share: 1) }
                }
                .fixedSize()
            }
        }
    }

    private func regionTag(here: Bool, auto: Autopilot?) -> WorldTag {
        if here { return WorldTag(text: loc("map.here"), kind: .green) }
        guard let auto else { return WorldTag(text: loc("map.unlocked"), kind: .yellow) }
        return auto.issue != nil ? WorldTag(text: loc("map.problem"), kind: .red) : WorldTag(text: loc("map.auto"), kind: .yellow)
    }

    private func regionSubtitle(_ r: RegionID, here: Bool, auto: Autopilot?, _ game: Game) -> String {
        if here { return loc("holding.hereSub") }
        if let auto {
            // Today's delivery; right after parking, the expected amount instead.
            let expected = auto.base * game.holdingBoost(r) * game.state.holding.officeMultiplier(r)
            var text: String
            if game.state.holding.sends(r) {
                text = loc("holding.autoSub", eurH(auto.today != 0 ? auto.today : Int(expected.rounded())))
            } else {
                // v131: kept in the region: yesterday's net there (after the holding's running costs), in its money
                let kept = auto.kept ?? Int((expected * (1 - game.state.holding.expenseRate) * r.fx).rounded())
                text = loc("holding.keptSub", money(kept, in: r), money(game.state.parked[r]?.state.cash ?? 0, in: r))
            }
            if let open = auto.issue { text += " " + loc("map.problemSub", open.kind.title) }
            return text
        }
        let start = r.startCash.formatted(.currency(code: r.currency).precision(.fractionLength(0)))
        return loc("holding.enterSub", eurH(r.entryFee), start)
    }

    @ViewBuilder
    private func regionActions(_ r: RegionID, here: Bool, auto: Autopilot?, _ game: Game) -> some View {
        if !here {
            VStack(alignment: .trailing, spacing: 6) {
                if auto?.issue != nil {
                    HoldingPill(title: loc("map.decide"), style: .coral) { store.issueRegion = r }
                }
                if auto != nil {
                    HoldingPill(title: loc("map.go")) { store.goTo(r) }
                } else if game.state.needsPack(r) {
                    HoldingPill(title: loc("map.openTour", storePrice(.worldTour)), style: .gold) { store.showTourOffer = true }
                } else {
                    HoldingPill(title: loc("map.enter", eurH(r.entryFee)), style: .gold, enabled: game.canEnterRegion(r)) { store.goTo(r) }
                }
            }
            .fixedSize()
        }
    }

    // MARK: Campaigns and deals

    private func dealsSection(_ game: Game) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(loc("holding.deals"))
            hint(loc("holding.mkt.hint"))
            tvCard(game)
            billboardCard(game)
            hint(loc("holding.deals.hint"))
            celebrityCard(game.state)
            researchCard(game.state)
        }
    }

    /// v136 (TestFlight): a TV campaign for each region you own, each with its own run and wait, bought from one card
    /// whichever region the holding was opened from.
    private func tvCard(_ game: Game) -> some View {
        let s = game.state, h = s.holding, d = s.day
        let chips = [loc("holding.chip.demandRegion", percent(Holding.tvBoost - 1)), loc("holding.chip.days", num(Holding.tvDays)),
                     loc("holding.chip.starsRegion", starsValue(Holding.tvRep * 4)), loc("holding.chip.wait", num(Holding.tvCooldown))]
        let rows = game.ownedRegions.map { r -> HoldingRegionRow in
            let until = h.tvUntil(r), ready = h.tvReady(r)
            let status = until > d ? loc("holding.tv.active", num(until - d)) : ready > d ? loc("holding.row.wait", num(ready - d)) : loc("holding.row.free")
            return HoldingRegionRow(region: r, here: r == s.region, status: status, on: until > d, price: h.tvCost,
                                    buyable: game.canRunTV(in: r), enabled: game.canRunTV(in: r) && h.cash >= h.tvCost, cta: loc("holding.tv.cta"),
                                    action: { store.act { g in _ = g.runTVCampaign(in: r) } })
        }
        return HoldingDealCard(art: .tv, kicker: loc("holding.tv.kicker"), title: loc("holding.tv.title"),
                               detail: loc("holding.tv.descRegion"), chips: chips, regionRows: rows, action: {})
    }

    private func celebrityCard(_ s: GameState) -> some View {
        let h = s.holding, d = s.day
        let star: Celebrity? = (h.celebrity?.until ?? 0) > d ? h.celebrity : nil
        // v140: the first deal is a rising star's, cheaper; the card says so
        let detail = star.map { loc("holding.celeb.descActive", celebrityName($0.index)) } ?? loc(h.celebrity == nil ? "holding.celeb.descFirst" : "holding.celeb.desc")
        let active = star.map { loc("holding.celeb.active", celebrityName($0.index), num($0.until - d)) }
        let chips = [loc("holding.chip.allDemand", percent(Holding.celebrityBoost - 1)), loc("holding.chip.days", num(h.celebrityDays)),
                     loc("holding.chip.starsAll", starsValue(Holding.celebrityRep * 4))]
        return HoldingDealCard(art: .star, kicker: loc("holding.celeb.kicker"), title: loc("holding.celeb.title"),
                               detail: detail, chips: chips, price: h.celebrityCost, cta: loc("holding.celeb.cta"),
                               enabled: h.cash >= h.celebrityCost, active: active,
                               action: { store.act { g in _ = g.signCelebrity() } })
    }

    /// v122.7: the league champion's jersey.
    private func jerseyCard(_ s: GameState) -> some View {
        let h = s.holding, d = s.day, on = (h.jerseyUntil ?? 0) > d
        let chips = [loc("holding.chip.allDemand", percent(Holding.jerseyBoost - 1)), loc("holding.chip.days", num(Holding.jerseyDays)),
                     loc("holding.chip.starsAll", starsValue(Holding.jerseyRep * 4))]
        return HoldingDealCard(art: .jersey, kicker: loc("holding.jersey.kicker"), title: loc("holding.jersey.title"),
                               detail: loc(on ? "holding.jersey.descActive" : "holding.jersey.desc", s.company), chips: chips,
                               price: Holding.jerseyCost, cta: loc("holding.jersey.cta"),
                               enabled: h.cash >= Holding.jerseyCost,
                               active: on ? loc("holding.jersey.active", num((h.jerseyUntil ?? d) - d)) : nil,
                               action: { store.act { g in _ = g.sponsorJersey() } })
    }

    /// v122.7: the World Games' opening show. v140: the Games come round every 360 days, each show 1.5 times the last.
    private func worldGamesCard(_ game: Game) -> some View {
        let s = game.state, h = s.holding, d = s.day, held = h.worldGamesHeld, on = (h.worldGamesUntil ?? 0) > d
        let wait = !on && held > 0 && h.worldGamesNext > d
        let chips = [loc("holding.chip.allDemand", percent(Holding.worldGamesBoost - 1)), loc("holding.chip.days", num(Holding.worldGamesDays)),
                     loc("holding.chip.starsAll", starsValue(Holding.worldGamesRep * 4)),
                     loc("holding.wg.chipStep", Holding.worldGamesStep.formatted(.number.precision(.fractionLength(0...1))))]
        let detail = held == 0 ? "holding.wg.desc" : on ? "holding.wg.descActive" : wait ? "holding.wg.descDone" : "holding.wg.descAgain"
        let active: String? = on ? loc("holding.wg.active", num((h.worldGamesUntil ?? d) - d)) : wait ? loc("holding.wg.wait", num(held), num(h.worldGamesNext - d)) : nil
        return HoldingDealCard(art: .worldGames, kicker: loc("holding.wg.kicker"), title: loc("holding.wg.title"),
                               detail: loc(detail), chips: chips,
                               price: h.worldGamesPrice, cta: held > 0 ? loc("holding.wg.ctaN", num(held + 1)) : loc("holding.wg.cta"),
                               enabled: game.canHoldWorldGames && h.cash >= h.worldGamesPrice,
                               lockNote: s.worldGamesOpen || held > 0 ? nil : loc("holding.wg.lockBri"),
                               active: active,
                               action: { store.act { g in _ = g.holdWorldGamesShow() } })
    }

    /// v140: the International Balloon Festival, hosted in one region you own at a time, a new one every 90 days.
    private func festivalCard(_ game: Game) -> some View {
        let s = game.state, h = s.holding, d = s.day, f = h.festival
        let on = f.map { $0.until > d } ?? false, wait = !on && !h.festivalReady(day: d)
        let chips = [loc("holding.chip.demandRegion", percent(Holding.festivalBoost - 1)), loc("holding.chip.days", num(Holding.festivalDays)),
                     loc("holding.chip.starsRegion", starsValue(Holding.festivalRep * 4)),
                     loc("holding.fest.chipFame", percent(Holding.festivalFame), percent(Holding.festivalFameMax)),
                     loc("holding.fest.chipEvery", num(Holding.festivalEvery)),
                     loc("holding.fest.chipStep", eurH(Holding.festivalStep), eurH(Holding.festivalMax))]
        let rows = game.ownedRegions.map { r -> HoldingRegionRow in
            let live = h.festivalOn(r, day: d), n = h.festivalsIn?[r] ?? 0
            let status = live ? loc("holding.fest.on", num((f?.until ?? d) - d))
                : n > 0 ? loc("holding.fest.fame", percent(h.festivalFame(r)), num(n)) : loc("holding.fest.none")
            return HoldingRegionRow(region: r, here: r == s.region, status: status, on: live, price: h.festivalCost,
                                    buyable: !on && !wait, enabled: game.canHostFestival(in: r) && h.cash >= h.festivalCost,
                                    cta: loc("holding.fest.cta"), action: { store.act { g in _ = g.hostFestival(in: r) } })
        }
        return HoldingDealCard(art: .festival, kicker: loc("holding.fest.kicker"), title: loc("holding.fest.title"),
                               detail: on ? loc("holding.fest.descOn", (f?.region ?? s.region).title) : loc("holding.fest.desc"), chips: chips,
                               rowsNote: wait ? loc("holding.fest.wait", num((f?.next ?? d) - d)) : nil, regionRows: rows, action: {})
    }

    /// v140: the Hot Air Foundation: projects without end, each in a region you own, each €500,000 more than the last.
    private func foundationCard(_ game: Game) -> some View {
        let s = game.state, h = s.holding, n = h.projects
        let chips = [loc("holding.chip.starsAll", starsValue(Holding.foundationRep * 4)), loc("holding.fdn.chipMonument"),
                     loc("holding.fdn.chipStep", eurH(Holding.foundationStep))]
        let rows = game.ownedRegions.map { r -> HoldingRegionRow in
            let here = h.projects(in: r)
            let next = loc("holding.fdn.next", projectName(r, here))
            return HoldingRegionRow(region: r, here: r == s.region, status: here > 0 ? next + " · " + loc("holding.fdn.here", num(here)) : next,
                                    on: here > 0, price: h.projectCost, buyable: true, enabled: h.cash >= h.projectCost,
                                    cta: loc("holding.fdn.cta"), action: { store.act { g in _ = g.fundProject(in: r) } })
        }
        return HoldingDealCard(art: .foundation, kicker: loc("holding.fdn.kicker"),
                               title: n > 0 ? loc("holding.fdn.titleN", num(n)) : loc("holding.fdn.title"),
                               detail: loc("holding.fdn.desc"), chips: chips, regionRows: rows, action: {})
    }

    /// v136: billboards for each region you own, bought from one card; each row names its region.
    private func billboardCard(_ game: Game) -> some View {
        let s = game.state, h = s.holding, d = s.day
        let chips = [loc("holding.chip.demandRegion", percent(Holding.billboardBoost - 1)), loc("holding.chip.days", num(Holding.billboardDays))]
        let rows = game.ownedRegions.map { r -> HoldingRegionRow in
            let until = h.billboards[r] ?? 0, up = until > d
            return HoldingRegionRow(region: r, here: r == s.region, status: up ? loc("holding.bb.active", num(until - d)) : loc("holding.row.free"),
                                    on: up, price: Holding.billboardCost, buyable: !up, enabled: !up && h.cash >= Holding.billboardCost,
                                    cta: loc("holding.bb.cta"), action: { store.act { g in _ = g.runBillboards(in: r) } })
        }
        return HoldingDealCard(art: .billboard, kicker: loc("holding.bb.kicker"), title: loc("holding.bb.title"),
                               detail: loc("holding.bb.descRegion"), chips: chips, regionRows: rows, action: {})
    }

    /// The envelope research, levels 1 and 2 (v137: levels 3 and 4 have their own cards).
    private func researchCard(_ s: GameState) -> some View {
        let h = s.holding
        let lv = min(h.research, Holding.envelopeResearch)
        let next: Holding.ResearchLevel? = lv < Holding.envelopeResearch ? Holding.researchLevels[lv] : nil
        let chips = [loc("holding.chip.life", num(s.envelopeLife), num(next?.life ?? s.envelopeLife)), loc("holding.chip.permanent")]
        return HoldingDealCard(art: .lab, kicker: loc("holding.lab.kicker"), title: loc("holding.lab.title"),
                               detail: loc(next == nil ? "holding.lab.descDone" : "holding.lab.desc"), chips: chips,
                               price: next?.cost, cta: loc("holding.lab.cta", num(lv + 1)),
                               enabled: h.cash >= (next?.cost ?? Int.max),
                               active: next == nil ? loc("holding.lab.done", num(lv)) : nil,
                               action: { store.act { g in _ = g.fundResearch() } })
    }

    /// v137: R&D level 3 (the weather radar network) and 4 (the composite basket), one after the other.
    private func labCard(_ n: Int, _ s: GameState) -> some View {
        let h = s.holding, done = h.research >= n, ready = h.research == n - 1, radar = n == Holding.radarLevel
        let chips = radar
            ? [loc("holding.radar.chipRisk", percent(1 - Holding.radarAccident)), loc("holding.chip.autoIncome", percent(Holding.radarAutopilot - 1)), loc("holding.chip.permanent")]
            : [loc("holding.comp.chipFuel", percent(1 - Holding.compositeFuel)), loc("holding.comp.chipUpkeep", percent(1 - Holding.compositeUpkeep)),
               loc("holding.chip.autoIncome", percent(Holding.compositeAutopilot - 1)), loc("holding.chip.permanent")]
        let key = radar ? "radar" : "comp"
        return HoldingDealCard(art: radar ? .radar : .composite, kicker: loc("holding.lab.kickerLevel", num(n)), title: loc("holding.\(key).title"),
                               detail: loc("holding.\(key).desc"), chips: chips,
                               price: done ? nil : Holding.researchLevels[n - 1].cost, cta: loc("holding.lab.cta", num(n)),
                               enabled: ready && h.cash >= Holding.researchLevels[n - 1].cost,
                               lockNote: done || ready ? nil : loc("holding.lab.first", num(n - 1)),
                               active: done ? loc("holding.lab.done", num(n)) : nil,
                               action: { store.act { g in _ = g.fundResearch() } })
    }

    /// v137: the streaming documentary series: a season of 120 days, a new one 60 days after it ends.
    private func documentaryCard(_ game: Game) -> some View {
        let s = game.state, h = s.holding, d = s.day, doc = h.documentary
        let on = h.documentaryOn(d), wait = !on && !game.canMakeDocumentary, season = (doc?.season ?? 0) + (on ? 0 : 1)
        let chips = [loc("holding.chip.allDemand", percent(Holding.documentaryBoost - 1)), loc("holding.chip.days", num(Holding.documentaryDays)),
                     loc("holding.chip.starsAll", starsValue(Holding.documentaryRep * 4))]
        let active: String? = on ? loc("holding.doc.active", num(doc?.season ?? 1), num((doc?.until ?? d) - d))
            : wait ? loc("holding.doc.wait", num((doc?.next ?? d) - d)) : nil
        return HoldingDealCard(art: .documentary, kicker: loc("holding.doc.kicker"), title: loc("holding.doc.title"),
                               detail: on ? loc("holding.doc.descActive", s.company) : loc("holding.doc.desc"), chips: chips,
                               price: h.documentaryCost, cta: season > 1 ? loc("holding.doc.ctaSeason", num(season)) : loc("holding.doc.cta"),
                               enabled: game.canMakeDocumentary && h.cash >= h.documentaryCost, active: active,
                               action: { store.act { g in _ = g.makeDocumentary() } })
    }

    // MARK: Offices

    private func officesSection(_ s: GameState) -> some View {
        let h = s.holding
        let offices = Office.byPrice // v138: cheapest first
        let count = offices.filter { h.has($0) }.count
        // v137 (developer): any four offices 20%, all six 15%
        let text = count == offices.count
            ? loc("holding.officesSix", percent(Holding.allOfficesExpenseRate), percent(Holding.expenseRate))
            : count >= Holding.fewOffices
            ? loc("holding.officesFour", num(count), percent(Holding.fourOfficesExpenseRate), percent(Holding.expenseRate), percent(Holding.allOfficesExpenseRate))
            : loc("holding.officesRule", percent(Holding.expenseRate), percent(Holding.fourOfficesExpenseRate), percent(Holding.allOfficesExpenseRate))
        let rows = Array(stride(from: 0, to: offices.count, by: 2))
        // v140: the offices' rent and staff, paid every evening
        let rent = count > 0 ? loc("holding.officesRent", eurH(h.officeRent)) : loc("holding.officesRentNone")
        return VStack(alignment: .leading, spacing: 10) {
            sectionTitle(loc("holding.offices", "\(count)/\(offices.count)"))
            hint(text + " " + rent + (count < offices.count ? " " + loc("holding.officesNeedRegions") : ""))
            Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                ForEach(rows, id: \.self) { i in
                    GridRow {
                        officeCard(offices[i], h, s)
                        if i + 1 < offices.count {
                            officeCard(offices[i + 1], h, s)
                        } else {
                            Color.clear
                        }
                    }
                }
            }
        }
    }

    private func officeCard(_ o: Office, _ h: Holding, _ s: GameState) -> some View {
        let open = h.has(o)
        // v141: New York, Tokyo, London and Dubai open only once their region is entered
        let need = open ? nil : o.needs.flatMap { s.owns($0) ? nil : $0 }
        return VStack(alignment: .leading, spacing: 5) {
            Group {
                LineGlyph(kind: o.glyph, size: 34, weight: 1.7)
                    .foregroundStyle(open ? Theme.coral : HoldingLux.title)
                Text(o.title)
                    .font(Theme.font(19, .heavy, condensed: true))
                    .foregroundStyle(HoldingLux.title)
                Text(o.perk)
                    .font(Theme.font(12))
                    .foregroundStyle(HoldingLux.sub)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .opacity(need == nil ? 1 : 0.55)
            // v140: its rent and staff
            Text(loc("holding.office.rent", eurH(o.rent)))
                .font(Theme.font(11.5, .semibold))
                .foregroundStyle(HoldingLux.expense)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 4)
            if open {
                Text(loc("holding.officeIsOpen"))
                    .font(Theme.font(15, .heavy, condensed: true))
                    .foregroundStyle(HoldingLux.income)
            } else if let r = need {
                HStack(alignment: .top, spacing: 7) {
                    Image(systemName: "lock.fill").font(.system(size: 11, weight: .bold))
                    Text(loc("holding.officeLocked", r.title))
                        .font(Theme.font(12, .semibold))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(HoldingLux.title)
                .padding(.horizontal, 9).padding(.vertical, 7)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(HoldingLux.border.opacity(0.35), in: RoundedRectangle(cornerRadius: 11))
            } else {
                HoldingPill(title: loc("holding.openOffice", eurH(o.cost)), style: .gold, enabled: h.cash >= o.cost) {
                    store.act { g in _ = g.openOffice(o) }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(HoldingLux.card, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(open ? Theme.coral : HoldingLux.border, lineWidth: 2))
        .compositingGroup()
        .shadow(color: HoldingLux.border, radius: 0, y: 4)
    }
}

/// Colors of the holding's sheets: the prototype's light `#hqBody` (cream sheet, white cards, ink text).
enum HoldingLux {
    static let background = Theme.paper
    static let text = Theme.ink
    static let heading = Theme.ink
    static let title = Theme.ink
    static let sub = Theme.ink2
    static let card = Color.white
    static let cell = Color(hex: "#f1edf8")
    static let border = Theme.line
    static let accent = Theme.coral
    static let income = Theme.green
    static let expense = Theme.red
    static let incomeBar = Color(hex: "#3ad07a")
    static let expenseBar = Color(hex: "#ff6b55")
    static let chip = Color(hex: "#1b7d47")
}

/// Button on the holding sheets: light (`glass`), coral, ink, or the deal button (`gold`, coral like the prototype's `.dcta`).
struct HoldingPill: View {
    enum Style { case glass, coral, ink, gold }
    let title: String
    var style: Style = .glass
    var enabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.font(16, .heavy, condensed: true))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 14)
                .frame(minHeight: 40)
                .foregroundStyle(style == .glass ? Theme.ink : enabled ? Color.white : Theme.offText)
                .background(enabled || style == .glass ? background : AnyShapeStyle(Theme.offFill), in: RoundedRectangle(cornerRadius: 13))
                .compositingGroup()
                .shadow(color: enabled ? shadow : Color(hex: "#c9c1da"), radius: 0, y: 3)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled || style != .glass ? 1 : 0.55)
    }

    private var background: AnyShapeStyle {
        switch style {
        case .glass: AnyShapeStyle(HoldingLux.cell)
        case .coral, .gold: AnyShapeStyle(Theme.coral)
        case .ink: AnyShapeStyle(Theme.ink)
        }
    }

    private var shadow: Color {
        switch style {
        case .glass: HoldingLux.border
        case .coral, .gold: Color(hex: "#c7381a")
        case .ink: Color(hex: "#17122f")
        }
    }
}

// MARK: - Cash flow

/// Holding cash and the last 14 days of income and expenses.
struct HoldingCashBox: View {
    let holding: Holding

    var body: some View {
        let days = Array(holding.history.suffix(14))
        let income = days.reduce(0) { $0 + $1.income }
        let expense = days.reduce(0) { $0 + $1.expense }
        let net = income - expense
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 0) {
                Text(loc("holding.cash"))
                    .font(Theme.font(13))
                    .opacity(0.75)
                Text(eurH(holding.cash))
                    .font(Theme.font(36, .heavy, condensed: true))
                    .foregroundStyle(HoldingLux.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            HStack(spacing: 6) {
                total(loc("holding.income"), "+" + eurH(income), HoldingLux.income)
                total(loc("holding.expenses"), "−" + eurH(expense), HoldingLux.expense)
                total(loc("holding.net"), (net >= 0 ? "+" : "−") + eurH(abs(net)), HoldingLux.text)
            }
            // v140: the offices' rent and staff, a daily expense of its own
            if holding.officeRent > 0 {
                HStack(alignment: .firstTextBaseline) {
                    Text(loc("holding.rentLine"))
                        .font(Theme.font(12.5))
                    Spacer(minLength: 6)
                    Text("−" + loc("holding.perDayValue", eurH(holding.officeRent)))
                        .font(Theme.font(16, .heavy, condensed: true))
                        .foregroundStyle(HoldingLux.expense)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(HoldingLux.expense.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                .accessibilityElement(children: .combine)
            }
            legend
            if days.isEmpty {
                Text(loc("holding.chartEmpty"))
                    .font(Theme.font(13))
                    .opacity(0.6)
                    .padding(.vertical, 8)
            } else {
                HoldingCashChart(days: days)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HoldingLux.card, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(HoldingLux.border, lineWidth: 2))
    }

    private func total(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(Theme.font(11.5))
                .opacity(0.7)
                .lineLimit(1)
            Text(value)
                .font(Theme.font(19, .heavy, condensed: true))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HoldingLux.cell, in: RoundedRectangle(cornerRadius: 12))
    }

    private var legend: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(loc("holding.last14"))
                .font(Theme.font(12, .bold))
            legendLine(HoldingLux.incomeBar, loc("holding.legendIncome"))
            legendLine(HoldingLux.expenseBar, loc("holding.legendExpense", percent(holding.expenseRate)))
        }
        .opacity(0.75)
    }

    private func legendLine(_ color: Color, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 9, height: 9)
            Text(text)
                .font(Theme.font(12))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Daily bars: income above the zero line, expenses below. The scale follows ordinary days
/// (3 × the median of non-zero values); one-off amounts above it are clipped with a cut mark.
struct HoldingCashChart: View {
    let days: [Holding.Day]
    @State private var picked: Int? = nil

    private let slots = 14
    private let pad: CGFloat = 6

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                Canvas { ctx, size in
                    draw(&ctx, size)
                }
                .contentShape(Rectangle())
                .gesture(SpatialTapGesture().onEnded { value in
                    let i = index(atX: value.location.x, width: geo.size.width)
                    picked = i == picked ? nil : i
                })
            }
            .frame(height: 150)
            // VoiceOver swipes up and down through the days; the value reads the picked (or latest) day.
            .accessibilityElement()
            .accessibilityLabel(loc("a11y.holding.chart"))
            .accessibilityValue(tip(picked ?? days.count - 1) ?? "")
            .accessibilityAdjustableAction { dir in
                guard !days.isEmpty else { return }
                let i = picked ?? days.count - 1
                switch dir {
                case .increment: picked = min(i + 1, days.count - 1)
                case .decrement: picked = max(i - 1, 0)
                @unknown default: break
                }
            }
            if let i = picked, let t = tip(i) {
                Text(t)
                    .font(Theme.font(12, .semibold))
                    .opacity(0.85)
                    .accessibilityHidden(true)
            }
        }
    }

    /// "Day 12 · income … · expenses … · net …" for one bar.
    private func tip(_ i: Int) -> String? {
        guard days.indices.contains(i) else { return nil }
        let d = days[i], net = d.income - d.expense
        return loc("holding.chartTip", num(d.day), eurH(d.income), eurH(d.expense), (net >= 0 ? "+" : "−") + eurH(abs(net)))
    }

    /// The largest amount a bar shows in full.
    private var scaleMax: Double {
        let values = days.flatMap { [$0.income, $0.expense] }.filter { $0 > 0 }.sorted()
        let median = values.isEmpty ? 1 : values[values.count / 2]
        return Double(max(1, min(max(values.last ?? 1, 1), median * 3)))
    }

    private func slotWidth(_ width: CGFloat) -> CGFloat { (width - pad * 2) / CGFloat(slots) }

    private func index(atX x: CGFloat, width: CGFloat) -> Int? {
        let slot = Int(((x - pad) / slotWidth(width)).rounded(.down))
        let i = slot - (slots - days.count)
        return days.indices.contains(i) ? i : nil
    }

    private func draw(_ ctx: inout GraphicsContext, _ size: CGSize) {
        let height = size.height
        let mid = height * 0.56
        let bw = slotWidth(size.width)
        let top = mid - 12, bottom = height - mid - 14
        let maxValue = scaleMax

        var axis = Path()
        axis.move(to: CGPoint(x: pad, y: mid))
        axis.addLine(to: CGPoint(x: size.width - pad, y: mid))
        ctx.stroke(axis, with: .color(Color(hex: "#d9cfe6")), lineWidth: 1)

        for (i, d) in days.enumerated() {
            let x = pad + CGFloat(slots - days.count + i) * bw + 3
            let w = max(2, bw - 6)
            let corner = min(4, w / 2)
            let hi = CGFloat(min(1, Double(d.income) / maxValue)) * top
            let he = CGFloat(min(1, Double(d.expense) / maxValue)) * bottom
            if i == picked {
                ctx.fill(Path(roundedRect: CGRect(x: x - 2, y: 0, width: w + 4, height: height - 12), cornerRadius: 4),
                         with: .color(Theme.ink.opacity(0.06)))
            }
            if hi > 0.5 {
                ctx.fill(Path(roundedRect: CGRect(x: x, y: mid - 1 - hi, width: w, height: hi), cornerRadius: corner),
                         with: .color(HoldingLux.incomeBar))
            }
            if he > 0.5 {
                ctx.fill(Path(roundedRect: CGRect(x: x, y: mid + 1, width: w, height: he), cornerRadius: corner),
                         with: .color(HoldingLux.expenseBar))
            }
            if Double(d.income) > maxValue { cut(&ctx, x: x, width: w, y: mid - 1 - hi + 6) }
            if Double(d.expense) > maxValue { cut(&ctx, x: x, width: w, y: mid + he - 12) }
        }

        if let first = days.first, let last = days.last {
            let color = Color(hex: "#8a82a6")
            ctx.draw(Text(loc("hud.day", num(first.day))).font(Theme.font(10)).foregroundColor(color),
                     at: CGPoint(x: pad, y: height - 1), anchor: .bottomLeading)
            ctx.draw(Text(loc("hud.day", num(last.day))).font(Theme.font(10)).foregroundColor(color),
                     at: CGPoint(x: size.width - pad, y: height - 1), anchor: .bottomTrailing)
        }
    }

    /// Two slanted strokes across a bar that runs off the scale.
    private func cut(_ ctx: inout GraphicsContext, x: CGFloat, width w: CGFloat, y: CGFloat) {
        var p = Path()
        p.move(to: CGPoint(x: x - 1, y: y + 2))
        p.addLine(to: CGPoint(x: x + w + 1, y: y - 2))
        p.move(to: CGPoint(x: x - 1, y: y + 6))
        p.addLine(to: CGPoint(x: x + w + 1, y: y + 2))
        ctx.stroke(p, with: .color(Color.white), lineWidth: 2)
    }
}

// MARK: - Deal cards

struct HoldingDealCard: View {
    let art: HoldingArt.Kind
    let kicker: String
    let title: String
    let detail: String
    let chips: [String]
    var price: Int?
    var cta = ""
    var enabled = true
    var lockNote: String?
    /// How the price adds up ("€4,000 a day × 30 days"), under the price.
    var priceNote: String?
    /// Status line of a running deal; replaces the price and button.
    var active: String?
    /// A running deal you can break: the button's title, its explanation, and what it costs.
    var breakTitle: String?
    var breakNote: String?
    var breakEnabled = true
    var breakAction: (() -> Void)?
    /// v140: a line over the region rows (the wait for the next festival).
    var rowsNote: String?
    /// v136: one row per region you own (TV, billboards); replaces the price and button.
    var regionRows: [HoldingRegionRow] = []
    let action: () -> Void
    @State private var confirmBreak = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                HoldingArt(kind: art)
                    .frame(width: 48, height: 48)
                    .frame(width: 64, height: 64)
                    .background(HoldingLux.cell, in: RoundedRectangle(cornerRadius: 16))
                info
            }
            footer
        }
        .padding(14)
        .background(HoldingLux.card, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20)
            .strokeBorder(active != nil || regionRows.contains(where: \.on) ? Theme.green : HoldingLux.border, lineWidth: 2))
        .compositingGroup()
        .shadow(color: HoldingLux.border, radius: 0, y: 4)
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(kicker)
                .font(Theme.font(12, .heavy, condensed: true))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(HoldingLux.accent)
            Text(title)
                .font(Theme.font(21, .heavy, condensed: true))
                .foregroundStyle(HoldingLux.title)
                .fixedSize(horizontal: false, vertical: true)
            Text(detail)
                .font(Theme.font(13))
                .foregroundStyle(HoldingLux.sub)
                .fixedSize(horizontal: false, vertical: true)
            HoldingChipFlow(spacing: 5) {
                ForEach(chips.indices, id: \.self) { i in
                    Text(chips[i])
                        .font(Theme.font(11.5, .bold))
                        .foregroundStyle(HoldingLux.chip)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Theme.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var footer: some View {
        VStack(alignment: .leading, spacing: 6) {
            HoldingDash()
                .stroke(HoldingLux.border, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                .frame(height: 1)
            if !regionRows.isEmpty {
                if let rowsNote {
                    Text(rowsNote)
                        .font(Theme.font(12.5, .semibold))
                        .foregroundStyle(HoldingLux.sub)
                }
                ForEach(regionRows) { HoldingRegionRowView(row: $0) }
            } else if let active {
                Text(active)
                    .font(Theme.font(14, .heavy))
                    .foregroundStyle(Theme.green)
                if let breakTitle, let breakAction {
                    Button { confirmBreak = true } label: {
                        Text(breakTitle)
                            .font(Theme.font(14, .heavy))
                            .foregroundStyle(Theme.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.red.opacity(0.5), lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    .disabled(!breakEnabled)
                    .opacity(breakEnabled ? 1 : 0.45)
                    // v122.5: the game's own card, not the system dialog
                    .modifier(GameAlert(shown: $confirmBreak, title: breakTitle, message: breakNote ?? "",
                                        primary: loc("holding.shape.breakNo"), secondary: loc("holding.shape.breakYes"),
                                        onSecondary: breakAction, cover: true))
                    if let breakNote {
                        Text(breakNote)
                            .font(Theme.font(12))
                            .foregroundStyle(HoldingLux.sub)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            } else if let price {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(eurH(price))
                            .font(Theme.font(24, .heavy, condensed: true))
                            .foregroundStyle(HoldingLux.text)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        if let priceNote {
                            Text(priceNote)
                                .font(Theme.font(12.5, .semibold))
                                .foregroundStyle(HoldingLux.sub)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                    }
                    Spacer(minLength: 4)
                    HoldingPill(title: cta, style: .gold, enabled: enabled, action: action)
                }
                if let lockNote {
                    Text(lockNote)
                        .font(Theme.font(12))
                        .foregroundStyle(HoldingLux.sub)
                }
            }
        }
    }
}

/// v136: a region's line in a per-region campaign card: its name, how its campaign stands, and its own buy button.
struct HoldingRegionRow: Identifiable {
    let region: RegionID
    let here: Bool
    let status: String
    let on: Bool
    let price: Int
    /// The button shows (no campaign running or waiting); `enabled` also needs the holding's cash.
    let buyable: Bool
    let enabled: Bool
    let cta: String
    let action: () -> Void
    var id: RegionID { region }
}

struct HoldingRegionRowView: View {
    let row: HoldingRegionRow

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(row.region.title)
                        .font(Theme.font(16, .heavy, condensed: true))
                        .foregroundStyle(HoldingLux.title)
                    Text(row.region.currency)
                        .font(Theme.font(11, .bold))
                        .foregroundStyle(HoldingLux.sub)
                    if row.here {
                        Text(loc("holding.row.here"))
                            .font(Theme.font(11, .heavy))
                            .foregroundStyle(Theme.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Theme.green.opacity(0.12), in: Capsule())
                    }
                }
                Text(row.status)
                    .font(Theme.font(12.5, row.on ? .heavy : .semibold))
                    .foregroundStyle(row.on ? Theme.green : HoldingLux.sub)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            if row.buyable {
                HoldingPill(title: eurH(row.price), style: .gold, enabled: row.enabled, action: row.action)
                    .accessibilityLabel(loc("holding.row.a11y", row.region.title, row.cta))
                    .accessibilityValue(eurH(row.price))
            }
        }
        .padding(.vertical, 2)
    }
}

private struct HoldingDash: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return p
    }
}

/// Lays chips out in rows, wrapping when a row is full.
struct HoldingChipFlow: Layout {
    var spacing: CGFloat = 5

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, widest: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x > 0 && x + s.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            widest = max(widest, x + s.width)
            x += s.width + spacing
            rowHeight = max(rowHeight, s.height)
        }
        return CGSize(width: min(widest, maxWidth), height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x > bounds.minX && x + s.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            v.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(s))
            x += s.width + spacing
            rowHeight = max(rowHeight, s.height)
        }
    }
}

/// Code-drawn art for the deal cards (64×64 artboard, after the prototype's SVGs).
struct HoldingArt: View {
    enum Kind { case tv, star, billboard, lab, record, jersey, worldGames, shape(AdShape), documentary, radar, composite, pacific, globe, festival, foundation }
    let kind: Kind

    var body: some View {
        Canvas { ctx, size in
            let k = size.width / 64
            switch kind {
            case .tv: drawTV(&ctx, k)
            case .star: drawStar(&ctx, k)
            case .billboard: drawBillboard(&ctx, k)
            case .lab: drawLab(&ctx, k)
            case .record: drawRecord(&ctx, k)
            case .jersey: drawJersey(&ctx, k)
            case .worldGames: drawWorldGames(&ctx, k)
            case .shape(let s): AdShapeArt.draw(&ctx, s, center: CGPoint(x: 32 * k, y: 32 * k), size: 56 * k)
            case .documentary: drawDocumentary(&ctx, k)
            case .radar: drawRadar(&ctx, k)
            case .composite: drawComposite(&ctx, k)
            case .pacific: drawPacific(&ctx, k)
            case .globe: drawGlobe(&ctx, k)
            case .festival: drawLineArt(&ctx, k, Self.festivalArt)
            case .foundation: drawLineArt(&ctx, k, Self.foundationArt)
            }
        }
        .accessibilityHidden(true)
    }

    private static let gold = Color(hex: "#ffc23d")
    private static let teal = Color(hex: "#3ad0c0")

    private func pt(_ x: CGFloat, _ y: CGFloat, _ k: CGFloat) -> CGPoint { CGPoint(x: x * k, y: y * k) }

    private func svg(_ d: String, _ k: CGFloat) -> Path { HezarfenAvatar.svgPath(d).applying(CGAffineTransform(scaleX: k, y: k)) }

    /// v122.7: a red jersey with a gold collar and a white sponsor band (`INVEST_ART.jersey`).
    private func drawJersey(_ ctx: inout GraphicsContext, _ k: CGFloat) {
        ctx.fill(svg("M22 10 L14 14 L6 24 L14 30 L18 26 L18 56 L46 56 L46 26 L50 30 L58 24 L50 14 L42 10 C40 15 36 17 32 17 C28 17 24 15 22 10 Z", k), with: .color(Color(hex: "#e5432f")))
        ctx.stroke(svg("M22 10 C24 15 28 17 32 17 C36 17 40 15 42 10", k), with: .color(Self.gold), lineWidth: 2.5 * k)
        ctx.fill(Path(roundedRect: rect(22, 30, 20, 9, k), cornerRadius: 2 * k), with: .color(.white))
        ctx.stroke(line([(26, 34.5), (38, 34.5)], k), with: .color(Color(hex: "#2b2350")), style: StrokeStyle(lineWidth: 2.4 * k, lineCap: .round))
    }

    /// v122.7: five hot-air balloons over a stadium, in the order of the Olympic rings (`INVEST_ART.wg`).
    private func drawWorldGames(_ ctx: inout GraphicsContext, _ k: CGFloat) {
        ctx.fill(svg("M4 56 C14 48 50 48 60 56 L60 62 L4 62 Z", k), with: .color(Color(hex: "#5a4a8a")))
        ctx.stroke(svg("M10 56 C20 51 44 51 54 56", k), with: .color(Self.gold), style: StrokeStyle(lineWidth: 2 * k, dash: [3 * k, 3 * k]))
        let balloons: [(CGFloat, CGFloat, String)] = [(13, 14, "#2b7fd6"), (32, 14, "#2b2350"), (51, 14, "#e5432f"), (22.5, 29, "#ffc23d"), (41.5, 29, "#1fa35a")]
        let wicker = Color(hex: "#8a5a2e")
        for (x, y, hex) in balloons {
            ctx.fill(envelope(x, y, 7.5, k), with: .color(Color(hex: hex)))
            ctx.fill(envelope(x, y, 3, k), with: .color(.white.opacity(0.18)))
            ctx.stroke(line([(x - 2, y + 9), (x - 1.6, y + 12)], k), with: .color(wicker), lineWidth: 0.8 * k)
            ctx.stroke(line([(x + 2, y + 9), (x + 1.6, y + 12)], k), with: .color(wicker), lineWidth: 0.8 * k)
            ctx.fill(Path(roundedRect: rect(x - 2, y + 12, 4, 3.5, k), cornerRadius: 0.6 * k), with: .color(wicker))
        }
    }

    // v137: the new investments (`INVEST_ART.doc`, `.radar`, `.comp`, `.pacific`)

    /// A clapperboard with a balloon on its screen.
    private func drawDocumentary(_ ctx: inout GraphicsContext, _ k: CGFloat) {
        let dark = Color(hex: "#1f1b2e")
        ctx.fill(Path(roundedRect: rect(8, 22, 48, 34, k), cornerRadius: 4 * k), with: .color(dark))
        ctx.fill(svg("M8 14 L54 6 L56 14 L10 22 Z", k), with: .color(.white))
        ctx.stroke(svg("M16 12.6 L22 19.5 M27 10.7 L33 17.6 M38 8.8 L44 15.7", k), with: .color(dark), lineWidth: 4 * k)
        ctx.fill(svg("M32 27 C38 27 42 31.5 42 37 C42 42 38 45.5 35.5 48 L28.5 48 C26 45.5 22 42 22 37 C22 31.5 26 27 32 27 Z", k), with: .color(Color(hex: "#ff5e3a")))
        ctx.fill(svg("M32 27 C34 27 35 31.5 35 37 C35 42 33.5 45.5 33 48 L31 48 C30.5 45.5 29 42 29 37 C29 31.5 30 27 32 27 Z", k), with: .color(Self.gold))
        ctx.fill(Path(roundedRect: rect(29.5, 49, 5, 4, k), cornerRadius: 1 * k), with: .color(Color(hex: "#c98a5a")))
    }

    /// A weather radar: rings, a sweep and two echoes.
    private func drawRadar(_ ctx: inout GraphicsContext, _ k: CGFloat) {
        ctx.fill(Path(ellipseIn: rect(8, 10, 48, 48, k)), with: .color(Color(hex: "#12324a")))
        ctx.stroke(Path(ellipseIn: rect(16, 18, 32, 32, k)), with: .color(Self.teal.opacity(0.6)), lineWidth: 1.5 * k)
        ctx.stroke(Path(ellipseIn: rect(24, 26, 16, 16, k)), with: .color(Self.teal.opacity(0.6)), lineWidth: 1.5 * k)
        ctx.fill(svg("M32 34 L32 10 C40 10 48.5 14.5 52.8 22 Z", k), with: .color(Self.teal.opacity(0.45)))
        ctx.stroke(line([(32, 34), (52.8, 22)], k), with: .color(Self.teal), style: StrokeStyle(lineWidth: 2.5 * k, lineCap: .round))
        ctx.fill(Path(ellipseIn: rect(40, 41, 6, 6, k)), with: .color(Self.gold))
        ctx.fill(Path(ellipseIn: rect(19.8, 23.8, 4.4, 4.4, k)), with: .color(Color(hex: "#ff5e3a")))
    }

    /// A composite basket under an efficient burner's flame.
    private func drawComposite(_ ctx: inout GraphicsContext, _ k: CGFloat) {
        ctx.fill(svg("M32 6 C37 13 41 17 41 23 C41 28 37 32 32 32 C27 32 23 28 23 23 C23 17 27 13 32 6 Z", k), with: .color(Color(hex: "#ff5e3a")))
        ctx.fill(svg("M32 15 C35 19 37 21.5 37 24.5 C37 27.3 34.8 29.5 32 29.5 C29.2 29.5 27 27.3 27 24.5 C27 21.5 29 19 32 15 Z", k), with: .color(Self.gold))
        let steel = Color(hex: "#8d93a0")
        ctx.fill(Path(roundedRect: rect(22, 33, 20, 5, k), cornerRadius: 2 * k), with: .color(steel))
        ctx.stroke(svg("M24 38 L20 44 M40 38 L44 44", k), with: .color(steel), lineWidth: 2 * k)
        ctx.fill(polygon([(16, 44), (48, 44), (45, 58), (19, 58)], k), with: .color(Color(hex: "#2b2350")))
        ctx.stroke(svg("M24 44 L22 58 M32 44 L32 58 M40 44 L42 58", k), with: .color(Color(hex: "#4a4270")), lineWidth: 1.4 * k)
        ctx.stroke(svg("M18 49 L46 49 M19 54 L45 54", k), with: .color(Self.teal), lineWidth: 1.6 * k)
    }

    /// The round-the-world flight: a globe, a dashed route over it and a balloon (`INVEST_ART.globe`).
    private func drawGlobe(_ ctx: inout GraphicsContext, _ k: CGFloat) {
        ctx.fill(Path(ellipseIn: rect(9, 15, 42, 42, k)), with: .color(Color(hex: "#2b7fd6")))
        ctx.stroke(svg("M30 15 C21 21 21 51 30 57 M30 15 C39 21 39 51 30 57 M9 36 L51 36 M12 26 L48 26 M12 46 L48 46", k),
                   with: .color(.white.opacity(0.45)), lineWidth: 1.6 * k)
        ctx.stroke(svg("M8 30 C9 17 22 8 38 9", k), with: .color(Self.gold),
                   style: StrokeStyle(lineWidth: 2.4 * k, lineCap: .round, dash: [3 * k, 4 * k]))
        ctx.fill(svg("M50 4 C55 4 58 8 58 12 C58 16 55 18 53 20 L47 20 C45 18 42 16 42 12 C42 8 45 4 50 4 Z", k), with: .color(Color(hex: "#ff5e3a")))
        ctx.fill(Path(roundedRect: rect(48, 21, 4, 3.5, k), cornerRadius: 1 * k), with: .color(Color(hex: "#8a5a2e")))
    }

    /// A balloon over two rows of ocean waves.
    private func drawPacific(_ ctx: inout GraphicsContext, _ k: CGFloat) {
        let wicker = Color(hex: "#8a5a2e")
        ctx.fill(svg("M32 4 C41 4 47 11 47 19 C47 27 41 32 37 36 L27 36 C23 32 17 27 17 19 C17 11 23 4 32 4 Z", k), with: .color(Color(hex: "#2b7fd6")))
        ctx.fill(svg("M32 4 C35 4 37 11 37 19 C37 27 35 32 34 36 L30 36 C29 32 27 27 27 19 C27 11 29 4 32 4 Z", k), with: .color(.white.opacity(0.3)))
        ctx.stroke(svg("M28 36 L29 38 M36 36 L35 38", k), with: .color(wicker), lineWidth: 1.2 * k)
        ctx.fill(Path(roundedRect: rect(28, 38, 8, 6, k), cornerRadius: 1.5 * k), with: .color(wicker))
        let wave = StrokeStyle(lineWidth: 3 * k, lineCap: .round)
        ctx.stroke(svg("M4 52 C9 48 13 48 18 52 C23 56 27 56 32 52 C37 48 41 48 46 52 C51 56 55 56 60 52", k), with: .color(Self.teal), style: wave)
        ctx.stroke(svg("M4 60 C9 56 13 56 18 60 C23 64 27 64 32 60 C37 56 41 56 46 60 C51 64 55 64 60 60", k), with: .color(Color(hex: "#2b5ab8")), style: wave)
    }

    /// A balloon envelope centred at (x, y), half as wide as `w`, its mouth 9 below the centre.
    private func envelope(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ k: CGFloat) -> Path {
        let m = min(3, w * 0.4)
        var p = Path()
        p.move(to: pt(x, y - 8, k))
        p.addCurve(to: pt(x + w, y, k), control1: pt(x + w * 2 / 3, y - 8, k), control2: pt(x + w, y - 4.5, k))
        p.addCurve(to: pt(x + 2, y + 9, k), control1: pt(x + w, y + 4, k), control2: pt(x + m, y + 7, k))
        p.addLine(to: pt(x - 2, y + 9, k))
        p.addCurve(to: pt(x - w, y, k), control1: pt(x - m, y + 7, k), control2: pt(x - w, y + 4, k))
        p.addCurve(to: pt(x, y - 8, k), control1: pt(x - w, y - 4.5, k), control2: pt(x - w * 2 / 3, y - 8, k))
        p.closeSubpath()
        return p
    }

    /// A record balloon with a pressurised capsule and a climbing red line (`INVEST_ART.rec`).
    private func drawRecord(_ ctx: inout GraphicsContext, _ k: CGFloat) {
        ctx.fill(HezarfenAvatar.svgPath("M32 6 C41 6 47 13 47 22 C47 30 41 36 37 40 L27 40 C23 36 17 30 17 22 C17 13 23 6 32 6 Z").applying(CGAffineTransform(scaleX: k, y: k)), with: .color(Self.gold))
        ctx.fill(polygon([(27, 40), (37, 40), (36, 46), (28, 46)], k), with: .color(Color(hex: "#c9ccd2")))
        ctx.fill(Path(roundedRect: rect(25, 47, 14, 10, k), cornerRadius: 5 * k), with: .color(Color(hex: "#c9ccd2")))
        ctx.fill(Path(ellipseIn: rect(32.4, 49.4, 5.2, 5.2, k)), with: .color(Color(hex: "#2b5ab8")))
        var line = Path()
        line.move(to: pt(8, 58, k)); line.addLine(to: pt(16, 48, k)); line.addLine(to: pt(22, 53, k)); line.addLine(to: pt(30, 41, k))
        ctx.stroke(line, with: .color(Color(hex: "#e5432f")), style: StrokeStyle(lineWidth: 3 * k, lineCap: .round, lineJoin: .round))
    }

    private func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ k: CGFloat) -> CGRect {
        CGRect(x: x * k, y: y * k, width: w * k, height: h * k)
    }

    private func polygon(_ points: [(CGFloat, CGFloat)], _ k: CGFloat) -> Path {
        var p = Path()
        for (i, xy) in points.enumerated() {
            if i == 0 { p.move(to: pt(xy.0, xy.1, k)) } else { p.addLine(to: pt(xy.0, xy.1, k)) }
        }
        p.closeSubpath()
        return p
    }

    private func line(_ points: [(CGFloat, CGFloat)], _ k: CGFloat) -> Path {
        var p = Path()
        for (i, xy) in points.enumerated() {
            if i == 0 { p.move(to: pt(xy.0, xy.1, k)) } else { p.addLine(to: pt(xy.0, xy.1, k)) }
        }
        return p
    }

    private func drawTV(_ ctx: inout GraphicsContext, _ k: CGFloat) {
        let frame = Path(roundedRect: rect(6, 12, 52, 34, k), cornerRadius: 6 * k)
        ctx.fill(frame, with: .color(Color(hex: "#1f1b2e")))
        ctx.stroke(frame, with: .color(Self.gold), lineWidth: 3 * k)
        ctx.fill(Path(roundedRect: rect(11, 17, 42, 24, k), cornerRadius: 3 * k), with: .color(Theme.coral))
        ctx.fill(polygon([(26, 23), (38, 29), (26, 35)], k), with: .color(.white))
        let stand = StrokeStyle(lineWidth: 3 * k, lineCap: .round)
        ctx.stroke(line([(24, 52), (40, 52)], k), with: .color(Self.gold), style: stand)
        ctx.stroke(line([(32, 46), (32, 52)], k), with: .color(Self.gold), style: stand)
    }

    /// v140: line art in the 24-unit grid of the office landmarks (prototype `INVEST_ART.hf` / `.fdn`), each part in its
    /// own colour: the festival's two balloons over bunting, the foundation's bronze balloon on a plinth between laurels.
    static let festivalArt: [(String, String)] = [
        ("M9 2.5 C5.7 2.5 3.5 5 3.5 8 C3.5 11 6.3 13 7.6 15 L10.4 15 C11.7 13 14.5 11 14.5 8 C14.5 5 12.3 2.5 9 2.5 Z M7.8 15 L8 16.6 L10 16.6 L10.2 15 "
            + "M9 2.5 C7.6 4.5 7.2 6.5 7.2 8.2 C7.2 10.5 7.9 12.7 8.3 15 M9 2.5 C10.4 4.5 10.8 6.5 10.8 8.2 C10.8 10.5 10.1 12.7 9.7 15", "#ff5e3a"),
        ("M18.2 6 C16.4 6 15.3 7.3 15.3 8.8 C15.3 10.3 16.7 11.3 17.4 12.4 L19 12.4 C19.7 11.3 21.1 10.3 21.1 8.8 C21.1 7.3 20 6 18.2 6 Z "
            + "M17.5 12.4 L17.6 13.6 L18.8 13.6 L18.9 12.4", "#14a39a"),
        ("M1.5 18.5 C8 21 16 21 22.5 18.5 M4.6 19.4 L5.6 22 L6.8 19.9 M10.6 20.3 L11.8 22.8 L13 20.3 M17 19.9 L18.2 22 L19.2 19.4", "#e0a020"),
    ]
    static let foundationArt: [(String, String)] = [
        ("M6.5 20.5 L17.5 20.5 M8 20.5 L8 16.4 L16 16.4 L16 20.5 M7 16.4 L17 16.4", "#8d93a0"),
        ("M12 3 C9.3 3 7.6 5 7.6 7.4 C7.6 9.8 9.8 11.4 10.8 13 L13.2 13 C14.2 11.4 16.4 9.8 16.4 7.4 C16.4 5 14.7 3 12 3 Z M11 13 L11.2 16.4 M13 13 L12.8 16.4 "
            + "M12 3 C11 5 10.8 6.5 10.8 8 C10.8 9.8 11.2 11.4 11.5 13 M12 3 C13 5 13.2 6.5 13.2 8 C13.2 9.8 12.8 11.4 12.5 13", "#c98a1a"),
        ("M4.6 18 C2.8 15 2.9 11.4 4.8 8.6 M3.9 14.6 L2.4 13.8 M3.8 12 L2.4 10.9 M4.3 9.7 L3.4 8.3 "
            + "M19.4 18 C21.2 15 21.1 11.4 19.2 8.6 M20.1 14.6 L21.6 13.8 M20.2 12 L21.6 10.9 M19.7 9.7 L20.6 8.3", "#4f9a4a"),
    ]

    private func drawLineArt(_ ctx: inout GraphicsContext, _ k: CGFloat, _ parts: [(String, String)]) {
        let s = k * 64 / 24
        for (d, col) in parts {
            ctx.stroke(svg(d, s), with: .color(Color(hex: col)), style: StrokeStyle(lineWidth: 1.5 * s, lineCap: .round, lineJoin: .round))
        }
    }

    private func drawStar(_ ctx: inout GraphicsContext, _ k: CGFloat) {
        let points: [(CGFloat, CGFloat)] = [(32, 6), (39, 21), (55, 23), (43, 34), (46, 50), (32, 42), (18, 50), (21, 34), (9, 23), (25, 21)]
        ctx.fill(polygon(points, k), with: .color(Self.gold))
        ctx.fill(Path(ellipseIn: rect(26, 23, 12, 12, k)), with: .color(Color(hex: "#fff3c4")))
    }

    private func drawBillboard(_ ctx: inout GraphicsContext, _ k: CGFloat) {
        let legs = StrokeStyle(lineWidth: 3 * k, lineCap: .round)
        let grey = Color(hex: "#c9c1db")
        ctx.stroke(line([(18, 38), (18, 56)], k), with: .color(grey), style: legs)
        ctx.stroke(line([(46, 38), (46, 56)], k), with: .color(grey), style: legs)
        ctx.stroke(line([(12, 56), (52, 56)], k), with: .color(grey), style: legs)
        ctx.fill(Path(roundedRect: rect(6, 10, 52, 28, k), cornerRadius: 3 * k), with: .color(Self.gold))
        // A little balloon on the poster.
        ctx.fill(Path(ellipseIn: rect(25, 13, 14, 16, k)), with: .color(Theme.coral))
        ctx.fill(Path(ellipseIn: rect(30, 13, 4, 16, k)), with: .color(Color(hex: "#fffaf3")))
        ctx.fill(Path(roundedRect: rect(29.5, 30, 5, 4, k), cornerRadius: 1 * k), with: .color(Theme.ink))
    }

    private func drawLab(_ ctx: inout GraphicsContext, _ k: CGFloat) {
        let liquid: [(CGFloat, CGFloat)] = [(17, 44), (47, 44), (51, 51), (49, 54), (15, 54), (13, 51)]
        ctx.fill(polygon(liquid, k), with: .color(Self.teal))
        let glass = StrokeStyle(lineWidth: 3 * k, lineCap: .round, lineJoin: .round)
        ctx.stroke(line([(24, 8), (40, 8)], k), with: .color(Self.gold), style: glass)
        let flask: [(CGFloat, CGFloat)] = [(27, 8), (27, 24), (12, 50), (16, 57), (48, 57), (52, 50), (37, 24), (37, 8)]
        ctx.stroke(line(flask, k), with: .color(Self.gold), style: glass)
        ctx.fill(Path(ellipseIn: rect(25.5, 35.5, 5, 5, k)), with: .color(Self.teal))
        ctx.fill(Path(ellipseIn: rect(34.2, 31.2, 3.6, 3.6, k)), with: .color(Self.teal))
    }
}
