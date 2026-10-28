import Foundation

extension GameState {
    /// v121.13 (TestFlight: 261 balloons bought from rivals, but only a few pilots to hire a day): a take-over or a
    /// bankrupt fleet brings the rival's pilots too, one per balloon, on the contracts they had. Their level follows the
    /// rival's style (`RivalStyle.crewMix`) and the wage is 90–110% of the level's. The crew comes from its own generator
    /// seeded by the deal, so the card and the deal show the same people without touching the game's random sequence.
    /// Ids are given when they join. Port of the prototype's `dealCrew`.
    public func dealCrew(_ i: Int, bankrupt: Bool) -> [Pilot] {
        guard local.rivals.indices.contains(i) else { return [] }
        let r = local.rivals[i]
        let sizes = bankrupt ? (r.forSale?.sizes ?? []) : r.balloons
        var rng = SplitMix64(seed: UInt64(r.id) &* 0x9E37_79B9_7F4A_7C15 &+ (bankrupt ? 7 : 3) &+ UInt64(sizes.count) &* 1_000_003)
        let mix = r.style.crewMix, names = region.pilotNames
        return sizes.map { _ in
            let x = rng.unit()
            let level: PilotLevel = x < mix.rookie ? .rookie : x < mix.rookie + mix.experienced ? .experienced : .senior
            let initial = Character(UnicodeScalar(65 + rng.int(26))!)
            let trait: PilotTrait? = rng.chance(0.25) ? nil : rng.pick(PilotTrait.allCases)
            return Pilot(id: 0, name: "\(rng.pick(names)) \(initial).", level: level,
                         customWage: jsRound(Double(level.wage) * rng.range(0.9, 1.1)), trait: trait)
        }
    }
}
