import Foundation
import BalloonBaronCore

/// Looks up `key` in Localizable.xcstrings and fills `%@` / `%1$@` placeholders.
func loc(_ key: String, _ args: CVarArg...) -> String {
    let format = Bundle.main.localizedString(forKey: key, value: nil, table: nil)
    return args.isEmpty ? format : String(format: format, locale: .current, arguments: args)
}

/// The region on screen. `GameStore` keeps it in sync so money and local names follow the region.
var currentRegion: RegionID = .cap

/// Money of the region you're playing (euros in Cappadocia, dollars in Albuquerque), without cents,
/// in the player's locale (€1.213, 1.213 €, $1,213…).
func eur(_ n: Int) -> String {
    n.formatted(.currency(code: currentRegion.currency).precision(.fractionLength(0)))
}

/// Holding money, always euros.
func eurH(_ n: Int) -> String {
    n.formatted(.currency(code: "EUR").precision(.fractionLength(0)))
}

func percent(_ x: Double) -> String { x.formatted(.percent.precision(.fractionLength(0))) }

func starsValue(_ stars: Double) -> String {
    stars.formatted(.number.precision(.fractionLength(1))) + "★"
}

func num(_ n: Int) -> String { n.formatted() }

func starsText(_ rep: Double) -> String {
    Rules.stars(rep).formatted(.number.precision(.fractionLength(1))) + "★"
}

/// Some names differ per region: Albuquerque has its own hotels, sponsors and valley mission.
private func regional(_ key: String, _ local: Bool = true) -> String {
    local && currentRegion != .cap ? loc("\(currentRegion.rawValue).\(key)") : loc(key)
}

extension Mission {
    var title: String { regional("mission.\(rawValue)", self == .valley) }
    var detail: String { regional("mission.desc.\(rawValue)", self == .valley) }
}
extension Hotel { var title: String { regional("hotel.\(rawValue)") } }
extension Sponsor { var title: String { regional("sponsor.\(rawValue)") } }
extension RegionID { var title: String { loc("region.\(rawValue)") } }
extension MapPin {
    var title: String { mystery ? loc("map.soon") : loc("pin.\(rawValue)") }
    var land: String { loc("pin.\(rawValue).land") }
}
extension Pattern { var title: String { loc("pattern.\(rawValue)") } }
extension Office {
    var title: String { loc("office.\(rawValue)") }
    var perk: String { loc("office.\(rawValue).perk") }
    var icon: String { ["🕌", "🗽", "🏙️", "🗼"][Office.allCases.firstIndex(of: self)!] }
}
extension Design {
    var title: String { gift?.title ?? (name.isEmpty ? "\(pattern.title) \(number)" : name) }
}
extension EnvelopeShape { var title: String { storeItem.title } }
extension StoreItem { var title: String { loc("store.\(rawValue)") } }
extension PilotTrait {
    var title: String { loc("trait.\(rawValue)") }
    var detail: String { loc("trait.\(rawValue).d") }
}
extension Building {
    var title: String { loc("building.\(rawValue)") }
    /// What level `n` (2 or 3) is called and does.
    func levelTitle(_ n: Int) -> String { loc("building.\(rawValue).\(n)") }
    func levelDetail(_ n: Int) -> String { loc("building.\(rawValue).\(n).d") }
}
extension Achievement {
    var title: String { loc("ach.\(rawValue)") }
    var detail: String { loc("ach.\(rawValue).d") }
}
extension HoldingGoal { var title: String { loc("hgoal.\(rawValue)") } }
extension MorningEvent {
    var title: String { loc("event.\(rawValue).title") }
}
func festivalName(_ i: Int) -> String { loc("festival.\(i)") }
extension Chapter {
    var title: String { loc("chapter.\(id)") }
    var award: String { loc("chapter.\(id).award") }
}
extension Issue {
    var title: String { loc("issue.\(rawValue)") }
    var body: String { loc("issue.\(rawValue).body") }
    var hezarfen: String { loc("issue.\(rawValue).hez") }
    func option(_ c: Choice) -> String { loc("issue.\(rawValue).\(c == .a ? "a" : "b")") }
    func note(_ c: Choice) -> String { loc("issue.\(rawValue).\(c == .a ? "a" : "b").note") }
}
func celebrityName(_ i: Int) -> String { loc("celebrity.\(i)") }

extension Goal {
    func label(region: RegionID) -> String {
        switch kind {
        case .balloons: loc("goal.balloons", num(Int(target)))
        case .pilots: loc("goal.pilots", num(Int(target)))
        case .stars: loc("goal.stars", starsValue(target))
        case .cash: loc("goal.cash", eur(Int(target)))
        case .hotelOwn: loc("goal.hotelOwn", num(Int(target)))
        case .share: loc("goal.share", percent(target))
        case .xl: loc("goal.xl", region.xlName)
        default: loc("goal.\(kind.rawValue)")
        }
    }
}

extension GameState {
    /// "3/5", "4.2★ / 4.8★", "done" …
    func progressText(_ g: Goal) -> String {
        let v = value(g.kind)
        if g.kind.yesNo { return loc(v >= g.target ? "goal.done" : "goal.notYet") }
        switch g.kind {
        case .stars: return "\(starsValue(v)) / \(starsValue(g.target))"
        case .cash: return "\(eur(Int(v))) / \(eur(Int(g.target)))"
        case .share: return "\(percent(v)) / \(percent(g.target))"
        default: return "\(num(Int(v)))/\(num(Int(g.target)))"
        }
    }
}
extension PilotLevel { var title: String { loc("level.\(rawValue)") } }
extension BalloonSize { var title: String { loc("size.\(rawValue)") } }

extension Flag {
    var title: String { loc("flag.\(rawValue)") }
    var note: String { loc("flag.note.\(rawValue)") }
}

extension HezMessage {
    var text: String {
        switch self {
        case .tip(let t): loc("hez.\(t.rawValue)")
        case .winterComing: loc("hez.winterComing")
        case .spring: loc("hez.spring")
        case .entrant(let e): loc("hez.entrant.\(e.rawValue)")
        case .holdingOpened: loc("hez.holdingOpened")
        case .enteredRegion(let r): loc("hez.entered.\(r.rawValue)", eur(Rules.startCash))
        case .fiestaStarted: loc("hez.fiestaStarted")
        case let .regionIssue(r, i): loc("hez.regionIssue", r.title, i.body)
        case .officeOpened(let o): loc("hez.officeOpened", o.title) + " " + o.perk
        case .allOffices: loc("hez.allOffices")
        case .celebritySigned(let i): loc("hez.celebritySigned", celebrityName(i))
        case let .boss(r, line): loc("boss.\(r.rawValue).\(line.rawValue)")
        case .festivalStarted(let i): loc("hez.festival.\(i)")
        case .eventOutcome(let o): loc("outcome.\(o.rawValue)")
        case let .bazaarGift(k, b): b.map { loc("hez.bazaarGift", k.title, $0) } ?? loc("hez.bazaarGift.noBalloon", k.title)
        case .rescued: loc("hez.rescued")
        case .worldBaron: loc("hez.worldBaron")
        }
    }
}

extension Review {
    func text(company: String, designs: [Design] = []) -> String {
        var t = loc("review.\(kind.rawValue).\(variant)")
        var values = args
        values["c"] = company
        if let d = values["d"], let id = Int(d) { values["d"] = designs.first { $0.id == id }?.title ?? "" }
        if let s = values["s"], let sponsor = Sponsor(rawValue: s) { values["s"] = sponsor.title }
        if let p = values["p"], let n = Int(p) { values["p"] = eur(n) }
        for (k, v) in values { t = t.replacingOccurrences(of: "{\(k)}", with: v) }
        return t
    }
    var place: String { loc("country.\(country)") }
}

extension DayEvent {
    var text: String {
        switch self {
        case let .cancelled(b, pax, comp): loc("event.cancelled", b, num(pax), eur(comp))
        case let .missionDone(m, reward): loc("event.missionDone", m.title, eur(reward))
        case let .missionFailed(m): loc("event.missionFailed", m.title)
        case let .perfectLanding(b, tips): loc("event.perfectLanding", b, eur(tips))
        case let .goodLanding(b): loc("event.goodLanding", b)
        case let .farLanding(b, m): loc("event.farLanding", b, num(m))
        case let .accident(b, pilot, severe, days, repair, comp, cover):
            loc(severe ? "event.accident.severe" : "event.accident.light", b, pilot.title, num(days), eur(repair), eur(comp))
                + " " + loc("cover.\(cover.key)")
        case let .redCaught(s): loc("event.redCaught", num(s), eur(Rules.redFine))
        case .redBan: loc("event.redBan")
        case .redUnseen: loc("event.redUnseen")
        case let .pilotPromoted(name, level, wage): loc("event.pilotPromoted", name, level.title, eur(wage))
        case let .envelopeWorn(b): loc("event.envelopeWorn", b)
        case .licenseExpiring: loc("event.licenseExpiring")
        case .licenseRenewedByFlight: loc("event.licenseRenewedByFlight")
        case let .founderAbsent(days): loc("event.founderAbsent", num(days))
        case let .antitrustFine(share, fine): loc("event.antitrustFine", num(share), eur(fine))
        case let .seized(b, v): loc("event.seized", b, eur(v))
        case let .hotelLeft(h): loc("event.hotelLeft", h.title)
        case let .chapterDone(id, reward): loc("event.chapterDone", loc("chapter.\(id)"), loc("chapter.\(id).award"), eur(reward))
        case let .baron(r): loc("event.baron", loc("chapter.\(r.chapters.last!.id)"))
        case let .moment(k, tips): loc("event.moment.\(k.rawValue)", eur(tips))
        case let .rivalFleetSold(r): loc("event.rivalFleetSold", r)
        case let .newEntrant(r): loc("event.newEntrant", r, currentRegion.title)
        case let .rivalAccidents(r, n): loc("event.rivalAccidents", r, num(n))
        case let .rivalRedFined(r): loc("event.rivalRedFined", r, eur(Rules.redFine))
        case let .rivalRedSneaked(r): loc("event.rivalRedSneaked", r)
        case let .poachAttempt(r, p): loc("event.poachAttempt", r, p)
        case let .rivalHotelDeal(r, h): loc("event.rivalHotelDeal", r, h.title)
        case let .rivalStoleHotel(r, h): loc("event.rivalStoleHotel", r, h.title)
        case let .rivalCampaign(r): loc("event.rivalCampaign", r)
        case let .rivalPrice(r, from, to): loc("event.rivalPrice", r, eur(from), eur(to))
        case let .rivalNewBalloon(r): loc("event.rivalNewBalloon", r)
        case let .rivalBankrupt(r, n, price): loc("event.rivalBankrupt", r, num(n), eur(price))
        case let .rivalForSale(r, price): loc("event.rivalForSale", r, eur(price))
        case let .rivalsMerged(a, b, name, n): loc("event.rivalsMerged", a, b, name, num(n))
        }
    }
}

extension DayEvent.Pilot {
    var title: String {
        switch self {
        case .you: loc("pilot.you")
        case .named(let n): n
        case .unknown: loc("pilot.unknown")
        }
    }
}

extension DayEvent.Cover {
    var key: String {
        switch self {
        case .all: "all"
        case .hullOnly: "hullOnly"
        case .paxOnly: "paxOnly"
        case .none: "none"
        }
    }
}
