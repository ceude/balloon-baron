import Foundation

/// A passenger review. Text comes from the string catalog: `review.<kind>.<variant>`.
public struct Review: Codable, Equatable, Sendable {
    public enum Kind: String, Codable, CaseIterable, Sendable {
        case perfect, good, far, hard, crash, accident, red, skip, cheap, pricey, general, ad, cancel
        case influencer, guide, proposal, valley, panorama, precision, xl, meh, rival, absent, design, welcome

        /// Stars of each variant; the count is the number of text variants.
        public var variants: [Int] {
            switch self {
            case .perfect: [5, 5, 5]
            case .good: [4, 4, 5]
            case .far: [3, 2]
            case .hard: [2, 1]
            case .crash: [1, 1]
            case .accident: [1, 2]
            case .red: [2, 1]
            case .skip: [4, 4]
            case .cheap: [5, 5]
            case .pricey: [3, 3]
            case .general: [5, 4, 5]
            case .ad: [2, 3, 3]
            case .cancel: [2, 3]
            case .influencer: [5, 4, 5]
            case .guide: [4, 5]
            case .proposal, .valley, .precision: [5, 5]
            case .panorama: [5, 4]
            case .xl: [5, 5, 4]
            case .meh: [2, 2, 3]
            case .rival: [5, 4]
            case .absent: [3, 2]
            case .design: [5, 5, 4]
            case .welcome: [5]
            }
        }

        static func mission(_ m: Mission) -> Kind {
            switch m {
            case .proposal: .proposal
            case .valley: .valley
            case .panorama: .panorama
            case .precision: .precision
            }
        }
    }

    /// Reviewer name and home; the home is localized via `country.<code>`.
    public static let reviewers: [(name: String, country: String)] = [
        ("Emily", "gb"), ("Kenji", "jp"), ("Lucía", "es"), ("Mehmet", "istanbul"), ("Ji-woo", "kr"), ("Ahmed", "eg"),
        ("Olga", "pl"), ("Marco", "it"), ("Priya", "in"), ("Tom", "us"), ("Chloé", "fr"), ("Wei", "cn"),
        ("Ayşe", "ankara"), ("Lukas", "de"), ("Ana", "br"), ("Noah", "nl"), ("Mehmet", "goreme")
    ]

    public var reviewer: Int
    public var kind: Kind
    public var variant: Int
    public var stars: Int
    public var day: Int
    /// Placeholder values: balloon, price, sponsor, rival, design id.
    public var args: [String: String]

    public var name: String { Self.reviewers[reviewer].name }
    public var country: String { Self.reviewers[reviewer].country }
}

extension Game {
    mutating func addReview(_ kind: Review.Kind, _ args: [String: String] = [:]) {
        let v = rng.int(kind.variants.count)
        let r = Review(reviewer: rng.int(Review.reviewers.count), kind: kind, variant: v, stars: kind.variants[v], day: state.day, args: args)
        state.reviews.insert(r, at: 0)
        if state.reviews.count > 40 { state.reviews.removeLast(state.reviews.count - 40) }
    }

    struct ReviewContext {
        var xl = false
        var mission: Mission?
        var ads: [Sponsor] = []
        var landing: FlightResult.Landing?
        var accidents: [String] = []
        var red = false
        var flew = false
        var skipped = false
        var flag = Flag.green
    }

    mutating func generateReviews(_ o: ReviewContext) {
        let before = state.reviews.count
        if let q = o.landing {
            switch q {
            case .perfect: addReview(.perfect)
            case .good: addReview(.good)
            case .far: addReview(.far)
            case .hard: addReview(.hard)
            case .crash: addReview(.crash)
            case .cancel: addReview(.cancel)
            }
        }
        if let m = o.mission { addReview(.mission(m)) }
        if o.xl && rng.chance(0.5) { addReview(.xl) }
        for b in o.accidents { addReview(.accident, ["b": b]) }
        if o.red && o.flew { addReview(.red) }
        if !o.ads.isEmpty && rng.chance(0.35) { addReview(.ad, ["s": rng.pick(o.ads).rawValue]) }
        if o.skipped && o.flag != .green { addReview(.skip) }
        if o.flew && state.price <= 120 && rng.chance(0.6) { addReview(.cheap, ["p": String(state.price)]) }
        if o.flew && state.price >= 230 && rng.chance(0.6) { addReview(.pricey, ["p": String(state.price)]) }
        let alive = state.rivals.filter(\.alive)
        if o.flew && o.accidents.isEmpty && !alive.isEmpty && rng.chance(0.25) { addReview(.rival, ["r": rng.pick(alive).name]) }
        if o.flew && o.accidents.isEmpty && state.reviews.count - before < 2 && rng.chance(0.8) {
            addReview(state.stars < 3 ? .meh : .general)
        }
    }
}
