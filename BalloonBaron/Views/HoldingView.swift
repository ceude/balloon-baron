import SwiftUI
import BalloonBaronCore

/// The holding's boardroom: cash flow, money from the region, regions, campaigns and city offices.
/// A desk of the holding office and the part of the holding it opens. Names: `hq.<rawValue>`.
enum HoldingUnit: String, CaseIterable, Identifiable {
    case board, window, marketing, deals, research, offices, records, shapes
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
            tvCard(game)
            billboardCard(s)
        }
        if unit == .deals {
            sectionTitle(loc("hq.face"))
            celebrityCard(s)
        }
        if unit == .research {
            sectionTitle(loc("hq.lab"))
            researchCard(s)
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

    /// Desk 5: a sponsored world record. The first attempt at each always works; the odds shown apply to beating your own.
    private func recordCard(_ k: RecordAttempt, _ s: GameState) -> some View {
        let h = s.holding, run = h.record, now = run?.kind == k, set = s.recordSet(k)
        let chips = [loc("holding.chip.prep", num(k.days)), loc("holding.chip.odds", percent(k.odds)), loc("holding.chip.allDemandLasting", percent(k.boost))]
        let lock: String? = !s.recordsOpen ? loc("holding.rec.lockNote") : run != nil && !now ? loc("holding.rec.oneAtATime") : nil
        return HoldingDealCard(art: .record, kicker: loc("holding.rec.kicker"), title: k.title, detail: k.detail, chips: chips,
                               price: k.cost, cta: loc(set ? "holding.rec.again" : "holding.rec.cta"),
                               enabled: lock == nil && h.cash >= k.cost, lockNote: lock ?? (set ? loc("holding.rec.yours") : nil),
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

    /// The holding's own goals; all six make you World Baron.
    private func holdingGoals(_ s: GameState) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle(loc(s.holding.worldBaron != nil ? "hgoal.worldTitle" : "hgoal.title"))
            ForEach(HoldingGoal.allCases, id: \.self) { g in
                let d = s.done(g)
                HStack(spacing: 10) {
                    Image(systemName: d ? "checkmark.square.fill" : "square")
                        .foregroundStyle(d ? HoldingLux.income : HoldingLux.sub)
                    Text(g.title).font(Theme.font(15, .semibold)).strikethrough(d)
                    Spacer()
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(g.title)
                .accessibilityValue(d ? loc("goals.finished") : "")
            }
            hint(loc("hgoal.hint"))
        }
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
        let hintKey = s.region.fx != 1 ? "holding.withdrawHintFx" : "holding.withdrawHint"
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
        return HStack(alignment: .center, spacing: 10) {
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
        .padding(12)
        .background(HoldingLux.card, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(HoldingLux.border, lineWidth: 2))
        .compositingGroup()
        .shadow(color: HoldingLux.border, radius: 0, y: 3)
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
            var text = loc("holding.autoSub", eurH(auto.today != 0 ? auto.today : Int(expected.rounded())))
            if let open = auto.issue { text += " " + loc("map.problemSub", open.kind.title) }
            return text
        }
        let start = Rules.startCash.formatted(.currency(code: r.currency).precision(.fractionLength(0)))
        return loc("holding.enterSub", eurH(Holding.entryFee), start)
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
            tvCard(game)
            celebrityCard(game.state)
            billboardCard(game.state)
            researchCard(game.state)
        }
    }

    private func tvCard(_ game: Game) -> some View {
        let s = game.state, h = s.holding, d = s.day
        let on = h.tvUntil > d
        let lock: String? = !on && !game.canRunTV ? loc("holding.tv.lock", num(h.tvCooldown - d)) : nil
        let chips = [loc("holding.chip.allDemand", percent(0.2)), loc("holding.chip.days", num(Holding.tvDays)),
                     loc("holding.chip.stars", s.region.title, starsValue(0.4))]
        return HoldingDealCard(art: .tv, kicker: loc("holding.tv.kicker"), title: loc("holding.tv.title"),
                               detail: loc("holding.tv.desc"), chips: chips, price: h.tvCost, cta: loc("holding.tv.cta"),
                               enabled: lock == nil && h.cash >= h.tvCost, lockNote: lock,
                               active: on ? loc("holding.tv.active", num(h.tvUntil - d)) : nil,
                               action: { store.act { g in _ = g.runTVCampaign() } })
    }

    private func celebrityCard(_ s: GameState) -> some View {
        let h = s.holding, d = s.day
        let star: Celebrity? = (h.celebrity?.until ?? 0) > d ? h.celebrity : nil
        let detail = star.map { loc("holding.celeb.descActive", celebrityName($0.index)) } ?? loc("holding.celeb.desc")
        let active = star.map { loc("holding.celeb.active", celebrityName($0.index), num($0.until - d)) }
        let chips = [loc("holding.chip.allDemand", percent(0.1)), loc("holding.chip.days", num(h.celebrityDays)),
                     loc("holding.chip.stars", s.region.title, starsValue(0.6))]
        return HoldingDealCard(art: .star, kicker: loc("holding.celeb.kicker"), title: loc("holding.celeb.title"),
                               detail: detail, chips: chips, price: h.celebrityCost, cta: loc("holding.celeb.cta"),
                               enabled: h.cash >= h.celebrityCost, active: active,
                               action: { store.act { g in _ = g.signCelebrity() } })
    }

    private func billboardCard(_ s: GameState) -> some View {
        let h = s.holding, d = s.day
        let until = h.billboards[s.region] ?? 0
        let chips = [loc("holding.chip.regionDemand", s.region.title, percent(0.1)), loc("holding.chip.days", num(Holding.billboardDays))]
        return HoldingDealCard(art: .billboard, kicker: loc("holding.bb.kicker"), title: loc("holding.bb.title"),
                               detail: loc("holding.bb.desc", s.region.title), chips: chips, price: Holding.billboardCost,
                               cta: loc("holding.bb.cta"), enabled: h.cash >= Holding.billboardCost,
                               active: until > d ? loc("holding.bb.active", num(until - d)) : nil,
                               action: { store.act { g in _ = g.runBillboards() } })
    }

    private func researchCard(_ s: GameState) -> some View {
        let h = s.holding
        let lv = h.research
        let next: Holding.ResearchLevel? = lv < Holding.researchLevels.count ? Holding.researchLevels[lv] : nil
        let chips = [loc("holding.chip.life", num(s.envelopeLife), num(next?.life ?? s.envelopeLife)), loc("holding.chip.permanent")]
        return HoldingDealCard(art: .lab, kicker: loc("holding.lab.kicker"), title: loc("holding.lab.title"),
                               detail: loc(next == nil ? "holding.lab.descDone" : "holding.lab.desc"), chips: chips,
                               price: next?.cost, cta: loc("holding.lab.cta", num(lv + 1)),
                               enabled: h.cash >= (next?.cost ?? Int.max),
                               active: next == nil ? loc("holding.lab.done", num(lv)) : nil,
                               action: { store.act { g in _ = g.fundResearch() } })
    }

    // MARK: Offices

    private func officesSection(_ s: GameState) -> some View {
        let h = s.holding
        let offices = Office.allCases
        let count = offices.filter { h.has($0) }.count
        let text = count == offices.count
            ? loc("holding.officesAll", percent(Holding.allOfficesExpenseRate), percent(Holding.expenseRate))
            : loc("holding.officesHint", percent(Holding.expenseRate), percent(Holding.allOfficesExpenseRate))
        let rows = Array(stride(from: 0, to: offices.count, by: 2))
        return VStack(alignment: .leading, spacing: 10) {
            sectionTitle(loc("holding.offices", "\(count)/\(offices.count)"))
            hint(text)
            Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                ForEach(rows, id: \.self) { i in
                    GridRow {
                        officeCard(offices[i], h)
                        if i + 1 < offices.count {
                            officeCard(offices[i + 1], h)
                        } else {
                            Color.clear
                        }
                    }
                }
            }
        }
    }

    private func officeCard(_ o: Office, _ h: Holding) -> some View {
        let open = h.has(o)
        return VStack(alignment: .leading, spacing: 5) {
            Text(o.icon)
                .font(.system(size: 30))
            Text(o.title)
                .font(Theme.font(19, .heavy, condensed: true))
                .foregroundStyle(HoldingLux.title)
            Text(o.perk)
                .font(Theme.font(12))
                .foregroundStyle(HoldingLux.sub)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 4)
            if open {
                Text(loc("holding.officeIsOpen"))
                    .font(Theme.font(15, .heavy, condensed: true))
                    .foregroundStyle(HoldingLux.income)
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
                .foregroundStyle(style == .glass ? Theme.ink : Color.white)
                .background(background, in: RoundedRectangle(cornerRadius: 13))
                .compositingGroup()
                .shadow(color: shadow, radius: 0, y: 3)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.45)
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
            .strokeBorder(active != nil ? Theme.green : HoldingLux.border, lineWidth: 2))
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
            if let active {
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
                    .confirmationDialog(breakTitle, isPresented: $confirmBreak, titleVisibility: .visible) {
                        Button(loc("holding.shape.breakYes"), role: .destructive, action: breakAction)
                        Button(loc("holding.shape.breakNo"), role: .cancel) {}
                    } message: {
                        Text(breakNote ?? "")
                    }
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
    enum Kind { case tv, star, billboard, lab, record, shape(AdShape) }
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
            case .shape(let s): AdShapeArt.draw(&ctx, s, center: CGPoint(x: 32 * k, y: 32 * k), size: 56 * k)
            }
        }
        .accessibilityHidden(true)
    }

    private static let gold = Color(hex: "#ffc23d")
    private static let teal = Color(hex: "#3ad0c0")

    private func pt(_ x: CGFloat, _ y: CGFloat, _ k: CGFloat) -> CGPoint { CGPoint(x: x * k, y: y * k) }

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
