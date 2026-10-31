import Foundation
import BalloonBaronCore

/// What a building in the company town looks like.
enum TownLook {
    case hangar, workshop, office, school, bank, tower, hotel, agency, guide, kiosk, mast, bazaar
}

/// What tapping a building does.
enum TownTap: Equatable {
    /// An office page, scrolled to one of its sections.
    case page(Page, section: PageSection?)
    case card(TownCard)
    case goals
    /// A building's upgrade card (with the way into its page).
    case building(Building)
    case bazaar
    /// v122: the guide office's and the agency's own screens.
    case guides, agency
}

/// A section an office page can scroll to when it opens from the town.
enum PageSection: String {
    case workshop, school, hotels, rivals
}

/// The small card the town shows for the agencies and for buildings that aren't open yet.
enum TownCard: Equatable, Identifiable {
    /// A building that opens on a later day.
    case locked(name: String, day: Int)

    var id: String {
        switch self {
        case .locked(let name, _): return "locked." + name
        }
    }
}

/// One building (or empty plot) on the town grid. Footprint in tiles.
struct TownBuilding {
    var id: String
    var gx: Double, gy: Double, w: Double, d: Double
    var name: String
    var look: TownLook
    /// -1 not open yet (scaffolding), 0 empty plot for sale, 1 built, 2 grown.
    var lv: Int
    var sub: String
    var tap: TownTap
    var star = 0
    /// Flag on a hotel: yours, or the rival that signed it.
    var flag: String?
    /// Kiosk colors: the company's balloon colors.
    var colors: [String] = []
    var small = false
}

/// A zone name written in the sand. The baseline is centered on (gx, gy); `side` zones run along -gy.
struct TownZone {
    enum Alert { case crew, market }
    var key: String
    var gx: Double, gy: Double
    /// Where a tap glides to.
    var at: (Double, Double)
    var side = false
    var alert: Alert?
}

/// The town's layout and what each building says about the company. Port of the prototype's `townBuildings()`.
enum Town {
    static let unlockDay: [Feature: Int] = Rules.unlockDay

    static let zones: [TownZone] = [
        TownZone(key: "town.zone.depot", gx: 4, gy: 3.55, at: (4, 2)),
        TownZone(key: "town.zone.finance", gx: 11.3, gy: 3.85, at: (11.3, 2)),
        TownZone(key: "town.zone.crew", gx: 10.9, gy: 7.5, at: (11, 6), alert: .crew),
        TownZone(key: "town.zone.agency", gx: 15.05, gy: 10, at: (11, 10), side: true),
        TownZone(key: "town.zone.companies", gx: 11.9, gy: 14.25, at: (11.9, 12.8), alert: .market),
        TownZone(key: "town.zone.hotels", gx: 3.3, gy: 15.25, at: (3.3, 11.8))
    ]

    /// Red dots on the zones: a balloon without a pilot or the licence (crew), a rival's offer or a sale (market).
    static func alerts(_ s: GameState) -> Set<TownZone.Alert> {
        var out: Set<TownZone.Alert> = []
        if !s.licenseValid || s.statusByID.values.contains(.noPilot) { out.insert(.crew) }
        if s.local.rivals.contains(where: { r in (r.alive && r.offer != nil && !r.offerDeclined) || (r.forSale != nil && !r.saleDeclined) }) {
            out.insert(.market)
        }
        return out
    }

    private static func locked(_ name: String, _ f: Feature) -> TownTap { .card(.locked(name: name, day: unlockDay[f] ?? 1)) }

    static func buildings(_ s: GameState) -> [TownBuilding] {
        var L: [TownBuilding] = []
        let n = s.local.balloons.count, np = s.local.pilots.count, ds = s.designs.count
        let open = s.unlocked
        let soon = loc("town.sub.soon")

        let hangar = loc("town.b.hangar")
        L.append(TownBuilding(id: "hangar", gx: 1, gy: 1, w: 3, d: 2, name: hangar, look: .hangar, lv: n >= 8 ? 2 : 1,
                              sub: loc("town.sub.balloons", num(n) + "/" + num(s.hangarCapacity)) + " · " + loc("building.sub.level", num(s.level(.hangar))),
                              tap: open.contains(.fleet) ? .building(.hangar) : locked(hangar, .fleet)))
        let shop = loc("town.b.workshop")
        L.append(TownBuilding(id: "shop", gx: 5, gy: 1, w: 2, d: 2, name: shop, look: .workshop,
                              lv: s.workshopDay != nil ? (ds >= 3 || s.factoryLevel >= 3 ? 2 : 1) : open.contains(.workshop) ? 0 : -1,
                              sub: s.workshopDay == nil ? loc("town.sub.build", eur(Studio.workshopCost))
                                : s.factory?.job.map { loc("town.sub.making", $0.size.rawValue, num(max(0, $0.done - s.day))) }
                                ?? loc("town.sub.workshopLevel", num(s.factoryLevel), num(ds)),
                              tap: open.contains(.workshop) || s.workshopDay != nil ? .page(.workshop, section: nil) : locked(shop, .workshop)))
        let office = loc("town.b.office")
        L.append(TownBuilding(id: "office", gx: 9, gy: 5, w: 2, d: 2, name: office, look: .office,
                              lv: open.contains(.crew) ? (np >= 6 ? 2 : 1) : -1,
                              sub: open.contains(.crew) ? loc("town.sub.pilots", num(np)) + " · " + loc("building.sub.level", num(s.level(.office))) : soon,
                              tap: open.contains(.crew) ? .building(.office) : locked(office, .crew)))
        let school = loc("town.b.school")
        L.append(TownBuilding(id: "school", gx: 12, gy: 5, w: 2, d: 2, name: school, look: .school,
                              lv: s.local.school ? (np >= 8 ? 2 : 1) : (open.contains(.school) ? 0 : -1),
                              sub: s.local.school ? loc("town.sub.open") : loc("town.sub.build", eur(Rules.schoolCost)),
                              tap: open.contains(.school) || s.local.school ? .page(.crew, section: .school) : locked(school, .school)))
        // Finance sits in the back row so the tall holding tower hides nothing behind it.
        let bank = loc("town.b.bank")
        L.append(TownBuilding(id: "bank", gx: 12, gy: 1, w: 2, d: 2, name: bank, look: .bank,
                              lv: open.contains(.bank) ? (s.local.loans.isEmpty ? 1 : 2) : -1,
                              sub: open.contains(.bank) ? (s.local.loans.isEmpty ? loc("town.sub.noLoans") : loc("town.sub.loans", num(s.local.loans.count))) : soon,
                              tap: open.contains(.bank) ? .page(.bank, section: nil) : locked(bank, .bank)))
        L.append(TownBuilding(id: "holding", gx: 9, gy: 1, w: 2, d: 2, name: loc("town.b.holding"), look: .tower,
                              lv: s.anyBaron ? 2 : -1, sub: s.anyBaron ? eurH(s.holding.cash) : loc("town.sub.baron"),
                              tap: s.anyBaron ? .page(.holding, section: nil) : .goals))

        let hotelX: [Double] = [1, 4, 1, 4], hotelY: [Double] = [9, 9, 11.6, 11.3]
        for (i, h) in Hotel.allCases.enumerated() {
            let own = s.local.ownHotels.contains(h), deal = s.local.hotelDeals.contains(h)
            let lock = s.local.hotelLocks[h].flatMap { $0.until > s.day ? $0 : nil }
            let rivalCol = lock.flatMap { l in s.local.rivals.first { $0.name == l.rival }?.colors.first }
            let sub = own ? loc("town.sub.yours") : deal ? loc("town.sub.signed") : lock != nil ? loc("town.sub.rivalSigned")
                : loc("town.sub.wants", starsValue(h.minStars))
            L.append(TownBuilding(id: "hotel\(i)", gx: hotelX[i], gy: hotelY[i], w: i == 3 ? 3.2 : 2, d: i == 3 ? 3 : 2,
                                  name: h.title, look: .hotel, lv: own ? 2 : 1, sub: sub,
                                  tap: open.contains(.market) ? .page(.market, section: .hotels) : locked(h.title, .market),
                                  star: i, flag: own || deal ? s.colors.first : rivalCol))
        }

        let icd = s.local.influencerCooldown - s.day, gcd = s.local.guideCooldown - s.day
        let influ = loc("town.b.influencer"), market = open.contains(.market), agency = open.contains(.agency), guides = open.contains(.guide)
        let influSub = !agency ? soon : s.day <= s.local.influencerUntil ? loc("town.sub.running")
            : icd > 0 ? loc("town.sub.wait", num(icd)) : loc("town.sub.from", eur(InfluencerOffer.local.cost(s)))
        L.append(TownBuilding(id: "influ", gx: 9, gy: 9, w: 2, d: 2, name: influ, look: .agency,
                              lv: agency ? (s.day <= s.local.influencerUntil ? 2 : 1) : -1, sub: influSub,
                              tap: agency ? .agency : locked(influ, .agency)))
        let guide = loc("town.b.guide")
        let guideSub = !guides ? soon : s.day <= s.local.guideUntil ? loc("town.sub.guides")
            : gcd > 0 ? loc("town.sub.wait", num(gcd)) : loc("town.sub.from", eur(GuideOffer.ayse.cost))
        L.append(TownBuilding(id: "guide", gx: 12, gy: 9, w: 2, d: 2, name: guide, look: .guide,
                              lv: guides ? (s.day <= s.local.guideUntil ? 2 : 1) : -1, sub: guideSub,
                              tap: guides ? .guides : locked(guide, .guide)))

        // Booking offices side by side: yours first, then the rivals'. Same kiosk, awning in each company's colors.
        let mine = s.company.isEmpty ? loc("town.b.mine") : s.company
        L.append(TownBuilding(id: "mine", gx: 8.7, gy: 12.2, w: 1.2, d: 1.2, name: mine, look: .kiosk, lv: 1,
                              sub: loc("town.sub.balloons", num(n)) + " · " + loc("building.sub.level", num(s.level(.sales))),
                              tap: market ? .building(.sales) : locked(mine, .market),
                              colors: s.colors, small: true))
        // v128: the bazaar, a row of shops on the main road by the square; the wind mast by the launch field.
        let bazaar = loc("town.b.bazaar")
        let decor = StoreItem.allCases.filter { $0.kind == .decoration }
        L.append(TownBuilding(id: "bazaar", gx: 5.9, gy: 8.7, w: 1.4, d: 2.5, name: bazaar, look: .bazaar,
                              lv: open.contains(.bazaar) ? (s.decorationCount > 0 ? 2 : 1) : -1,
                              sub: open.contains(.bazaar) ? loc("town.sub.decor", num(s.decorationCount), num(decor.count)) : soon,
                              tap: open.contains(.bazaar) ? .bazaar : locked(bazaar, .bazaar), small: true))
        let mastSub = s.level(.mast) >= 2 ? loc("building.sub.tomorrow", (s.local.forecast?[s.day + 1]).map { $0.title } ?? "?")
            : loc("building.sub.level", num(s.level(.mast)))
        L.append(TownBuilding(id: "mast", gx: 6.95, gy: 3.95, w: 0.4, d: 0.4, name: Building.mast.title, look: .mast, lv: 1,
                              sub: mastSub, tap: .building(.mast), small: true))
        for (i, r) in s.local.rivals.enumerated() {
            let sub = r.alive ? loc("town.sub.balloons", num(r.balloons.count))
                : r.mergedInto != nil ? loc("town.sub.merged") : r.forSale != nil ? loc("town.sub.forSale") : loc("town.sub.closed")
            L.append(TownBuilding(id: "rival\(i)", gx: 10.55 + Double(i) * 1.85, gy: 12.2, w: 1.2, d: 1.2, name: r.name, look: .kiosk,
                                  lv: r.alive ? 1 : 0, sub: sub,
                                  tap: market ? .page(.market, section: .rivals) : locked(r.name, .market),
                                  colors: r.colors, small: true))
        }
        return L
    }

    /// v128: the feature that opens each building; on the day it opens (or the school or workshop is built) its name
    /// shows from afar too.
    static let opens: [String: Feature] = ["hangar": .fleet, "shop": .workshop, "office": .crew, "school": .school, "bank": .bank,
                                           "influ": .agency, "guide": .guide, "bazaar": .bazaar, "mine": .market]

    static func openedToday(_ b: TownBuilding, _ s: GameState) -> Bool {
        guard b.lv >= 0, let f = opens[b.id], let d = s.openedOn?[f.rawValue] else { return false }
        return d == s.day
    }

    /// Height above the footprint center where a building's label sits: just over its roof.
    static func labelTop(_ b: TownBuilding) -> Double {
        if b.lv <= 0 && b.look != .kiosk { return 90 }
        switch b.look {
        case .hotel: return [95, 165, 190, 200][b.star]
        case .kiosk: return 80
        case .hangar: return 120
        // Higher than the roof needs (v110), so the wind mast's tag in front no longer hides it.
        case .workshop: return 145
        case .office: return b.lv == 2 ? 150 : 120
        case .school: return 160
        case .bank: return 130
        case .guide: return 90
        case .agency: return 185 // v128: over the phone sign on the roof
        case .tower: return 300
        case .mast: return 175
        case .bazaar: return 82
        }
    }
}
