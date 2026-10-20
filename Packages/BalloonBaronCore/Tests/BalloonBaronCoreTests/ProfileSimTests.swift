import XCTest
@testable import BalloonBaronCore

final class ProfileSimTests: XCTestCase {
    enum SelfFly { case daily, every(Int), licenseOnly, never }
    enum PricePolicy { case adaptive, fixed(Int) }

    struct Profile {
        let name: String
        var selfFly: SelfFly
        var hotels = 0
        var influencer = 0
        var guide = false
        var price: PricePolicy = .adaptive
        var flyRed = false
        var insurance = true
        var loans = 1          // loans at once
        var buyAt = 50000      // buy an M balloon above this cash
        var maxBalloons = 14
        var renew = true
        var extraPilots = 0
        var idle = false       // never grows or hires
        var landing = 0.82     // share of good-or-better self landings
    }

    struct Outcome {
        var survived = true, seized = false, over = false
        var worth100 = 0, balloons = 0, stars = 0.0, founding: Int?, seizedDay: Int?
    }

    static var profiles: [Profile] {
        [
            Profile(name: "A Pilots + PR, license only", selfFly: .licenseOnly, hotels: 3, influencer: 1, guide: true),
            Profile(name: "B Pilots, no PR", selfFly: .licenseOnly),
            Profile(name: "C Self daily, no PR", selfFly: .daily),
            Profile(name: "D Self every 3-4 days, no PR", selfFly: .every(4)),
            Profile(name: "E Self daily + 1 influencer", selfFly: .daily, influencer: 1),
            Profile(name: "F Self daily + 1 hotel", selfFly: .daily, hotels: 1),
            Profile(name: "G Self daily + full PR", selfFly: .daily, hotels: 3, influencer: 1, guide: true),
            Profile(name: "H Self every 3-4 days + PR", selfFly: .every(4), hotels: 3, influencer: 1, guide: true),
            Profile(name: "I Never flies, pays license + PR", selfFly: .never, hotels: 3, influencer: 1, guide: true),
            Profile(name: "J Pilots + influencer always", selfFly: .licenseOnly, influencer: .max, guide: true),
            // Players likely to go under.
            Profile(name: "K Debt-fuelled growth (2 loans, buys at 36k)", selfFly: .daily, hotels: 1, loans: 2, buyAt: 36000, maxBalloons: 30),
            Profile(name: "L Price breaker (fixed €110)", selfFly: .daily, hotels: 1, price: .fixed(110)),
            Profile(name: "M Greedy (fixed €260)", selfFly: .daily, hotels: 1, price: .fixed(260)),
            Profile(name: "N Flies on red flags", selfFly: .daily, hotels: 1, flyRed: true),
            Profile(name: "O No insurance", selfFly: .daily, hotels: 1, insurance: false),
            Profile(name: "P No insurance + red flags", selfFly: .daily, hotels: 1, flyRed: true, insurance: false),
            Profile(name: "Q Never renews envelopes", selfFly: .daily, hotels: 1, renew: false),
            Profile(name: "R Overstaffed (+3 idle pilots)", selfFly: .licenseOnly, hotels: 1, extraPilots: 3),
            Profile(name: "S Clumsy pilot (half good landings)", selfFly: .daily, hotels: 1, landing: 0.5),
            Profile(name: "T Does nothing (one balloon, self)", selfFly: .daily, idle: true),
            Profile(name: "U Worst: pilots, no PR, 2 loans, red, no insurance", selfFly: .licenseOnly, flyRed: true, insurance: false, loans: 2, buyAt: 36000, maxBalloons: 30),
        ]
    }

    func flight(_ g: Game, _ p: Profile, rng: inout SplitMix64) -> FlightResult {
        let r = rng.unit()
        let goodShare = p.landing, perfect = goodShare * 0.37
        let q: FlightResult.Landing = r < perfect ? .perfect : r < goodShare ? .good : r < goodShare + (1 - goodShare) * 0.75 ? .far : .hard
        let m = g.state.weather?.mission
        return FlightResult(landing: q, distance: q == .far ? 400 : 60, mission: m, missionDone: m != nil && rng.chance(0.6 * goodShare / 0.82))
    }

    func run(_ p: Profile, seed: UInt64, days: Int = 100) -> Outcome {
        var g = Game(company: "Sim", colors: Rules.palettes[0], seed: seed)
        var rng = SplitMix64(seed: seed &* 31 &+ 7)
        var o = Outcome()
        var influencerRuns = 0
        g.setInsurance(hull: p.insurance, pax: p.insurance)
        for _ in 0..<days {
            if g.state.over { break }
            g.startDay()
            while g.nextHezarfen() != nil {}
            let s = g.state
            let selfToday: Bool
            switch p.selfFly {
            case .daily: selfToday = true
            case .every(let n): selfToday = s.daysSinceSelfFly >= n - 1 || s.licenseDaysLeft <= 0
            case .licenseOnly: selfToday = s.licenseDaysLeft <= 0
            case .never:
                selfToday = false
                if s.licenseDaysLeft <= 0 && s.cash >= Rules.recertCost { g.renewLicense() }
            }
            g.setSelfFly(selfToday || !g.state.licenseValid)

            switch p.price {
            case .fixed(let v): g.setPrice(v)
            case .adaptive:
                if let ls = s.lastShare, ls.cap > 0 {
                    let load = Double(ls.me) / Double(ls.cap)
                    if load > 0.97 { g.setPrice(s.price + 5) } else if load < 0.75 { g.setPrice(s.price - 5) }
                    g.setPrice(clamp(g.state.price, 120, 260))
                }
            }
            if !p.idle {
                if g.state.loans.count < p.loans && g.state.day >= 4 && (p.loans > 1 || g.state.balloons.count < 4) {
                    for i in stride(from: Rules.loans.count - 1, through: 0, by: -1) where g.canTakeLoan(Rules.loans[i]) { g.takeLoan(i); break }
                }
                if g.state.winter == nil {
                    if g.state.cash > p.buyAt && g.state.balloons.count < p.maxBalloons { g.buyBalloon(.M) } else if g.state.cash > 24000 && g.state.balloons.count < 3 { g.buyBalloon(.S) }
                }
                while g.state.balloons.contains(where: { g.state.status($0) == .noPilot }), let c = g.state.candidates.min(by: { $0.wage < $1.wage }) { g.hire(c.id) }
                while g.state.pilots.count < g.state.balloons.count + p.extraPilots - 1 && p.extraPilots > 0, let c = g.state.candidates.first { g.hire(c.id) }
            }
            if p.renew {
                for b in g.state.balloons where g.state.condition(b) <= 0 && g.state.cash > g.renewCost(b) + 3000 { g.renewEnvelope(b.id) }
            }
            if let offer = g.state.poach { g.answerPoach(match: offer.wage <= 300) }
            if p.hotels > 0 && g.state.hotelDeals.count < p.hotels {
                for h in Hotel.allCases where g.state.hotelDeals.count < p.hotels && g.state.cash > h.dailyFee * 3 + 4000 { g.signHotel(h) }
            }
            if influencerRuns < p.influencer && g.state.cash > g.state.influencerCost + 5000 && g.state.balloons.count >= 2 {
                if g.runInfluencer() { influencerRuns += 1 }
            }
            if p.guide && g.state.cash > Rules.guideCost + 4000 { g.runGuideFlight() }

            let red = g.state.weather?.flag == .red
            let r: DayReport
            if g.launch(skip: red && !p.flyRed) != nil { r = g.finishDay(flight: flight(g, p, rng: &rng)) } else { r = g.finishDay(flight: nil) }
            if r.ledger.seizure > 0 && o.seizedDay == nil { o.seized = true; o.seizedDay = r.day }
            for e in r.events { if case .chapterDone(let id, _) = e, id == "founding" { o.founding = r.day } }
        }
        let s = g.state
        o.over = s.over
        o.survived = !s.over && !o.seized
        o.balloons = s.balloons.count
        o.stars = s.stars
        let debt = s.loans.reduce(0) { $0 + $1.payoff }
        o.worth100 = s.cash + s.balloons.reduce(0) { $0 + $1.size.cost * 6 / 10 } + s.ownHotels.reduce(0) { $0 + $1.buyPrice } - debt
        return o
    }

    func testProfiles() {
        guard ProcessInfo.processInfo.environment["PROFILES"] != nil else { return }
        let seeds = (1...100).map { UInt64($0) }
        func med(_ xs: [Int]) -> Int { let s = xs.sorted(); return s.isEmpty ? 0 : s[s.count / 2] }
        func medD(_ xs: [Double]) -> Double { let s = xs.sorted(); return s.isEmpty ? 0 : s[s.count / 2] }
        print("profile|clean%|seized%|closed%|first seizure day|worth d100|balloons|stars|founding (n)")
        for p in Self.profiles {
            let os = seeds.map { run(p, seed: $0) }
            let clean = os.filter(\.survived).count, seized = os.filter(\.seized).count, over = os.filter(\.over).count
            let sd = os.compactMap(\.seizedDay), f = os.compactMap(\.founding)
            print("\(p.name)|\(clean)|\(seized)|\(over)|\(sd.isEmpty ? "-" : String(med(sd)))|\(med(os.map(\.worth100)))|\(med(os.map(\.balloons)))|\(String(format: "%.1f", medD(os.map(\.stars))))|\(f.isEmpty ? "-" : String(med(f))) (\(f.count))")
        }
    }
}
