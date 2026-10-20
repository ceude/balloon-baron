import XCTest
@testable import BalloonBaronCore

/// Plays the game with different player styles to compare how they fare.
/// Run with `PROFILES=1 swift test --filter ProfileSimTests` to print the table.
final class ProfileSimTests: XCTestCase {
    struct Profile {
        let name: String
        /// Fly the flagship yourself: every day, every N days, or only to keep the license.
        enum SelfFly { case daily, every(Int), licenseOnly, never }
        let selfFly: SelfFly
        let hotels: Int
        let influencer: Int   // campaigns over the game; Int.max = whenever off cooldown
        let guide: Bool
    }

    struct Outcome {
        var survived = true, seized = false
        var cash30 = 0, cash60 = 0, cash100 = 0, worth100 = 0, balloons = 0
        var stars = 0.0, founding: Int?, growth: Int?
        var minCash = Int.max
    }

    static let profiles: [Profile] = [
        Profile(name: "A Pilots + PR (license only)", selfFly: .licenseOnly, hotels: 3, influencer: 1, guide: true),
        Profile(name: "B Pilots, no PR (license only)", selfFly: .licenseOnly, hotels: 0, influencer: 0, guide: false),
        Profile(name: "C Self daily, no PR", selfFly: .daily, hotels: 0, influencer: 0, guide: false),
        Profile(name: "D Self every 3-4 days, no PR", selfFly: .every(4), hotels: 0, influencer: 0, guide: false),
        Profile(name: "E Self daily + 1 PR (1 influencer)", selfFly: .daily, hotels: 0, influencer: 1, guide: false),
        Profile(name: "F Self daily + 1 hotel", selfFly: .daily, hotels: 1, influencer: 0, guide: false),
        Profile(name: "G Self daily + full PR", selfFly: .daily, hotels: 3, influencer: 1, guide: true),
        Profile(name: "H Self every 3-4 days + PR", selfFly: .every(4), hotels: 3, influencer: 1, guide: true),
        Profile(name: "I Never flies, pays license + PR", selfFly: .never, hotels: 3, influencer: 1, guide: true),
        Profile(name: "J Pilots + heavy PR (influencer always)", selfFly: .licenseOnly, hotels: 4, influencer: .max, guide: true),
    ]

    /// The player's own landing: mostly good, sometimes perfect, rarely far or hard.
    func flight(_ g: Game, rng: inout SplitMix64) -> FlightResult {
        let r = rng.unit()
        let q: FlightResult.Landing = r < 0.3 ? .perfect : r < 0.82 ? .good : r < 0.96 ? .far : .hard
        let m = g.state.weather?.mission
        return FlightResult(landing: q, distance: q == .far ? 400 : 60, mission: m, missionDone: m != nil && rng.chance(0.6))
    }

    func run(_ p: Profile, seed: UInt64, days: Int = 100) -> Outcome {
        var g = Game(company: "Sim", colors: Rules.palettes[0], seed: seed)
        var rng = SplitMix64(seed: seed &* 31 &+ 7)
        var o = Outcome()
        var influencerRuns = 0
        g.startDay()
        for _ in 0..<days {
            if g.state.over { o.survived = false; break }
            g.startDay()
            while g.nextHezarfen() != nil {}
            let s = g.state

            // Who flies the flagship today.
            let selfToday: Bool
            switch p.selfFly {
            case .daily: selfToday = true
            case .every(let n): selfToday = s.daysSinceSelfFly >= n - 1 || s.licenseDaysLeft <= 0
            case .licenseOnly: selfToday = s.licenseDaysLeft <= 0
            case .never:
                selfToday = false
                if s.licenseDaysLeft <= 0 && s.cash >= Rules.recertCost { g.renewLicense() }
            }
            g.setSelfFly(selfToday || (!g.state.licenseValid))

            // Same business sense for everyone: price by yesterday's load, grow, staff, one loan at most.
            if let ls = s.lastShare, ls.cap > 0 {
                let load = Double(ls.me) / Double(ls.cap)
                if load > 0.97 { g.setPrice(s.price + 5) } else if load < 0.75 { g.setPrice(s.price - 5) }
                g.setPrice(clamp(g.state.price, 120, 260))
            }
            if g.state.loans.isEmpty && g.state.day >= 4 && g.state.balloons.count < 4 {
                for i in stride(from: Rules.loans.count - 1, through: 0, by: -1) where g.canTakeLoan(Rules.loans[i]) {
                    g.takeLoan(i); break
                }
            }
            if g.state.winter == nil {
                if g.state.cash > 50000 && g.state.balloons.count < 14 { g.buyBalloon(.M) } else if g.state.cash > 24000 && g.state.balloons.count < 3 { g.buyBalloon(.S) }
            }
            for b in g.state.balloons where g.state.condition(b) <= 0 && g.state.cash > g.renewCost(b) + 3000 { g.renewEnvelope(b.id) }
            // Enough pilots for every balloon the founder doesn't fly.
            while g.state.balloons.contains(where: { g.state.status($0) == .noPilot }), let c = g.state.candidates.min(by: { $0.wage < $1.wage }) {
                g.hire(c.id)
            }
            if let offer = g.state.poach { g.answerPoach(match: offer.wage <= 300) }

            // Reputation work.
            if p.hotels > 0 && g.state.hotelDeals.count < p.hotels {
                for h in Hotel.allCases where g.state.hotelDeals.count < p.hotels && g.state.cash > h.dailyFee * 3 + 4000 { g.signHotel(h) }
            }
            if influencerRuns < p.influencer && g.state.cash > g.state.influencerCost + 5000 && g.state.balloons.count >= 2 {
                if g.runInfluencer() { influencerRuns += 1 }
            }
            if p.guide && g.state.cash > Rules.guideCost + 4000 { g.runGuideFlight() }

            let red = g.state.weather?.flag == .red
            let before = g.state.balloons.count
            let r: DayReport
            if g.launch(skip: red) != nil { r = g.finishDay(flight: flight(g, rng: &rng)) } else { r = g.finishDay(flight: nil) }
            if r.ledger.seizure > 0 { o.seized = true }
            _ = before
            o.minCash = min(o.minCash, g.state.cash)
            if case .chapterDone(let id, _) = r.events.first(where: { if case .chapterDone = $0 { return true }; return false }) ?? .redBan {
                if id == "founding" { o.founding = r.day }
                if id == "growth" { o.growth = r.day }
            }
            let d = r.day
            if d == 30 { o.cash30 = g.state.cash }
            if d == 60 { o.cash60 = g.state.cash }
        }
        let s = g.state
        o.survived = !s.over && !o.seized
        o.cash100 = s.cash
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
        print("profile|survive%|seized%|cash d30|cash d60|cash d100|worth d100|balloons|stars|lowest cash|founding day (n)|growth day (n)")
        for p in Self.profiles {
            let os = seeds.map { run(p, seed: $0) }
            let surv = os.filter(\.survived).count * 100 / os.count
            let seized = os.filter(\.seized).count * 100 / os.count
            let f = os.compactMap(\.founding), gr = os.compactMap(\.growth)
            print("\(p.name)|\(surv)|\(seized)|\(med(os.map(\.cash30)))|\(med(os.map(\.cash60)))|\(med(os.map(\.cash100)))|\(med(os.map(\.worth100)))|\(med(os.map(\.balloons)))|\(String(format: "%.1f", medD(os.map(\.stars))))|\(med(os.map(\.minCash)))|\(f.isEmpty ? "-" : String(med(f))) (\(f.count))|\(gr.isEmpty ? "-" : String(med(gr))) (\(gr.count))")
        }
    }
}
