import Foundation

/// A place the company can fly. Display names are localized in the app under `region.<rawValue>`.
public enum RegionID: String, Codable, CaseIterable, CodingKeyRepresentable, Sendable {
    case cap, abq, lux
    /// v124: Bristol, England. Opens after the Luxor baron.
    case bri

    /// ISO currency of the region's own cash box.
    public var currency: String { self == .abq ? "USD" : self == .bri ? "GBP" : "EUR" }
    /// Local money per euro. Every price is the same number in every region; only the holding converts.
    /// Bristol counts in pounds at a fixed £1 = €1.20 (v124.2).
    public var fx: Double { self == .abq ? 1.1 : self == .bri ? 1 / 1.2 : 1 }
    /// The signature XL balloon.
    public var xlName: String {
        switch self {
        case .cap: Rules.xlName
        case .abq: "Fiesta Yıldızı"
        case .lux: "Teb Yıldızı"
        case .bri: "Avon Yıldızı"
        }
    }
    /// The region before it: becoming its baron opens this one (none for Cappadocia).
    public var unlockedBy: RegionID? {
        switch self {
        case .cap: nil
        case .abq: .cap
        case .lux: .abq
        case .bri: .lux
        }
    }
    /// What the holding pays to open the region.
    public var entryFee: Int { self == .bri ? 240000 : self == .lux ? 150000 : Holding.entryFee }
    /// Cash in the region's box on the first day.
    public var startCash: Int { self == .bri ? 6000 : self == .lux ? 5000 : Rules.startCash }
    /// The ticket price on the first day (v124: £185 in Bristol).
    public var startPrice: Int { self == .bri ? 185 : Rules.startPrice }
    /// Tourists a day at the start (v124: Bristol has fewer, 145).
    public var startDemand: Int { self == .bri ? 145 : Rules.startDemand }
    /// v124: Bristol's pilots cost 15% more (`regWage`).
    public var wageFactor: Double { self == .bri ? 1.15 : 1 }
    /// v124: Bristol's changeable weather: more yellow flags (green 42%, yellow 43%, red 15%; winter as everywhere).
    public var greenShare: Double { self == .bri ? 0.42 : 0.55 }

    public var balloonNames: [String] {
        switch self {
        case .cap: Rules.balloonNames
        case .abq: ["Sandia", "Rio Grande", "Corrales", "Bernalillo", "Placitas", "Isleta", "Jemez", "Taos",
                    "Santa Fe", "Mesa", "Zuni", "Acoma", "Chama", "Galisteo", "Pecos", "Cibola"]
        case .lux: LUX.balloonNames
        case .bri: BRI.balloonNames
        }
    }

    /// v124.4: surname initials. Turkish surnames never start with Q, W or X (nor Ğ), so Cappadocia uses Turkish letters.
    public var pilotInitials: [Character] {
        self == .cap ? Array("ABCÇDEFGHİKLMNOÖPRSŞTUÜVYZ") : Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    }

    public var pilotNames: [String] {
        switch self {
        case .cap: Rules.pilotNames
        case .abq: ["Jake", "Emma", "Luis", "Sofia", "Tyler", "Grace", "Diego", "Hannah",
                    "Cody", "Maya", "Ryan", "Ava", "Miguel", "Chloe", "Ethan", "Lily"]
        case .lux: LUX.pilotNames
        case .bri: BRI.pilotNames
        }
    }

    public var entrants: [Entrant] { Entrant.allCases.filter { $0.region == self } }
    public var chapters: [Chapter] { Chapter.all(in: self) }

    /// Albuquerque's famous box: low winds one way, higher winds back, so you can land where you started.
    public var boxWinds: Bool { self == .abq }
    /// The Nile valley's layers: north low, south higher, alternating the other way round from the box.
    public var nileWinds: Bool { self == .lux }
    /// v124: Bristol's west wind off the Bristol Channel: low air mixed, east at middle heights, the top half the time
    /// against you or weak.
    public var westWinds: Bool { self == .bri }
    /// v124: Bristol's morning fog, the airport's airspace and its own flight world (bridge, harbour, fields, mud).
    public var bristol: Bool { self == .bri }
    /// Albuquerque's Balloon Fiesta, and Luxor's Nile cruise season, which uses the same days and goal.
    public var hasFiesta: Bool { self != .cap }
    public var fiestaEvery: Int { self == .lux ? 21 : Rules.fiestaEvery }
    public var fiestaDays: Int { self == .lux ? 3 : Rules.fiestaDays }
    public var fiestaDemand: Double { self == .lux ? 1.6 : self == .bri ? 1.8 : Rules.fiestaDemand }
    public var hasFestivals: Bool { self == .cap }
    /// Rivals here fight harder: more campaigns, more hotel poaching, faster and bigger fleet growth.
    public var rivalEdge: Bool { self != .cap }
    /// Luxor's rivals join forces sooner, more often, and at a smaller share of the market.
    public var mergesEarly: Bool { self == .lux || self == .bri }
    /// The rival owned by the region's boss (Kenan Arslan, Dale Whitaker, Nabil Haddad).
    public var bossCompany: String {
        switch self {
        case .cap: "Göreme Sky"
        case .abq: "Sandia Sky Rides"
        case .lux: "Theban Skies"
        case .bri: "Clifton Crown Balloons"
        }
    }

    func startingRivals() -> [Rival] {
        switch self {
        case .cap:
            [Rival(id: 0, name: "Göreme Sky", colors: ["#5aa9e6", "#eaf4fc"], style: .safe, balloons: [.L, .L, .L, .M, .M, .M], price: 195, rep: 1.15, cash: 50000),
             Rival(id: 1, name: "Peribaca Balloons", colors: ["#9b7be0", "#f2ebff"], style: .mid, balloons: [.M, .M, .M, .S], price: 165, rep: 1, cash: 20000),
             Rival(id: 2, name: "Kızıl Vadi Air", colors: ["#c73a2a", "#ffd9a8"], style: .risky, balloons: [.S, .S, .S], price: 135, rep: 0.85, cash: 12000)]
        // Stronger than Cappadocia's: bigger fleets, better known, deeper pockets (and `rivalEdge`).
        case .abq:
            [Rival(id: 0, name: "Sandia Sky Rides", colors: ["#5aa9e6", "#eaf4fc"], style: .safe, balloons: [.L, .L, .L, .L, .M, .M, .M, .M], price: 205, rep: 1.2, cash: 90000),
             Rival(id: 1, name: "Rio Grande Balloons", colors: ["#3c9a8f", "#e6fff9"], style: .mid, balloons: [.L, .M, .M, .M, .M, .S], price: 170, rep: 1.05, cash: 40000),
             Rival(id: 2, name: "Route 66 Air", colors: ["#e08a1e", "#fff1d6"], style: .risky, balloons: [.M, .S, .S, .S, .S], price: 140, rep: 0.9, cash: 20000)]
        // The hardest market: an old family boss with the biggest fleet.
        case .lux:
            [Rival(id: 0, name: "Theban Skies", colors: ["#1f6f8b", "#e8c47a"], style: .safe, balloons: [.L, .L, .L, .L, .L, .M, .M, .M, .M, .M], price: 215, rep: 1.28, cash: 130000),
             Rival(id: 1, name: "Pharaoh Balloons", colors: ["#c9a040", "#2a2018"], style: .mid, balloons: [.L, .L, .M, .M, .M, .M, .S], price: 175, rep: 1.1, cash: 60000),
             Rival(id: 2, name: "Nile Dawn Air", colors: ["#e0408a", "#fff0f6"], style: .risky, balloons: [.M, .M, .S, .S, .S, .S], price: 130, rep: 0.95, cash: 30000)]
        // v124: old money at the top, a steady middle, a cheap harbour outfit.
        case .bri:
            [Rival(id: 0, name: "Clifton Crown Balloons", colors: ["#7a2a34", "#e8d6a0"], style: .safe, balloons: [.L, .L, .L, .L, .L, .M, .M, .M, .M, .M, .M], price: 230, rep: 1.3, cash: 150000),
             Rival(id: 1, name: "Severn Sky Co.", colors: ["#2a6a5a", "#e6f2ea"], style: .mid, balloons: [.L, .L, .M, .M, .M, .M, .S], price: 190, rep: 1.1, cash: 65000),
             Rival(id: 2, name: "Harbourside Air", colors: ["#e0a020", "#1f2a44"], style: .risky, balloons: [.M, .M, .S, .S, .S, .S], price: 145, rep: 0.95, cash: 30000)]
        }
    }
}

private enum BRI {
    static let balloonNames = ["Clifton", "Avon", "Ashton", "Severn", "Redland", "Cabot", "Brandon", "Leigh Woods",
                               "Kingsweston", "Bedminster", "Hotwells", "Downs", "Mendip", "Cotham", "Brunel", "Portishead"]
    static let pilotNames = ["Oliver", "Amelia", "George", "Isla", "Harry", "Poppy", "Jack", "Freya",
                             "Alfie", "Evie", "Charlie", "Ruby", "Archie", "Florence", "Thomas", "Daisy"]
}

private enum LUX {
    static let balloonNames = ["Karnak", "Memnon", "Hatşepsut", "Nefertari", "Teb", "Abidos", "Dendera", "Esna",
                               "Edfu", "Kom Ombo", "File", "Kurna", "Habu", "Amon", "Horus", "İsis"]
    static let pilotNames = ["Ahmed", "Mona", "Karim", "Yasmin", "Omar", "Nour", "Tarek", "Salma",
                             "Hassan", "Laila", "Youssef", "Mariam", "Khaled", "Dina", "Mostafa", "Hana"]
}

/// Pins on the world map. Regions without a `RegionID` are only "coming soon"; the mystery one has no name yet.
public enum MapPin: String, CaseIterable, Sendable {
    case cap, abq, lux, bri, mara, asia

    public var region: RegionID? { RegionID(rawValue: rawValue) }
    public var lon: Double { [34.8, -106.6, 32.6, -2.6, 35.1, 95][index] }
    public var lat: Double { [38.6, 35.1, 25.7, 51.45, -1.5, 21][index] }
    public var mystery: Bool { self == .asia }
    private var index: Int { Self.allCases.firstIndex(of: self)! }
}

public struct Fiesta: Codable, Equatable, Sendable {
    public var start: Int, end: Int
    public init(start: Int, end: Int) { self.start = start; self.end = end }
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
    /// v118: hotels you sold, with the rival that bought them (optional: older saves have none).
    public var hotelOwners: [Hotel: String]? = nil
    /// v118: hotels of a rival that went bankrupt, offered to you once, cheap (optional, like `hotelOwners`).
    public var hotelBargains: [HotelBargain]? = nil
    public var reviews: [Review] = []
    public var repHistory: [RepPoint] = []
    public var influencerUntil = 0, influencerCooldown = 0, influencerCount = 0
    public var guideUntil = 0, guideCooldown = 0, guideCount = 0
    /// v122: tourists a day sent by the guide and the influencer you picked (nil: the old deal's 5 and 8).
    public var guidePax: Int?
    public var influPax: Int?
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

    // Added in version 3 (optional so older saves load).
    /// Building levels above 1.
    public var buildings: [Building: Int]?
    /// Flags already rolled for coming days, so the wind mast's forecast comes true.
    public var forecast: [Int: Flag]?
    public var festival: Festival?
    public var festivalNext: Int?
    public var festivalCount: Int?
    /// v121.12: flew on a festival day here.
    public var festivalFlown: Bool?
    /// Most passengers flown in a day, for the record headline.
    public var bestPax: Int?
    /// Morning events: pilots on strike today, a balloon chartered today, fuel price up until, documentary day.
    public var strikeDay: Int?
    /// Pilots who were refused a raise stay off work through this day.
    public var strikeUntil: Int?
    /// A problem raised while the region was on autopilot, still undecided now that you're here, and the day its card last showed.
    public var openIssue: Autopilot.OpenIssue?
    /// Big loans (by amount) this region's bank has opened; they stay open.
    public var loansOpen: [Int]?
    /// Rivals that went bankrupt here; after the first, a new company takes 14 days instead of 6 to fill the slot.
    public var rivalBusts: Int?
    public var issueSeen: Int?
    public var charter: Charter?
    public var fuelUpUntil: Int?
    public var docDay: Int?
    public var nextEvent: Int?
    public var lastEvent: MorningEvent?
    /// A night-owl pilot who overslept, and the day that was last checked.
    public var late: LatePilot?
    var lateChecked: Int?
    /// Winter whose first night has been shown.
    var winterNight: Int?
    /// The inspector's last visit about worn envelopes, and visits in a row while any is still worn.
    public var inspectDay: Int?
    public var inspectCount: Int?
    /// You fly another balloon while the flagship is in repair; the flagship comes back once it's repaired.
    public var flagReturn: FlagReturn?
    /// The flagship repair (its `damagedUntil`) already asked about, so the offer comes once per repair.
    public var flagAskedUntil: Int?
    /// v111 Balloon Show: the day it's booked for (tonight), the balloons in it, the next day one can be booked,
    /// the last day its tourists come, the day it was held, and how many so far.
    public var showTonight: Int?
    public var showIDs: [Int]?
    public var showNext: Int?
    public var showUntil: Int?
    public var lastShow: Int?
    public var showCount: Int?
    /// v124 Bristol (optional so older saves load): own flights ended safely on a foggy morning; Night Glows held; the
    /// night one is booked for, the festival (its start day) it was booked in, and its balloons; the last festival day
    /// with an evening ascent and how many balloons went up.
    public var fogFlown: Int?
    public var glowCount: Int?
    public var glowTonight: Int?
    public var glowFest: Int?
    public var glowN: Int?
    public var eveDay: Int?
    public var eveN: Int?
    /// v125 (optional so older saves load): corporate contracts; balloons brought from home on their way, and what this
    /// region still pays back for them.
    public var contracts: ContractState?
    public var transferShip: TransferShip?
    public var transferDebt: TransferDebt?
    /// v127 (optional so older saves load): the first day Hezarfen may remind you again about balloons outside the hangar.
    public var hangarReminder: Int?

    init(rivals: [Rival]) { self.rivals = rivals }

    public func level(_ b: Building) -> Int { buildings?[b] ?? 1 }
}

/// Cappadocia's festivals: three busy days about every five weeks. Name: `festival.<index>`.
public struct Festival: Codable, Equatable, Sendable {
    public var index: Int, start: Int, end: Int
}

/// The real flagship (`original`) and the balloon you fly until it's out of repair (`temp`).
public struct FlagReturn: Codable, Equatable, Sendable { public var original: Int, temp: Int }

public struct Charter: Codable, Equatable, Sendable { public var day: Int, balloon: Int }
public struct LatePilot: Codable, Equatable, Sendable { public var day: Int, pilot: Int }

/// A region the company left behind. Its manager keeps flying and sends profit to the holding.
public struct Autopilot: Codable, Equatable, Sendable {
    public struct Modifier: Codable, Equatable, Sendable { public var mult: Double, until: Int }
    public struct OpenIssue: Codable, Equatable, Sendable {
        public var kind: Issue, day: Int
        public init(kind: Issue, day: Int) { self.kind = kind; self.day = day }
    }

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
