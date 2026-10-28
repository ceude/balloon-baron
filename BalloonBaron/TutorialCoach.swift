import SwiftUI
import BalloonBaronCore

// v122: Faz 1, the tutorial that shows (prototype `tutStep`, `tutHome`, `GUIDED`, `guideStart` / `guideTick`).
// Day one at home: the ticket price (lower it, watch the passengers go up), then "Collect passengers". When a building
// opens, Hezarfen's lesson becomes a guided action: the home camera glides to the building, it pulses, the page it
// opens scrolls to the one thing to do and lights it. The flight's steps live in `FlightModel`.

/// Asks the open page to bring a spot into view (`scrollIntoView`).
struct TutScroll: Equatable {
    let id: String
    let nonce: Int
}

/// The home town gliding to the building a guided action points at (`HOMEF`).
struct HomeFocus: Equatable {
    let id: String
    let t0: Date
    var out: Date?
    var tapped = false
    var active: Bool { out == nil }
}

/// Where the town drew the building it glides to (a circle, in screen points), written by the canvas every frame.
final class HomeFocusBox {
    var pos: CGRect?
}

/// One of Hezarfen's lessons shown, not told (`GA`).
struct GuidedAction: Equatable {
    let tip: Tip
    var t0 = Date()
    /// The furthest step reached (1-based) and the step on screen now (-1: none).
    var max = 0
    var cur = -2
    var t1 = Date()
    var rescrolled = false
    /// The button lit up can't be used yet: the line says why.
    var poor = false
    var curID: String?
    let n0: Counts

    struct Counts: Equatable { var balloons, pilots, hotels, guides, influencers: Int }

    struct Def {
        /// The town building the home camera glides to first.
        var bld: String?
        /// The spots to light, in order; the last one present on screen wins.
        var steps: [String]
        /// Done after this many seconds on the last step (nothing to buy).
        var look: Double?
        var poorKey = "tut.poor"
    }

    /// `GUIDED`: which lessons are shown, and how.
    static func def(_ t: Tip) -> Def? {
        switch t {
        case .insurance: return Def(steps: ["ga.insPill", "ga.insChips"], look: 2.5)
        case .goals: return Def(steps: ["ga.goals"])
        case .fleet: return Def(bld: "hangar", steps: ["ga.toFleet", "ga.fleet"])
        case .price: return Def(steps: ["pcard", "pMinus"])
        case .bank: return Def(bld: "bank", steps: ["ga.bank"], look: 3)
        case .crew: return Def(bld: "office", steps: ["ga.toCrew", "ga.hire"])
        case .market: return Def(bld: "mine", steps: ["ga.toMarket", "ga.hotel"], poorKey: "tut.poorHotel")
        case .guide: return Def(bld: "guide", steps: ["ga.guide"])
        case .agency: return Def(bld: "influ", steps: ["ga.influ"])
        case .bazaar: return Def(bld: "bazaar", steps: ["ga.gift", "ga.takeGift"])
        case .workshop: return Def(bld: "shop", steps: ["ga.workshop"])
        case .school: return Def(bld: "school", steps: ["ga.school"])
        default: return nil
        }
    }

    /// The prototype's lesson keys, for the telemetry signals (`ga_<lesson>_done`).
    static func name(_ t: Tip) -> String { t == .insurance ? "ins" : t.rawValue }
}

extension View {
    /// A spot a guided action may scroll to and light up (`data-tut`).
    func tutTarget(_ id: String, disabled: Bool = false) -> some View {
        tutSpot(id, disabled: disabled).id(id)
    }

    /// `tutTarget` on the one view of a list the guided action points at.
    @ViewBuilder func tutTargetIf(_ on: Bool, _ id: String, disabled: Bool = false) -> some View {
        if on { tutTarget(id, disabled: disabled) } else { self }
    }

    /// A page's scroll view follows the guided action to its button.
    func tutScrolling(_ proxy: ScrollViewProxy, _ store: GameStore) -> some View {
        onChange(of: store.tutScroll) { _, t in
            guard let t else { return }
            withAnimation(.easeOut(duration: 0.35)) { proxy.scrollTo(t.id, anchor: .center) }
        }
    }
}

/// "Yolcu topla" pulses while the day-one step points at it (`tutpulse`).
struct TutPulse: ViewModifier {
    let on: Bool
    func body(content: Content) -> some View {
        if on {
            TimelineView(.animation) { tl in
                let k = 0.5 - 0.5 * cos(tl.date.timeIntervalSinceReferenceDate / 1.1 * 2 * .pi)
                content
                    .shadow(color: Color(red: 1, green: 194 / 255, blue: 61 / 255).opacity(0.55 * k), radius: 6 + 10 * k)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(red: 1, green: 210 / 255, blue: 122 / 255).opacity(0.55 * k), lineWidth: 8 * k).padding(-4 * k))
            }
        } else {
            content
        }
    }
}

extension GameStore {
    // MARK: Steps

    /// `tutStep`: records a step once and sends its TelemetryDeck signal (`tutorial.<step>`, with the day).
    func tutStep(_ k: String) {
        guard let day = state?.day else { return }
        var new = false
        act { new = $0.tutorialStep(k) }
        if new { Telemetry.tutorial(k, day: day) }
    }

    /// "Skip": on a guided action only that one; otherwise the whole tutorial.
    func skipTutorial() {
        if guided != nil { guideEnd("skip"); return }
        guard let day = state?.day else { return }
        var new = false
        act { new = $0.skipTutorial() }
        if new { Telemetry.tutorial("skip", day: day) }
    }

    // MARK: Day one at home (`tutHome`)

    /// The day-one step at home: "price" until the price sheet has been closed once, then "go". v122.4: day 2's
    /// "price2" (raise the price on a busy day) until the sheet is closed after raising it.
    var homeTutStep: String? {
        guard let s = state, s.tutorialOn, auto == nil, guided == nil, s.region == .cap,
              s.flyingToday.contains(where: { s.isSelf($0) }) else { return nil }
        if s.day == 2 && !s.tutorialHas("price2") { return "price2" }
        guard s.day == 1 else { return nil }
        if !s.tutorialHas("price") { return "price" }
        if !s.tutorialHas("go") { return "go" }
        return nil
    }

    /// Nothing else on screen or still to come this morning (`nextPopup` has run to its end).
    var homeQuiet: Bool {
        guard let s = state, !busy, !priceSheetOpen, flightPax == nil, report == nil else { return false }
        return s.hezQueue.isEmpty && (s.paper ?? []).isEmpty && s.chapterNews == nil && s.mergeNews == nil
            && s.newPostcards?.isEmpty != false && s.eventDue != true
    }

    /// "Yolcu topla" pulses.
    var tutPulseGo: Bool { homeTutStep == "go" && homeQuiet }

    /// The price sheet came up or went (HomeView's own sheet).
    func priceSheet(open: Bool) {
        priceSheetOpen = open
        if open {
            if (homeTutStep == "price" || homeTutStep == "price2") && tutP0 == nil { tutP0 = state?.price }
        } else if homeTutStep == "price" {
            // On to "Yolcu topla", whether or not the price went down.
            tutStep("price")
        } else if homeTutStep == "price2", state?.tutorialHas("price2_up") == true {
            tutStep("price2")
        }
    }

    /// A price change on the sheet: going below where the lesson started counts as `price_low`.
    func tutPriceChanged() {
        if homeTutStep == "price2", let p0 = tutP0, let p = state?.price, p > p0, state?.tutorialHas("price2_up") == false,
           let est = game?.estimatedIncome(), est.seats > 0, est.pax >= est.seats {
            tutStep("price2_up") // v122.4: higher price, still a full basket
            return
        }
        guard homeTutStep == "price", let p0 = tutP0, let p = state?.price, p < p0, state?.tutorialHas("price_low") == false else { return }
        tutStep("price_low")
    }

    /// What the root presentation's layer shows: a guided action's spot, or the day-one step.
    func rootTutFrame(_ sp: TutSpots) -> TutFrame? {
        guard state != nil, flightPax == nil, report == nil, hezarfen == nil, travel == nil, night == nil, !showIntro,
              homeIntro == nil, !collecting, !openingFilm, !replayingOpening else { return nil }
        if let g = guided { return guideFrame(g, sp, sheet: false) }
        guard let k = homeTutStep, homeQuiet else { return nil }
        if k == "price" || k == "price2" {
            guard let h = sp.hole("pcard", pad: 4) else { return nil }
            return TutFrame(key: k, holes: [h], line: loc("tut." + k))
        }
        guard let h = sp.hole("go", pad: 5) else { return nil }
        return TutFrame(key: "go", holes: [h], line: loc("tut.go"))
    }

    /// What the price sheet's layer shows: the day-one price step, or the guided price lesson's − button.
    func sheetTutFrame(_ sp: TutSpots) -> TutFrame? {
        guard hezarfen == nil else { return nil }
        if let g = guided { return guideFrame(g, sp, sheet: true) }
        if homeTutStep == "price2", let s = state {
            if s.tutorialHas("price2_up") {
                let hs = [sp.hole("psOk", pad: 6), sp.hole("est", pad: 6)].compactMap { $0 }
                return TutFrame(key: "price2.up", holes: hs, arrow: .some(nil), line: loc("tut.price2Seen"))
            }
            let hs = [sp.hole("pPlus", pad: 6, round: true), sp.hole("est", pad: 6)].compactMap { $0 }
            return TutFrame(key: "price2", holes: hs, line: loc("tut.price2"))
        }
        guard homeTutStep == "price", let s = state else { return nil }
        if s.tutorialHas("price_low") {
            let hs = [sp.hole("psOk", pad: 6), sp.hole("est", pad: 6)].compactMap { $0 }
            return TutFrame(key: "price.low", holes: hs, arrow: .some(nil), line: loc("tut.priceSeen"))
        }
        let hs = [sp.hole("pMinus", pad: 6, round: true), sp.hole("est", pad: 6)].compactMap { $0 }
        return TutFrame(key: "price", holes: hs, line: loc("tut.price"))
    }

    private func guideFrame(_ g: GuidedAction, _ sp: TutSpots, sheet: Bool) -> TutFrame? {
        guard let def = GuidedAction.def(g.tip) else { return nil }
        var holes: [TutHole] = []
        if let id = g.curID {
            guard (id == "pMinus") == sheet, let h = sp.hole(id, pad: 6, round: id == "pMinus") else { return nil }
            holes = [h]
        } else if !sheet, let f = homeFocus, f.active, Date().timeIntervalSince(f.t0) > 0.6, let p = focusBox.pos {
            holes = [TutHole(rect: p, radius: p.width / 2)]
        } else {
            return nil
        }
        let line = g.poor ? loc(def.poorKey) : loc("tip.\(g.tip.rawValue).short")
        return TutFrame(key: "ga." + g.tip.rawValue + (g.poor ? ".poor" : ""), holes: holes, line: line, more: loc("hez.\(g.tip.rawValue)"))
    }

    // MARK: Guided actions (`GUIDED`)

    /// `guideOk`: a lesson is shown as a guided action from the home screen, when its building is in the town.
    func guideOK(_ t: Tip) -> Bool {
        guard let def = GuidedAction.def(t), let s = state, auto == nil, !collecting, flightPax == nil, report == nil else { return false }
        if let b = def.bld { return Town.buildings(s).contains { $0.id == b && $0.lv >= 0 } }
        return true
    }

    func startGuide(_ t: Tip) {
        guard let s = state else { return }
        guided = GuidedAction(tip: t, n0: .init(balloons: s.local.balloons.count, pilots: s.local.pilots.count, hotels: s.local.hotelDeals.count,
                                                guides: s.local.guideCount, influencers: s.local.influencerCount))
        startGuideTimer()
    }

    /// `guideEnd`: done, left (the page closed) or skipped; the morning's next card follows once the page is closed.
    func guideEnd(_ how: String) {
        guard let g = guided else { return }
        guided = nil
        tutStep("ga_\(GuidedAction.name(g.tip))_\(how)")
        if homeFocus?.active == true { homeFocus?.out = Date() }
        guideNext = true
        startGuideTimer()
    }

    private func startGuideTimer() {
        guard guideTimer == nil else { return }
        guideTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.guideTick()
        }
    }

    private func guideDone(_ g: GuidedAction, _ s: GameState) -> Bool {
        switch g.tip {
        case .goals: return g.max > 0 && page == .goals
        case .fleet: return s.local.balloons.count > g.n0.balloons
        case .price: return g.max >= 2 && !priceSheetOpen
        case .crew: return s.local.pilots.count > g.n0.pilots
        case .market: return s.local.hotelDeals.count > g.n0.hotels
        case .guide: return s.local.guideCount > g.n0.guides
        case .agency: return s.local.influencerCount > g.n0.influencers
        case .bazaar: return s.owned(.lanterns)
        case .workshop: return s.workshopDay != nil
        case .school: return s.local.school
        default: return false
        }
    }

    /// `guideTick`, ten times a second while a guided action (or its glide back, or the next card) is pending.
    private func guideTick() {
        let now = Date()
        if var g = guided, let s = state, let def = GuidedAction.def(g.tip) {
            if guideDone(g, s) {
                SoundEngine.shared.play(.coin)
                guideEnd("done")
                return
            }
            let spots = rootSpots.merging(priceSheetOpen ? sheetSpots : [:]) { a, _ in a }
            var idx = -1
            for i in stride(from: def.steps.count - 1, through: 0, by: -1) where spots[def.steps[i]] != nil { idx = i; break }
            let home = !busy && !priceSheetOpen
            if idx == -1 && g.max > 0 && home { guideEnd("left"); return }
            if idx >= 0 {
                g.max = Swift.max(g.max, idx + 1)
                if g.cur != idx {
                    // Bring it into view, and once more a moment later (the page may scroll itself to a heading).
                    g.cur = idx
                    g.t1 = now
                    g.rescrolled = false
                    tutScroll = TutScroll(id: def.steps[idx], nonce: (tutScroll?.nonce ?? 0) + 1)
                } else if !g.rescrolled && now.timeIntervalSince(g.t1) > 0.8 {
                    g.rescrolled = true
                    tutScroll = TutScroll(id: def.steps[idx], nonce: (tutScroll?.nonce ?? 0) + 1)
                }
                if let look = def.look, idx == def.steps.count - 1, now.timeIntervalSince(g.t1) > look {
                    guided = g
                    guideEnd("done")
                    return
                }
            } else {
                g.cur = -1
            }
            g.curID = idx >= 0 ? def.steps[idx] : nil
            g.poor = idx >= 0 && spots[def.steps[idx]] == true
            // The building step: the home camera glides to it while nothing else is open.
            let wantPan = def.bld != nil && idx == -1 && home && g.max == 0
            if wantPan, let b = def.bld, homeFocus?.active != true { homeFocus = HomeFocus(id: b, t0: now) }
            if !wantPan, homeFocus?.active == true { homeFocus?.out = now }
            if g != guided { guided = g }
        }
        if let f = homeFocus, let o = f.out, now.timeIntervalSince(o) > 0.7 { homeFocus = nil; focusBox.pos = nil }
        if guideNext && guided == nil && !busy && !priceSheetOpen {
            guideNext = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in self?.showNextHezarfen() }
        }
        if guided == nil && homeFocus == nil && !guideNext {
            guideTimer?.invalidate()
            guideTimer = nil
        }
    }

    /// A tap on the home town while it glides to a building: only that building opens.
    func homeFocusTap(_ p: CGPoint) {
        guard let f = homeFocus, f.active, !f.tapped, let pos = focusBox.pos, let s = state,
              let b = Town.buildings(s).first(where: { $0.id == f.id }) else { return }
        guard hypot(p.x - pos.midX, p.y - pos.midY) <= pos.width / 2 + 10 else { return }
        SoundEngine.shared.play(.click)
        homeFocus?.tapped = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) { [weak self] in self?.tapTown(b.tap) }
    }
}
