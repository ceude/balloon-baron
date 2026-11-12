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
        let mix = r.style.crewMix
        var taken = local.pilots.map(\.name) + local.candidates.map(\.name)
        return sizes.map { _ in
            let x = rng.unit()
            let level: PilotLevel = x < mix.rookie ? .rookie : x < mix.rookie + mix.experienced ? .experienced : .senior
            let initial = rng.pick(region.pilotInitials)
            let trait: PilotTrait? = rng.chance(0.25) ? nil : rng.pick(PilotTrait.allCases)
            let name = freshPilotName(&rng, initial: initial, taken: taken)
            taken.append(name)
            return Pilot(id: 0, name: name, level: level,
                         customWage: jsRound(Double(level.wage) * rng.range(0.9, 1.1)), trait: trait)
        }
    }

    /// v142b (TestFlight: "three Deryas and two Cerens in a crew of eight"): a new pilot's name, "First I.". The first
    /// name is one nobody in `taken` (the crew, the hire list, the people joining with them) has, while the region's
    /// list has one left. Once all are used, the surname initial tells them apart: another initial is tried until the
    /// full name is new. Port of the prototype's `freshPilotName`.
    func freshPilotName(_ rng: inout SplitMix64, initial: Character, taken: [String]) -> String {
        let firsts = Set(taken.map(Self.firstName))
        let pool = region.pilotNames, free = pool.filter { !firsts.contains($0) }
        let first = rng.pick(free.isEmpty ? pool : free)
        var name = "\(first) \(initial).", tries = 0
        let all = Set(taken)
        while all.contains(name) && tries < 60 {
            name = "\(first) \(rng.pick(region.pilotInitials))."
            tries += 1
        }
        return name
    }

    /// "Derya K." → "Derya".
    static func firstName(_ name: String) -> String {
        guard let sp = name.lastIndex(of: " "), name.hasSuffix(".") else { return name }
        return String(name[..<sp])
    }
}
