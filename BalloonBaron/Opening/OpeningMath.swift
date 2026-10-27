import Foundation
import simd

// The opening film's math, ported from the prototype's `open3dLoad()`: its seeded random numbers and noises, three.js's
// Catmull-Rom curves, and a small mesh builder (lathe, icosphere, rounded box) that merges many copies into one geometry.

typealias D3 = SIMD3<Double>
typealias F3 = SIMD3<Float>
typealias F2 = SIMD2<Float>

@inline(__always) func oClamp(_ v: Double, _ a: Double, _ b: Double) -> Double { max(a, min(b, v)) }
@inline(__always) func oLerp(_ a: Double, _ b: Double, _ k: Double) -> Double { a + (b - a) * k }
@inline(__always) func oLerp(_ a: D3, _ b: D3, _ k: Double) -> D3 { a + (b - a) * k }
/// `ease3`: fast out, slow in.
func oEase3(_ k: Double) -> Double { 1 - pow(1 - oClamp(k, 0, 1), 3) }
/// `easeIO3`: cubic in and out.
func oEaseIO3(_ k: Double) -> Double {
    let k = oClamp(k, 0, 1)
    return k < 0.5 ? 4 * k * k * k : 1 - pow(-2 * k + 2, 3) / 2
}

/// The prototype's `mulberry32`: the same seed gives the same town.
struct Mulberry32 {
    private var a: UInt32
    init(_ seed: UInt32) { a = seed }

    mutating func next() -> Double {
        a = a &+ 0x6D2B79F5
        var q = (a ^ (a >> 15)) &* (1 | a)
        q = (q &+ ((q ^ (q >> 7)) &* (61 | q))) ^ q
        return Double(q ^ (q >> 14)) / 4294967296
    }

    /// `rnd() * n | 0`.
    mutating func int(_ n: Int) -> Int { Int(next() * Double(n)) }
}

/// three.js's `ImprovedNoise`: Ken Perlin's reference 3D noise with his permutation table.
enum ImprovedNoise {
    private static let p: [Int] = {
        let base = [151, 160, 137, 91, 90, 15, 131, 13, 201, 95, 96, 53, 194, 233, 7, 225, 140, 36, 103, 30, 69, 142, 8, 99, 37, 240, 21, 10,
                    23, 190, 6, 148, 247, 120, 234, 75, 0, 26, 197, 62, 94, 252, 219, 203, 117, 35, 11, 32, 57, 177, 33, 88, 237, 149, 56, 87,
                    174, 20, 125, 136, 171, 168, 68, 175, 74, 165, 71, 134, 139, 48, 27, 166, 77, 146, 158, 231, 83, 111, 229, 122, 60, 211, 133,
                    230, 220, 105, 92, 41, 55, 46, 245, 40, 244, 102, 143, 54, 65, 25, 63, 161, 1, 216, 80, 73, 209, 76, 132, 187, 208, 89, 18,
                    169, 200, 196, 135, 130, 116, 188, 159, 86, 164, 100, 109, 198, 173, 186, 3, 64, 52, 217, 226, 250, 124, 123, 5, 202, 38, 147,
                    118, 126, 255, 82, 85, 212, 207, 206, 59, 227, 47, 16, 58, 17, 182, 189, 28, 42, 223, 183, 170, 213, 119, 248, 152, 2, 44,
                    154, 163, 70, 221, 153, 101, 155, 167, 43, 172, 9, 129, 22, 39, 253, 19, 98, 108, 110, 79, 113, 224, 232, 178, 185, 112, 104,
                    218, 246, 97, 228, 251, 34, 242, 193, 238, 210, 144, 12, 191, 179, 162, 241, 81, 51, 145, 235, 249, 14, 239, 107, 49, 192,
                    214, 31, 181, 199, 106, 157, 184, 84, 204, 176, 115, 121, 50, 45, 127, 4, 150, 254, 138, 236, 205, 93, 222, 114, 67, 29, 24,
                    72, 243, 141, 128, 195, 78, 66, 215, 61, 156, 180]
        return base + base
    }()

    @inline(__always) private static func fade(_ t: Double) -> Double { t * t * t * (t * (t * 6 - 15) + 10) }
    @inline(__always) private static func lerp(_ t: Double, _ a: Double, _ b: Double) -> Double { a + t * (b - a) }
    @inline(__always) private static func grad(_ hash: Int, _ x: Double, _ y: Double, _ z: Double) -> Double {
        let h = hash & 15
        let u = h < 8 ? x : y, v = h < 4 ? y : (h == 12 || h == 14 ? x : z)
        return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v)
    }

    static func noise(_ x: Double, _ y: Double, _ z: Double) -> Double {
        let fx = floor(x), fy = floor(y), fz = floor(z)
        let X = Int(fx) & 255, Y = Int(fy) & 255, Z = Int(fz) & 255
        let x = x - fx, y = y - fy, z = z - fz
        let x1 = x - 1, y1 = y - 1, z1 = z - 1
        let u = fade(x), v = fade(y), w = fade(z)
        let A = p[X] + Y, AA = p[A] + Z, AB = p[A + 1] + Z, B = p[X + 1] + Y, BA = p[B] + Z, BB = p[B + 1] + Z
        return lerp(w, lerp(v, lerp(u, grad(p[AA], x, y, z), grad(p[BA], x1, y, z)),
                            lerp(u, grad(p[AB], x, y1, z), grad(p[BB], x1, y1, z))),
                    lerp(v, lerp(u, grad(p[AA + 1], x, y, z1), grad(p[BA + 1], x1, y, z1)),
                         lerp(u, grad(p[AB + 1], x, y1, z1), grad(p[BB + 1], x1, y1, z1))))
    }
}

@inline(__always) func n3(_ x: Double, _ y: Double, _ z: Double) -> Double { ImprovedNoise.noise(x, y, z) }

/// The prototype's own 2D gradient noise and fbm, its permutation shuffled by the seeded generator.
struct Perlin2 {
    private let P: [Int]

    init(_ rnd: inout Mulberry32) {
        var p = Array(0..<256)
        for i in stride(from: 255, to: 0, by: -1) {
            let j = Int(floor(rnd.next() * Double(i + 1)))
            p.swapAt(i, j)
        }
        P = p + p
    }

    @inline(__always) private static func fade(_ t: Double) -> Double { t * t * t * (t * (t * 6 - 15) + 10) }
    @inline(__always) private static func grad(_ h: Int, _ x: Double, _ y: Double) -> Double {
        ((h & 1) != 0 ? x : -x) + ((h & 2) != 0 ? y : -y)
    }

    func noise(_ x: Double, _ y: Double) -> Double {
        let fx = floor(x), fy = floor(y)
        let X = Int(fx) & 255, Y = Int(fy) & 255
        let x = x - fx, y = y - fy
        let u = Perlin2.fade(x), v = Perlin2.fade(y), A = P[X] + Y, B = P[X + 1] + Y
        return oLerp(oLerp(Perlin2.grad(P[A], x, y), Perlin2.grad(P[B], x - 1, y), u),
                     oLerp(Perlin2.grad(P[A + 1], x, y - 1), Perlin2.grad(P[B + 1], x - 1, y - 1), u), v)
    }

    func fbm(_ x: Double, _ y: Double, _ o: Int = 5) -> Double {
        var s = 0.0, a = 0.5, f = 1.0
        for _ in 0..<o {
            s += a * noise(x * f, y * f)
            a *= 0.5
            f *= 2.03
        }
        return s
    }
}

/// three.js's `CatmullRomCurve3` (open, centripetal): `point(t)` like `getPoint`, and the arc-length versions
/// `pointAt` / `tangentAt` like `getPointAt` / `getTangentAt`.
struct CRCurve {
    let pts: [D3]
    private var lengths: [Double] = []

    init(_ pts: [D3]) {
        self.pts = pts
        var acc = [0.0], last = point(0), sum = 0.0
        for i in 1...200 {
            let p = point(Double(i) / 200)
            sum += simd_distance(p, last)
            acc.append(sum)
            last = p
        }
        lengths = acc
    }

    init(_ pts: [[Double]]) { self.init(pts.map { D3($0[0], $0[1], $0[2]) }) }

    private static func cubic(_ x0: Double, _ x1: Double, _ x2: Double, _ x3: Double, _ dt0: Double, _ dt1: Double, _ dt2: Double,
                              _ t: Double) -> Double {
        var t1 = (x1 - x0) / dt0 - (x2 - x0) / (dt0 + dt1) + (x2 - x1) / dt1
        var t2 = (x2 - x1) / dt1 - (x3 - x1) / (dt1 + dt2) + (x3 - x2) / dt2
        t1 *= dt1
        t2 *= dt1
        let c0 = x1, c1 = t1, c2 = -3 * x1 + 3 * x2 - 2 * t1 - t2, c3 = 2 * x1 - 2 * x2 + t1 + t2
        return c0 + c1 * t + c2 * t * t + c3 * t * t * t
    }

    func point(_ t: Double) -> D3 {
        let l = pts.count
        guard l > 1 else { return pts.first ?? .zero }
        let p = Double(l - 1) * oClamp(t, 0, 1)
        var i = Int(floor(p)), w = p - Double(i)
        if w == 0 && i == l - 1 { i = l - 2; w = 1 }
        let p0 = i > 0 ? pts[i - 1] : pts[0] + (pts[0] - pts[1])
        let p1 = pts[i], p2 = pts[i + 1]
        let p3 = i + 2 < l ? pts[i + 2] : pts[l - 1] + (pts[l - 1] - pts[l - 2])
        var dt0 = pow(simd_distance_squared(p0, p1), 0.25), dt1 = pow(simd_distance_squared(p1, p2), 0.25)
        var dt2 = pow(simd_distance_squared(p2, p3), 0.25)
        if dt1 < 1e-4 { dt1 = 1 }
        if dt0 < 1e-4 { dt0 = dt1 }
        if dt2 < 1e-4 { dt2 = dt1 }
        return D3(CRCurve.cubic(p0.x, p1.x, p2.x, p3.x, dt0, dt1, dt2, w), CRCurve.cubic(p0.y, p1.y, p2.y, p3.y, dt0, dt1, dt2, w),
                  CRCurve.cubic(p0.z, p1.z, p2.z, p3.z, dt0, dt1, dt2, w))
    }

    /// `getUtoTmapping`: the curve's own parameter at a fraction of its length.
    private func uToT(_ u: Double) -> Double {
        let n = lengths.count, target = oClamp(u, 0, 1) * lengths[n - 1]
        var low = 0, high = n - 1
        while low <= high {
            let i = low + (high - low) / 2, c = lengths[i] - target
            if c < 0 { low = i + 1 } else if c > 0 { high = i - 1 } else { high = i; break }
        }
        let i = max(0, min(n - 2, high))
        if lengths[i] == target { return Double(i) / Double(n - 1) }
        let seg = lengths[i + 1] - lengths[i]
        return (Double(i) + (seg > 0 ? (target - lengths[i]) / seg : 0)) / Double(n - 1)
    }

    func pointAt(_ u: Double) -> D3 { point(uToT(u)) }

    func tangentAt(_ u: Double) -> D3 {
        let t = uToT(u)
        let a = point(max(0, t - 0.0001)), b = point(min(1, t + 0.0001))
        return simd_normalize(b - a)
    }
}

/// three.js's `SplineCurve` (uniform Catmull-Rom in 2D) sampled like `getPoints(divisions)`.
func splinePoints(_ pts: [(Double, Double)], _ divisions: Int) -> [(Double, Double)] {
    func cr(_ t: Double, _ p0: Double, _ p1: Double, _ p2: Double, _ p3: Double) -> Double {
        let v0 = (p2 - p0) * 0.5, v1 = (p3 - p1) * 0.5, t2 = t * t, t3 = t * t2
        return (2 * p1 - 2 * p2 + v0 + v1) * t3 + (-3 * p1 + 3 * p2 - 2 * v0 - v1) * t2 + v0 * t + p1
    }
    let n = pts.count
    return (0...divisions).map { d in
        let p = Double(n - 1) * Double(d) / Double(divisions)
        let i = Int(floor(p)), w = p - Double(i)
        let a = pts[i == 0 ? i : i - 1], b = pts[min(i, n - 1)], c = pts[i > n - 2 ? n - 1 : i + 1], e = pts[i > n - 3 ? n - 1 : i + 2]
        return (cr(w, a.0, b.0, c.0, e.0), cr(w, a.1, b.1, c.1, e.1))
    }
}

/// Triangles with normals, texture coordinates (three.js's: v goes up) and linear vertex colors. Many copies of
/// small meshes are merged into one, so the film draws a few big geometries instead of thousands of nodes.
struct Mesh {
    var p: [F3] = []
    var n: [F3] = []
    var uv: [F2] = []
    var c: [F3] = []
    var i: [UInt32] = []

    var isEmpty: Bool { i.isEmpty }

    /// Smooth normals from the faces (`computeVertexNormals`).
    mutating func computeNormals() {
        var acc = [F3](repeating: .zero, count: p.count)
        var k = 0
        while k + 2 < i.count {
            let a = Int(i[k]), b = Int(i[k + 1]), d = Int(i[k + 2])
            let fn = simd_cross(p[b] - p[a], p[d] - p[a])
            acc[a] += fn
            acc[b] += fn
            acc[d] += fn
            k += 3
        }
        n = acc.map { simd_length($0) > 1e-12 ? simd_normalize($0) : F3(0, 1, 0) }
    }

    /// Averages the normals of the two columns where a lathe closes, so the seam doesn't show.
    mutating func weldSeam(columns: Int, rows: Int) {
        guard n.count == (columns + 1) * rows else { return }
        for j in 0..<rows {
            let a = j, b = columns * rows + j
            let m = n[a] + n[b]
            let v = simd_length(m) > 1e-12 ? simd_normalize(m) : n[a]
            n[a] = v
            n[b] = v
        }
    }

    /// Appends `m` moved by position, rotation and scale, its colors multiplied by `tint`. Normals follow the scale
    /// properly (the inverse transpose), like three.js does for instances.
    mutating func add(_ m: Mesh, at pos: F3, rot: simd_quatf = simd_quatf(angle: 0, axis: F3(0, 1, 0)), scale: F3 = F3(1, 1, 1),
                      tint: F3 = F3(1, 1, 1)) {
        let base = UInt32(p.count)
        p.reserveCapacity(p.count + m.p.count)
        for v in m.p { p.append(rot.act(v * scale) + pos) }
        let hasN = m.n.count == m.p.count
        for k in 0..<m.p.count {
            if hasN {
                let w = rot.act(m.n[k] / scale)
                n.append(simd_length(w) > 1e-12 ? simd_normalize(w) : F3(0, 1, 0))
            } else {
                n.append(F3(0, 1, 0))
            }
            uv.append(k < m.uv.count ? m.uv[k] : F2(0, 0))
            c.append((k < m.c.count ? m.c[k] : F3(1, 1, 1)) * tint)
        }
        i.reserveCapacity(i.count + m.i.count)
        for x in m.i { i.append(base + x) }
    }

    /// `LatheGeometry(points, segments)`: x = r sin φ, z = r cos φ, u around, v along the profile.
    static func lathe(_ profile: [(Double, Double)], segments: Int) -> Mesh {
        var m = Mesh()
        let rows = profile.count
        for s in 0...segments {
            let phi = Double(s) / Double(segments) * 2 * Double.pi
            let sn = sin(phi), cs = cos(phi)
            for (j, q) in profile.enumerated() {
                m.p.append(F3(Float(q.0 * sn), Float(q.1), Float(q.0 * cs)))
                m.uv.append(F2(Float(Double(s) / Double(segments)), Float(Double(j) / Double(rows - 1))))
            }
        }
        for s in 0..<segments {
            for j in 0..<(rows - 1) {
                let a = UInt32(s * rows + j), b = a + UInt32(rows), c = b + 1, d = a + 1
                m.i += [a, b, d, c, d, b]
            }
        }
        m.computeNormals()
        m.weldSeam(columns: segments, rows: rows)
        return m
    }

    /// three.js's `IcosahedronGeometry(1, detail)` with shared vertices (`mergeVertices`), so displaced rock shades smoothly.
    static func icosphere(_ detail: Int) -> Mesh {
        let t = (1 + 5.0.squareRoot()) / 2
        let base: [D3] = [D3(-1, t, 0), D3(1, t, 0), D3(-1, -t, 0), D3(1, -t, 0), D3(0, -1, t), D3(0, 1, t), D3(0, -1, -t), D3(0, 1, -t),
                          D3(t, 0, -1), D3(t, 0, 1), D3(-t, 0, -1), D3(-t, 0, 1)]
        let faces = [0, 11, 5, 0, 5, 1, 0, 1, 7, 0, 7, 10, 0, 10, 11, 1, 5, 9, 5, 11, 4, 11, 10, 2, 10, 7, 6, 7, 1, 8, 3, 9, 4, 3, 4, 2, 3, 2, 6,
                     3, 6, 8, 3, 8, 9, 4, 9, 5, 2, 4, 11, 6, 2, 10, 8, 6, 7, 9, 8, 1]
        var m = Mesh()
        var index: [SIMD3<Int32>: UInt32] = [:]
        func vertex(_ v: D3) -> UInt32 {
            let u = simd_normalize(v)
            let key = SIMD3<Int32>(Int32((u.x * 1e4).rounded()), Int32((u.y * 1e4).rounded()), Int32((u.z * 1e4).rounded()))
            if let k = index[key] { return k }
            let k = UInt32(m.p.count)
            m.p.append(F3(u))
            index[key] = k
            return k
        }
        let cols = detail + 1
        for f in stride(from: 0, to: faces.count, by: 3) {
            let a = base[faces[f]], b = base[faces[f + 1]], c = base[faces[f + 2]]
            var v: [[D3]] = []
            for i in 0...cols {
                let aj = oLerp(a, c, Double(i) / Double(cols)), bj = oLerp(b, c, Double(i) / Double(cols)), rows = cols - i
                var row: [D3] = []
                for j in 0...rows { row.append(j == 0 && i == cols ? aj : oLerp(aj, bj, Double(j) / Double(rows))) }
                v.append(row)
            }
            for i in 0..<cols {
                for j in 0..<(2 * (cols - i) - 1) {
                    let k = j / 2
                    if j % 2 == 0 {
                        m.i += [vertex(v[i][k + 1]), vertex(v[i + 1][k]), vertex(v[i][k])]
                    } else {
                        m.i += [vertex(v[i][k + 1]), vertex(v[i + 1][k + 1]), vertex(v[i + 1][k])]
                    }
                }
            }
        }
        m.computeNormals()
        return m
    }

    /// `RoundedBoxGeometry(w, h, d, segments, radius)`: each face a grid whose border rows wrap round the edges.
    /// Every face carries its own 0…1 texture, upright on the sides.
    static func roundedBox(_ size: F3, radius: Float, segments: Int) -> Mesh {
        var m = Mesh()
        let half = size / 2, r = min(radius, min(half.x, min(half.y, half.z)))
        let inner = half - F3(repeating: r)
        // Positions along one side of a face: the corner arc, then straight across.
        let steps = (0...segments).map { Float($0) / Float(segments) }
        func line(_ h: Float) -> [Float] {
            var a: [Float] = steps.map { -h + r * $0 * 0.999 }
            a += steps.map { (h - r) + r * $0 }
            return a.enumerated().filter { $0.offset == 0 || $0.element > a[$0.offset - 1] + 1e-5 }.map(\.element)
        }
        // (normal axis, sign, u axis, v axis), u and v chosen so the texture reads upright from outside.
        let faces: [(Int, Float, Int, Float, Int, Float)] = [(0, 1, 2, -1, 1, 1), (0, -1, 2, 1, 1, 1), (1, 1, 0, 1, 2, -1),
                                                             (1, -1, 0, 1, 2, 1), (2, 1, 0, 1, 1, 1), (2, -1, 0, -1, 1, 1)]
        for (ax, sg, ua, us, va, vs) in faces {
            let us0 = line(half[ua]), vs0 = line(half[va])
            let base = UInt32(m.p.count), cu = us0.count, cv = vs0.count
            var out = F3.zero, du = F3.zero, dv = F3.zero
            out[ax] = sg
            du[ua] = us
            dv[va] = vs
            let ccw = simd_dot(simd_cross(du, dv), out) > 0
            for vv in vs0 {
                for uu in us0 {
                    var q = F3.zero
                    q[ax] = sg * half[ax]
                    q[ua] = uu * us
                    q[va] = vv * vs
                    let c = simd_clamp(q, -inner, inner)
                    let d = q - c
                    let nn = simd_length(d) > 1e-6 ? simd_normalize(d) : { var z = F3.zero; z[ax] = sg; return z }()
                    m.p.append(c + nn * r)
                    m.n.append(nn)
                    m.uv.append(F2((uu / half[ua] + 1) / 2, (vv / half[va] + 1) / 2))
                }
            }
            for jv in 0..<(cv - 1) {
                for ju in 0..<(cu - 1) {
                    // Wound so the face's normal points out.
                    let a = base + UInt32(jv * cu + ju), b = a + 1, c = a + UInt32(cu), d = c + 1
                    m.i += ccw ? [a, b, c, b, d, c] : [a, c, b, b, c, d]
                }
            }
        }
        return m
    }
}

/// sRGB hex to the linear color three.js keeps (`new THREE.Color('#…')` with color management on).
func linearColor(_ hex: String) -> F3 {
    let s = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
    let v = UInt32(s, radix: 16) ?? 0
    func lin(_ c: UInt32) -> Float {
        let x = Float(c) / 255
        return x <= 0.04045 ? x / 12.92 : pow((x + 0.055) / 1.055, 2.4)
    }
    return F3(lin((v >> 16) & 0xff), lin((v >> 8) & 0xff), lin(v & 0xff))
}

func linearColor(_ v: UInt32) -> F3 { linearColor(String(format: "%06x", v)) }

/// sRGB components 0…1, for painting textures.
func srgbColor(_ v: UInt32) -> F3 { F3(Float((v >> 16) & 0xff) / 255, Float((v >> 8) & 0xff) / 255, Float(v & 0xff) / 255) }
