import Foundation

/// A place the company can fly. Display names are localized in the app under `region.<rawValue>`.
public enum RegionID: String, Codable, CaseIterable, CodingKeyRepresentable, Sendable {
    case cap, abq

    /// ISO currency of the region's own cash box.
    public var currency: String { self == .abq ? "USD" : "EUR" }
    /// Local money per euro. Every price is the same number in every region; only the holding converts.
    public var fx: Double { self == .abq ? 1.1 : 1 }
    /// The signature XL balloon.
    public var xlName: String { self == .abq ? "Fiesta Yıldızı" : Rules.xlName }

    public var balloonNames: [String] {
        switch self {
        case .cap: Rules.balloonNames
        case .abq: ["Sandia", "Rio Grande", "Corrales", "Bernalillo", "Placitas", "Isleta", "Jemez", "Taos",
                    "Santa Fe", "Mesa", "Zuni", "Acoma", "Chama", "Galisteo", "Pecos", "Cibola"]
        }
    }

    public var pilotNames: [String] {
        switch self {
        case .cap: Rules.pilotNames
        case .abq: ["Jake", "Emma", "Luis", "Sofia", "Tyler", "Grace", "Diego", "Hannah",
                    "Cody", "Maya", "Ryan", "Ava", "Miguel", "Chloe", "Ethan", "Lily"]
        }
    }

    public var entrants: [Entrant] { Entrant.allCases.filter { $0.region == self } }
    public var chapters: [Chapter] { Chapter.all(in: self) }

    /// Albuquerque's famous box: low winds one way, higher winds back, so you can land where you started.
    public var boxWinds: Bool { self == .abq }
    public var hasFiesta: Bool { self == .abq }

    func startingRivals() -> [Rival] {
        switch self {
        case .cap:
            [Rival(id: 0, name: "Göreme Sky", colors: ["#5aa9e6", "#eaf4fc"], style: .safe, balloons: [.L, .L, .L, .M, .M, .M], price: 195, rep: 1.15, cash: 50000),
             Rival(id: 1, name: "Peribaca Balloons", colors: ["#9b7be0", "#f2ebff"], style: .mid, balloons: [.M, .M, .M, .S], price: 165, rep: 1, cash: 20000),
             Rival(id: 2, name: "Kızıl Vadi Air", colors: ["#c73a2a", "#ffd9a8"], style: .risky, balloons: [.S, .S, .S], price: 135, rep: 0.85, cash: 12000)]
        case .abq:
            [Rival(id: 0, name: "Sandia Sky Rides", colors: ["#5aa9e6", "#eaf4fc"], style: .safe, balloons: [.L, .L, .L, .M, .M, .M], price: 195, rep: 1.15, cash: 50000),
             Rival(id: 1, name: "Rio Grande Balloons", colors: ["#3c9a8f", "#e6fff9"], style: .mid, balloons: [.M, .M, .M, .S], price: 165, rep: 1, cash: 20000),
             Rival(id: 2, name: "Route 66 Air", colors: ["#e08a1e", "#fff1d6"], style: .risky, balloons: [.S, .S, .S], price: 135, rep: 0.85, cash: 12000)]
        }
    }
}

/// Pins on the world map. The mystery ones are only "coming soon".
public enum MapPin: String, CaseIterable, Sendable {
    case cap, abq, luxor, asia, europe

    public var region: RegionID? { RegionID(rawValue: rawValue) }
    public var lon: Double { [34.8, -106.6, 32.6, 95, 8][index] }
    public var lat: Double { [38.6, 35.1, 25.7, 21, 46.8][index] }
    public var mystery: Bool { self == .asia || self == .europe }
    private var index: Int { Self.allCases.firstIndex(of: self)! }
}

public struct Fiesta: Codable, Equatable, Sendable {
    public var start: Int, end: Int
}

/// Everything that belongs to one region. The active region lives in `GameState.local`; the
/// others are parked with an autopilot. Holding money, the founder's license, the workshop and
/// designs, Hezarfen's lessons and the day counter are company-wide.
public struct RegionState: Codable, Equatable, Sendable {
    public var cash = Rules.startCash
    public var loans: [Loan] = []
    public var weather: Weather?
    public var demand: Int?
    public var balloons: [Balloon] = []
    public var pilots: [Pilot] = []
    public var candidates: [Pilot] = []
    public var rivals: [Rival]
    public var price = Rules.startPrice
    public var rep = 1.0
    public var strikes = 0
    public var banUntil = 0
    public var flagship = 0
    public var selfFly = true
    public var lastShare: MarketShare?
    /// Your share of yesterday's passengers; kept when nobody flew.
    public var shareNow = 0.0
    public var hotelDeals: [Hotel] = []
    public var ownHotels: [Hotel] = []
    public var hotelLocks: [Hotel: HotelLock] = [:]
    public var reviews: [Review] = []
    public var repHistory: [RepPoint] = []
    public var influencerUntil = 0, influencerCooldown = 0, influencerCount = 0
    public var guideUntil = 0, guideCooldown = 0, guideCount = 0
    public var plan: DayPlan?
    public var winter: Winter?
    public var nextWinter: Int?
    public var monopolyDays = 0
    /// Days you've held more than half the market; rivals merge against you.
    public var dominanceDays = 0
    public var lastMerge: Int?
    public var firstMissionGiven = false
    public var poach: PoachOffer?
    public var school = false
    public var demandBase = Rules.startDemand
    /// Index into the region's chapters; equal to the count once you're its baron.
    public var chapter = 0
    public var fiesta: Fiesta?
    public var fiestaNext: Int?
    public var fiestaFlown = 0
    /// Last 14 days of net profit, used to size the autopilot.
    public var netHistory: [Int] = []
    var rivalPlanDay = 0
    /// Day of the last guide flight, for the popularity cap.
    public var lastGuide: Int?
    var absentNoticeDay = 0

    init(rivals: [Rival]) { self.rivals = rivals }
}

/// A region the company left behind. Its manager keeps flying and sends profit to the holding.
public struct Autopilot: Codable, Equatable, Sendable {
    public struct Modifier: Codable, Equatable, Sendable { public var mult: Double, until: Int }
    public struct OpenIssue: Codable, Equatable, Sendable { public var kind: Issue, day: Int }

    /// Expected daily profit in euros before boosts.
    public var base: Double
    public var issue: OpenIssue?
    public var modifiers: [Modifier] = []
    public var since: Int
    public var lastIssue: Int
    /// Today's raw profit (euros) and what reached the holding after boosts.
    public var todayRaw = 0.0
    public var today = 0
}

public struct ParkedRegion: Codable, Equatable, Sendable {
    public var state: RegionState
    public var auto: Autopilot
}

/// Problems a parked region raises. Text: `issue.<rawValue>.*`.
public enum Issue: String, Codable, CaseIterable, Sendable {
    case raise, war, accident, hotel, envelope

    public enum Choice: Sendable { case a, b }

    /// Up-front holding cost of the choice, if it is a payment.
    public func cost(_ c: Choice, base: Double) -> Int {
        guard c == .a else { return 0 }
        switch self {
        case .hotel: return jsRound(base * 5 / 100) * 100
        case .envelope: return jsRound(base * 8 / 100) * 100
        default: return 0
        }
    }
}
