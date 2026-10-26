import SwiftUI
import Observation
import BalloonBaronCore

/// Office pages opened from the side buttons on the home screen.
enum Page: String, Identifiable {
    case fleet, crew, bank, market, goals, holding, map, workshop
    var id: String { rawValue }
}

/// A rival's offer waiting for an answer.
struct DealOffer: Equatable {
    var rival: Int
    var bankrupt: Bool
}

/// Owns the running game and persists it after every change.
@Observable
final class GameStore {
    var game: Game?
    /// The report shown after a day ends.
    var report: DayReport?
    /// Hezarfen's message currently on screen.
    var hezarfen: HezMessage?
    /// Chapter ceremony or merger news on screen; these come before Hezarfen.
    var chapter: ChapterNews?
    var merge: MergeNews?
    /// A rival wants one of your pilots (after Hezarfen, like the prototype).
    var poach: PoachOffer?
    /// A struggling rival offers its company, or a bankrupt one its fleet.
    var deal: DealOffer?
    /// The purchase loan's terms card for a rival up for sale.
    var buyLoan: DealOffer?
    /// The menu (save code, new game, sound) and the popularity chart.
    var showMenu = false
    var showRepChart = false
    /// The office page on screen.
    var page: Page?
    /// Asks the home town to glide into the holding tower before the office opens.
    var hqDive = false
    /// Section the page scrolls to when it opens from the town.
    var pageSection: PageSection?
    /// The town's card for the agencies and for buildings that open later.
    var townCard: TownCard?
    /// A parked region whose problem the player is deciding.
    var issueRegion: RegionID?
    /// A problem waiting in the region you're in: the camera goes to your office first, the card follows.
    var issueScene = false
    /// The dream-flight intro runs at every launch, like the prototype.
    var showIntro = true
    /// Passengers are being gathered (the seat-filling screen before take-off).
    var collecting = false
    /// Passengers riding with you while the flight scene runs.
    var flightPax: Int?
    /// The morning paper on screen (biggest story first).
    var paper: [PaperItem]?
    /// A morning event waiting for your answer.
    var morningEvent: MorningEvent?
    /// Hezarfen's rescue plan, shown when cash first goes below zero.
    var showRescue = false
    /// The flagship you fly is in repair: the offer to fly another balloon meanwhile (v110).
    var showTempFlag = false
    /// v114: a rival's order for the workshop, shown in the morning.
    var showFactoryOrder = false
    /// The Balloon Show's card (v111).
    var showShowCard = false
    /// Ask the home screen to open the price sheet (Hezarfen's price lesson).
    var showPriceSheet = false
    /// A new postcard, and the album from the menu.
    var postcard: Achievement?
    var showAlbum = false
    /// A building's upgrade card, the bazaar, and the purchase sheet for one of its items.
    var buildingCard: Building?
    var showBazaar = false
    var storeItem: StoreItem?
    /// Passengers queueing in the town while they gather (shared by the card and the town canvas).
    let collectScene = CollectScene()
    /// Take-off was pressed: the collect card fades while the jeeps come (observed, unlike `collectScene`).
    var leaving = false
    /// The night between two days, with what lights it up.
    struct Night: Equatable { var event: NightEvent? }
    var night: Night?
    /// The short flight across the world map when the region changes (`showTravel`).
    struct Travel: Equatable { let from: RegionID, to: RegionID }
    var travel: Travel?

    /// Anything already covering the home screen; the next popup waits for it.
    private var busy: Bool {
        showIntro || collecting || hezarfen != nil || chapter != nil || merge != nil || poach != nil || deal != nil || showMenu
            || townCard != nil || report != nil || flightPax != nil || page != nil || issueRegion != nil || paper != nil
            || morningEvent != nil || showRescue || showTempFlag || showFactoryOrder || showShowCard || postcard != nil || showAlbum || buildingCard != nil || showBazaar || storeItem != nil
            || night != nil || travel != nil || issueScene || buyLoan != nil
    }

    init() {
        // After launches that crashed before settling, open quietly: no intro and none of the waiting popups;
        // after one more, from yesterday's save. Anything that ran for 15 seconds counts as settled.
        let crashes = LaunchGuard.begin()
        if var state = SaveVault.load(preferPrevious: crashes >= 3) {
            if crashes >= 2 {
                showIntro = false
                state.chapterNews = nil
                state.mergeNews = nil
                state.paper = nil
                state.eventDue = false
                state.newPostcards = []
                state.hezQueue = []
                state.local.poach = nil
            }
            var g = Game(state: state)
            g.startDay()
            game = g
            currentRegion = state.region
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) { LaunchGuard.settled() }
        Task { @MainActor [weak self] in Shop.shared.start { k, bought in self?.purchased(k, bought: bought) } }
        #if DEBUG
        applyDemoArguments()
        #endif
    }

    var state: GameState? { game?.state }

    func newGame(company: String, colors: [String]) {
        var g = Game(company: company, colors: colors)
        g.startDay()
        game = g
        save()
        // Items bought in an earlier game belong to the Apple ID: they come back.
        Task { await Shop.shared.restoreEntitlements() }
        showNextHezarfen()
    }

    /// Writes happen in order on a background queue, so encoding never stalls a transition.
    private let saveQueue = DispatchQueue(label: "balloonbaron.save", qos: .utility)
    @ObservationIgnored private var pendingSave: DispatchWorkItem?

    /// Saves half a second later: quick changes (a held price button) make one write. The game itself lives in
    /// memory, so nothing waits for the disk; `flushSave` writes at once when it matters.
    func save() {
        pendingSave?.cancel()
        let item = DispatchWorkItem { [weak self] in self?.flushSave() }
        pendingSave = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: item)
    }

    /// Writes now (taking off, at the end of a day, leaving the app).
    func flushSave() {
        pendingSave?.cancel()
        pendingSave = nil
        guard let state = game?.state else { return }
        saveQueue.async { SaveVault.write(state) }
    }

    /// Runs an action on the game and saves.
    func act(_ f: (inout Game) -> Void) {
        guard var g = game else { return }
        let from = g.state.region
        f(&g)
        let chapterDone = g.finishChapterNow()
        game = g
        if g.state.region != from { travel = Travel(from: from, to: g.state.region) }
        currentRegion = g.state.region
        save()
        if chapterDone {
            if let n = g.state.chapterNews { Telemetry.chapterNow(g.state, n) }
            celebrateChapterSoon()
        }
    }

    /// The chapter's goals were just met: the ceremony comes up right away, over an open office page too,
    /// unless a flight, the report, the night or another card is on screen; then it waits its turn.
    private func celebrateChapterSoon() {
        DispatchQueue.main.async { [self] in
            guard let c = game?.state.chapterNews, chapter == nil, !showIntro, !collecting, flightPax == nil, report == nil,
                  night == nil, travel == nil, hezarfen == nil, morningEvent == nil, deal == nil, merge == nil, paper == nil else { return }
            chapter = c
            act { $0.state.chapterNews = nil }
        }
    }

    /// Shows the next popup in the prototype's order (`nextPopup`): chapter ceremony, merger news, the morning
    /// paper, the rescue plan, a morning event, a new postcard, then Hezarfen, a poaching rival and deals.
    func showNextHezarfen() {
        guard !busy, let g = game else { return }
        let s = g.state
        if let c = s.chapterNews {
            chapter = c
            act { $0.state.chapterNews = nil }
        } else if let m = s.mergeNews {
            merge = m
            act { $0.state.mergeNews = nil }
        } else if let p = s.paper, !p.isEmpty {
            act { paper = $0.readPaper() }
            SoundEngine.shared.play(.tick)
        } else if g.rescueDue {
            act { $0.markRescueShown() }
            showRescue = true
            Haptics.warning()
        } else if !g.tempFlagshipCandidates.isEmpty {
            showTempFlag = true
        } else if s.eventDue == true {
            var e: MorningEvent?
            act { e = $0.drawMorningEvent() }
            if let e { morningEvent = e } else { showNextHezarfen() }
        } else if s.newPostcards?.isEmpty == false {
            act { postcard = $0.nextPostcard() }
            SoundEngine.shared.play(.fanfare)
            Haptics.success()
        } else if s.factoryOrderDue {
            act { $0.markFactoryOrderSeen() }
            showFactoryOrder = true
        } else if !s.hezQueue.isEmpty {
            act { $0.clearRescue() }
            act { hezarfen = $0.nextHezarfen() }
        } else if g.liveIssue != nil && s.local.issueSeen != s.day {
            // A problem that waited for you here opens by itself once a day.
            act { _ = $0.liveIssueCardDue() }
            showLiveIssue()
        } else if let p = s.poach {
            // The offer is shown once; it leaves the state so rivals can try again later.
            act { $0.state.poach = nil }
            if s.pilots.contains(where: { $0.id == p.pilotID }), s.rivals.indices.contains(p.rivalIndex), s.rivals[p.rivalIndex].alive {
                poach = p
            } else {
                showNextHezarfen()
            }
        } else if let d = g.pendingDeal {
            act { $0.markDealSeen(d.rival, bankrupt: d.bankrupt) }
            deal = DealOffer(rival: d.rival, bankrupt: d.bankrupt)
        }
    }

    /// Keep the pilot by matching the rival's wage, or let them go.
    func answerPoach(_ offer: PoachOffer, match: Bool) {
        act { g in
            g.state.poach = offer
            g.answerPoach(match: match)
        }
        poach = nil
        showNextHezarfen()
    }

    /// Accept or decline a rival's company or fleet.
    func answerDeal(_ d: DealOffer, accept: Bool) {
        act { g in
            if accept {
                if d.bankrupt { _ = g.buyBankruptFleet(d.rival) } else { _ = g.takeOver(d.rival) }
            } else {
                g.declineDeal(d.rival, bankrupt: d.bankrupt)
            }
        }
        deal = nil
        showNextHezarfen()
    }

    /// Buy with the purchase loan, from its terms card.
    func buyWithLoan(_ d: DealOffer) {
        act { _ = $0.buyWithLoan(d.rival, bankrupt: d.bankrupt) }
        buyLoan = nil
        deal = nil
        showNextHezarfen()
    }

    func closeMenu() {
        showMenu = false
        showNextHezarfen()
    }

    /// Wipes the save and starts over from the intro.
    func startOver() {
        pendingSave?.cancel()
        pendingSave = nil
        saveQueue.async { SaveVault.wipe() }
        game = nil
        currentRegion = .cap
        report = nil
        hezarfen = nil
        chapter = nil
        merge = nil
        poach = nil
        deal = nil
        page = nil
        issueRegion = nil
        collecting = false
        flightPax = nil
        showMenu = false
        showRepChart = false
        showIntro = true
    }

    /// A save code to continue on another device (base64 JSON), and loading one.
    var saveCode: String? {
        guard let state = game?.state, let data = try? JSONEncoder().encode(state) else { return nil }
        return data.base64EncodedString()
    }

    @discardableResult
    func load(code: String) -> Bool {
        guard let data = Data(base64Encoded: code.trimmingCharacters(in: .whitespacesAndNewlines)),
              let state = try? JSONDecoder().decode(GameState.self, from: data) else { return false }
        var g = Game(state: state)
        g.startDay()
        game = g
        currentRegion = state.region
        save()
        showMenu = false
        showNextHezarfen()
        return true
    }

    func dismissHezarfen() {
        hezarfen = nil
        showNextHezarfen()
    }

    func closePaper() {
        paper = nil
        showNextHezarfen()
    }

    func answerEvent(_ e: MorningEvent, accept: Bool) {
        act { g in
            if let o = g.answerEvent(e, accept: accept) { g.state.hezQueue.insert(.eventOutcome(o), at: 0) }
        }
        morningEvent = nil
        showNextHezarfen()
    }

    /// A move on the rescue card; the card closes once cash is back above zero.
    func rescueMove(_ f: (inout Game) -> Void) {
        var done = false
        act { g in
            f(&g)
            done = g.rescueStepDone()
        }
        if done { closeRescue() }
    }

    func closeRescue() {
        showRescue = false
        showNextHezarfen()
    }

    /// The morning's order card: take it (the line is the rival's for a few days) or leave it.
    func answerFactoryOrder(_ yes: Bool) {
        act { g in if yes { _ = g.acceptFactoryOrder() } else { g.declineFactoryOrder() } }
        showFactoryOrder = false
        showNextHezarfen()
    }

    /// Yes flies `id` until the flagship is repaired; no (nil) leaves the flagship and lets pilots fly the rest.
    /// Either way the offer is made once per repair.
    func answerTempFlag(_ id: Int?) {
        act { g in
            g.markTempFlagshipAsked()
            if let id { g.flyTempFlagship(id) }
        }
        showTempFlag = false
        showNextHezarfen()
    }

    func closePostcard() {
        postcard = nil
        showNextHezarfen()
    }

    /// The free gift taken from the bazaar.
    func takeGift(_ k: StoreItem) {
        act { $0.grantStoreItem(k) }
        SoundEngine.shared.play(.coin)
        storeItem = nil
    }

    /// The App Store says an item is the player's: a fresh purchase (`bought`), or one restored to this game.
    func purchased(_ k: StoreItem, bought: Bool) {
        guard let s = state, !s.owned(k) else { return }
        act { $0.grantStoreItem(k) }
        if bought {
            Telemetry.bought(k, day: s.day)
            SoundEngine.shared.play(.coin)
            Haptics.success()
            if storeItem == k { storeItem = nil }
        }
    }

    /// Hezarfen's bazaar lesson ends at the bazaar.
    func dismissHezarfen(openBazaar: Bool, openShow: Bool = false, openPrice: Bool = false) {
        hezarfen = nil
        if openBazaar { showBazaar = true } else if openShow { showShowCard = true } else if openPrice { showPriceSheet = true } else { showNextHezarfen() }
    }

    func closeShowCard() {
        showShowCard = false
        showNextHezarfen()
    }

    func dismissPopup() {
        if let c = chapter, c.region == state?.region { act { $0.chapterStarted(c.index + 1) } }
        chapter = nil
        merge = nil
        showNextHezarfen()
    }

    // MARK: Town

    /// A tapped building: its office page (scrolled to its section), its card, or the goals.
    /// The holding opens like the prototype's `openHQ`: from the home screen the town first glides to the tower
    /// and dives into it (`HomeTownView` watches `hqDive`), then the office floor opens.
    func openHolding() {
        if page == nil, morningEvent == nil, !collecting { hqDive = true } else { page = .holding }
    }

    func tapTown(_ tap: TownTap) {
        switch tap {
        case .page(.holding, _):
            openHolding()
        case .page(let p, let section):
            pageSection = section
            page = p
        case .card(let c):
            townCard = c
        case .goals:
            page = .goals
        case .building(let b):
            buildingCard = b
        case .bazaar:
            showBazaar = true
        }
    }

    func closeBuildingCard() {
        buildingCard = nil
        showNextHezarfen()
    }

    func closeBazaar() {
        showBazaar = false
        showNextHezarfen()
    }

    func closeTownCard() {
        townCard = nil
        showNextHezarfen()
    }

    /// Scrolls a page that opened from the town to the building's section.
    func scrollToSection(_ proxy: ScrollViewProxy) {
        guard let s = pageSection else { return }
        pageSection = nil
        DispatchQueue.main.async { proxy.scrollTo(s, anchor: .top) }
    }

    /// `issueScene`: the camera flies to your office (pilots asking for a raise wave placards there) and the
    /// decision card comes up three and a half seconds later.
    func showLiveIssue() {
        guard let g = game, g.liveIssue != nil else { return }
        let r = g.state.region
        page = nil
        collectScene.from = nil
        issueScene = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { [self] in
            guard issueScene, game?.liveIssue != nil, game?.state.region == r else { issueScene = false; return }
            issueRegion = r
        }
    }

    func closePage() {
        pageSection = nil
        page = nil
        issueRegion = nil
        showNextHezarfen()
    }

    /// Moves to another region (or into a new one) and closes the office pages.
    func goTo(_ r: RegionID) {
        if let s = state, !s.owns(r), s.needsPack(r) { storeItem = .egypt; return }
        page = nil
        issueRegion = nil
        act { g in
            if g.state.owns(r) { g.switchRegion(r) } else { _ = g.enterRegion(r) }
        }
        showNextHezarfen()
    }

    func startCollect() {
        collectScene.reset()
        leaving = false
        collecting = true
    }

    /// Take-off: the card goes, the jeeps come and go (about 3.5 s), then the flight.
    func leaveCollect() {
        guard collectScene.leaveDate == nil else { return }
        guard collectAnimation else { fly(); return }
        collectScene.leaveDate = Date()
        withAnimation(.easeOut(duration: 0.3)) { leaving = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { [weak self] in self?.fly() }
    }

    /// The intro balloon has left the screen.
    func finishIntro() {
        showIntro = false
        showNextHezarfen()
    }

    func cancelCollect() {
        collecting = false
        leaving = false
    }

    func fly(skip: Bool = false) {
        collecting = false
        leaving = false
        var selfPax: Int?
        act { selfPax = $0.launch(skip: skip) }
        flushSave()
        if let selfPax { flightPax = selfPax } else { endDay(nil) }
    }

    func endDay(_ result: FlightResult?) {
        flightPax = nil
        var r: DayReport?
        act { r = $0.finishDay(flight: result) }
        flushSave()
        if let s = state {
            GameCenter.report(s)
            if let r { Telemetry.dayEnded(s, r) }
        }
        report = r
    }

    /// Settings switch for the night scene (v110); off, the night still passes (its event makes the paper).
    static let nightSceneKey = "nightScene"
    /// Settings switch for the boarding scene (v110): passengers walking up and the jeeps. Off, the card still shows
    /// where the passengers came from and who flies, filled at once, and take-off follows without the jeeps.
    static let collectSceneKey = "collectScene"
    var collectAnimation: Bool { UserDefaults.standard.object(forKey: Self.collectSceneKey) as? Bool ?? true }

    /// "Go to the morning" on the report plays the night first, unless the player switched the night scene off.
    func closeReport() {
        var ev: NightEvent?
        act { ev = $0.startNight() }
        // A paid Balloon Show always plays; other nights follow the setting.
        let show: Bool = { if case .show? = ev { return true }; return false }()
        if !show && UserDefaults.standard.object(forKey: Self.nightSceneKey) as? Bool == false {
            report = nil
            endNight()
            return
        }
        night = Night(event: ev)
        report = nil
    }

    /// The night's camera, handed to the home town as the morning comes (`HomeTownView` takes it).
    var morningCamera: TownViewport?

    func endNight(camera: TownViewport? = nil) {
        morningCamera = camera
        night = nil
        act { $0.startDay() }
        showNextHezarfen()
    }

    #if DEBUG
    func resetForTesting() { startOver() }
    #endif
}
