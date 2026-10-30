import Foundation

/// Every week or so something happens at one of your buildings and you decide. Text: `event.<rawValue>.*`.
public enum MorningEvent: String, Codable, CaseIterable, Sendable {
    case strike, vip, wedding, doc, fuel, press

    /// Grid point of the town the camera flies to (the office, a hotel, the hangar).
    public var townSpot: (Double, Double) {
        switch self {
        case .strike, .press: (9.3, 13.6)
        case .vip: (5.5, 12.8)
        case .wedding: (5, 10.2)
        case .doc: (10, 10.4)
        case .fuel: (2.5, 2.4)
        }
    }
}

/// What came of an answered morning event, told by Hezarfen. Text: `outcome.<rawValue>`.
public enum EventOutcome: String, Codable, Sendable {
    case strikeRaised, strikeEndured, vip, wedding, doc, fuelStocked, pressGood, pressBad
}

/// The numbers a morning event's card shows.
public struct EventOffer: Equatable, Sendable {
    /// Wages per day now, and what the 15% raise adds.
    public var wages = 0, raise = 0
    /// The balloon a VIP or wedding party wants, and what they pay up front.
    public var balloon: String?
    public var pay = 0
    /// Propane stock that beats the coming price rise.
    public var stock = 0

    public init() {}
}

/// A headline for the morning paper. The biggest story leads. Text: `paper.<kind>` (+ `.sub`).
public enum PaperItem: Codable, Equatable, Sendable {
    case vip, wedding, documentary, pressGood, pressBad
    case accident(balloon: String, days: Int, severe: Bool)
    case redCaught(fine: Int)
    case antitrust(sharePercent: Int, fine: Int)
    case seized(balloon: String)
    case festival(Int)
    case rivalAccident(rival: String, count: Int)
    case rivalRedCaught(rival: String, fine: Int)
    case rivalBankrupt(rival: String, balloons: Int)
    case newEntrant(rival: String)
    case hotelLost(Hotel, rival: String)
    case record(pax: Int)
    case passedBoss(rival: String)
    case upgrade(Building, level: Int)
    case worldBaron
    case night(NightEvent)
    case inspectorFine(fine: Int)
    case worldRecord(RecordAttempt)
    /// A holding investment makes the next morning's paper.
    case deed(HoldingDeed)
    /// The company's round day.
    case milestone(Int)
    /// v111: last night's Balloon Show, with this many balloons.
    case show(balloons: Int)
    /// v114: the workshop grew a level.
    case factoryGrew(company: String, level: Int)
    /// v124 Bristol: the airport's fine; tonight's Night Glow (the company lit up the festival night); the festival opens.
    case airspace(fine: Int)
    case nightGlow(balloons: Int)
    case briFestival
    /// v125: you became a contract company's preferred operator; a rival flew a group you didn't take.
    case preferredOperator(company: String, kind: ContractKind)
    case rivalGroup(rival: String, company: String, n: Int, len: Int, balloons: Int, kind: ContractKind)

    public var priority: Int {
        switch self {
        case .upgrade, .night(.shootingStar), .factoryGrew: 1
        case .vip, .wedding, .record, .night, .milestone: 2
        case .documentary, .pressGood, .pressBad, .rivalAccident, .rivalRedCaught, .hotelLost, .inspectorFine, .deed: 3
        case .accident(_, _, let severe): severe ? 5 : 3
        case .redCaught, .festival, .newEntrant, .passedBoss, .show, .nightGlow, .briFestival: 4
        case .airspace, .preferredOperator, .rivalGroup: 3
        case .antitrust, .seized: 5
        case .rivalBankrupt, .worldBaron, .worldRecord: 6
        }
    }
}

/// Something that lights up the night. Text: `night.<kind>`.
public enum NightEvent: Codable, Equatable, Sendable {
    /// The festival's lantern walk through the valley.
    case lanterns(festival: Int)
    /// Fiesta night: balloons on the ground fire their burners.
    case balloonGlow
    /// The first night of winter, snow and lit windows.
    case snow
    /// A wedding's fireworks over one of the hotels.
    case fireworks(Hotel)
    case shootingStar
    /// v111: your Balloon Show over the town, with these balloons.
    case show(balloons: [Int])
    /// v124 Bristol: the booked Night Glow, with this many balloons; a festival evening's ascent at dusk.
    case nightGlow(balloons: Int)
    case eveningAscent(balloons: Int)
}

extension Game {
    mutating func addPaper(_ p: PaperItem) {
        state.paperNext = (state.paperNext ?? []) + [p]
    }

    /// Today's paper, biggest story first, at most three. Reading it clears it.
    public mutating func readPaper() -> [PaperItem] {
        let list = (state.paper ?? []).enumerated().sorted { ($0.element.priority, -$0.offset) > ($1.element.priority, -$1.offset) }.prefix(3).map(\.element)
        state.paper = nil
        return Array(list)
    }

    /// Yesterday's headlines go to print when a new day starts.
    mutating func printPaper() {
        if let next = state.paperNext, !next.isEmpty {
            state.paper = next
            state.paperNext = nil
        }
    }

    // MARK: Morning events

    /// A morning event every 7–8 days once the crew building is open, never in winter.
    mutating func scheduleEvent() {
        if state.day >= 12 && state.unlocked.contains(.crew) && state.winter == nil && state.day >= (state.nextEvent ?? 12) {
            state.eventDue = true
            state.nextEvent = state.day + 7 + (rng.chance(0.5) ? 1 : 0)
        }
    }

    /// The balloon a charter party would take: the biggest that can fly, other than the flagship.
    var spareBalloon: Balloon? {
        state.balloons.filter { $0.id != state.flagship && state.status($0) == .ok }.sorted { $0.size.capacity > $1.size.capacity }.first
    }

    func eventPossible(_ e: MorningEvent) -> Bool {
        switch e {
        case .strike: return state.pilots.count >= 2
        case .vip, .wedding: return spareBalloon != nil
        case .doc: return state.balloon(state.flagship).map { state.status($0) == .ok } ?? false
        case .fuel: return state.balloons.count >= 2
        case .press: return true
        }
    }

    /// Draws today's event (never the same as last time). Nil when none fits.
    public mutating func drawMorningEvent() -> MorningEvent? {
        state.eventDue = false
        let keys = MorningEvent.allCases.filter { eventPossible($0) && $0 != state.lastEvent }
        guard !keys.isEmpty else { return nil }
        let e = rng.pick(keys)
        state.lastEvent = e
        return e
    }

    func raisedWage(_ p: Pilot) -> Int { jsRound(Double(p.wage) * 1.15 / 5) * 5 }

    public func eventOffer(_ e: MorningEvent) -> EventOffer {
        var o = EventOffer()
        o.wages = state.pilots.reduce(0) { $0 + $1.wage }
        o.raise = state.pilots.reduce(0) { $0 + raisedWage($1) - $1.wage }
        if let b = spareBalloon {
            o.balloon = b.name
            o.pay = jsRound(Double(b.size.capacity * state.price) * (e == .vip ? 2.2 : 1.4) / 50) * 50
        }
        let fuel = state.balloons.reduce(0) { $0 + $1.size.fuel }
        o.stock = jsRound(Double(fuel * 5) * 0.25 / 50) * 50
        return o
    }

    /// Answer an event: `accept` is the card's main button. Returns Hezarfen's comment, if any.
    @discardableResult
    public mutating func answerEvent(_ e: MorningEvent, accept: Bool) -> EventOutcome? {
        let o = eventOffer(e)
        switch (e, accept) {
        case (.strike, true):
            for i in state.pilots.indices { state.pilots[i].customWage = raisedWage(state.pilots[i]) }
            return .strikeRaised
        case (.strike, false):
            // Only the founder flies today.
            state.strikeDay = state.day
            state.rep -= 0.02
            state.selfFly = true
            assignPilots()
            return .strikeEndured
        case (.vip, true), (.wedding, true):
            guard let b = spareBalloon else { return nil }
            let vip = e == .vip
            state.cash += o.pay
            state.charter = Charter(day: state.day, balloon: b.id)
            state.rep += vip ? 0.02 : 0.015
            addReview(vip ? .perfect : .good)
            addPaper(vip ? .vip : .wedding)
            return vip ? .vip : .wedding
        case (.doc, true):
            state.docDay = state.day
            state.rep += 0.06
            addPaper(.documentary)
            return .doc
        case (.fuel, true):
            guard state.cash >= o.stock else { return nil }
            state.cash -= o.stock
            return .fuelStocked
        case (.fuel, false):
            state.fuelUpUntil = state.day + 4
            return nil
        case (.press, true):
            if rng.chance(0.65) {
                state.rep += 0.05
                addPaper(.pressGood)
                return .pressGood
            }
            state.rep -= 0.03
            addPaper(.pressBad)
            return .pressBad
        default:
            return nil
        }
    }

    // MARK: Rescue plan

    /// Cash went below zero and the rescue plan hasn't been offered yet.
    public var rescueDue: Bool { state.cash < 0 && state.rescueShown != true }

    public mutating func markRescueShown() { state.rescueShown = true }

    /// After a move on the rescue card: true (and Hezarfen's well done) once cash is back above zero.
    public mutating func rescueStepDone() -> Bool {
        guard state.cash >= 0 else { return false }
        state.rescueShown = nil
        state.hezQueue.insert(.rescued, at: 0)
        return true
    }

    /// With cash above zero again the plan can come back next time it dips.
    public mutating func clearRescue() { if state.cash >= 0 { state.rescueShown = nil } }

    public mutating func fireIdlePilots() {
        let idle = Set(state.idlePilots.map(\.id))
        state.pilots.removeAll { idle.contains($0.id) }
        assignPilots()
    }

    // MARK: Night

    /// The night between two days. Picks what lights it up (if anything) and puts it in tomorrow's paper.
    public mutating func startNight() -> NightEvent? {
        let ev: NightEvent?
        if state.local.showTonight == state.day - 1, let ids = state.local.showIDs {
            // The Balloon Show has its own headline (made in finishDay).
            return .show(balloons: ids)
        } else if state.local.glowTonight == state.day - 1 {
            // v124: Bristol's festival evenings: the booked Night Glow, otherwise the evening ascent at dusk
            ev = .nightGlow(balloons: state.local.glowN ?? glowFleet.count)
        } else if state.region.bristol && state.local.eveDay == state.day - 1 {
            ev = .eveningAscent(balloons: state.local.eveN ?? 1)
        } else if let f = state.festival {
            ev = .lanterns(festival: f.index)
        } else if state.fiesta != nil {
            ev = .balloonGlow
        } else if let w = state.winter, state.winterNight != w.start {
            state.winterNight = w.start
            ev = .snow
        } else {
            let r = rng.unit()
            ev = r < 0.22 ? .fireworks(rng.pick(Hotel.allCases)) : r < 0.32 ? .shootingStar : nil
        }
        if let ev { addPaper(.night(ev)) }
        return ev
    }
}
