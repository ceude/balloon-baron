import Foundation
import BalloonBaronCore

/// Looks up `key` in Localizable.xcstrings and fills `%@` / `%1$@` placeholders.
func loc(_ key: String, _ args: CVarArg...) -> String {
    let format = Bundle.main.localizedString(forKey: key, value: nil, table: nil)
    return args.isEmpty ? format : String(format: format, locale: .current, arguments: args)
}

/// Euros without cents, in the player's locale (€1.213, 1.213 €, €1,213…).
func eur(_ n: Int) -> String {
    n.formatted(.currency(code: "EUR").precision(.fractionLength(0)))
}

func num(_ n: Int) -> String { n.formatted() }

func starsText(_ rep: Double) -> String {
    Rules.stars(rep).formatted(.number.precision(.fractionLength(1))) + "★"
}

extension Mission {
    var title: String { loc("mission.\(rawValue)") }
    var detail: String { loc("mission.desc.\(rawValue)") }
}
extension Hotel { var title: String { loc("hotel.\(rawValue)") } }
extension Sponsor { var title: String { loc("sponsor.\(rawValue)") } }
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
        }
    }
}

extension Review {
    func text(company: String) -> String {
        var t = loc("review.\(kind.rawValue).\(variant)")
        var values = args
        values["c"] = company
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
        case let .redCaught(s): loc("event.redCaught", num(s))
        case .redBan: loc("event.redBan")
        case .redUnseen: loc("event.redUnseen")
        case let .pilotPromoted(name, level, wage): loc("event.pilotPromoted", name, level.title, eur(wage))
        case let .envelopeWorn(b): loc("event.envelopeWorn", b)
        case .licenseExpiring: loc("event.licenseExpiring")
        case let .antitrustFine(share, fine): loc("event.antitrustFine", num(share), eur(fine))
        case let .seized(b, v): loc("event.seized", b, eur(v))
        case let .hotelLeft(h): loc("event.hotelLeft", h.title)
        case let .rivalFleetSold(r): loc("event.rivalFleetSold", r)
        case let .newEntrant(r): loc("event.newEntrant", r)
        case let .rivalAccidents(r, n): loc("event.rivalAccidents", r, num(n))
        case let .rivalRedFined(r): loc("event.rivalRedFined", r)
        case let .rivalRedSneaked(r): loc("event.rivalRedSneaked", r)
        case let .poachAttempt(r, p): loc("event.poachAttempt", r, p)
        case let .rivalHotelDeal(r, h): loc("event.rivalHotelDeal", r, h.title)
        case let .rivalStoleHotel(r, h): loc("event.rivalStoleHotel", r, h.title)
        case let .rivalCampaign(r): loc("event.rivalCampaign", r)
        case let .rivalPrice(r, from, to): loc("event.rivalPrice", r, eur(from), eur(to))
        case let .rivalNewBalloon(r): loc("event.rivalNewBalloon", r)
        case let .rivalBankrupt(r, n, price): loc("event.rivalBankrupt", r, num(n), eur(price))
        case let .rivalForSale(r, price): loc("event.rivalForSale", r, eur(price))
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
