import Foundation

// Balance numbers ported from prototype/balloon-baron.html. See docs/GAME_DESIGN.md.
// Display names are localized in the app; the core only holds ids and numbers.

public enum BalloonSize: String, Codable, CaseIterable, Comparable, Sendable {
    case S, M, L, XL

    public var capacity: Int { [8, 16, 24, 32][rank] }
    public var cost: Int { [15000, 35000, 60000, 150000][rank] }
    public var fuel: Int { [60, 90, 120, 170][rank] }
    public var upkeep: Int { [40, 60, 80, 140][rank] }
    public var risk: Double { [0.8, 1, 1.3, 1.15][rank] }
    public var rank: Int { Self.allCases.firstIndex(of: self)! }

    /// Sizes you can order from the shop. XL is a one-off signature balloon.
    public static let shop: [BalloonSize] = [.S, .M, .L]

    public static func < (a: Self, b: Self) -> Bool { a.rank < b.rank }
}

public enum PilotLevel: Int, Codable, CaseIterable, Comparable, Sendable {
    case rookie = 1, experienced, senior

    public var wage: Int { [90, 150, 240][rawValue - 1] }
    public var risk: Double { [1.6, 1, 0.6][rawValue - 1] }
    /// Flights needed to reach the next level.
    public var xpToNext: Int? { self == .senior ? nil : [40, 100][rawValue - 1] }

    public static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
}

public enum Flag: String, Codable, CaseIterable, Sendable {
    case green, yellow, red

    public var accident: Double { [0.006, 0.03, 0.14][index] }
    public var demand: Double { [1, 0.9, 1][index] }
    public var wind: Double { [1, 1.45, 2][index] }
    public var gust: Double { [0.25, 0.9, 1.7][index] }
    private var index: Int { Self.allCases.firstIndex(of: self)! }
}

public enum Sponsor: String, Codable, CaseIterable, Sendable {
    case carpet, wine, bank, energy

    public var minSize: BalloonSize { [.S, .M, .M, .L][index] }
    public var basePay: Int { [30, 55, 90, 150][index] }
    public var repLoss: Double { [0.002, 0.004, 0.007, 0.013][index] }
    public var colors: (bg: String, fg: String) {
        [("#8c2f39", "#ffe9c7"), ("#5b1f4a", "#f7d6ea"), ("#0d5c8c", "#ffffff"), ("#c4f000", "#1a1a1a")][index]
    }
    public func allowed(on size: BalloonSize) -> Bool { size >= minSize }
    public func pay(for size: BalloonSize) -> Int {
        jsRound(Double(basePay) * pow(Double(size.capacity) / 8, 0.6) / 5) * 5
    }
    private var index: Int { Self.allCases.firstIndex(of: self)! }
}

public enum Hotel: String, Codable, CaseIterable, Sendable {
    case stone, mansion, cave, palace

    /// Minimum stars to sign or buy.
    public var minStars: Double { [2.0, 3.0, 3.8, 4.4][index] }
    public var dailyFee: Int { [60, 120, 220, 380][index] }
    public var repPerDay: Double { [0.005, 0.0075, 0.01, 0.0125][index] }
    public var guests: Int { [4, 7, 12, 18][index] }
    /// Ticket price these guests are comfortable with.
    public var priceCenter: Double { [200, 240, 290, 340][index] }
    public var buyPrice: Int { [40000, 110000, 240000, 520000][index] }
    public var roomIncome: Int { [350, 900, 2000, 4300][index] }
    public var color: String { ["#ffc23d", "#ff8a3d", "#f3e08a", "#ffb3a0"][index] }
    private var index: Int { Self.allCases.firstIndex(of: self)! }
}

public enum Mission: String, Codable, CaseIterable, Sendable {
    case proposal, valley, panorama, precision

    public var reward: Int { [450, 300, 250, 400][index] }
    /// Bigger baskets carry more guests, so the client pays more: S ×1, M ×2, L ×3, XL ×4.
    public func reward(for size: BalloonSize) -> Int { reward * size.capacity / 8 }
    private var index: Int { Self.allCases.firstIndex(of: self)! }
}

public struct LoanOffer: Sendable {
    public let amount: Int, days: Int, installment: Int, balloonsNeeded: Int
    public var total: Int { installment * days }
    public var interest: Double { Double(total - amount) / Double(amount) }
}

public enum RivalStyle: String, Codable, Sendable { case safe, mid, risky }

public enum Entrant: String, Codable, CaseIterable, Sendable {
    case bosphorus, anatolian, periLuxe, aegean
    case mesaGold, turquoise, desertBloom, bigSky
    case redSea, felucca, hatshepsut, karnak

    public var name: String {
        ["Bosphorus Balloons", "Anatolian Sky", "Peri Luxe Flights", "Aegean Air Tours",
         "Mesa Gold Balloons", "Turquoise Trail Air", "Desert Bloom Flights", "Big Sky Fiesta Co.",
         "Red Sea Balloon Co.", "Felucca Flights", "Hatshepsut Air", "Karnak Wings"][index]
    }
    public var region: RegionID { [RegionID.cap, .abq, .lux][index / 4] }
    /// A rich chain: it always arrives with more balloons than you.
    var rich: Bool { index % 4 == 0 }
    var style: RivalStyle { [.safe, .risky, .mid, .mid][index % 4] }
    /// Luxor's newcomers are a size up from the others.
    var balloons: [BalloonSize] {
        region == .lux ? [[.L, .L, .L, .M, .M], [.M, .M, .S, .S, .S, .S], [.L, .M, .M], [.L, .M, .M, .M]][index % 4]
            : [[.L, .L, .M, .M], [.M, .M, .S, .S, .S], [.M, .M], [.L, .M, .M]][index % 4]
    }
    var price: Int { region == .lux ? [200, 120, 255, 180][index % 4] : [190, 125, 250, 175][index % 4] }
    var rep: Double { region == .lux ? [1.15, 0.9, 1.3, 1.05][index % 4] : [1.1, 0.9, 1.25, 1][index % 4] }
    var cash: Double { region == .lux ? [90000, 35000, 60000, 50000][index % 4] : [70000, 30000, 50000, 40000][index % 4] }
    private var index: Int { Self.allCases.firstIndex(of: self)! }
}

public enum Rules {
    public static let startCash = 3000
    public static let startPrice = 170
    public static let startDemand = 165
    public static let priceRange = 40...320
    public static let licenseDays = 15
    public static let recertCost = 15000
    public static let cancelCompensation = 40
    public static let envelopeLife = 120
    public static let renewShare = 0.35
    public static let sellShare = 0.6
    public static let schoolCost = 60000
    public static let schoolWageFactor = 0.7
    public static let guideCost = 1500
    public static let crisisRep = 0.5
    public static let repRange = 0.4...1.4
    public static let maxLoans = 2
    public static let seizeBelow = -5000
    public static let redFine = 5000
    public static let redCatch = 0.35
    public static let xlName = "Kapadokya Yıldızı"
    public static let xlRepPerFlight = 0.005
    /// Passengers pay this much extra to fly with the founder.
    public static let founderPremium = 0.25
    /// Without a hotel or a recent guide flight popularity stops at 4.2★ (4.5★ with a recent influencer campaign).
    public static let prCap = 1.05
    public static let prCapInfluencer = 1.125
    /// A guide flight keeps counting for the cap this many days.
    public static let guideFresh = 10
    /// After this many days without flying yourself, popularity erodes.
    public static let absentGraceDays = 5
    public static let absentRepLoss = 0.008
    /// Bigger companies are more visible: market appeal scales with seats to this power.
    public static let seatWeight = 1.0
    /// At 5★ popularity fills up to this share of your seats on its own.
    public static let popularitySeatShare = 0.5
    /// Antitrust fine: this share of company worth (cash, balloons, hotels), at least `redFine`.
    public static let monopolyRate = 0.03
    public static let fiestaDays = 4, fiestaEvery = 30, fiestaDemand = 1.9
    public static let fiestaBalloons = 46
    /// Cappadocia's festivals: from day 24, every 35 days, three days of extra tourists and richer special requests.
    public static let festivalFirst = 24, festivalEvery = 35, festivalDays = 3
    public static let festivalDemand = 1.4, festivalReward = 1.5
    public static let festivalCount = 3

    public static let loans = [
        LoanOffer(amount: 10000, days: 40, installment: 300, balloonsNeeded: 0),
        LoanOffer(amount: 25000, days: 45, installment: 650, balloonsNeeded: 2),
        LoanOffer(amount: 50000, days: 50, installment: 1250, balloonsNeeded: 3)
    ]

    public static let balloonNames = ["Şafak", "Güvercin", "Zelve", "Uçhisar", "Avanos", "Ihlara", "Ortahisar", "Kızılçukur",
                                      "Paşabağ", "Erciyes", "Soğanlı", "Mustafapaşa", "Göreme", "Çavuşin", "Ürgüp", "Sinasos"]
    public static let pilotNames = ["Mert", "Elif", "Kerem", "Zeynep", "Hakan", "Selin", "Burak", "Derya",
                                    "Emre", "Aslı", "Onur", "Ceren", "Tolga", "Melis", "Cem", "İpek"]

    /// Company colors offered at setup (primary, secondary).
    public static let palettes: [[String]] = [
        ["#ff5e3a", "#ffc23d"], ["#14a39a", "#e8fff9"], ["#2b2350", "#ffc23d"], ["#ff6fa8", "#fff0f6"], ["#5aa9e6", "#eaf4fc"],
        ["#9b7be0", "#f2ebff"], ["#22a45d", "#fff3b0"], ["#e5432f", "#ffffff"], ["#ffc23d", "#2b2350"], ["#1f1b2e", "#ffffff"]
    ]
    static let rivalColors: [[String]] = [
        ["#5aa9e6", "#eaf4fc"], ["#9b7be0", "#f2ebff"], ["#c73a2a", "#ffd9a8"], ["#e08a1e", "#fff1d6"], ["#3c9a8f", "#e6fff9"], ["#7a7f8c", "#f4f4f4"]
    ]

    /// Wind band centers in meters (bands 0–60, 60–180, 180–350, 350–650).
    public static let windCenters: [Double] = [30, 120, 265, 500]

    public static func influencerCost(balloons: Int) -> Int { 2500 + 400 * balloons }

    /// Share of tourists happy to pay `price`.
    public static func willing(_ price: Double, center: Double = 230) -> Double { 1 / (1 + exp((price - center) / 30)) }

    public static func stars(_ rep: Double) -> Double { clamp(3 + (rep - 0.75) * 4, 1, 5) }
}
