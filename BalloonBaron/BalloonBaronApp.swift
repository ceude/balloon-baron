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
            if let m = store.hezarfen {
                HezarfenView(message: m) { store.dismissHezarfen() }
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
        .animation(.easeOut(duration: 0.25), value: store.chapter)
        .animation(.easeOut(duration: 0.25), value: store.merge)
        .animation(.easeOut(duration: 0.25), value: store.collecting)
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
        case .market: MarketView()
        case .goals: GoalsView()
        case .holding: HoldingView()
        case .map: WorldMapView()
        }
    }
}
