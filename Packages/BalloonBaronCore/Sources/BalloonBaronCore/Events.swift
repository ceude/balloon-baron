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
    case antitrustFine(sharePercent: Int, fine: Int)
    case seized(balloon: String, value: Int)
    case hotelLeft(Hotel)

    // Rivals
    case rivalFleetSold(rival: String)
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
}

public struct Ledger: Codable, Equatable, Sendable {
    // Income
    public var tickets = 0, hotelIncome = 0, mission = 0, ads = 0, tips = 0, insurancePaid = 0, seizure = 0
    public var missionDone: Mission?
    public var adRepLoss = 0.0
    // Costs
    public var fuel = 0, wages = 0, upkeep = 0, insurance = 0, loans = 0, repairs = 0, compensation = 0
    public var fines = 0, cancellations = 0, hotelFees = 0, antitrust = 0

    public var net: Int {
        tickets + hotelIncome + mission + ads + tips + insurancePaid + seizure
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
    public var net: Int { ledger.net }
}

/// How the player's own flight ended, reported by the flight scene.
public struct FlightResult: Codable, Equatable, Sendable {
    public enum Landing: String, Codable, Sendable { case perfect, good, far, hard, crash, cancel }
    public var landing: Landing
    public var distance: Double
    public var mission: Mission?
    public var missionDone: Bool

    public init(landing: Landing, distance: Double = 0, mission: Mission? = nil, missionDone: Bool = false) {
        self.landing = landing; self.distance = distance; self.mission = mission; self.missionDone = missionDone
    }
}
