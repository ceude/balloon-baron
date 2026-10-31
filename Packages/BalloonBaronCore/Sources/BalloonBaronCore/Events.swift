import Foundation

/// Something that happened during a day. The app turns these into localized sentences.
public enum DayEvent: Codable, Equatable, Sendable {
    public enum Pilot: Codable, Equatable, Sendable { case you, named(String), unknown }
    public enum Cover: Codable, Equatable, Sendable { case all, hullOnly, paxOnly, none }

    // Your company
    case cancelled(balloon: String, pax: Int, compensation: Int)
    case missionDone(Mission, reward: Int)
    case missionFailed(Mission)
    case perfectLanding(balloon: String, tips: Int)
    case goodLanding(balloon: String)
    case farLanding(balloon: String, meters: Int)
    case accident(balloon: String, pilot: Pilot, severe: Bool, days: Int, repair: Int, compensation: Int, cover: Cover)
    case redCaught(strikes: Int)
    case redBan
    case redUnseen
    case pilotPromoted(name: String, level: PilotLevel, wage: Int)
    case envelopeWorn(balloon: String)
    case licenseExpiring
    /// v111: the Balloon Show is tonight, with this many balloons.
    case showTonight(balloons: Int)
    /// v114: your own balloon is ready from the workshop and has joined the fleet.
    case factoryReady(balloon: String, size: BalloonSize)
    /// v114: the workshop delivered a rival's order; the price came in.
    case factoryDelivered(rival: String, size: BalloonSize, price: Int)
    /// v114: the rival that ordered is gone: it had paid, the balloon stays with you.
    case factoryKept(rival: String, price: Int)
    /// v114 (rivals' column): a rival asks the workshop for a balloon.
    case factoryOrderAsk(rival: String, size: BalloonSize)
    /// v111: balloons that crashed today drop out of tonight's show; their fee comes back.
    case showDropped(refund: Int)
    /// v111: too few balloons left after today's crashes: tonight's show is called off, the rest of the fees come back.
    case showCancelled(refund: Int)
    /// v111: in your first own flights a crash costs one day in repair.
    case rookieRepair
    /// v121.12: your only balloon is repaired in a hurry.
    case onlyBalloonRepair(days: Int)
    case licenseRenewedByFlight
    case founderAbsent(days: Int)
    case antitrustFine(sharePercent: Int, fine: Int)
    case seized(balloon: String, value: Int)
    case hotelLeft(Hotel)
    case chapterDone(String, reward: Int)
    case baron(RegionID)
    /// A small moment in your flight (a thermal, a greeting, a sunrise photo) and the tips it brought.
    case moment(FlightMoment.Kind, tips: Int)
    /// v124 Bristol: the first safe flight on a foggy morning; landing among sheep or cows (the farmer's due); in the
    /// tidal mud; the airport's fine; the festival's evening ascent; tonight's Night Glow.
    case fogFlown
    case farmLanding(PenAnimal, fine: Int)
    case mudLanding
    case airspaceFine(fine: Int)
    case eveningAscent(balloons: Int, pax: Int, income: Int)
    case nightGlowTonight(balloons: Int)
    /// v125 contracts: a foggy morning under Bristol's guarantee (refund and vouchers); a red flag (nothing owed); the
    /// group flew (`dayN`/`len` for a block, 0 for one day); seats missing; a job that never flew for the weather; jobs
    /// done in full with the owner so far; trust lost over people left on the ground.
    case contractFog(company: String, n: Int, voucher: Int)
    case contractRed(company: String)
    case contractFlown(company: String, dayN: Int, len: Int, n: Int, price: Int, total: Int)
    case contractShort(short: Int, perSeat: Int, total: Int)
    case contractWeather(company: String)
    case contractProgress(owner: ContractOwner, ok: Int, need: Int)
    case contractTrustDown(owner: ContractOwner, short: Int)
    /// v126: the evening before a charter group's first morning: "the plane may be late" (the owner's `warn` line).
    case contractDelayWarning(owner: ContractOwner)
    /// v126: seats kept for a late plane flew empty; the agency pays `amount` for them.
    case contractDelayNoShow(owner: ContractOwner, seats: Int, amount: Int)
    /// v125: a rival flies a contract group you didn't take (and bought this many balloons with it).
    case rivalFlewGroup(rival: String, company: String, n: Int, len: Int, balloons: Int)

    // Rivals
    case rivalFleetSold(rival: String)
    case rivalShrank(rival: String)
    case newEntrant(rival: String)
    case rivalAccidents(rival: String, count: Int)
    case rivalRedFined(rival: String)
    case rivalRedSneaked(rival: String)
    case poachAttempt(rival: String, pilot: String)
    case rivalHotelDeal(rival: String, hotel: Hotel)
    case rivalStoleHotel(rival: String, hotel: Hotel)
    case rivalCampaign(rival: String)
    case rivalPrice(rival: String, from: Int, to: Int)
    case rivalNewBalloon(rival: String)
    case rivalBankrupt(rival: String, balloons: Int, price: Int)
    case rivalForSale(rival: String, price: Int)
    case rivalsMerged(a: String, b: String, name: String, balloons: Int)
}

public struct Ledger: Codable, Equatable, Sendable {
    // Income
    public var tickets = 0, founderBonus = 0, hotelIncome = 0, mission = 0, ads = 0, tips = 0, insurancePaid = 0, seizure = 0
    public var chapterReward = 0
    /// v124: tickets of a Bristol festival's evening ascent (optional: older saved reports).
    public var evening: Int?
    /// v125: a contract group's pay and size, the missing seats' penalty, Bristol's fog vouchers, and the day's payment
    /// for balloons brought from home (optional: older saved reports).
    public var contract: Int?
    public var contractN: Int?
    public var contractPenalty: Int?
    public var contractVoucher: Int?
    /// v126: what the agency paid for seats kept empty for a late charter plane.
    public var contractWait: Int?
    public var transfer: Int?
    public var missionDone: Mission?
    public var adRepLoss = 0.0
    /// Popularity your designs brought today.
    public var designRep = 0.0
    /// What reached the holding today from parked regions, after its expenses. Not part of `net`.
    public var holdingNet = 0
    // Costs
    public var fuel = 0, wages = 0, upkeep = 0, insurance = 0, loans = 0, repairs = 0, compensation = 0
    public var fines = 0, cancellations = 0, hotelFees = 0, antitrust = 0

    public var net: Int {
        tickets + (evening ?? 0) + (contract ?? 0) + (contractWait ?? 0) - (contractPenalty ?? 0) - (contractVoucher ?? 0) - (transfer ?? 0) + founderBonus + hotelIncome + mission + ads + tips + insurancePaid + seizure + chapterReward
            - fuel - wages - upkeep - insurance - loans - repairs - compensation - fines - cancellations - hotelFees - antitrust
    }
}

public struct DayReport: Codable, Equatable, Sendable {
    public var day: Int
    public var flag: Flag
    public var ledger: Ledger
    public var events: [DayEvent]
    public var rivalEvents: [DayEvent]
    public var passengers: Int
    public var capacity: Int
    public var skipped: Bool
    /// v124.6: popularity before and after the day, and what moved it (`RepReason`).
    public var repFrom: Double?
    public var repTo: Double?
    public var repWhy: [RepReason: Double]?
    public var net: Int { ledger.net }

    /// The biggest reasons (at least 0.02★), largest first, at most three.
    public var repReasons: [(RepReason, Double)] {
        (repWhy ?? [:]).filter { abs($0.value) * 4 >= 0.02 }.sorted { abs($0.value) > abs($1.value) }.prefix(3).map { ($0.key, $0.value) }
    }
}

/// v124.6: why popularity changed on a day. Text: `repWhy.<rawValue>`.
public enum RepReason: String, Codable, CaseIterable, Sendable {
    case cancelled, traits, ads, mission, moment, perfect, good, far, farm, mud, airspace, pilotsSafe
    case hard, crash, pilotAccident, hotels, drift, xl, designs, glow, show, prCap, absent, influencer
    /// v125: a contract group left on the ground.
    case contract
}

/// How the player's own flight ended, reported by the flight scene.
public struct FlightResult: Codable, Equatable, Sendable {
    public enum Landing: String, Codable, Sendable { case perfect, good, far, hard, crash, cancel }
    public var landing: Landing
    public var distance: Double
    public var mission: Mission?
    public var missionDone: Bool
    /// The flight moment you caught, if any.
    public var moment: FlightMoment.Kind?
    /// v124 Bristol: landed in a field with these animals, in the tidal mud, and stayed in the airport's airspace.
    public var farm: PenAnimal?
    public var mud: Bool?
    public var airFine: Bool?

    public init(landing: Landing, distance: Double = 0, mission: Mission? = nil, missionDone: Bool = false, moment: FlightMoment.Kind? = nil) {
        self.landing = landing; self.distance = distance; self.mission = mission; self.missionDone = missionDone; self.moment = moment
    }
}
