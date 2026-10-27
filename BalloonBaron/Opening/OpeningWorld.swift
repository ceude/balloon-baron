import SceneKit
import UIKit
import simd

/// The land under the film: Göreme round the origin, its launch field, the Three Beauties to the south-east and Uçhisar
/// on its hill to the south-west (metres). `height()` is the prototype's, octave for octave.
struct OpeningLand {
    let perlin: Perlin2
    let UG = D3(270, 0, 560), UCH = D3(-390, 0, 400)

    /// v121.5: our own town east of Göreme, the game's grid one to one: tile (gx, gy) is 12 m, gx runs east, gy south.
    static let TL = 12.0, TO = D3(110, 0, -150)
    static func tw(_ gx: Double, _ gy: Double, _ y: Double = 0) -> D3 { D3(TO.x + gx * TL, y, TO.z + gy * TL) }
    static let TC = tw(7.5, 7.5)
    /// Inside the town's square, with a margin.
    static func inTown(_ x: Double, _ z: Double, _ m: Double) -> Bool { abs(x - TC.x) < 8 * TL + m && abs(z - TC.z) < 8 * TL + m }
    /// Distance from the line the balloon flies from the field to the town (kept clear of the big cave rocks).
    static func toTown(_ x: Double, _ z: Double) -> Double {
        let ax = -44.0, az = 31.0, bx = TO.x + 2 * TL, bz = TO.z + 5 * TL
        let k = oClamp(((x - ax) * (bx - ax) + (z - az) * (bz - az)) / ((bx - ax) * (bx - ax) + (bz - az) * (bz - az)), 0, 1)
        return hypot(x - ax - k * (bx - ax), z - az - k * (bz - az))
    }

    func height(_ x: Double, _ z: Double) -> Double {
        let tb = max(abs(x - OpeningLand.TC.x) - 100, abs(z - OpeningLand.TC.z) - 100, 0) // the town stands on level ground
        return natural(x, z) * oClamp(tb / 70, 0, 1)
    }

    private func natural(_ x: Double, _ z: Double) -> Double {
        let d = hypot(x, z), flat = oClamp((d - 80) / 240, 0, 1)
        var y = perlin.fbm(x * 0.004, z * 0.004) * 80 * flat + max(0, perlin.fbm(x * 0.0016 + 7, z * 0.0016) * 220 - 20) * flat * flat
        y += abs(perlin.fbm(x * 0.01 + 3, z * 0.01 + 9, 3)) * 12 * flat
        let du = hypot(x - UCH.x, z - UCH.z)
        y += 75 * exp(-du * du / (2 * 150 * 150)) // Uçhisar's hill
        let dg = hypot(x - UG.x, z - UG.z)
        y *= oClamp(dg / 60, 0.35, 1) // the Beauties stand on a gentle rise
        return y + perlin.fbm(x * 0.05, z * 0.05, 2) * 1.2
    }
}

/// A balloon in the film: the whole rig, its envelope and the burner's glow.
struct FilmBalloon {
    let node: SCNNode
    let env: SCNNode
    let glow: SCNNode
    /// The hero's ropes, each a chain of short segments that can hang slack (`ropeFrame`).
    var dyn: [[SCNNode]] = []
}

/// What the film's copy of our town is built from, kept from the world (`OpeningTown`).
struct TownKit {
    let facades: [SCNMaterial]
    let tuff: SCNMaterial
    let basalt: SCNMaterial
    let basaltColor: F3
    let mottle: CGImage?
    let chimneys: [Mesh]
    let cap: Mesh
    /// The rounded unit box standing on its base (`hgeo`) and the parapet slab (`parG`).
    let box: Mesh
    let parapet: Mesh
}

/// One of the morning's balloons: where it stands, when it goes up and how fast.
struct CrowdBalloon {
    let b: FilmBalloon
    let gy: Double, go: Double, v: Double, ph: Double, x: Double, z: Double
}

/// The whole film set, built once off the main thread (`open3dLoad()` up to the render loop): sky, terrain, fairy
/// chimneys, Üç Güzeller, Uçhisar, the towns, the terrace, the field with the old basket, the morning's balloons, mist and
/// dust, and the camera paths. `OpeningFilm` animates it.
final class OpeningWorld {
    let scene = SCNScene()
    let cameraNode = SCNNode()
    let camera = SCNCamera()
    let land: OpeningLand
    let FIELD: D3, BASKET: D3, TERR: D3
    var UG: D3 { land.UG }
    var UCH: D3 { land.UCH }

    // what the light and the dawn change
    let skyMaterial: SCNMaterial
    let stars: SCNNode
    let moon: SCNNode
    let sunNode = SCNNode()
    let sun = SCNLight()
    let ambient = SCNLight(), skyFill = SCNLight(), groundFill = SCNLight()
    let litWindows: SCNMaterial
    let lantern = SCNLight()
    let mists: [SCNNode]
    let mistMaterial: SCNMaterial
    let dust: SCNNode
    let crowd: [CrowdBalloon]
    let cloth: SCNNode
    let basket: SCNNode
    /// Every material that takes the fog.
    private(set) var fogged: [SCNMaterial] = []

    // the colour pick in the sky, and what the hero balloon is made of
    let pick: [FilmBalloon]
    let halo: SCNNode
    let flameLight = SCNLight()
    private let envGeometry: SCNGeometry
    private let basketGeometry: SCNGeometry
    private let flameMaterial: SCNMaterial
    private let ropeMaterial: SCNMaterial
    private let ropeSegment: SCNGeometry
    let kit: TownKit

    /// Where the ropes start (the basket's corners) and end (round the envelope's mouth), in balloon units.
    static let ropeB = [(1, 1), (1, -1), (-1, 1), (-1, -1)].map { F3(Float($0.0) * 0.047, 0.06, Float($0.1) * 0.047) }
    static let ropeM = [(1, 1), (1, -1), (-1, 1), (-1, -1)].map { F3(Float($0.0) * 0.074, 0, Float($0.1) * 0.074) }

    /// A rope segment: a thin five-sided tube from the origin up to y = 1.
    static func ropeCylinder() -> Mesh {
        var m = Mesh()
        for y in [Float(0), Float(1)] {
            for s in 0...5 {
                let a = Float(s) / 5 * 2 * Float.pi
                m.p.append(F3(sin(a), y, cos(a)))
            }
        }
        for s in 0..<5 {
            let a = UInt32(s), b = UInt32(s + 1), c = UInt32(s + 6), d = UInt32(s + 7)
            m.i += [a, b, c, b, d, c]
        }
        m.computeNormals()
        return m
    }

    /// The rotation and length that take a unit rope segment from `a` to `b` (`span`).
    static func span(_ a: F3, _ b: F3) -> (simd_quatf, Float) {
        let d = b - a, l = simd_length(d)
        guard l > 1e-6 else { return (simd_quatf(angle: 0, axis: F3(0, 1, 0)), 0) }
        return (simd_quatf(from: F3(0, 1, 0), to: d / l), l)
    }

    /// Windows and doors: arched panes turned to face out (`winMesh`).
    static func windows(_ list: [(D3, Double, Double)]) -> SCNGeometry {
        var arch = Mesh()
        arch.p = [F3(-0.5, 0, 0), F3(0.5, 0, 0), F3(-0.5, 1.5, 0), F3(0.5, 1.5, 0)]
        arch.n = Array(repeating: F3(0, 0, 1), count: 4)
        arch.i = [0, 1, 2, 1, 3, 2]
        var m = Mesh()
        for (p, a, s) in list { m.add(arch, at: F3(p), rot: simd_quatf(angle: Float(Double.pi / 2 - a), axis: F3(0, 1, 0)), scale: F3(repeating: Float(s))) }
        return OpeningKit.geometry(m, colors: false)
    }

    // the camera's paths
    let flightEye: CRCurve, flightAt: CRCurve
    let liftEye: CRCurve, liftUp: CRCurve
    private let floorTable: [Double]
    static let flightDur = 30.0

    /// Light masks: the lantern lights only the terrace, the hero's burner only the hero and the ground.
    static let terraceMask = 2, flameMask = 4

    // swiftlint:disable:next function_body_length
    init(lite: Bool) {
        var rnd = FilmRandom(1907)
        let land = OpeningLand(perlin: Perlin2(&rnd))
        self.land = land
        func height(_ x: Double, _ z: Double) -> Double { land.height(x, z) }
        func fbm(_ x: Double, _ y: Double, _ o: Int = 5) -> Double { land.perlin.fbm(x, y, o) }
        let FIELD = D3(-40, 0, 30)
        var BASKET = D3(-44, 0, 31)
        let UG = D3(land.UG.x, height(land.UG.x, land.UG.z), land.UG.z)
        let UCH = D3(land.UCH.x, height(land.UCH.x, land.UCH.z), land.UCH.z)
        var TERR = D3(14, 0, 92)
        TERR.y = height(TERR.x, TERR.z)
        let root = scene.rootNode
        var fogged: [SCNMaterial] = []
        func lit(_ contents: Any?, doubleSided: Bool = false, fog: Bool = true) -> SCNMaterial {
            let m = SCNMaterial()
            m.lightingModel = .lambert
            m.diffuse.contents = contents
            OpeningKit.mipmapped(m.diffuse)
            m.isDoubleSided = doubleSided
            if fog {
                m.shaderModifiers = [.fragment: OpeningKit.fogModifier]
                fogged.append(m)
            }
            return m
        }
        func node(_ g: SCNGeometry, _ mats: [SCNMaterial], shadow: Bool = true, mask: Int = 1) -> SCNNode {
            g.materials = mats
            let n = SCNNode(geometry: g)
            n.castsShadow = shadow
            n.categoryBitMask = mask
            root.addChildNode(n)
            return n
        }

        // camera: three.js's PerspectiveCamera(42, aspect, .3, 9000); the grade becomes SceneKit's own post effects
        camera.fieldOfView = 42
        camera.zNear = 0.3
        camera.zFar = 9000
        camera.wantsHDR = true
        camera.wantsExposureAdaptation = false
        camera.bloomIntensity = 0.6
        camera.bloomThreshold = 0.8
        camera.bloomBlurRadius = 10
        camera.vignettingPower = 0.6
        camera.vignettingIntensity = 0.9
        camera.grainIntensity = lite ? 0 : 0.05
        camera.grainScale = 1
        camera.grainIsColored = false
        camera.colorFringeStrength = 0.4
        camera.colorFringeIntensity = 0.5
        camera.saturation = 1.04
        cameraNode.camera = camera
        root.addChildNode(cameraNode)

        // sky: a gradient dome with the sun's disk and glow
        let skyMat = SCNMaterial()
        skyMat.lightingModel = .constant
        skyMat.diffuse.contents = UIColor.black
        skyMat.cullMode = .front
        skyMat.writesToDepthBuffer = false
        skyMat.shaderModifiers = [.fragment: OpeningKit.skyModifier]
        skyMaterial = skyMat
        let skyGeo = SCNSphere(radius: 6000)
        skyGeo.segmentCount = 48
        let sky = node(skyGeo, [skyMat], shadow: false)
        sky.renderingOrder = -100

        // stars, and the moon
        var sp: [F3] = []
        for _ in 0..<1200 {
            let a = rnd.next() * Double.pi * 2, el = asin(rnd.next() * 0.95 + 0.05), r = 5500.0
            sp.append(F3(Float(cos(a) * cos(el) * r), Float(sin(el) * r), Float(sin(a) * cos(el) * r)))
        }
        let starMat = OpeningKit.flat(OpeningKit.color(linearColor("#fff4dd")))
        starMat.writesToDepthBuffer = false
        stars = node(OpeningKit.points(sp, size: 1, minRadius: 1, maxRadius: 1), [starMat], shadow: false)
        stars.renderingOrder = -90
        let moonMat = OpeningKit.flat(OpeningTextures.glow(srgbColor(0xdfe6ff)), additive: true)
        moon = OpeningKit.sprite(moonMat, size: 260)
        moon.simdPosition = F3(-2600, 1700, -3800)
        moon.renderingOrder = -80
        root.addChildNode(moon)

        // light: the sun (casting shadows round the camera) and a hemisphere, here an ambient plus a light from above and
        // one from below
        sun.type = .directional
        sun.castsShadow = true
        sun.shadowMapSize = lite ? CGSize(width: 1024, height: 1024) : CGSize(width: 2048, height: 2048)
        sun.orthographicScale = 220
        sun.zNear = 10
        sun.zFar = 2400
        sun.shadowMode = .forward
        sun.shadowSampleCount = lite ? 1 : 4
        sun.shadowRadius = 2
        sun.shadowBias = 2
        sun.shadowColor = UIColor(white: 0, alpha: 1)
        sun.intensity = 0
        sunNode.light = sun
        root.addChildNode(sunNode)
        ambient.type = .ambient
        let skyFillNode = SCNNode(), groundFillNode = SCNNode(), ambientNode = SCNNode()
        skyFill.type = .directional
        groundFill.type = .directional
        skyFillNode.light = skyFill
        skyFillNode.simdEulerAngles = F3(-Float.pi / 2, 0, 0)
        groundFillNode.light = groundFill
        groundFillNode.simdEulerAngles = F3(Float.pi / 2, 0, 0)
        ambientNode.light = ambient
        root.addChildNode(skyFillNode)
        root.addChildNode(groundFillNode)
        root.addChildNode(ambientNode)

        // terrain: tuff in bands, darker on slopes, a little green in the hollows
        let tuff = ["#ecd2ae", "#e6b693", "#dba489", "#f2e0c6", "#cf957a"].map(linearColor)
        let grass = linearColor("#7d8448"), slopeCol = linearColor("#a46c56")
        var tm = Mesh()
        let N = 260, size = 5200.0
        for j in 0...N {
            for i in 0...N {
                let x = -size / 2 + size * Double(i) / Double(N), z = -size / 2 + size * Double(j) / Double(N), y = height(x, z)
                tm.p.append(F3(Float(x), Float(y), Float(z)))
                tm.uv.append(F2(Float(i) / Float(N), 1 - Float(j) / Float(N)))
                let band = Int(abs(floor(y / 8 + fbm(x * 0.01, z * 0.01, 2) * 3))) % tuff.count
                let slope = Float(oClamp((abs(height(x + 3, z) - y) + abs(height(x, z + 3) - y)) / 6, 0, 1))
                var c = simd_mix(tuff[band], slopeCol, F3(repeating: slope * 0.45))
                if y < 8 { c = simd_mix(c, grass, F3(repeating: Float(oClamp(fbm(x * 0.02 + 4, z * 0.02) * 2 + 0.15, 0, 0.5)))) }
                tm.c.append(c * Float(0.9 + fbm(x * 0.2, z * 0.2, 2) * 0.22))
            }
        }
        for j in 0..<N {
            for i in 0..<N {
                let a = UInt32(j * (N + 1) + i), b = a + 1, c = a + UInt32(N + 1), d = c + 1
                tm.i += [a, c, b, b, c, d]
            }
        }
        tm.computeNormals()

        // Erciyes far away, snow on its shoulders
        var em = Mesh()
        let eRad = 64, eRows = 16
        for y in 0...eRows {
            let v = Double(y) / Double(eRows)
            for x in 0...eRad {
                let th = Double(x) / Double(eRad) * 2 * Double.pi, r = v * 900, i = Double(y * (eRad + 1) + x)
                let py = -v * 1300 + 650, k = (py + 650) / 1300
                let sx = r * sin(th) * (1 + fbm(i * 0.07, k * 4, 2) * 0.25), sz = r * cos(th) * (1 + fbm(k * 4, i * 0.05, 2) * 0.25)
                em.p.append(F3(Float(sx), Float(py), Float(sz)))
                em.c.append(k > 0.72 + fbm(i * 0.3, 1, 2) * 0.1 ? linearColor("#f4f1f6") : linearColor("#8a6a7a"))
            }
        }
        for y in 0..<eRows {
            for x in 0..<eRad {
                let a = UInt32(y * (eRad + 1) + x), b = a + UInt32(eRad + 1), c = b + 1, d = a + 1
                em.i += [a, b, d, b, c, d]
            }
        }
        em.computeNormals()
        let erciyes = node(OpeningKit.geometry(em), [lit(UIColor.white)], shadow: false)
        erciyes.simdPosition = F3(1900, 600, -3700)

        /* a fairy chimney: a lathed tuff body, then carved by 3D noise: big lumps, layers, ledges and pocks, a slight lean.
           Six variants, so no two neighbours match; a finer and a coarser cut of each. */
        let bands = ["#f3e3cc", "#ecccab", "#e0b394", "#f2dbbd", "#d8a48a"].map(linearColor)
        func chimney(_ slim: Bool, _ seed: Double, fine: Bool) -> Mesh {
            let base: [(Double, Double)] = slim
                ? [(0.75, 0), (0.66, 0.08), (0.5, 0.25), (0.4, 0.45), (0.34, 0.65), (0.3, 0.82), (0.27, 0.92), (0.18, 0.96), (0, 0.965)]
                : [(1.25, 0), (1.1, 0.05), (0.96, 0.18), (0.84, 0.36), (0.72, 0.54), (0.6, 0.7), (0.5, 0.8), (0.4, 0.88), (0.28, 0.94), (0.14, 0.98), (0, 0.995)]
            var g = Mesh.lathe(splinePoints(base, fine ? 36 : 20), segments: fine ? 40 : 22)
            let lean = (seed.truncatingRemainder(dividingBy: 3) - 1) * 0.12
            for k in g.p.indices {
                let x = Double(g.p[k].x), y = Double(g.p[k].y), z = Double(g.p[k].z), r = hypot(x, z)
                var d = n3(x * 1.4 + seed, y * 2.2, z * 1.4) * 0.22 + n3(x * 4 + seed, y * 6, z * 4) * 0.08 + n3(x * 12, y * 15 + seed, z * 12) * 0.03
                d += sin(y * 34 + n3(x * 2, y * 3, z * 2) * 5) * 0.014 + (n3(x * 7, y * 3 + seed * 2, z * 7) > 0.32 ? -0.05 : 0) // ledges and hollows
                let kk = r > 0.01 ? 1 + d : 1
                g.p[k] = F3(Float(x * kk + lean * y * y), Float(y * (1 + n3(x, seed, z) * 0.04)), Float(z * kk))
                let bi = ((Int(floor(y * 11 + n3(x * 2, y * 4, z * 2) * 3 + 8)) % 5) + 5) % 5
                g.c.append(bands[bi] * Float(oClamp(0.82 + d * 1.1 + (1 - min(1, y * 3)) * -0.08, 0.6, 1.08)))
            }
            g.computeNormals()
            g.weldSeam(columns: fine ? 40 : 22, rows: (fine ? 36 : 20) + 1)
            return g
        }
        func boulder(_ seed: Double, _ flat: Double, detail: Int) -> Mesh {
            var g = Mesh.icosphere(detail)
            for k in g.p.indices {
                let v = D3(g.p[k])
                let kk = 1 + n3(v.x * 1.6 + seed, v.y * 1.6, v.z * 1.6) * 0.45 + n3(v.x * 5, v.y * 5 + seed, v.z * 5) * 0.1
                g.p[k] = F3(Float(v.x * kk), Float(v.y * kk * flat), Float(v.z * kk))
            }
            g.computeNormals()
            return g
        }

        // tuff mottled with pocks and drip stains; the ground with grit and small stones
        let mottle = OpeningTextures.mottle(&rnd)
        let grit = OpeningTextures.grit(&rnd)
        let tuffMat = lit(mottle)
        OpeningKit.repeatTexture(tuffMat.diffuse, 3, 2)
        let basaltCol = linearColor("#6a524a")
        let terrainMat = lit(grit)
        OpeningKit.repeatTexture(terrainMat.diffuse, 900, 900)
        let terrain = node(OpeningKit.geometry(tm), [terrainMat], shadow: false, mask: 1 | OpeningWorld.flameMask)
        _ = terrain

        // Merged geometry, in 300 m tiles so SceneKit can leave out what the camera (and the sun's shadow) doesn't see.
        typealias Tiles = [SIMD2<Int32>: Mesh]
        func tile(_ x: Double, _ z: Double) -> SIMD2<Int32> { SIMD2(Int32(floor(x / 300)), Int32(floor(z / 300))) }
        var tuffTiles = Tiles(), basaltTiles = Tiles(), shrubTiles = Tiles()

        // carving: windows and doors cut into a surface, found on the geometry itself so they sit on it
        var holes: [(D3, Double, Double)] = [], lights: [(D3, Double, Double)] = []
        func carve(_ g: Mesh, pos: F3, rot: simd_quatf, scale: F3, _ n: Int, _ lit: Double, _ y0: Float, _ y1: Float, _ size: Double) {
            var k = 0, tries = 0
            while k < n && tries < n * 30 {
                tries += 1
                let i = rnd.int(g.p.count), y = g.p[i].y
                if y < y0 || y > y1 { continue }
                let nn = simd_normalize(rot.act(g.n[i] * scale))
                if abs(nn.y) > 0.35 { continue }
                let w = D3(rot.act(g.p[i] * scale) + pos) + D3(nn) * 0.12
                let isLit = rnd.next() < lit
                let item = (w, atan2(Double(nn.z), Double(nn.x)), size * (0.8 + rnd.next() * 0.5))
                if isLit { lights.append(item) } else { holes.append(item) }
                k += 1
            }
        }

        // where chimneys stand: the valley the drone threads, clusters round the village, many further out
        let VALLEY = [D3(-250, 0, 330), D3(-150, 0, 255), D3(-75, 0, 190), D3(-25, 0, 135)]
        let vcurve = CRCurve(VALLEY)
        let vpts = (0...60).map { vcurve.pointAt(Double($0) / 60) }
        func nearValley(_ x: Double, _ z: Double) -> Double { vpts.reduce(1e9) { min($0, hypot($1.x - x, $1.z - z)) } }
        var spots: [(Double, Double, Double)] = []
        func free(_ x: Double, _ z: Double, _ r: Double) -> Bool { !spots.contains { hypot($0.0 - x, $0.1 - z) < r + $0.2 * 0.7 } }
        func keepOut(_ x: Double, _ z: Double) -> Bool {
            hypot(x - FIELD.x, z - FIELD.z) < 40 || hypot(x, z) < 70 || hypot(x - UCH.x, z - UCH.z) < 170 || hypot(x - UG.x, z - UG.z) < 50
                || nearValley(x, z) < 14 || hypot(x - TERR.x, z - TERR.z) < 24 || OpeningLand.inTown(x, z, 30)
        }
        var tries = 0
        while tries < 3000 && spots.count < 300 {
            tries += 1
            let a = rnd.next() * Double.pi * 2, d = 60 + pow(rnd.next(), 0.8) * 1000, x = cos(a) * d, z = sin(a) * d
            let s = 8 + rnd.next() * 16 + (d < 400 ? 6 : 0)
            if !keepOut(x, z) && free(x, z, s * 0.9) { spots.append((x, z, s)) }
        }
        for (i, p) in vpts.enumerated() {
            for side in [-1.0, 1.0] {
                let t = vcurve.tangentAt(Double(i) / 60), nx = -t.z * side, nz = t.x * side, off = 15 + rnd.next() * 14
                let x = p.x + nx * off, z = p.z + nz * off, s = 11 + rnd.next() * 12
                if free(x, z, s * 0.6) { spots.append((x, z, s)) }
            }
        }
        // six shapes; a basalt hat on about a third
        let fineVar = (0..<6).map { chimney(false, Double($0 * 7 + 1), fine: true) }
        let coarseVar = (0..<6).map { chimney(false, Double($0 * 7 + 1), fine: false) }
        var byVar: [[(Double, Double, Double)]] = Array(repeating: [], count: 6)
        for (i, s) in spots.enumerated() { byVar[i % 6].append(s) }
        let capGeo = boulder(11, 0.42, detail: 5)
        var caps: [(F3, simd_quatf, F3)] = []
        for (vi, list) in byVar.enumerated() {
            for (x, z, s) in list {
                let hh = s * (2 + rnd.next() * 1.5), y = height(x, z) - 1
                let ex = (rnd.next() - 0.5) * 0.06, ey = rnd.next() * 6.3, ez = (rnd.next() - 0.5) * 0.06
                let q = OpeningKit.quat(ex, ey, ez)
                let pos = F3(Float(x), Float(y), Float(z)), sc = F3(Float(s * 0.5), Float(hh), Float(s * 0.5))
                let tint = Float(0.88 + rnd.next() * 0.16)
                let near = hypot(x, z) < 380 || nearValley(x, z) < 60
                let fine = near || hypot(x - UG.x, z - UG.z) < 240 || hypot(x - UCH.x, z - UCH.z) < 320
                tuffTiles[tile(x, z), default: Mesh()].add(fine ? fineVar[vi] : coarseVar[vi], at: pos, rot: q, scale: sc, tint: F3(repeating: tint))
                if rnd.next() < 0.33 { caps.append((F3(Float(x), Float(y + hh * 0.985), Float(z)), q, F3(Float(s * 0.24), Float(s * 0.16), Float(s * 0.22)))) }
                // carved windows and doors near the village and along the valley: dark, some lit (cave homes, hotels)
                if near { carve(fineVar[vi], pos: pos, rot: q, scale: sc, 2 + rnd.int(5), 0.45, 0.1, 0.55, s * 0.07) }
            }
        }
        for (p, q, s) in caps { basaltTiles[tile(Double(p.x), Double(p.z)), default: Mesh()].add(capGeo, at: p, rot: q, scale: s, tint: basaltCol) }

        // the ground is never bare: tuff rocks and dry shrubs along the valley floor and round the village
        do {
            var rockG = boulder(70, 0.6, detail: 2)
            rockG.c = Array(repeating: F3(0.93, 0.8, 0.68), count: rockG.p.count)
            var shrubG = Mesh.icosphere(2)
            for k in shrubG.p.indices {
                let v = D3(shrubG.p[k]), kk = 1 + n3(v.x * 3, v.y * 3, v.z * 3) * 0.45
                shrubG.p[k] = F3(Float(v.x * kk), Float(v.y * kk * 0.7), Float(v.z * kk))
            }
            shrubG.computeNormals()
            var rocks: [(Double, Double)] = [], shrubs: [(Double, Double)] = []
            var n = 0
            while n < 6000 && (rocks.count < 700 || shrubs.count < 420) {
                n += 1
                let x = (rnd.next() - 0.5) * 900, z = (rnd.next() - 0.35) * 900, nv = nearValley(x, z), nvil = hypot(x, z)
                if !(nv < 70 || (nvil > 40 && nvil < 260)) { continue }
                if hypot(x - FIELD.x, z - FIELD.z) < 30 || hypot(x, z) < 60 || nv < 6 || OpeningLand.inTown(x, z, 8) { continue }
                if rnd.next() < 0.6 { rocks.append((x, z)) } else { shrubs.append((x, z)) }
            }
            for (x, z) in rocks {
                let s = 0.4 + pow(rnd.next(), 2) * 2.4
                let q = OpeningKit.quat(rnd.next(), rnd.next() * 6, rnd.next())
                let tint = Float(0.85 + rnd.next() * 0.2)
                tuffTiles[tile(x, z), default: Mesh()].add(rockG, at: F3(Float(x), Float(height(x, z) + s * 0.2), Float(z)), rot: q,
                                                           scale: F3(Float(s * 1.3), Float(s), Float(s)), tint: F3(repeating: tint))
            }
            let shrubBase = linearColor(0x6a6a3a), shrubCols = ["#7a7a42", "#5e6a38", "#8a7a4a"].map(linearColor)
            for (i, (x, z)) in shrubs.enumerated() {
                let s = 0.5 + rnd.next() * 1.1
                let q = OpeningKit.quat(0, rnd.next() * 6, 0)
                shrubTiles[tile(x, z), default: Mesh()].add(shrubG, at: F3(Float(x), Float(height(x, z) + s * 0.3), Float(z)), rot: q,
                                                            scale: F3(repeating: Float(s)), tint: shrubBase * shrubCols[i % 3])
            }
        }

        // Üç Güzeller: three slender chimneys, each with a big flat boulder for a hat
        for (i, b) in [(0.0, 0.0, 26.0, 1.1), (9, 4, 22, 1), (4, -8, 15, 0.85)].enumerated() {
            let (dx, dz, hh, k) = b
            let x = UG.x + dx, z = UG.z + dz, y = height(x, z) - 0.5
            tuffTiles[tile(x, z), default: Mesh()].add(chimney(true, Double(5 + i), fine: true), at: F3(Float(x), Float(y), Float(z)),
                                                       scale: F3(Float(4.6 * k), Float(hh), Float(4.6 * k)))
            basaltTiles[tile(x, z), default: Mesh()].add(boulder(Double(i * 3), 0.42, detail: 5), at: F3(Float(x + 0.6), Float(y + hh * 0.965 + 1.2 * k), Float(z)),
                                                         rot: OpeningKit.quat(0.12, Double(i), -0.1), scale: F3(Float(3.3 * k), Float(2.2 * k), Float(2.9 * k)),
                                                         tint: basaltCol)
        }

        // Uçhisar Castle: a craggy tuff mass riddled with windows; houses on its slopes, a minaret
        do {
            var ug = Mesh.icosphere(10)
            for k in ug.p.indices {
                let v = D3(ug.p[k])
                let kk = 1 + fbm(v.x * 2.2, v.z * 2.2 + v.y * 1.5, 5) * 0.45 + abs(fbm(v.x * 6, v.y * 6, 2)) * 0.12
                let y = v.y < 0 ? v.y * 1.5 : v.y // the foot flares and goes down into the hill
                ug.p[k] = F3(Float(v.x * kk * (1 + max(0, -y) * 0.7)), Float(y * kk * (y > 0 ? 1.15 : 1)), Float(v.z * kk * (1 + max(0, -y) * 0.7)))
                let bi = ((Int(floor((y + 1) * 9 + fbm(v.x * 3, v.z * 3, 2) * 3 + 9)) % 5) + 5) % 5
                ug.c.append(tuff[bi] * Float(0.92 + fbm(v.x * 9, v.y * 9, 2) * 0.2))
            }
            ug.computeNormals()
            let pos = F3(Float(UCH.x), Float(UCH.y + 22), Float(UCH.z)), sc = F3(62, 58, 54), q = simd_quatf(angle: 0, axis: F3(0, 1, 0))
            tuffTiles[tile(UCH.x, UCH.z), default: Mesh()].add(ug, at: pos, scale: sc)
            for _ in 0..<160 {
                let i = rnd.int(ug.p.count), v = ug.p[i]
                if v.y < -0.1 { continue }
                let w = q.act(v * sc) + pos, nn = simd_normalize(ug.n[i] * sc)
                if nn.y > 0.6 { continue }
                let a = atan2(Double(nn.z), Double(nn.x))
                let isLit = rnd.next() < 0.3
                let item = (D3(Double(w.x + nn.x * 0.3), Double(w.y), Double(w.z + nn.z * 0.3)), a, 1.1 + rnd.next() * 0.9)
                if isLit { lights.append(item) } else { holes.append(item) }
            }
        }

        /* houses: Göreme round the square, Uçhisar terraced round its castle. Soft-cornered stone, five kinds:
           plastered, cut stone, vaulted, stepped (a second storey set back) and an arcade front; each facade its own pattern */
        struct House { let x: Double, z: Double, w: Double, d: Double, h: Double, a: Double, kind: Int }
        var houses: [House] = []
        func addHouses(_ cx: Double, _ cz: Double, _ r0: Double, _ r1: Double, _ count: Int, _ skip: (Double, Double) -> Bool) {
            var n = count, k = 0
            while k < n * 8 && n > 0 {
                k += 1
                let a = rnd.next() * Double.pi * 2, d = r0 + rnd.next() * (r1 - r0), x = cx + cos(a) * d, z = cz + sin(a) * d
                if skip(x, z) { continue }
                let w = 6 + rnd.next() * 7, dd = 6 + rnd.next() * 7, hh = 3.6 + rnd.next() * 4.6
                if houses.contains(where: { abs($0.x - x) < ($0.w + w) / 2 + 1.2 && abs($0.z - z) < ($0.d + dd) / 2 + 1.2 }) { continue }
                let ha = (rnd.next() - 0.5) * 0.5, kind = rnd.int(5)
                houses.append(House(x: x, z: z, w: w, d: dd, h: hh, a: ha, kind: kind))
                n -= 1
            }
        }
        func approach(_ x: Double, _ z: Double) -> Double {
            let ax = -20.0, az = 56.0, bx = -33.0, bz = 41.0
            let k = oClamp(((x - ax) * (bx - ax) + (z - az) * (bz - az)) / ((bx - ax) * (bx - ax) + (bz - az) * (bz - az)), 0, 1)
            return hypot(x - ax - k * (bx - ax), z - az - k * (bz - az))
        }
        addHouses(8, -6, 10, 72, 80) { x, z in hypot(x - FIELD.x, z - FIELD.z) < 30 || hypot(x - TERR.x, z - TERR.z) < 14 || approach(x, z) < 14 }
        addHouses(UCH.x, UCH.z, 62, 165, 70) { _, _ in false }
        let facades = (0..<5).map { OpeningTextures.facade($0, &rnd) }
        var hgeo = Mesh.roundedBox(F3(1, 1, 1), radius: 0.07, segments: 3)
        hgeo.p = hgeo.p.map { $0 + F3(0, 0.5, 0) }
        var kindLists: [[(F3, Float, F3)]] = Array(repeating: [], count: 5)
        var vaults: [(F3, Float, F3)] = [], parapets: [(F3, Float, F3)] = []
        for o in houses {
            let y = height(o.x, o.z) - 0.6
            kindLists[o.kind].append((F3(Float(o.x), Float(y), Float(o.z)), Float(o.a), F3(Float(o.w), Float(o.h), Float(o.d))))
            if o.kind == 3 { // the storey set back
                kindLists[3].append((F3(Float(o.x - cos(o.a) * o.w * 0.15), Float(y + o.h), Float(o.z + sin(o.a) * o.w * 0.15)), Float(o.a),
                                     F3(Float(o.w * 0.6), Float(o.h * 0.7), Float(o.d * 0.7))))
            }
            if o.kind == 2 {
                vaults.append((F3(Float(o.x), Float(y + o.h), Float(o.z)), Float(o.a), F3(Float(o.w * 0.98), Float(o.d * 0.5), Float(o.d * 0.98))))
            } else {
                let top = y + o.h * (o.kind == 3 ? 1.7 : 1), pw = o.kind == 3 ? o.w * 0.6 : o.w, pd = o.kind == 3 ? o.d * 0.7 : o.d
                parapets.append((F3(Float(o.x), Float(top + 0.18), Float(o.z)), Float(o.a), F3(Float(pw + 0.4), 0.4, Float(pd + 0.4))))
            }
            // warm windows at night, on the facades, turned with the house
            let fwd = D3(sin(o.a), 0, cos(o.a)), side = D3(cos(o.a), 0, -sin(o.a))
            var k = 0
            while k < 2 + rnd.int(2) {
                k += 1
                let front = rnd.next() < 0.6, u = (rnd.next() - 0.5) * 0.6, wy = y + 1.6 + rnd.next() * max(0.5, o.h - 3)
                let p = D3(o.x, wy, o.z) + (front ? fwd : side) * ((front ? o.d : o.w) / 2 + 0.05) + (front ? side : fwd) * (u * (front ? o.w : o.d))
                let nrm = front ? fwd : side
                if rnd.next() < 0.6 { lights.append((p, atan2(nrm.z, nrm.x), 0.75)) }
            }
        }
        let facadeMats = facades.map { lit($0) }
        for (kind, list) in kindLists.enumerated() {
            var m = Mesh()
            for (p, a, s) in list { m.add(hgeo, at: p, rot: simd_quatf(angle: a, axis: F3(0, 1, 0)), scale: s, tint: F3(repeating: Float(0.9 + rnd.next() * 0.12))) }
            if !m.isEmpty { _ = node(OpeningKit.geometry(m), [facadeMats[kind]]) }
        }
        do {
            // a barrel vault on top: half a cylinder along the house, closed at both ends
            var vg = Mesh()
            let segs = 20
            for end in [Float(-0.5), Float(0.5)] {
                for s in 0...segs {
                    let th = Float(s) / Float(segs) * Float.pi
                    vg.p.append(F3(0.5 * cos(th), 0.5 * sin(th), end))
                }
            }
            for s in 0..<segs {
                let a = UInt32(s), b = UInt32(s + 1), c = UInt32(segs + 1 + s), d = UInt32(segs + 2 + s)
                vg.i += [a, b, c, b, d, c]
            }
            for (end, flip) in [(Float(-0.5), true), (Float(0.5), false)] {
                let center = UInt32(vg.p.count)
                vg.p.append(F3(0, 0, end))
                let ring = UInt32(vg.p.count)
                for s in 0...segs { let th = Float(s) / Float(segs) * Float.pi; vg.p.append(F3(0.5 * cos(th), 0.5 * sin(th), end)) }
                for s in 0..<UInt32(segs) { vg.i += flip ? [center, ring + s + 1, ring + s] : [center, ring + s, ring + s + 1] }
            }
            vg.computeNormals()
            vg.c = Array(repeating: linearColor(0xe8d4b4), count: vg.p.count)
            var vm = Mesh()
            for (p, a, s) in vaults { vm.add(vg, at: p, rot: simd_quatf(angle: a, axis: F3(0, 1, 0)), scale: s) }
            let vaultMat = lit(mottle)
            if !vm.isEmpty { _ = node(OpeningKit.geometry(vm), [vaultMat]) }
            var parG = Mesh.roundedBox(F3(1, 1, 1), radius: 0.2, segments: 2)
            parG.c = Array(repeating: linearColor(0xdcc4a2), count: parG.p.count)
            var pm = Mesh()
            for (p, a, s) in parapets { pm.add(parG, at: p, rot: simd_quatf(angle: a, axis: F3(0, 1, 0)), scale: s) }
            if !pm.isEmpty { _ = node(OpeningKit.geometry(pm), [lit(mottle)]) }
        }
        // cave houses: tuff outcrops at the village edge with homes cut into them, doors and lit windows
        for k in 0..<18 {
            let a = -Double.pi * (0.1 + rnd.next() * 0.8), d = 70 + rnd.next() * 50, x = cos(a) * d + 8, z = sin(a) * d - 6
            // north-east of the village: off the camera's way in and out of the field's view
            // (v121.5: and off the way to our town)
            if hypot(x - FIELD.x, z - FIELD.z) < 36 || hypot(x - TERR.x, z - TERR.z) < 20 || x < -10 || OpeningLand.inTown(x, z, 25)
                || OpeningLand.toTown(x, z) < 110 { continue }
            var rock = boulder(Double(40 + k), 0.8, detail: 5)
            rock.c = Array(repeating: F3(0.94, 0.82, 0.7), count: rock.p.count)
            let s = 10 + rnd.next() * 10, sc = F3(Float(s * 1.3), Float(s), Float(s))
            let pos = F3(Float(x), Float(height(x, z) + s * 0.3), Float(z)), q = simd_quatf(angle: Float(rnd.next() * 6), axis: F3(0, 1, 0))
            tuffTiles[tile(x, z), default: Mesh()].add(rock, at: pos, rot: q, scale: sc)
            carve(rock, pos: pos, rot: q, scale: sc, 5 + rnd.int(5), 0.6, -0.4, 0.5, 1.2)
        }
        func minaret(_ x: Double, _ z: Double, _ hh: Double) {
            let g = SCNNode(), m = lit(UIColor(red: 0xf0 / 255, green: 0xe2 / 255, blue: 0xcc / 255, alpha: 1))
            let shaft = SCNCone(topRadius: 1.1, bottomRadius: 1.3, height: hh)
            shaft.radialSegmentCount = 16
            shaft.materials = [m]
            let sh = SCNNode(geometry: shaft)
            sh.position.y = Float(hh / 2)
            let balcony = SCNCone(topRadius: 1.8, bottomRadius: 1.6, height: 0.7)
            balcony.radialSegmentCount = 16
            balcony.materials = [m]
            let bal = SCNNode(geometry: balcony)
            bal.position.y = Float(hh * 0.78)
            let cap = SCNCone(topRadius: 0, bottomRadius: 1.15, height: 6)
            cap.radialSegmentCount = 16
            cap.materials = [lit(UIColor(red: 0x7a / 255, green: 0x7f / 255, blue: 0x8a / 255, alpha: 1))]
            let top = SCNNode(geometry: cap)
            top.position.y = Float(hh + 3)
            for c in [sh, bal, top] { g.addChildNode(c) }
            g.simdPosition = F3(Float(x), Float(height(x, z)), Float(z))
            root.addChildNode(g)
        }
        minaret(UCH.x + 110, UCH.z - 60, 30)
        minaret(26, -30, 26)

        // windows: carved holes dark, lit ones warm before dawn and going out with the sun (a few stay on)
        let windows = OpeningWorld.windows
        let holeMat = OpeningKit.flat(OpeningKit.color(linearColor(0x2a1812)))
        holeMat.shaderModifiers = [.fragment: OpeningKit.fogModifier]
        fogged.append(holeMat)
        let litMat = OpeningKit.flat(OpeningKit.color(linearColor(0xffb35a)))
        litMat.shaderModifiers = [.fragment: OpeningKit.fogModifier]
        fogged.append(litMat)
        litWindows = litMat
        _ = node(windows(holes), [holeMat], shadow: false)
        _ = node(windows(lights), [litMat], shadow: false)

        // the terrace over Göreme: a cave hotel's roof terrace, higher than the houses round it so the view is open over the
        // town; stone floor, a kilim, cushions, a low table, a lantern
        let terr = SCNNode()
        terr.simdPosition = F3(Float(TERR.x), Float(TERR.y + 7), Float(TERR.z))
        let mask = 1 | OpeningWorld.terraceMask
        func part(_ g: SCNGeometry, _ m: SCNMaterial, _ p: F3) {
            g.materials = [m]
            let n = SCNNode(geometry: g)
            n.simdPosition = p
            n.categoryBitMask = mask
            terr.addChildNode(n)
        }
        var slab = Mesh.roundedBox(F3(12, 0.5, 9), radius: 0.15, segments: 2)
        slab.c = Array(repeating: linearColor(0xe6d2b4), count: slab.p.count)
        part(OpeningKit.geometry(slab), lit(mottle), F3(0, 5.2, 0))
        let below = Mesh.roundedBox(F3(12.4, 17.2, 9.4), radius: 0.5, segments: 3)
        part(OpeningKit.geometry(below), lit(OpeningTextures.facade(1, &rnd)), F3(0, -3.4, 0))
        let kilimG = SCNPlane(width: 6.4, height: 4)
        kilimG.materials = [lit(OpeningTextures.kilim())]
        let kilimN = SCNNode(geometry: kilimG)
        kilimN.simdPosition = F3(-1, 5.47, 0.5)
        kilimN.simdEulerAngles = F3(-Float.pi / 2, 0, 0)
        kilimN.categoryBitMask = mask
        terr.addChildNode(kilimN)
        func hexUI(_ v: UInt32) -> UIColor { UIColor(red: CGFloat((v >> 16) & 0xff) / 255, green: CGFloat((v >> 8) & 0xff) / 255, blue: CGFloat(v & 0xff) / 255, alpha: 1) }
        let tableG = SCNCylinder(radius: 1.1, height: 0.12)
        tableG.radialSegmentCount = 32
        part(tableG, lit(hexUI(0x3a4a6a)), F3(-1, 6.0, 0.4))
        part(SCNCylinder(radius: 0.08, height: 0.5), lit(hexUI(0x2a2a30)), F3(-1, 5.7, 0.4))
        for (c, x, z) in [(UInt32(0xff7a3a), 0.25, 0.2), (0xffc23d, -0.2, 0.3), (0x9a2a3a, 0.1, -0.3), (0x7aa040, -0.35, -0.1)] {
            let f = SCNSphere(radius: 0.14)
            f.segmentCount = 12
            part(f, lit(hexUI(c)), F3(Float(-1 + x), 6.15, Float(0.4 + z)))
        }
        for (x, z, c) in [(-3.2, 0.3, UInt32(0xd8c8b0)), (1.2, 1.8, 0xb06a4a)] {
            part(SCNBox(width: 1.6, height: 0.35, length: 1.1, chamferRadius: 0.14), lit(hexUI(c)), F3(Float(x), 5.65, Float(z)))
        }
        lantern.type = .omni
        lantern.color = OpeningKit.color(linearColor(0xffa24a))
        lantern.attenuationStartDistance = 0
        lantern.attenuationEndDistance = 14
        lantern.attenuationFalloffExponent = 1.8
        lantern.categoryBitMask = OpeningWorld.terraceMask
        let lanternNode = SCNNode()
        lanternNode.light = lantern
        lanternNode.simdPosition = F3(3.6, 6.6, 2.4)
        terr.addChildNode(lanternNode)
        let lampG = SCNCylinder(radius: 0.24, height: 0.6)
        lampG.radialSegmentCount = 8
        part(lampG, OpeningKit.flat(OpeningKit.color(linearColor(0xffd08a))), F3(3.6, 6.6, 2.4))
        part(SCNBox(width: 12, height: 0.12, length: 0.12, chamferRadius: 0), lit(hexUI(0x2a2a30)), F3(0, 6.4, -4.4))
        root.addChildNode(terr)

        // the launch field: trodden grass; the old basket on its side and an envelope laid out, faded
        var fm = Mesh()
        fm.p.append(F3(0, 0, 0))
        fm.uv.append(F2(0.5, 0.5))
        for s in 0...48 {
            let th = Float(s) / 48 * 2 * Float.pi
            fm.p.append(F3(26 * cos(th), 0, -26 * sin(th)))
            fm.uv.append(F2(0.5 + 0.5 * cos(th), 0.5 + 0.5 * sin(th)))
        }
        for s in 1...48 { fm.i += [0, UInt32(s), UInt32(s + 1)] }
        fm.n = Array(repeating: F3(0, 1, 0), count: fm.p.count)
        fm.c = Array(repeating: linearColor(0xa9a26a), count: fm.p.count)
        let fieldMat = lit(grit)
        OpeningKit.repeatTexture(fieldMat.diffuse, 30, 30)
        let field = node(OpeningKit.geometry(fm), [fieldMat], shadow: false, mask: 1 | OpeningWorld.flameMask)
        field.simdPosition = F3(Float(FIELD.x), Float(height(FIELD.x, FIELD.z) + 0.12), Float(FIELD.z))
        BASKET.y = height(BASKET.x, BASKET.z)
        let wickerMat = lit(OpeningTextures.wicker())
        let bigBasket = SCNBox(width: 1.4, height: 1.2, length: 1.4, chamferRadius: 0.04)
        basket = node(bigBasket, [wickerMat])
        basket.simdPosition = F3(Float(BASKET.x), Float(BASKET.y + 0.62), Float(BASKET.z))
        basket.simdOrientation = OpeningKit.quat(0, 0.5, Double.pi / 2 - 0.12)
        let oldCloth = OpeningTextures.oldCloth(&rnd)
        var cm = Mesh()
        let cw = 48, ch = 16
        for iy in 0...ch {
            for ix in 0...cw {
                let x = -8 + 16 * Double(ix) / Double(cw), zz = -3 + 6 * Double(iy) / Double(ch)
                let y = 0.2 + max(0, sin(zz * 2.2 + x * 0.3)) * 0.35 * (1 - abs(zz) / 3.2) + abs(fbm(x * 0.3, zz * 0.5, 2)) * 0.4
                cm.p.append(F3(Float(x), Float(y), Float(zz * (1 - (x + 8) / 40))))
                cm.uv.append(F2(Float(ix) / Float(cw), Float(iy) / Float(ch)))
            }
        }
        for iy in 0..<ch {
            for ix in 0..<cw {
                let a = UInt32(iy * (cw + 1) + ix), b = a + 1, c = a + UInt32(cw + 1), d = c + 1
                cm.i += [a, c, b, b, c, d]
            }
        }
        cm.computeNormals()
        cloth = node(OpeningKit.geometry(cm, colors: false), [lit(oldCloth, doubleSided: true)])
        cloth.simdPosition = F3(Float(BASKET.x + 9), Float(BASKET.y), Float(BASKET.z - 1))
        cloth.simdEulerAngles = F3(0, -0.25, 0)

        // balloons: the game's own envelope (`balloon`), a round dome of radius R over a long taper to the mouth, 2.55 R
        // tall, lathed in gores; the basket below
        var prof: [(Double, Double)] = []
        let ER = 1.25 / 2.55
        for i in 0...16 {
            let k = Double(i) / 16, a = (1 - k) * (1 - k), b = 2 * k * (1 - k), c = k * k
            prof.append(((a * 0.22 + b * 0.75 + c * 0.891) * ER, (b * 0.40 + c * 1.096) * ER))
        }
        for i in 1...24 {
            let an = -Double.pi * 0.15 + (Double.pi * 0.65) * Double(i) / 24
            prof.append((max(0.001, cos(an)) * ER, (1.55 + sin(an)) * ER))
        }
        let envG = OpeningKit.geometry(Mesh.lathe(prof, segments: 40), colors: false)
        envGeometry = envG
        let PAL = [["#ff5e3a", "#ffc23d"], ["#14a39a", "#e8fff9"], ["#9b7be0", "#f2ebff"], ["#5aa9e6", "#eaf4fc"], ["#e5432f", "#ffffff"],
                   ["#ff6fa8", "#fff0f6"], ["#22a45d", "#fff3b0"], ["#ffc23d", "#2b2350", "#ff5e3a"]]
        let palMat = PAL.map { lit(OpeningTextures.gores($0), doubleSided: true) }
        let basketG = SCNBox(width: 0.1, height: 0.08, length: 0.1, chamferRadius: 0)
        basketG.materials = [wickerMat]
        basketGeometry = basketG
        let flameMat = OpeningKit.flat(OpeningTextures.glow(srgbColor(0xffa040)), additive: true)
        flameMaterial = flameMat
        // v121.6: the ropes from the basket's corners up to the envelope's mouth: very thin, but there. One merged geometry
        // of the four, shared by every balloon.
        let ropeMat = lit(UIColor(red: 0x3a / 255, green: 0x2a / 255, blue: 0x1e / 255, alpha: 1))
        ropeMaterial = ropeMat
        let ropeSeg = OpeningWorld.ropeCylinder()
        let ropeSegG = OpeningKit.geometry(ropeSeg, colors: false)
        ropeSegG.materials = [ropeMat]
        ropeSegment = ropeSegG
        var ropeMesh = Mesh()
        for (i, a) in OpeningWorld.ropeB.enumerated() {
            let b = OpeningWorld.ropeM[i] + F3(0, 0.3, 0), (q, l) = OpeningWorld.span(a, b)
            ropeMesh.add(ropeSeg, at: a, rot: q, scale: F3(0.002, l, 0.002))
        }
        let ropesG = OpeningKit.geometry(ropeMesh, colors: false)
        ropesG.materials = [ropeMat]
        func makeBalloon(_ mat: SCNMaterial, _ s: Double) -> FilmBalloon {
            let g = SCNNode()
            let eg = envG.copy() as? SCNGeometry ?? envG
            eg.materials = [mat]
            let env = SCNNode(geometry: eg)
            env.position.y = 0.3
            let b = SCNNode(geometry: basketG)
            b.position.y = 0.02
            let gl = OpeningKit.sprite(flameMat)
            gl.position.y = 0.34
            gl.scale = SCNVector3(0.9, 0.9, 0.9)
            let ropes = SCNNode(geometry: ropesG)
            ropes.castsShadow = false
            for c in [env, b, gl, ropes] { g.addChildNode(c) }
            g.scale = SCNVector3(Float(s), Float(s), Float(s))
            return FilmBalloon(node: g, env: env, glow: gl)
        }
        // the morning's balloons: standing on the fields north of the village, burners lighting them in the dark; up at dawn
        // (none in our town)
        var crowd: [CrowdBalloon] = []
        for i in 0..<52 {
            let a = -Double.pi / 2 + (rnd.next() - 0.5) * 2.6, d = 160 + rnd.next() * 1100, x = cos(a) * d, z = sin(a) * d
            if OpeningLand.inTown(x, z, 20) { continue }
            let b = makeBalloon(palMat[i % palMat.count], 17 + rnd.next() * 6)
            let gy = height(x, z)
            b.node.simdPosition = F3(Float(x), Float(gy), Float(z))
            root.addChildNode(b.node)
            crowd.append(CrowdBalloon(b: b, gy: gy, go: 9 + rnd.next() * 13, v: 2.4 + rnd.next() * 2.2, ph: rnd.next() * 9, x: x, z: z))
        }
        self.crowd = crowd
        flameLight.type = .omni
        flameLight.color = OpeningKit.color(linearColor(0xff9a40))
        flameLight.attenuationStartDistance = 0
        flameLight.attenuationEndDistance = 60
        flameLight.attenuationFalloffExponent = 1.6
        flameLight.intensity = 0
        flameLight.categoryBitMask = OpeningWorld.flameMask

        // valley mist, and dust in the light
        let mistMat = OpeningKit.flat(OpeningTextures.mist { fbm($0, $1, $2) })
        mistMat.writesToDepthBuffer = false
        mistMat.blendMode = .alpha
        mistMat.multiply.contents = OpeningKit.color(linearColor(0xffd6c0))
        mistMaterial = mistMat
        let mistG = SCNPlane(width: 1, height: 1)
        mistG.materials = [mistMat]
        var mists: [SCNNode] = []
        for _ in 0..<34 {
            let s = 200 + rnd.next() * 380, x = (rnd.next() - 0.5) * 1800, z = (rnd.next() - 0.55) * 1800
            let m = SCNNode(geometry: mistG)
            m.castsShadow = false
            m.scale = SCNVector3(Float(s), Float(s * 0.6), 1)
            m.simdOrientation = OpeningKit.quat(-Double.pi / 2, 0, rnd.next() * 6)
            m.simdPosition = F3(Float(x), Float(height(x, z) + 6 + rnd.next() * 12), Float(z))
            m.opacity = 0.3
            root.addChildNode(m)
            mists.append(m)
        }
        self.mists = mists
        var dp: [F3] = []
        for _ in 0..<900 { dp.append(F3(Float((rnd.next() - 0.5) * 300 - 20), Float(rnd.next() * 40), Float((rnd.next() - 0.2) * 360))) }
        let dustMat = OpeningKit.flat(OpeningKit.color(linearColor(0xffe2b0)), additive: true)
        dust = node(OpeningKit.points(dp, size: 0.5, minRadius: 0.6, maxRadius: 3), [dustMat], shadow: false)
        dust.opacity = 0

        // the merged tiles
        let basaltMat = lit(mottle)
        for (tiles, mat) in [(tuffTiles, tuffMat), (basaltTiles, basaltMat), (shrubTiles, lit(mottle))] {
            for (_, m) in tiles where !m.isEmpty { _ = node(OpeningKit.geometry(m), [mat]) }
        }
        var parapet = Mesh.roundedBox(F3(1, 1, 1), radius: 0.2, segments: 2)
        parapet.c = Array(repeating: linearColor(0xdcc4a2), count: parapet.p.count)
        kit = TownKit(facades: facadeMats, tuff: tuffMat, basalt: basaltMat, basaltColor: basaltCol, mottle: mottle, chimneys: fineVar,
                      cap: capGeo, box: hgeo, parapet: parapet)

        // the colour pick: the choices as real balloons, out of the fog, built now and placed when the pick begins
        pick = PickBalloon.all.map { p in
            let b = makeBalloon(lit(OpeningTextures.gores(p.colors), doubleSided: true, fog: false), 1)
            b.node.isHidden = true
            root.addChildNode(b.node)
            return b
        }
        let haloMat = OpeningKit.flat(OpeningTextures.glow(srgbColor(0xfff0c8)))
        haloMat.writesToDepthBuffer = false
        haloMat.transparency = 0.5
        halo = OpeningKit.sprite(haloMat)
        halo.isHidden = true
        root.addChildNode(halo)

        /* the flight: one take, the eye and what it looks at as Catmull-Rom paths, a waypoint every ~2 s */
        let ugTop = UG.y + 20, uchTop = UCH.y + 70
        flightEye = CRCurve([[UG.x + 42, UG.y + 6, UG.z + 34], [UG.x + 10, UG.y + 9, UG.z + 52], [UG.x - 30, UG.y + 16, UG.z + 32], [UG.x - 70, UG.y + 45, UG.z - 10],
                             [60, 110, 520], [-160, 130, 520], [UCH.x + 150, uchTop + 10, UCH.z + 60], [UCH.x + 120, uchTop - 15, UCH.z - 40],
                             [VALLEY[0].x + 10, 34, VALLEY[0].z - 10], [VALLEY[1].x, 14, VALLEY[1].z], [VALLEY[2].x, 10, VALLEY[2].z], [VALLEY[3].x + 6, 11, VALLEY[3].z],
                             [TERR.x + 3, TERR.y + 14.4, TERR.z + 5.5], [TERR.x + 1, TERR.y + 14.8, TERR.z + 1], [TERR.x - 4, TERR.y + 20, TERR.z - 12], [-31, 3.2, 44], [-33, 2.6, 41]])
        flightAt = CRCurve([[UG.x, ugTop, UG.z], [UG.x, ugTop, UG.z], [UG.x, ugTop - 2, UG.z], [UG.x - 140, ugTop + 10, UG.z - 120],
                            [UCH.x, uchTop - 20, UCH.z], [UCH.x, uchTop - 20, UCH.z], [UCH.x, uchTop - 15, UCH.z], [VALLEY[1].x, 20, VALLEY[1].z - 40],
                            [VALLEY[1].x, 14, VALLEY[1].z], [VALLEY[2].x, 10, VALLEY[2].z - 10], [VALLEY[3].x, 9, VALLEY[3].z - 20], [0, 18, 40],
                            [-30, 32, -200], [-30, 42, -260], [FIELD.x, 4, FIELD.z], [BASKET.x + 2, 1, BASKET.z], [BASKET.x + 3, 0.8, BASKET.z]])
        /* v121.1: a floor under the flight that ignores small bumps: the highest ground ahead and behind, blurred, so the
           eye never dips into a hill nor bobs over every rock; the path rides on it with a soft max */
        do {
            let n = 720
            func clr(_ u: Double) -> Double { u < 0.9 ? 6 : oLerp(6, 2.4, oClamp((u - 0.9) / 0.06, 0, 1)) }
            var raw: [Double] = []
            for i in 0...n {
                let u = Double(i) / Double(n), e = flightEye.point(u)
                raw.append(height(e.x, e.z) + clr(u))
            }
            var f = (0...n).map { i in (max(0, i - 16)...min(n, i + 16)).reduce(-1e9) { max($0, raw[$1]) } }
            for _ in 0..<4 {
                let g = f
                f = (0...n).map { i in
                    let r = max(0, i - 16)...min(n, i + 16)
                    return r.reduce(0) { $0 + g[$1] } / Double(r.count)
                }
            }
            f = (0...n).map { i in
                let e = oClamp((Double(i) / Double(n) - 0.955) / 0.03, 0, 1)
                return oLerp(max(f[i], raw[i] - 1), raw[i], e * e * (3 - 2 * e)) // the field at the end is flat: settle onto it
            }
            floorTable = f
        }
        liftEye = CRCurve([[BASKET.x + 20, 3.2, BASKET.z + 30], [BASKET.x + 4, 2.6, BASKET.z + 32], [BASKET.x + 3, 1.2, BASKET.z + 9]])
        liftUp = CRCurve([[BASKET.x + 3, 1.2, BASKET.z + 9], [BASKET.x + 20, 26, BASKET.z + 40], [BASKET.x + 80, 70, BASKET.z + 140], [110, 95, 230]])

        self.FIELD = FIELD
        self.BASKET = BASKET
        self.TERR = TERR
        self.fogged = fogged
    }

    func height(_ x: Double, _ z: Double) -> Double { land.height(x, z) }

    /// The smoothed floor under the flight at `u` along it.
    func flightFloor(_ u: Double) -> Double {
        let n = floorTable.count - 1, x = oClamp(u, 0, 1) * Double(n), i = min(n - 1, Int(x))
        return oLerp(floorTable[i], floorTable[i + 1], x - Double(i))
    }

    /// The company's balloon, in its colors with its name (`heroFor()`), with the burner's light inside.
    func makeHero(name: String, colors: [String]) -> FilmBalloon {
        let mat = SCNMaterial()
        mat.lightingModel = .lambert
        mat.diffuse.contents = OpeningTextures.hero(colors: colors, name: name)
        OpeningKit.mipmapped(mat.diffuse)
        mat.isDoubleSided = true
        mat.shaderModifiers = [.fragment: OpeningKit.fogModifier]
        let g = SCNNode()
        let eg = envGeometry.copy() as? SCNGeometry ?? envGeometry
        eg.materials = [mat]
        let env = SCNNode(geometry: eg)
        env.position.y = 0.3
        env.categoryBitMask = 1 | OpeningWorld.flameMask
        let b = SCNNode(geometry: basketGeometry)
        b.position.y = 0.02
        let gl = OpeningKit.sprite(flameMaterial)
        gl.position.y = 0.34
        let light = SCNNode()
        light.light = flameLight
        light.position.y = 0.4
        for c in [env, b, gl, light] { g.addChildNode(c) }
        // its ropes follow the envelope: slack on the grass while it fills, taut once it stands (`heroRopes`)
        let dyn = OpeningWorld.ropeB.map { _ in
            (0..<OpeningWorld.ropeSegments).map { _ -> SCNNode in
                let n = SCNNode(geometry: ropeSegment)
                n.castsShadow = false
                g.addChildNode(n)
                return n
            }
        }
        g.scale = SCNVector3(15, 15, 15)
        return FilmBalloon(node: g, env: env, glow: gl, dyn: dyn)
    }

    static let ropeSegments = 12, ropeLength: Float = 0.246

    /// `ropeFrame(g, fill)`: each rope a quadratic curve from its basket corner to the envelope's mouth, sagging (each its
    /// own way) by as much as it is longer than the gap, never through the grass.
    static func ropeFrame(_ h: FilmBalloon, fill: Double) {
        let env = h.env.simdTransform
        for (i, segs) in h.dyn.enumerated() {
            let a = ropeB[i], m4 = env * SIMD4<Float>(ropeM[i], 1), b = F3(m4.x, m4.y, m4.z)
            let d = simd_length(b - a), L = max(ropeLength, d * Float(1 + 0.14 * (1 - fill)))
            let sag = d < L ? (L * L - d * d).squareRoot() * 0.6 : 0
            let ctl = (a + b) * 0.5 + F3(sin(Float(i) * 2.3) * sag * 0.5, -sag * 2, cos(Float(i) * 1.7) * sag * 0.5)
            var prev = a
            for k in 1...segs.count {
                let u = Float(k) / Float(segs.count)
                var q = a * ((1 - u) * (1 - u)) + ctl * (2 * u * (1 - u)) + b * (u * u)
                q.y = max(q.y, -0.012)
                let (rot, l) = span(prev, q)
                let n = segs[k - 1]
                n.simdPosition = prev
                n.simdOrientation = rot
                n.simdScale = F3(0.002, max(l, 1e-4), 0.002)
                prev = q
            }
        }
    }

    /// The hero's material takes the fog too; `OpeningFilm` adds it when the hero is built.
    func addFogged(_ m: SCNMaterial) { fogged.append(m) }
}
