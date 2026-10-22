import SwiftUI

@main
struct BalloonBaronApp: App {
    @State private var store = GameStore()

    init() {
        Theme.registerFonts()
        SoundEngine.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .preferredColorScheme(.light)
        }
    }
}

struct RootView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        ZStack {
            Theme.sky.ignoresSafeArea()
            if store.game == nil {
                if !store.showIntro { SetupView() }
            } else {
                HomeView()
            }
            if store.collecting && store.game != nil {
                CollectView()
                    .transition(.move(edge: .bottom))
            }
            if let p = store.page, store.game != nil {
                page(p)
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
            if let a = store.postcard {
                PostcardView(achievement: a).transition(.opacity)
            }
            if store.showAlbum {
                AlbumView().transition(.opacity)
            }
            if let m = store.hezarfen {
                HezarfenView(message: m, day: store.state?.day ?? 1) { store.dismissHezarfen(openBazaar: m == .tip(.bazaar)) }
                    .transition(.opacity)
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
        .animation(.easeOut(duration: 0.25), value: store.postcard)
        .animation(.easeOut(duration: 0.25), value: store.showAlbum)
        .fullScreenCover(isPresented: Binding(get: { store.flightPax != nil }, set: { _ in })) {
            FlightView()
                .environment(store)
        }
        .fullScreenCover(isPresented: Binding(get: { store.report != nil }, set: { _ in })) {
            if let r = store.report {
                ReportView(report: r)
                    .environment(store)
            }
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
        case .holding: HoldingView()
        case .map: WorldMapView()
        }
    }
}
