import StoreKit
import BalloonBaronCore

/// The App Store side of the bazaar (StoreKit 2): every item but the free lanterns is a non-consumable product
/// `balloonbaron.<item>`. A purchase belongs to the Apple ID, so a new game or a new phone gets it back: at launch,
/// at a new game and on Restore the current entitlements are granted again. `grant` puts an item into the game.
@MainActor @Observable
final class Shop {
    static let shared = Shop()
    private(set) var products: [StoreItem: Product] = [:]
    /// The item being bought, while the App Store sheet is up.
    private(set) var buying: StoreItem?
    /// A note for the purchase card (pending, failed, unavailable); nil when there's nothing to say.
    var note: String?
    @ObservationIgnored private var grant: (StoreItem, Bool) -> Void = { _, _ in }
    @ObservationIgnored private var updates: Task<Void, Never>?

    /// `grant(item, bought)`: `bought` is true for a fresh purchase, false when an old one comes back.
    func start(grant: @escaping (StoreItem, Bool) -> Void) {
        self.grant = grant
        updates = Task { [weak self] in
            for await result in Transaction.updates { await self?.handle(result) }
        }
        Task { await load(); await restoreEntitlements() }
    }

    func load() async {
        let ids = StoreItem.allCases.filter(\.isProduct).map(\.productID)
        guard let list = try? await Product.products(for: ids) else { return }
        for p in list { if let k = item(p.id) { products[k] = p } }
    }

    /// The App Store's price in the player's currency, or the tier price until it loads.
    func price(_ k: StoreItem) -> String { products[k]?.displayPrice ?? StoreItem.price(k) }

    /// Shows the App Store sheet; true once the item is the player's.
    func buy(_ k: StoreItem) async -> Bool {
        note = nil
        if products[k] == nil { await load() }
        guard let p = products[k] else { note = loc("store.unavailable"); return false }
        buying = k
        defer { buying = nil }
        do {
            switch try await p.purchase() {
            case .success(let v):
                guard case .verified(let t) = v else { note = loc("store.failed"); return false }
                grant(k, true)
                await t.finish()
                return true
            case .pending:
                note = loc("store.pending")
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            note = loc("store.failed")
        }
        return false
    }

    /// "Restore purchases": asks the App Store to sync, then grants what the Apple ID owns.
    func restore() async {
        try? await AppStore.sync()
        await restoreEntitlements()
    }

    func restoreEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result, t.revocationDate == nil, let k = item(t.productID) { grant(k, false) }
        }
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let t) = result else { return }
        if t.revocationDate == nil, let k = item(t.productID) { grant(k, true) }
        await t.finish()
    }

    private func item(_ id: String) -> StoreItem? { StoreItem.allCases.first { $0.productID == id } }
}

/// The App Store price for views that aren't on the main actor by type (all SwiftUI drawing runs there).
func storePrice(_ k: StoreItem) -> String { MainActor.assumeIsolated { Shop.shared.price(k) } }
