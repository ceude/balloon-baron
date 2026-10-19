import SwiftUI

@main
struct BalloonBaronApp: App {
    @State private var store = GameStore()

    init() { Theme.registerFonts() }

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
                SetupView()
            } else {
                HomeView()
            }
            if let m = store.hezarfen {
                HezarfenView(message: m) { store.dismissHezarfen() }
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.25), value: store.hezarfen)
        .fullScreenCover(isPresented: Binding(get: { store.flightPax != nil }, set: { _ in })) {
            FlightPlaceholderView()
                .environment(store)
        }
        .fullScreenCover(isPresented: Binding(get: { store.report != nil }, set: { _ in })) {
            if let r = store.report {
                ReportView(report: r)
                    .environment(store)
            }
        }
    }
}
