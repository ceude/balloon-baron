import Foundation

/// v135 / v135.1: the life outside the town's walls, on the two flanks the home screen doesn't show (|gx − gy| ≥
/// `calm`). Port of the prototype's `OUT_*`, `outFieldsN`, `outCrewsN`, `outInUse` and `outLayout`. The app draws it; the numbers and the layout live here.
public enum Outskirts {
    /// The home view never looks this far sideways (in grid units of |gx − gy|).
    public static let calm = 13.5
    /// One launch field outside town per this many balloons in the hangar beyond the town field's six, up to `maxFields`.
    public static let perField = 12
    public static let maxFields = 24
    /// At most this many balloons are drawn out there at once.
    public static let maxBalloons = 60
    /// About this share of the fields is in use on a morning (the nearest always).
    public static let useShare = 0.55

    /// Launch fields outside town for this many balloons inside the hangar.
    public static func fields(inside: Int) -> Int { clamp((inside - 6) / perField, 0, maxFields) }
    /// Chase crews: one, and one more per six fields, at most four.
    public static func crews(fields: Int) -> Int { min(4, 1 + fields / 6) }
    /// Whether field `i` is in use this morning (fixed for the day).
    public static func inUse(_ i: Int, fields: Int, day: Int) -> Bool {
        guard i < fields else { return false }
        if i == 0 { return true }
        var r = Mulberry32(seed: UInt32(truncatingIfNeeded: day * 131 + i * 17 + 7))
        return r.next() < useShare
    }

    /// Is this point on one of the flanks?
    public static func flank(_ x: Double, _ y: Double) -> Bool { abs(x - y) >= calm }
}

extension GameState {
    /// v135: launch fields outside town (from the balloons inside the hangar).
    public var outskirtsFields: Int { Outskirts.fields(inside: insideBalloons.count) }
}

/// A point on the town grid.
public struct GridPoint: Equatable, Sendable {
    public var x: Double, y: Double
    public init(_ x: Double, _ y: Double) { self.x = x; self.y = y }
}

/// v135.1: the valley on the flanks, laid out once per region (prototype `outLayout`). Farm tracks meander out from the
/// main roads and branch; plots of varied size sit along them, turned with the track, others lie back in loose clusters;
/// the nearest plots become launch fields as the fleet grows, the rest carry the region's decor; each crew drives its
/// own track to a landing spot beside it. Deterministic: the same generator and the same order of draws as the prototype.
public struct OutskirtsLayout: Sendable {
    public enum Decor: String, Sendable {
        case orchard, vine, dovecote, view, farm, rival, scrub, rv, mesa, cane, palms, crops, pasture
        /// Decor that wants a big plot.
        var big: Bool { [.dovecote, .view, .mesa, .rv, .palms, .farm].contains(self) }
    }

    /// A plot: centre, long axis (ux, uy), size along and across it, its slightly uneven corners.
    public struct Site: Sendable {
        public var cx: Double, cy: Double, ux: Double, uy: Double, w: Double, d: Double
        public var poly: [GridPoint]
        public var side: Int
        public var scattered: Bool
        public var r: Double, dist: Double
        public var seed: Int
        public var key: Double = 0
        public var kind: Decor?

        /// A point in the plot's own frame: a along its long axis, b across it.
        public func at(_ a: Double, _ b: Double) -> GridPoint { GridPoint(cx + ux * a - uy * b, cy + uy * a + ux * b) }
        /// Inside the plot, grown by m.
        public func contains(_ x: Double, _ y: Double, _ m: Double) -> Bool {
            let dx = x - cx, dy = y - cy, a = dx * ux + dy * uy, b = -dx * uy + dy * ux
            return abs(a) < w / 2 + m && abs(b) < d / 2 + m
        }
    }

    public struct Land: Sendable { public var x: Double, y: Double, s: Double, at: GridPoint }
    public struct Track: Sendable {
        public var P: [GridPoint]
        public var side: Int
        public var len: Double
        /// The track it branches off.
        public var from: Int?
        public var land: Land?
    }
    public struct Crew: Sendable { public var path: [GridPoint]; public var len: Double; public var spot: GridPoint; public var dir: GridPoint }
    public struct Loop: Sendable { public var site: Site; public var P: [GridPoint]; public var len: Double }
    public struct Tree: Sendable { public var x: Double, y: Double, k: Double, kind: Int }

    public var region: RegionID
    public var sites: [Site] = []
    public var tracks: [Track] = []
    public var decor: [Site] = []
    public var fields: [Site] = []
    public var crews: [Crew] = []
    public var loops: [Loop] = []
    public var lands: [Land] = []
    public var trees: [Tree] = []

    /// Where the farm tracks leave the main roads, for the left flank (x, y, heading x, heading y, length); the right flank
    /// mirrors them. The first three that find room are kept.
    static let starts: [(Double, Double, Double, Double, Double)] = [(8, 22.6, -1, 0.3, 17), (-8.6, 8, 0.25, 1, 15), (8, 32, 1, 0.6, 14),
                                                                      (-16, 8, -0.4, -1, 12), (8, 27.5, -1, -0.15, 14), (-12.5, 8, 0.1, 1, 13)]
    /// Older features out there the layout keeps clear of: other companies' fields (3 × 2.2) and the vineyards.
    static let outerFields: [(Double, Double)] = [(-6, 9.5), (18, 2), (10, 18), (-4, -6), (20, 15)]
    static let vines: [(Double, Double, Double, Double)] = [(-9, 2, 5, 4), (18, 10, 4, 5), (2, 18, 4, 3.5), (-12, 12, 4, 3)]

    /// What each region keeps on its flanks, in the order the plots are handed out.
    public static func decorKinds(_ r: RegionID) -> [Decor] {
        switch r {
        case .cap: return [.orchard, .vine, .dovecote, .view, .orchard, .farm, .vine, .rival, .orchard, .dovecote, .farm, .vine, .rival]
        case .abq: return [.scrub, .rv, .mesa, .view, .farm, .scrub, .mesa, .rival, .scrub, .mesa, .rival]
        case .lux: return [.cane, .palms, .crops, .view, .farm, .cane, .palms, .crops, .rival, .cane, .palms, .rival]
        case .bri: return [.pasture, .pasture, .farm, .view, .pasture, .crops, .pasture, .rival, .farm, .pasture, .rival]
        }
    }

    /// The point `s` along a polyline and the direction of the segment it's on (prototype `walkPath`).
    public static func walk(_ pts: [GridPoint], _ sIn: Double) -> (p: GridPoint, dir: GridPoint) {
        var s = sIn
        if pts.count > 1 {
            for i in 1..<pts.count {
                let a = pts[i - 1], b = pts[i], d = hypot(b.x - a.x, b.y - a.y)
                if s <= d || i == pts.count - 1 {
                    let k = clamp(s / max(d, 1e-6), 0, 1)
                    return (GridPoint(a.x + (b.x - a.x) * k, a.y + (b.y - a.y) * k), GridPoint(b.x - a.x, b.y - a.y))
                }
                s -= d
            }
        }
        return (pts[pts.count - 1], GridPoint(1, 0))
    }

    public static func length(_ P: [GridPoint]) -> Double {
        var s = 0.0
        if P.count > 1 { for i in 1..<P.count { s += hypot(P[i].x - P[i - 1].x, P[i].y - P[i - 1].y) } }
        return s
    }

    /// Builds the layout. `free` says whether the region's off-map place (the terminal, the airport…) leaves a point free.
    public init(region reg: RegionID, free ctrFree: (Double, Double) -> Bool) {
        region = reg
        let code = Array(reg.rawValue.utf8)
        var R = Mulberry32(seed: UInt32(135 + Int(code[0]) * 7 + Int(code[1])))
        let wet = reg == .lux || reg == .bri
        func inRect(_ x: Double, _ y: Double, _ r: (Double, Double, Double, Double), _ m: Double) -> Bool {
            x > r.0 - m && x < r.0 + r.2 + m && y > r.1 - m && y < r.1 + r.3 + m
        }
        func land0(_ x: Double, _ y: Double) -> Bool {
            Outskirts.flank(x, y) && x + y > -8 && x + y < 56 && x > -24 && y > -24 && x < 44 && y < 44
                && !(x > -2.5 && x < 17.5 && y > -2.5 && y < 17.5) && ctrFree(x, y) && !(wet && y < -8.6)
                && !Self.outerFields.contains { inRect(x, y, ($0.0, $0.1, 3, 2.2), 0.8) } && !Self.vines.contains { inRect(x, y, $0, 0.4) }
        }
        func okPt(_ x: Double, _ y: Double) -> Bool { land0(x, y) && abs(x - 8) > 1.2 && abs(y - 8) > 1.2 }

        // 1. the tracks
        var tracks: [Track] = []
        func nearTrack(_ x: Double, _ y: Double, _ d: Double, _ skip: Int?) -> Bool {
            for (ti, T) in tracks.enumerated() where ti != skip {
                for p in T.P where abs(p.x - x) < d && abs(p.y - y) < d && hypot(p.x - x, p.y - y) < d { return true }
            }
            return false
        }
        func walkTrack(_ x0: Double, _ y0: Double, _ a0: Double, _ len: Double, _ side: Int, _ from: Int?) -> Track? {
            func ok(_ x: Double, _ y: Double, _ k: Int) -> Bool {
                land0(x, y) && (k < 4 || (abs(x - 8) > 0.9 && abs(y - 8) > 0.9)) && !nearTrack(x, y, k < 6 ? 1.2 : 3, k < 8 ? from : nil)
            }
            if !land0(x0, y0) { return nil }
            var x = x0, y = y0, a = a0, turn = 0.0
            var P = [GridPoint(x, y)]
            var k = 1
            while Double(k) * 0.45 < len {
                turn = turn * 0.86 + (R.next() - 0.5) * 0.14; a += turn; a += (a0 - a) * 0.05
                var nx = x + cos(a) * 0.45, ny = y + sin(a) * 0.45
                if !ok(nx, ny, k) {
                    var found = false
                    for da in [0.3, -0.3, 0.6, -0.6, 0.9, -0.9] {
                        let b = a + da, bx = x + cos(b) * 0.45, by = y + sin(b) * 0.45
                        if ok(bx, by, k) { a = b; turn *= 0.3; nx = bx; ny = by; found = true; break }
                    }
                    if !found { break }
                }
                x = nx; y = ny; P.append(GridPoint(x, y))
                k += 1
            }
            return Double(P.count) * 0.45 < 5 ? nil : Track(P: P, side: side, len: Self.length(P), from: from)
        }
        for side in [-1, 1] {
            var kept = 0
            for s0 in Self.starts {
                if kept >= 3 { break }
                let (x0, y0, hx, hy, len) = side < 0 ? s0 : (s0.1, s0.0, s0.3, s0.2, s0.4)
                if let T = walkTrack(x0, y0, atan2(hy, hx), len, side, nil) { tracks.append(T); kept += 1 }
            }
        }
        // a branch off the middle of each long track
        for ti in 0..<tracks.count {
            let T = tracks[ti]
            if T.len < 9 { continue }
            let at = Self.walk(T.P, T.len * (0.38 + R.next() * 0.2)), a = atan2(at.dir.y, at.dir.x)
            let mag = 1 + R.next() * 0.3, turn = mag * (R.next() < 0.5 ? 1 : -1)
            for tw in [turn, -turn] {
                let len = 6 + R.next() * 4
                if let B = walkTrack(at.p.x, at.p.y, a + tw, len, T.side, ti) { tracks.append(B); break }
            }
        }
        func trackDist(_ x: Double, _ y: Double) -> Double {
            var m = 9.0
            for T in tracks { for p in T.P { let d = hypot(p.x - x, p.y - y); if d < m { m = d } } }
            return m
        }
        func unit(_ d: GridPoint) -> (Double, Double) {
            var l = hypot(d.x, d.y); if l == 0 { l = 1 }
            return (d.x / l, d.y / l)
        }

        // 2. a landing spot beside each main track, two thirds of the way out
        var lands: [Land] = []
        for ti in 0..<tracks.count where tracks[ti].from == nil {
            let T = tracks[ti]
            let s = T.len * (0.58 + R.next() * 0.16), at = Self.walk(T.P, s), (ux, uy) = unit(at.dir)
            for sd in R.next() < 0.5 ? [1.0, -1.0] : [-1.0, 1.0] {
                let x = at.p.x - uy * sd * 1.05, y = at.p.y + ux * sd * 1.05
                if okPt(x, y) && okPt(x + 0.7, y) && okPt(x - 0.5, y + 0.5) {
                    let L = Land(x: x, y: y, s: s, at: at.p); tracks[ti].land = L; lands.append(L); break
                }
            }
        }

        // 3. the plots
        var sites: [Site] = []
        func fits(_ cx: Double, _ cy: Double, _ ux: Double, _ uy: Double, _ w: Double, _ d: Double, _ m: Double) -> Bool {
            var a = -0.5
            while a <= 0.501 {
                var b = -0.5
                while b <= 0.501 {
                    let x = cx + ux * a * w - uy * b * d, y = cy + uy * a * w + ux * b * d
                    if !okPt(x, y) || trackDist(x, y) < 0.34 || lands.contains(where: { hypot(x - $0.x, y - $0.y) < 1.25 })
                        || sites.contains(where: { $0.contains(x, y, m) }) { return false }
                    b += 0.25
                }
                a += 0.25
            }
            let me = Site(cx: cx, cy: cy, ux: ux, uy: uy, w: w, d: d, poly: [], side: 0, scattered: false, r: 0, dist: 0, seed: 0)
            return !sites.contains { q in
                let c1 = q.at(q.w / 2, q.d / 2), c2 = q.at(-q.w / 2, -q.d / 2), c3 = q.at(q.w / 2, -q.d / 2), c4 = q.at(-q.w / 2, q.d / 2)
                return me.contains(q.cx, q.cy, m) || me.contains(c1.x, c1.y, m) || me.contains(c2.x, c2.y, m) || me.contains(c3.x, c3.y, m) || me.contains(c4.x, c4.y, m)
            }
        }
        func addSite(_ cx: Double, _ cy: Double, _ ux: Double, _ uy: Double, _ w: Double, _ d: Double, _ side: Int, _ scat: Bool) {
            var c = Site(cx: cx, cy: cy, ux: ux, uy: uy, w: w, d: d, poly: [], side: side, scattered: scat,
                         r: hypot(w, d) / 2, dist: hypot(cx - 7.5, cy - 7.5), seed: 0)
            for (i, j) in [(-1.0, -1.0), (1.0, -1.0), (1.0, 1.0), (-1.0, 1.0)] {
                let a = i * w / 2 + (R.next() - 0.5) * 0.3
                let b = j * d / 2 + (R.next() - 0.5) * 0.26
                c.poly.append(c.at(a, b))
            }
            c.seed = Int(floor(R.next() * 1e6))
            sites.append(c)
        }
        func rot(_ ux: Double, _ uy: Double, _ tw: Double) -> (Double, Double) {
            (ux * cos(tw) - uy * sin(tw), ux * sin(tw) + uy * cos(tw))
        }
        for T in tracks {
            var s = 0.9 + R.next() * 1.1
            while s < T.len - 0.6 {
                let at = Self.walk(T.P, s), (ux, uy) = unit(at.dir)
                var step = 1.2
                for sd in R.next() < 0.5 ? [1.0, -1.0] : [-1.0, 1.0] {
                    if R.next() < 0.15 { continue } // open land here
                    let w = 1.8 + R.next() * 1.3
                    let d = 1.35 + R.next() * 1.05
                    let off = d / 2 + 0.4 + R.next() * 0.35
                    let tw = (R.next() - 0.5) * 0.22
                    let (vx, vy) = rot(ux, uy, tw)
                    let cx = at.p.x - uy * sd * off, cy = at.p.y + ux * sd * off
                    if fits(cx, cy, vx, vy, w, d, 0.2) { addSite(cx, cy, vx, vy, w, d, T.side, false); step = max(step, w * 0.8) }
                }
                s += step + 0.3 + R.next() * 0.9
            }
        }
        // plots lying back from the tracks, in loose clusters, and then enough for every field and the decor
        func scatter(_ T: Track, near: Double, spread: Double, wBase: Double, wVar: Double, dBase: Double, dVar: Double, mBase: Double, mVar: Double) {
            let at = Self.walk(T.P, R.next() * T.len)
            let ang = R.next() * Double.pi * 2
            let dist = near + R.next() * spread
            let cx = at.p.x + cos(ang) * dist, cy = at.p.y + sin(ang) * dist
            let (ux0, uy0) = unit(at.dir)
            let tw = (R.next() - 0.5) * 0.7
            let (ux, uy) = rot(ux0, uy0, tw)
            let w = wBase + R.next() * wVar
            let d = dBase + R.next() * dVar
            let m = mBase + R.next() * mVar
            if fits(cx, cy, ux, uy, w, d, m) { addSite(cx, cy, ux, uy, w, d, T.side, true) }
        }
        for T in tracks { for _ in 0..<26 { scatter(T, near: 2.6, spread: 3.4, wBase: 1.6, wVar: 1.5, dBase: 1.3, dVar: 1.1, mBase: 0.3, mVar: 0.5) } }
        let kindsAll = Self.decorKinds(reg)
        let need = Outskirts.maxFields + kindsAll.count + 3
        var n = 0
        while !tracks.isEmpty && sites.count < need && n < 900 {
            scatter(tracks[n % tracks.count], near: 2.2, spread: 3 + Double(n) / 60, wBase: 1.7, wVar: 1.2, dBase: 1.35, dVar: 0.9, mBase: 0.25, mVar: 0.3)
            n += 1
        }

        // 4. hand them out
        for i in sites.indices { sites[i].key = sites[i].dist + R.next() * 2.2 }
        var free = sites, decor: [Site] = [], fields: [Site] = [], kinds = kindsAll
        func pick(_ side: Int, _ forDecor: Bool, _ kind: Decor?) -> Site? {
            var best: Int?, bk = 1e9
            for (i, c) in free.enumerated() where c.side == side {
                var k = c.key + (c.scattered == forDecor ? 0 : 1.6)
                if let kind, kind.big { k += max(0, 2.3 - c.w) * 2 + max(0, 1.8 - c.d) * 2 }
                if k < bk { bk = k; best = i }
            }
            guard let b = best else { return nil }
            return free.remove(at: b)
        }
        var i = 0
        while !free.isEmpty && (fields.count < Outskirts.maxFields || !kinds.isEmpty) && i < 400 {
            let side = i % 2 == 1 ? 1 : -1, wantDecor = !kinds.isEmpty && ((i / 2) % 2 == 1 || fields.count >= Outskirts.maxFields)
            i += 1
            guard var c = pick(side, wantDecor, wantDecor ? kinds[0] : nil) else { continue }
            if wantDecor { c.kind = kinds.removeFirst(); decor.append(c) } else { fields.append(c) }
        }
        fields.sort { $0.key < $1.key }

        // 5. the crews: one per main track with a landing spot, nearest first, the two sides taking turns
        let withLand = tracks.enumerated().filter { $0.element.land != nil }
            .sorted { a, b in
                let da = hypot(a.element.P[0].x - 7.5, a.element.P[0].y - 7.5), db = hypot(b.element.P[0].x - 7.5, b.element.P[0].y - 7.5)
                return da != db ? da < db : a.offset < b.offset
            }.map(\.element)
        let crews: [Crew] = withLand.map { T in
            let L = T.land!
            var path = [T.P[0]], s = 0.0
            for i in 1..<T.P.count {
                s += hypot(T.P[i].x - T.P[i - 1].x, T.P[i].y - T.P[i - 1].y)
                if s >= L.s { break }
                path.append(T.P[i])
            }
            path.append(L.at)
            return Crew(path: path, len: Self.length(path), spot: GridPoint(L.x, L.y), dir: GridPoint(L.x - L.at.x, L.y - L.at.y))
        }
        var cl = crews.filter { $0.path[0].y - $0.path[0].x > 0 }, cr = crews.filter { $0.path[0].y - $0.path[0].x <= 0 }, alt: [Crew] = []
        while !cl.isEmpty || !cr.isEmpty {
            if !cl.isEmpty { alt.append(cl.removeFirst()) }
            if !cr.isEmpty { alt.append(cr.removeFirst()) }
        }

        // 6. an ATV loop and a riders' loop round decor plots
        var loops: [Loop] = []
        kindLoop: for k in [Decor.dovecote, .mesa, .pasture, .palms, .orchard, .scrub, .cane, .farm] {
            for c in decor where c.kind == k {
                if loops.contains(where: { $0.site.cx == c.cx && $0.site.cy == c.cy }) { continue }
                var got: [GridPoint]?
                for extra in [0.75, 1.1, 1.45] {
                    let ph = R.next() * 6, rr = c.r + extra
                    var P: [GridPoint] = []
                    for i in 0...32 {
                        let th = Double(i) / 32 * Double.pi * 2
                        let q = 1 + 0.1 * sin(2 * th + ph) + 0.05 * sin(3 * th + ph * 2)
                        P.append(GridPoint(c.cx + cos(th) * rr * q, c.cy + sin(th) * rr * q * 0.86))
                    }
                    P[32] = P[0]
                    let ok = P.allSatisfy { p in
                        okPt(p.x, p.y) && !sites.contains { q in !(q.cx == c.cx && q.cy == c.cy) && q.contains(p.x, p.y, 0.12) }
                            && !lands.contains { hypot(p.x - $0.x, p.y - $0.y) < 1.1 }
                    }
                    if ok { got = P; break }
                }
                if let P = got { loops.append(Loop(site: c, P: P, len: Self.length(P))); break }
            }
            if loops.count >= 2 { break kindLoop }
        }

        // 7. a few trees along the tracks
        var trees: [Tree] = []
        for T in tracks {
            var s = 1.4
            while s < T.len {
                defer { s += 0.8 + R.next() * 2.4 }
                if R.next() < 0.4 { continue }
                let at = Self.walk(T.P, s), (ux, uy) = unit(at.dir)
                let sd: Double = R.next() < 0.5 ? 1 : -1
                let off = 0.5 + R.next() * 0.25
                let x = at.p.x - uy * sd * off, y = at.p.y + ux * sd * off
                let k = 0.8 + R.next() * 0.4
                let kind = R.next() < 0.3 ? 1 : 0
                if okPt(x, y) && !sites.contains(where: { $0.contains(x, y, 0.12) }) && !lands.contains(where: { hypot($0.x - x, $0.y - y) < 1.4 })
                    && !loops.contains(where: { l in l.P.contains { hypot($0.x - x, $0.y - y) < 0.4 } }) {
                    trees.append(Tree(x: x, y: y, k: k, kind: kind))
                }
            }
        }

        self.sites = sites; self.tracks = tracks; self.decor = decor; self.fields = fields
        self.crews = alt; self.loops = loops; self.lands = lands; self.trees = trees
    }

    /// The outer landmarks (fairy chimneys, buttes, trees…) keep clear of every plot, track and loop (`outBusy`).
    public func busy(_ gx: Double, _ gy: Double) -> Bool {
        sites.contains { $0.contains(gx, gy, 0.9) }
            || tracks.contains { T in T.P.contains { abs($0.x - gx) < 0.8 && abs($0.y - gy) < 0.8 } }
            || lands.contains { hypot($0.x - gx, $0.y - gy) < 1.8 }
            || loops.contains { hypot($0.site.cx - gx, $0.site.cy - gy) < $0.site.r + 2.4 }
    }

    /// How far the town can be dragged: the plots in use and the crews' landing spots (`outskirtsExtent`).
    public func extent(fields nf: Int) -> [GridPoint] {
        decor.map { GridPoint($0.cx, $0.cy) } + fields.prefix(max(1, nf)).map { GridPoint($0.cx, $0.cy) }
            + crews.prefix(Outskirts.crews(fields: nf)).map(\.spot)
    }
}
