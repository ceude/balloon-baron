import Foundation

public struct Balloon: Codable, Identifiable, Equatable, Sendable {
    public let id: Int
    public var size: BalloonSize
    public var name: String
    /// Player's choice to send it up today.
    public var fly = true
    public var damagedUntil = 0
    public var pilot: Int?
    public var flights = 0
    public var ad: Sponsor?

    /// Envelope condition, 1 = new, 0 = grounded.
    public var condition: Double { clamp(1 - Double(flights) / Double(Rules.envelopeLife), 0, 1) }
}

public struct Pilot: Codable, Identifiable, Equatable, Sendable {
    public let id: Int
    public var name: String
    public var level: PilotLevel
    public var xp = 0
    public var fromSchool = false
    /// Set after a raise; otherwise wage follows level.
    public var customWage: Int?

    public var wage: Int {
        customWage ?? jsRound(Double(level.wage) * (fromSchool ? Rules.schoolWageFactor : 1))
    }
}

public struct Loan: Codable, Equatable, Sendable {
    public var amount: Int
    public var installment: Int
    public var daysLeft: Int
    public var payoff: Int { jsRound(Double(installment * daysLeft) * 0.9) }
}

public struct ForSale: Codable, Equatable, Sendable {
    public var sizes: [BalloonSize]
    public var price: Int
}

public struct Rival: Codable, Identifiable, Equatable, Sendable {
    public var id: Int
    public var name: String
    public var colors: [String]
    public var style: RivalStyle
    public var balloons: [BalloonSize]
    public var price: Int
    public var rep: Double
    public var cash: Double
    public var entrant: Entrant?
    public var alive = true
    public var damagedUntil: [Int]
    public var flyToday: [Int] = []
    public var lastPax = 0
    public var lastCap = 0
    public var forSale: ForSale?
    public var offer: Int?
    public var lowDays = 0
    public var highDays = 0
    public var deadDay: Int?
    public var campaignUntil = 0
    public var lastBuy = 0
    public var offerSeen = false, offerDeclined = false
    public var saleSeen = false, saleDeclined = false

    init(id: Int, name: String, colors: [String], style: RivalStyle, balloons: [BalloonSize], price: Int, rep: Double, cash: Double) {
        self.id = id; self.name = name; self.colors = colors; self.style = style
        self.balloons = balloons; self.price = price; self.rep = rep; self.cash = cash
        damagedUntil = balloons.map { _ in 0 }
    }
}

public struct Weather: Codable, Equatable, Sendable {
    public var flag: Flag
    /// Surface wind in km/h, for display.
    public var surfaceWind: Int
    /// Wind speed (m/s, + is east) per band.
    public var layers: [Double]
    /// Landing target x in meters from launch.
    public var target: Double
    public var seed: UInt64
    public var mission: Mission?
    /// Valley x for the valley mission.
    public var valley: Double
}

public struct Winter: Codable, Equatable, Sendable {
    public var start: Int, end: Int
}

public struct HotelLock: Codable, Equatable, Sendable {
    public var rival: String
    public var until: Int
}

public struct PoachOffer: Codable, Equatable, Sendable {
    public var rivalIndex: Int
    public var pilotID: Int
    public var wage: Int
}

public struct MarketShare: Codable, Equatable, Sendable {
    public var me: Int
    public var rivals: [Int]
    public var demand: Int
    /// Tourists who came straight to you through referrals.
    public var extra: Int
}

public struct RepPoint: Codable, Equatable, Sendable {
    public var day: Int, rep: Double
}

public enum Feature: String, Codable, CaseIterable, Sendable { case insurance, fleet, bank, market, crew }

/// Hezarfen's one-off lessons. Text lives in the string catalog under `hez.<rawValue>`.
public enum Tip: String, Codable, CaseIterable, Sendable {
    case welcome, insurance, fleet, bank, market, crew, yellow, red, mission, accident, crisis
    case rivals, rivals2, rivals3, expect, antitrust, aging
}

public enum HezMessage: Codable, Equatable, Sendable {
    case tip(Tip)
    case winterComing
    case spring
    case entrant(Entrant)
}

public struct DayPlan: Codable, Equatable, Sendable {
    public var skipped: Bool
    public var flying: [Int]
    public var pax: [Int: Int]
    public var rivalPax: [Int]
    public var rivalCap: [Int]
    public var referrals: Int
}

public struct GameState: Codable, Equatable, Sendable {
    public static let currentVersion = 1
    public var version = GameState.currentVersion

    public var day = 1
    public var cash = Rules.startCash
    public var rep = 1.0
    public var price = Rules.startPrice
    public var company: String
    public var colors: [String]
    public var strikes = 0
    public var banUntil = 0
    public var selfFly = true
    public var lastSelfFly = 1
    public var nextID = 1
    public var flagship = 0
    public var insureHull = true
    public var insurePax = true
    public var balloons: [Balloon] = []
    public var pilots: [Pilot] = []
    public var candidates: [Pilot] = []
    public var loans: [Loan] = []
    public var demandBase = Rules.startDemand
    public var rivals: [Rival]
    public var lastShare: MarketShare?
    public var tutorialDone = false
    public var reviews: [Review] = []
    public var repHistory: [RepPoint] = []
    public var influencerUntil = 0, influencerCooldown = 0
    public var guideUntil = 0, guideCooldown = 0
    public var hotelDeals: [Hotel] = []
    public var ownHotels: [Hotel] = []
    public var hotelLocks: [Hotel: HotelLock] = [:]
    public var unlocked: Set<Feature> = []
    public var tipsSeen: Set<Tip> = []
    public var hezQueue: [HezMessage] = []
    public var poach: PoachOffer?
    public var school = false
    public var winter: Winter?
    public var nextWinter: Int?
    public var monopolyDays = 0
    public var firstMissionGiven = false
    public var weather: Weather?
    public var demand: Int?
    public var plan: DayPlan?
    var rivalPlanDay = 0
    public var over = false

    public init(company: String, colors: [String]) {
        self.company = company
        self.colors = colors
        rivals = [
            Rival(id: 0, name: "Göreme Sky", colors: ["#5aa9e6", "#eaf4fc"], style: .safe, balloons: [.L, .L, .M, .M, .M], price: 195, rep: 1.15, cash: 40000),
            Rival(id: 1, name: "Peribaca Balloons", colors: ["#9b7be0", "#f2ebff"], style: .mid, balloons: [.M, .M, .S], price: 165, rep: 1, cash: 12000),
            Rival(id: 2, name: "Kızıl Vadi Air", colors: ["#c73a2a", "#ffd9a8"], style: .risky, balloons: [.S, .S], price: 135, rep: 0.85, cash: 5000)
        ]
        balloons.append(Balloon(id: nextID, size: .S, name: Rules.balloonNames[0]))
        flagship = nextID
        nextID += 1
    }

    public var stars: Double { Rules.stars(rep) }
    public var licenseDaysLeft: Int { Rules.licenseDays - (day - lastSelfFly) }
    public var licenseValid: Bool { licenseDaysLeft >= 0 }
    public var flyingSelf: Bool { selfFly && licenseValid }

    public func balloon(_ id: Int) -> Balloon? { balloons.first { $0.id == id } }
    public func pilot(of b: Balloon) -> Pilot? { pilots.first { $0.id == b.pilot } }
    public func isSelf(_ b: Balloon) -> Bool { b.id == flagship && flyingSelf }
    public func hotelActive(_ h: Hotel) -> Bool { hotelDeals.contains(h) || ownHotels.contains(h) }
    public var activeHotels: [Hotel] { Hotel.allCases.filter(hotelActive) }

    public func hotelIncome(_ h: Hotel) -> Int {
        jsRound(Double(h.roomIncome) * (stars < h.minStars ? 0.5 : 1) * (winter != nil ? 0.6 : 1))
    }

    public enum FlyStatus: Equatable, Sendable { case ok, banned, damaged, worn, noPilot }

    public func status(_ b: Balloon) -> FlyStatus {
        if banUntil >= day { return .banned }
        if b.damagedUntil > day { return .damaged }
        if b.condition <= 0 { return .worn }
        if !isSelf(b) && b.pilot == nil { return .noPilot }
        return .ok
    }

    /// Balloons that will actually go up today.
    public var flyingToday: [Balloon] { balloons.filter { $0.fly && status($0) == .ok } }
    public var capacityToday: Int { flyingToday.reduce(0) { $0 + $1.size.capacity } }

    public var influencerCost: Int { Rules.influencerCost(balloons: balloons.count) }
}
