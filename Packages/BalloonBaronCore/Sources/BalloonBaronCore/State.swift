import Foundation

public struct Balloon: Codable, Identifiable, Equatable, Sendable {
    public let id: Int
    public var size: BalloonSize
    public var name: String
    /// Player's choice to send it up today.
    public var fly = true
    public var damagedUntil = 0
    public var pilot: Int?
    /// Flights flown on this envelope; a top-level hangar wears it more slowly, so it can be fractional.
    public var flights = 0.0
    public var ad: Sponsor?
    /// Id of a workshop design painted on the envelope.
    public var design: Int?
    /// Burners on the frame: 1 (nil), 2 or 3. A spare burner lowers the accident risk and climbs faster.
    public var burner: Int?
    /// A turning vent lines the basket up for a windy landing.
    public var turningVent: Bool?
    /// Bought from a rival (take-over or bankrupt fleet): second-hand, it resells for less.
    public var used: Bool?
    /// v124.4: the pilot the player put on this balloon (`Game.pinPilot`); nil leaves it to the morning's placing.
    public var pinnedPilot: Int?
    /// v125: brought from this region on entering the current one (`Transfer`); not counted toward its goals.
    public var imported: RegionID?

    public var burners: Int { burner ?? 1 }
    public var hasTurningVent: Bool { turningVent ?? false }
}

/// Burner setups: one, two or three. `cost` is the share of the balloon's price to fit the next one.
public enum Burners {
    public static let risk: [Double] = [1, 0.85, 0.72]
    public static let heat: [Double] = [1, 1.3, 1.6]
    public static let cost: [Double] = [0, 0.1, 0.12]
    public static let turningVentCost = 0.06
    /// Accident factor of a turning vent on a yellow or red day.
    public static let turningVentRisk = 0.85
    /// Sink speed (m/s) that still lands softly with a turning vent; 2.6 without.
    public static let turningVentHardLanding = 3.1
}

public struct Pilot: Codable, Identifiable, Equatable, Sendable {
    public var id: Int
    public var name: String
    public var level: PilotLevel
    /// Flights flown; the flight simulator counts each one as 1.5.
    public var xp = 0.0
    public var fromSchool = false
    /// Set after a raise; otherwise wage follows level.
    public var customWage: Int?
    public var trait: PilotTrait?
    /// v125: brought from this region on entering the current one (`Transfer`); not counted toward its goals.
    public var imported: RegionID?

    public var wage: Int {
        customWage ?? Pilot.baseWage(level, school: fromSchool, trait: trait)
    }

    /// `region`: v124, Bristol's pilots cost 15% more (`regWage`); the region's factor is fixed into `customWage`
    /// when a pilot is hired there or promoted.
    static func baseWage(_ level: PilotLevel, school: Bool, trait: PilotTrait?, region: RegionID = .cap) -> Int {
        jsRound(Double(level.wage) * region.wageFactor * (school ? Rules.schoolWageFactor : 1) * (trait == .nightOwl ? 0.85 : 1))
    }
}

public struct Loan: Codable, Equatable, Sendable {
    public var amount: Int
    public var installment: Int
    public var daysLeft: Int
    /// Taken to buy a rival (the purchase loan).
    public var purchase: Bool?
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
    /// New and merged companies don't pay their owners for a while: they're out to grow.
    public var warChestUntil = 0
    /// Set on the company that disappeared in a merger: the name it joined.
    public var mergedInto: String?

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
    /// v124 Bristol: morning fog up to this height, and the airport's controlled airspace (optional: older saves).
    public var fog: Fog? = nil
    public var air: Airspace? = nil
}

/// v124: Bristol's morning fog: the landing field is hidden while you're above its top (90–150 m).
public struct Fog: Codable, Equatable, Sendable {
    public var top: Double
    public init(top: Double) { self.top = top }
}

/// v124: the airport's controlled airspace over part of the way: from `x0` to `x1`, above `floor`. Inside it for three
/// seconds is a violation: a fine and a story at the end of the day.
public struct Airspace: Codable, Equatable, Sendable {
    public var x0: Double, x1: Double, floor: Double
    public init(x0: Double, x1: Double, floor: Double) { self.x0 = x0; self.x1 = x1; self.floor = floor }
    public func contains(x: Double, alt: Double) -> Bool { x > x0 && x < x1 && alt > floor }
    public static let fine = 1500, rep = 0.04, seconds = 3.0
}

public struct Winter: Codable, Equatable, Sendable {
    public var start: Int, end: Int
}

/// A bankrupt rival's hotel, offered to you at `Rules.hotelBargainShare` of its price.
public struct HotelBargain: Codable, Equatable, Sendable {
    public var hotel: Hotel
    public var rival: String
    public var price: Int
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
    /// Your seats that day.
    public var cap: Int
    public var rivals: [Int]
    public var demand: Int
    /// Tourists who came straight to you through referrals.
    public var extra: Int
}

public struct RepPoint: Codable, Equatable, Sendable {
    public var day: Int, rep: Double
}

public enum Feature: String, Codable, CaseIterable, Sendable {
    case insurance, fleet, bank, market, crew
    /// v121.9: split off the market, fleet and crew so something opens every day from day 2 to day 11.
    case guide, agency, bazaar, workshop, school
}

/// Hezarfen's one-off lessons. Text lives in the string catalog under `hez.<rawValue>`.
public enum Tip: String, Codable, CaseIterable, Sendable {
    case welcome, insurance, fleet, bank, market, crew, yellow, red, mission, accident, crisis
    case rivals, rivals2, rivals3, expect, antitrust, aging, absent, licenseHold, goals
    case pr, influ, prcap, bazaar, delegate, noRivals, show, price
    /// v124.6: empty seats yesterday because of low popularity, or more seats than tourists (`emptySeatCause`).
    case priceRep, priceRiv
    /// v117: "⏩ Advance" is open (`GameState.autopilotOK`).
    case autopilot
    /// v121: Hezarfen tells Hasan's story after the first flight in Cappadocia.
    case hasan
    /// v121.9: the buildings that open on their own day.
    case guide, agency, workshop, school
    /// v122.11: day 3's reminder to set the price for today's tourists (a tutorial save in Cappadocia). Always the
    /// morning's first card, and it says what `price` would, so it takes that lesson's place (`spreadMorning`).
    case price3
}

public enum HezMessage: Codable, Equatable, Sendable {
    case tip(Tip)
    case winterComing
    case spring
    case entrant(Entrant)
    /// Cappadocia baron: the holding opens.
    case holdingOpened
    case enteredRegion(RegionID)
    case fiestaStarted
    case regionIssue(RegionID, Issue)
    case officeOpened(Office)
    case allOffices
    case celebritySigned(Int)
    /// The region's rival boss speaks (text `boss.<region>.<line>`), once per region and line.
    case boss(RegionID, BossLine)
    /// A Cappadocia festival starts; index into its three festivals.
    case festivalStarted(Int)
    /// How a morning event you answered turned out.
    case eventOutcome(EventOutcome)
    /// A bazaar pattern or shape arrived as a design on this balloon (nil: no balloon).
    case bazaarGift(StoreItem, balloon: String?)
    /// v113: the Founder Pack arrived: how many items, and the balloon that got the first shape.
    case founderPack(count: Int, balloon: String?, shape: StoreItem?)
    /// v114: the workshop is founded: Hezarfen explains how it grows into a factory.
    case factoryOpened
    /// Cash is back above zero after the rescue plan.
    case rescued
    case worldBaron
    /// Hezarfen praises a good move in the first weeks.
    case praise(Praise)
    /// The new region's guide introduces themselves (Ben Franklin, Imhotep).
    case guideHello(RegionID)
    /// The guide of the region you're in praises a holding investment. Text: `hez.deed.<rawValue>`.
    case deed(HoldingDeed)
    /// A round day: 100, 200, 300, the first year, 400, 500, then every hundred. Text: `hez.milestone.<day>`.
    case milestone(Int)
    /// The civil aviation inspector about worn envelopes: `visit` 1 and 2 warn, from 3 a fine.
    case inspector(visit: Int, balloons: [String], fine: Int)
    /// A record attempt came to an end.
    case record(RecordAttempt, success: Bool)
    /// The flagship is out of repair and is yours to fly again (its name).
    case flagshipBack(String)
    /// v125: a contract company's owner speaks (`ctrSay`): `n` people (`today`), `price` a head (`red`).
    case contract(ContractOwner, ContractLine, n: Int, price: Int)
    /// v126: the first time a charter plane is late, Hezarfen says what the choice is.
    case contractDelayIntro
    /// v125: the pilots who came with you, and the balloons on the cargo arriving on `day`.
    case transferBrought(pilots: [String], balloons: [String], day: Int)
    /// v125: the cargo arrived: these balloons are in the fleet.
    case cargoArrived([String])
    /// v127: the factory or the cargo left balloons outside the full hangar (how many are outside now).
    case hangarFull(Int)
    /// v127: the reminder, at most every `Hangar.reminderDays` days, about the balloons outside the hangar.
    case hangarOutside(Int)
}

/// Shown once, before other popups, when two rivals join forces against you.
public struct MergeNews: Codable, Equatable, Sendable {
    public var a: String, b: String, name: String
    public var balloons: Int
    public var cash: Int
    public var sharePercent: Int
    public var rep: Double
    /// Colors of the bigger partner and the main color of the other.
    public var colors: [String]
}

/// A finished chapter, shown as a ceremony the next morning.
public struct ChapterNews: Codable, Equatable, Sendable {
    public var region: RegionID
    public var index: Int
}

public struct DayPlan: Codable, Equatable, Sendable {
    public var skipped: Bool
    public var flying: [Int]
    public var pax: [Int: Int]
    public var rivalPax: [Int]
    public var rivalCap: [Int]
    public var referrals: Int
    /// v125: today's contract group, seated first (optional: older saves).
    public var contract: ContractPlan? = nil
    /// v126: seats kept empty today for a late charter plane that didn't come (optional: older saves).
    public var contractWait: Int? = nil
}

@dynamicMemberLookup
public struct GameState: Codable, Equatable, Sendable {
    /// 2: per-region state and the holding. 3: buildings, morning events, the paper, store, postcards.
    /// Fields added in 3 are optional so a version 2 save still loads. 4: four chapters per region (`migrate`).
    public static let currentVersion = 4
    public var version = GameState.currentVersion

    public var day = 1
    public var company: String
    public var colors: [String]
    public var lastSelfFly = 1
    public var nextID = 1
    public var insureHull = true
    public var insurePax = true
    public var tutorialDone = false
    /// v111: flights you flew yourself (cancelled ones not counted); the first few get the flying coach.
    public var selfFlights: Int?
    public var unlocked: Set<Feature> = []
    /// v121.9: 2 once the one-building-a-day schedule applies; nil in older saves (`unlockCheck` migrates them).
    public var unlockVersion: Int?
    /// v121.12: a flight landed without a crash (the first-flight postcard).
    public var firstCleanFlight: Bool?
    /// v121.12: lessons and postcards held back for the next mornings, and the day they were last spread.
    public var hezLater: [HezMessage]?
    public var postcardsLater: [Achievement]?
    public var spreadDay: Int?
    /// v122: the tutorial that shows (steps done, and whether it's over). Nil in older saves (`tutorialCheck`).
    public var tutorial: TutorialState?
    public var tipsSeen: Set<Tip> = []
    public var hezQueue: [HezMessage] = []
    public var over = false

    /// The region you're playing. Its state is `local`; reach its fields directly (`state.cash`).
    public var region = RegionID.cap
    public var local: RegionState
    public var parked: [RegionID: ParkedRegion] = [:]
    /// Day you became baron of each region.
    public var barons: [RegionID: Int] = [:]
    public var holding = Holding()
    public var workshopDay: Int?
    /// v114: the workshop grown into a factory: its level, the balloon on the line, a rival's order waiting.
    public var factory: Factory?
    public var designs: [Design] = []
    public var chapterNews: ChapterNews?
    public var mergeNews: MergeNews?

    // Added in version 3. Read them through the accessors below.
    /// Headlines collected during the day for tomorrow's paper, and the paper waiting to be read.
    public var paperNext: [PaperItem]?
    public var paper: [PaperItem]?
    /// A morning event is due when the day's popups reach it.
    public var eventDue: Bool?
    /// The rescue plan was shown while cash is below zero.
    public var rescueShown: Bool?
    /// Boss lines already spoken, as "region.line".
    public var bossSaid: Set<String>?
    /// Day each postcard was earned, and the ones still to be shown.
    public var postcards: [Achievement: Int]?
    public var newPostcards: [Achievement]?
    public var stats: Stats?
    /// Day each store item was bought.
    public var store: [StoreItem: Int]?
    /// v113: the Balloon Show's bought figure the player picked (nil: the free one, by fleet size).
    public var showFig: StoreItem?
    /// Hezarfen's praise: the ones given, the day of the last, and the current run of good landings.
    public var praised: Set<Praise>?
    public var praiseDay: Int?
    public var goodRun: Int?
    /// v123: the family's letter (`S.letter`): the day it was shown, once from day 50, and whether its review button
    /// was tapped.
    public var letterDay: Int?
    public var letterRated: Bool?
    /// v123.1: the day Apple's rating prompt was asked for, once, after the first chapter's ceremony (`S.rateAsked`).
    public var rateAsked: Int?
    /// v125: entering a region asks once whether to bring balloons and pilots from the others (`S.xfer`).
    public var transferAsk: RegionID?
    /// v125.7: decorations put away in storage from the bazaar (`S.decorOff`). They stay owned; put away they aren't
    /// drawn in any town. nil (old saves): everything owned is placed.
    public var storedDecor: Set<StoreItem>?

    public var achievements: [Achievement: Int] { postcards ?? [:] }
    public var statistics: Stats { stats ?? Stats() }
    /// A pack's items come with the pack; the Supporter Edition holds the Grand Tour.
    public func owned(_ k: StoreItem) -> Bool {
        store?[k] != nil || k.pack.map { store?[$0] != nil } == true || (k == .worldTour && store?[.supporter] != nil)
    }
    /// Town decorations owned (v115: only the look; they no longer bring tourists).
    public var decorationCount: Int { StoreItem.allCases.filter { $0.kind == .decoration && owned($0) }.count }
    /// v125.7: a decoration that is owned and not put away in storage: the towns draw only these (prototype `placed`).
    public func placed(_ k: StoreItem) -> Bool { owned(k) && storedDecor?.contains(k) != true }
    /// The decorations owned, in the bazaar's order, for its "Your decorations" shelf.
    public var ownedDecorations: [StoreItem] { StoreItem.allCases.filter { $0.kind == .decoration && owned($0) } }

    public subscript<T>(dynamicMember path: WritableKeyPath<RegionState, T>) -> T {
        get { local[keyPath: path] }
        set { local[keyPath: path] = newValue }
    }

    public init(company: String, colors: [String]) {
        self.company = company
        self.colors = colors
        unlockVersion = 2
        tutorial = TutorialState()
        local = RegionState(rivals: RegionID.cap.startingRivals())
        local.balloons.append(Balloon(id: nextID, size: .S, name: Rules.balloonNames[0]))
        local.flagship = nextID
        nextID += 1
        // A rival never wears your colors.
        for i in local.rivals.indices where local.rivals[i].colors[0].lowercased() == colors.first?.lowercased() {
            if let alt = Rules.rivalColors.first(where: { c in c[0] != colors.first && !local.rivals.contains { $0.colors[0] == c[0] } }) {
                local.rivals[i].colors = alt
            }
        }
        // A local from Göreme is glad a proper company is starting up.
        local.reviews.append(Review(reviewer: Review.reviewers.count - 1, kind: .welcome, variant: 0, stars: 5, day: 1, args: [:]))
    }

    public var stars: Double { Rules.stars(local.rep) }
    public var licenseDaysLeft: Int { Rules.licenseDays - (day - lastSelfFly) }
    public var licenseValid: Bool { licenseDaysLeft >= 0 }
    /// With an expired license you must fly the flagship yourself (a free renewal flight) or pay to renew.
    public var flyingSelf: Bool { local.selfFly || !licenseValid }
    public var daysSinceSelfFly: Int { day - lastSelfFly }

    /// Flights an envelope lasts; holding research stretches it.
    public var envelopeLife: Int { holding.research > 0 ? Holding.researchLevels[holding.research - 1].life : Rules.envelopeLife }
    /// Envelope condition, 1 = new, 0 = grounded.
    public func condition(_ b: Balloon) -> Double { clamp(1 - b.flights / Double(envelopeLife), 0, 1) }

    public func balloon(_ id: Int) -> Balloon? { local.balloons.first { $0.id == id } }
    public func pilot(of b: Balloon) -> Pilot? { local.pilots.first { $0.id == b.pilot } }
    public func isSelf(_ b: Balloon) -> Bool { b.id == local.flagship && flyingSelf }
    public func hotelActive(_ h: Hotel) -> Bool { local.hotelDeals.contains(h) || local.ownHotels.contains(h) }
    public var activeHotels: [Hotel] { Hotel.allCases.filter(hotelActive) }
    /// A hotel or a guide flight in the last ten days lifts the popularity cap.
    public var prOK: Bool {
        !activeHotels.isEmpty || (local.lastGuide.map { day - $0 <= Rules.guideFresh } ?? false) || (local.lastShow.map { day - $0 <= Rules.guideFresh } ?? false)
    }
    /// Highest popularity without hotels or guides: 4.2★, or 4.5★ while an influencer campaign is fresh.
    public var prCap: Double { local.influencerCooldown > day ? Rules.prCapInfluencer : Rules.prCap }

    public func hotelIncome(_ h: Hotel) -> Int {
        jsRound(Double(h.roomIncome) * (stars < h.minStars ? 0.5 : 1) * (local.winter != nil ? 0.6 : 1))
    }

    /// `chartered`: hired out whole by a morning event; `late`: its pilot overslept; `strike`: its pilot is on strike;
    /// `outside`: v127, no room in the hangar.
    public enum FlyStatus: Equatable, Sendable { case ok, banned, damaged, worn, noPilot, licenseHold, chartered, late, strike, outside }

    /// v121.12: nothing can fly today and nothing can change that (all in repair, or a flying ban): the day has to be skipped.
    public var forcedSkip: Bool {
        !local.balloons.isEmpty && insideBalloons.allSatisfy { let s = status($0); return s == .damaged || s == .banned }
    }

    public func status(_ b: Balloon) -> FlyStatus {
        if local.banUntil >= day { return .banned }
        if isOutside(b) { return .outside }
        if b.damagedUntil > day { return .damaged }
        if condition(b) <= 0 { return .worn }
        if !licenseValid && b.id != local.flagship { return .licenseHold }
        if let c = local.charter, c.day == day, c.balloon == b.id { return .chartered }
        if let l = local.late, l.day == day, b.pilot == l.pilot, !isSelf(b) { return .late }
        if (local.strikeDay == day || (local.strikeUntil ?? -1) >= day) && !isSelf(b) { return .strike }
        if !isSelf(b) && b.pilot == nil { return .noPilot }
        return .ok
    }

    /// Seats you can sell in a balloon today: the documentary crew takes four in the flagship.
    public func sellSeats(_ b: Balloon) -> Int {
        let cap = b.size.capacity
        return cap - (local.docDay == day && b.id == local.flagship ? min(4, cap - 1) : 0)
    }

    /// Balloons that will actually go up today.
    public var flyingToday: [Balloon] { insideBalloons.filter { $0.fly && status($0) == .ok } }
    public var capacityToday: Int { flyingToday.reduce(0) { $0 + sellSeats($1) } }

    public var influencerCost: Int { Rules.influencerCost(balloons: local.balloons.count) }

    /// Flagship first, then biggest, then by name; v127: the balloons outside the hangar last.
    public var sortedFleet: [Balloon] {
        let out = outsideIDs
        return local.balloons.sorted {
            (out.contains($0.id) ? 0 : 1, $0.id == local.flagship ? 1 : 0, $0.size.capacity, $1.name) > (out.contains($1.id) ? 0 : 1, $1.id == local.flagship ? 1 : 0, $1.size.capacity, $0.name)
        }
    }

    /// Hired pilots with no balloon to fly.
    public var idlePilots: [Pilot] {
        let busy = Set(local.balloons.compactMap(\.pilot))
        return local.pilots.filter { !busy.contains($0.id) }
    }

    public func isBaron(_ r: RegionID? = nil) -> Bool { barons[r ?? region] != nil }
    /// v117: the autopilot ("⏩ Advance", played by the app) opens with a big company: enough balloons here and
    /// Baron of Cappadocia.
    public var autopilotOK: Bool { insideBalloons.count >= Rules.autopilotBalloons && isBaron(.cap) }
    public var anyBaron: Bool { !barons.isEmpty }
    public func owns(_ r: RegionID) -> Bool { r == region || parked[r] != nil }
    public func design(of b: Balloon) -> Design? { b.design.flatMap { id in designs.first { $0.id == id } } }

    /// The region's old-money rival, if still in the market under its name.
    public var bossRival: Rival? { local.rivals.first { $0.name == region.bossCompany } }

    /// A region opens when you're the baron of the one before it.
    public func regionOpen(_ r: RegionID) -> Bool { r.unlockedBy.map { barons[$0] != nil } ?? true }
}

/// Company-wide counters for postcards.
public struct Stats: Codable, Equatable, Sendable {
    public var missions = 0, perfectLandings = 0, passengers = 0
}
