import SwiftUI

@main
struct BalloonBaronApp: App {
    @State private var store = GameStore()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        Theme.registerFonts()
        SoundEngine.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .preferredColorScheme(.light)
                .onChange(of: scenePhase) { _, phase in
                    if phase != .active { store.flushSave() } else { Telemetry.opened(store.state) }
                    Telemetry.became(active: phase == .active)
                    if phase == .background {
                        LaunchGuard.settled()
                        Reminder.schedule(day: store.state?.day ?? 1)
                    }
                }
                .task { GameCenter.signIn { if let s = store.state { GameCenter.report(s) } } }
        }
    }
}

struct RootView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        ZStack {
            Theme.sky.ignoresSafeArea()
            // The town; once the opening film has landed it is already there under the film's last frame (v121.5).
            if store.game != nil && (!store.openingFilm || store.homeIntro != nil) {
                HomeView()
            }
            // A new company: the opening film (or the 2D setup without it), until it hands over to the town.
            if (store.game == nil || store.openingFilm) && !store.showIntro {
                OpeningGate()
            }
            // v121.10: the opening film again from Settings, over the running game
            if store.replayingOpening && store.game != nil {
                OpeningReplay()
            }
            if store.collecting && store.game != nil {
                CollectView()
                    .transition(.move(edge: .bottom))
            }
            if let p = store.page, store.game != nil {
                PageFrame(fullBleed: p == .holding || p == .map) { page(p) }
                    .transition(.move(edge: .trailing))
            }
            if let c = store.townCard, store.game != nil {
                TownCardView(card: c)
                    .transition(.opacity)
            }
            if let r = store.issueRegion, store.game != nil {
                IssueView(region: r)
                    .transition(.opacity)
            }
            if let t = store.travel, store.game != nil {
                TravelView(travel: t)
                    .transition(.opacity)
                    .zIndex(50)
            }
            if store.auto != nil && store.night == nil {
                // v117: on autopilot a tap anywhere stops it.
                Color.clear.contentShape(Rectangle()).ignoresSafeArea()
                    .onTapGesture { store.stopAuto(.tapped) }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityLabel(loc("auto.stopA11y"))
            }
            if let n = store.autoNote, store.night == nil {
                AutopilotStrip(note: n)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 150)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
            if let c = store.chapter {
                ChapterView(news: c)
                    .transition(.opacity)
            }
            if let m = store.merge {
                MergeView(news: m)
                    .transition(.opacity)
            }
            if let p = store.poach {
                PoachView(offer: p)
                    .transition(.opacity)
            }
            if let d = store.deal {
                DealView(offer: d)
                    .transition(.opacity)
            }
            if let d = store.buyLoan, store.game != nil {
                BuyLoanView(offer: d)
                    .transition(.opacity)
            }
            if store.showRepChart {
                RepChartView()
                    .transition(.opacity)
            }
            if store.showMenu {
                MenuView()
                    .transition(.opacity)
            }
            if let p = store.paper {
                PaperView(items: p).transition(.opacity)
            }
            if let e = store.morningEvent {
                MorningEventView(event: e).transition(.move(edge: .bottom))
            }
            if store.showRescue {
                RescueView().transition(.opacity)
            }
            if store.showTempFlag {
                TempFlagView().transition(.opacity)
            }
            if store.showShowCard {
                ShowCardView().transition(.opacity)
            }
            if store.showGlowCard {
                GlowCardView().transition(.opacity)
            }
            if store.showFactoryOrder {
                FactoryOrderView().transition(.opacity)
            }
            if store.showTourOffer {
                TourOfferView().transition(.opacity)
            }
            if let b = store.hotelBargain {
                HotelBargainView(bargain: b).transition(.opacity)
            }
            if let h = store.hotelSale {
                HotelSaleView(hotel: h).transition(.opacity)
            }
            if let shots = store.showShots {
                ShowHighlightsView(shots: shots).transition(.opacity)
            }
            if let a = store.postcard {
                PostcardView(achievement: a).transition(.opacity)
            }
            if store.showAlbum {
                AlbumView().transition(.opacity)
            }
            if let b = store.buildingCard {
                BuildingCardView(building: b).transition(.opacity)
            }
            if store.showGuides && store.game != nil {
                GuideOfficeView().transition(.opacity)
            }
            if store.showAgency && store.game != nil {
                AgencyView().transition(.opacity)
            }
            if store.showBazaar {
                BazaarView().transition(.opacity)
            }
            if let k = store.storeItem, !store.studioOpen {
                StoreItemView(item: k).transition(.opacity)
            }
            if let m = store.hezarfen {
                HezarfenView(message: m, day: store.state?.day ?? 1) { store.dismissHezarfen(openBazaar: m == .tip(.bazaar), openShow: m == .tip(.show), openPrice: m == .tip(.price) || m == .tip(.price3)) }
                    .transition(.opacity)
            }
            if store.letter && store.game != nil {
                LetterView().transition(.opacity)
            }
            if let n = store.night {
                // It is already there when the report slides away (its own dusk falls inside it); the last of the
                // night fades slowly over the morning town (`dawnTick`).
                NightView(night: n)
                    .transition(.asymmetric(insertion: .identity, removal: .opacity.animation(.easeOut(duration: 1.4))))
                    .zIndex(5)
            }
            if store.showIntro {
                IntroView()
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .animation(.easeOut(duration: 0.25), value: store.hezarfen)
        .animation(.easeOut(duration: 0.25), value: store.page)
        .animation(.easeOut(duration: 0.25), value: store.issueRegion)
        .animation(.easeOut(duration: 0.25), value: store.townCard)
        .animation(.easeOut(duration: 0.25), value: store.chapter)
        .animation(.easeOut(duration: 0.25), value: store.merge)
        .animation(.easeOut(duration: 0.25), value: store.collecting)
        .animation(.easeOut(duration: 0.25), value: store.poach)
        .animation(.easeOut(duration: 0.25), value: store.deal)
        .animation(.easeOut(duration: 0.25), value: store.showMenu)
        .animation(.easeOut(duration: 0.25), value: store.showRepChart)
        .animation(.easeOut(duration: 0.25), value: store.paper)
        .animation(.easeOut(duration: 0.25), value: store.morningEvent)
        .animation(.easeOut(duration: 0.25), value: store.showRescue)
        .animation(.easeOut(duration: 0.25), value: store.showTempFlag)
        .animation(.easeOut(duration: 0.25), value: store.showShowCard)
        .animation(.easeOut(duration: 0.25), value: store.showGlowCard)
        .animation(.easeOut(duration: 0.25), value: store.postcard)
        .animation(.easeOut(duration: 0.25), value: store.showAlbum)
        .animation(.easeOut(duration: 0.25), value: store.buildingCard)
        .animation(.easeOut(duration: 0.25), value: store.showBazaar)
        .animation(.easeOut(duration: 0.25), value: store.storeItem)
        .animation(.easeInOut(duration: 0.6), value: store.night)
        .animation(.easeOut(duration: 0.25), value: store.showGuides)
        .animation(.easeOut(duration: 0.25), value: store.showAgency)
        .animation(.easeOut(duration: 0.25), value: store.letter)
        // v122: the tutorial that shows: day one's steps and the guided actions, over the town, its pages and cards
        .tutorialHost(minLineY: 104, present: { store.rootSpots = $0 },
                      alive: { store.guided != nil || store.homeFocus != nil || store.homeTutStep != nil },
                      frame: { store.rootTutFrame($0) },
                      onSkip: { store.skipTutorial() })
        // One cover for the flight and its report: the report slides up over the flight inside it, so the home
        // screen never flashes between two presentations.
        .fullScreenCover(isPresented: Binding(get: { store.flightPax != nil || store.report != nil }, set: { _ in })) {
            DayCover()
                .environment(store)
        }
    }

    @ViewBuilder
    private func page(_ p: Page) -> some View {
        switch p {
        case .fleet: FleetView()
        case .crew: CrewView()
        case .bank: BankView()
        case .market: MarketView()
        case .goals: GoalsView()
        case .holding: HoldingOfficeView()
        case .map: WorldMapView()
        case .workshop: WorkshopView()
        }
    }
}

/// The flight and then the day's report, in one full-screen cover.
private struct DayCover: View {
    @Environment(GameStore.self) private var store
    /// The flight stays under the report while it slides up, then goes.
    @State private var flightShown = false

    var body: some View {
        ZStack {
            if store.flightPax != nil || flightShown {
                FlightView()
                    .onAppear { flightShown = true }
            }
            if let r = store.report {
                ReportView(report: r)
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
            }
        }
        .animation(.easeOut(duration: 0.35), value: store.report == nil)
        .onChange(of: store.report == nil) { _, none in
            if !none { DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { flightShown = false } }
        }
    }
}

/// On an iPad the office pages open as a wide card over the dimmed town, so lines keep a readable length;
/// the holding office and the world map stay full screen. On an iPhone the page is the screen.
struct PageFrame<Content: View>: View {
    var fullBleed = false
    @ViewBuilder let content: () -> Content
    @Environment(\.horizontalSizeClass) private var width

    var body: some View {
        if width == .regular && !fullBleed {
            ZStack {
                Color(red: 27 / 255, green: 24 / 255, blue: 64 / 255).opacity(0.45)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {}
                content()
                    .frame(maxWidth: 720)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .shadow(color: .black.opacity(0.3), radius: 30, y: 12)
                    .padding(.vertical, 28)
                    .padding(.horizontal, 24)
            }
        } else {
            content()
        }
    }
}
