import BalloonBaronCore
import SceneKit
import UIKit
import simd

/// v121.5: our town in the film, built from the game's own layout (`Town.buildings`, the prototype's `townBuildings`) on
/// its 16×16 grid of 12 m tiles, with no writing anywhere: the ground with its cobbled roads and the green launch field,
/// the low wall with its gates, the buildings of day one (empty plots in scaffolding), the edge chimneys and the trees.
/// Heights follow the town's drawing: 2D px / 6.53 = m. Built off the main thread once the company exists.
enum OpeningTown {
    /// 2D town pixels per metre.
    static let PXM = 6.53

    /// The town's node, and the materials it adds that take the fog.
    static func build(_ s: GameState, kit: TownKit, litWindows: SCNMaterial) -> (SCNNode, [SCNMaterial]) {
        let root = SCNNode()
        var fogged: [SCNMaterial] = []
        func lit(_ contents: Any?, doubleSided: Bool = false) -> SCNMaterial {
            let m = SCNMaterial()
            m.lightingModel = .lambert
            m.diffuse.contents = contents
            OpeningKit.mipmapped(m.diffuse)
            m.isDoubleSided = doubleSided
            m.shaderModifiers = [.fragment: OpeningKit.fogModifier]
            fogged.append(m)
            return m
        }
        func ui(_ v: UInt32) -> UIColor {
            UIColor(red: CGFloat((v >> 16) & 0xff) / 255, green: CGFloat((v >> 8) & 0xff) / 255, blue: CGFloat(v & 0xff) / 255, alpha: 1)
        }
        func place(_ g: SCNGeometry, _ m: SCNMaterial, _ p: F3 = .zero, shadow: Bool = true) -> SCNNode {
            g.materials = [m]
            let n = SCNNode(geometry: g)
            n.simdPosition = p
            n.castsShadow = shadow
            root.addChildNode(n)
            return n
        }
        let TL = OpeningLand.TL
        func at(_ gx: Double, _ gy: Double, _ y: Double = 0) -> F3 { F3(OpeningLand.tw(gx, gy, y)) }
        var rnd = FilmRandom(4121)
        let TB = Town.buildings(s)

        // the ground: sand, worn plots, cobbled roads, the launch field in green stripes
        let gtex = OpeningTextures.canvas(1024, 1024) { c, wf, hf in
            let w = Double(wf), hh = Double(hf), k = w / 16
            func R(_ gx0: Double, _ gy0: Double, _ gx1: Double, _ gy1: Double, _ col: CGColor) {
                OpeningTextures.fillRect(c, col, (gx0 + 0.5) * k, (gy0 + 0.5) * k, (gx1 - gx0) * k, (gy1 - gy0) * k)
            }
            R(-0.5, -0.5, 15.5, 15.5, OpeningTextures.hex("#ecd2a8"))
            for _ in 0..<9000 {
                let v = rnd.next()
                let col = v < 0.5 ? OpeningTextures.rgba(255, 240, 215, 0.15 + rnd.next() * 0.2) : OpeningTextures.rgba(120, 80, 50, 0.06 + rnd.next() * 0.12)
                let x = rnd.next() * w, y = rnd.next() * hh, a = 1 + rnd.next() * 2, b = 1 + rnd.next() * 2
                OpeningTextures.fillRect(c, col, x, y, a, b)
            }
            for b in TB where b.lv <= 0 && b.look != .kiosk {
                R(b.gx + 0.12, b.gy + 0.12, b.gx + b.w - 0.12, b.gy + b.d - 0.12, OpeningTextures.rgba(150, 108, 70, 0.35))
            }
            func road(_ a: Double, _ b: Double, _ cc: Double, _ d: Double) {
                R(a, b, cc, d, OpeningTextures.hex("#c9a47a"))
                c.saveGState()
                c.clip(to: CGRect(x: (a + 0.5) * k, y: (b + 0.5) * k, width: (cc - a) * k, height: (d - b) * k))
                for _ in 0..<2600 {
                    let col = rnd.next() < 0.5 ? OpeningTextures.rgba(255, 240, 215, 0.35) : OpeningTextures.rgba(110, 70, 40, 0.22)
                    let x = (a + 0.5 + rnd.next() * (cc - a)) * k, y = (b + 0.5 + rnd.next() * (d - b)) * k, rot = rnd.next() * 3
                    OpeningTextures.ellipse(c, col, x, y, 3, 2, rot)
                }
                c.restoreGState()
            }
            road(0, 7.55, 15, 8.45)
            road(7.55, 0, 8.45, 15)
            road(0.6, 3.6, 7.55, 4.1)
            R(1, 4.4, 7, 7.2, OpeningTextures.hex("#a3b066"))
            for i in 0..<9 {
                R(1 + Double(i) * 0.67, 4.4, 1.33 + Double(i) * 0.67, 7.2,
                  i % 2 == 1 ? OpeningTextures.rgba(120, 140, 70, 0.3) : OpeningTextures.rgba(190, 200, 125, 0.3))
            }
            for _ in 0..<1500 {
                let col = rnd.next() < 0.5 ? OpeningTextures.rgba(90, 120, 50, 0.25) : OpeningTextures.rgba(200, 210, 140, 0.25)
                let x = (1.5 + rnd.next() * 6) * k, y = (4.9 + rnd.next() * 2.8) * k
                OpeningTextures.fillRect(c, col, x, y, 2, 3)
            }
        }
        var gm = Mesh()
        for (gy, gx) in [(-0.5, -0.5), (-0.5, 15.5), (15.5, -0.5), (15.5, 15.5)] {
            gm.p.append(at(gx, gy, 0.12))
            gm.uv.append(F2(Float((gx + 0.5) / 16), Float(1 - (gy + 0.5) / 16)))
        }
        gm.n = Array(repeating: F3(0, 1, 0), count: 4)
        gm.i = [0, 2, 1, 1, 2, 3]
        let ground = place(OpeningKit.geometry(gm, colors: false), lit(gtex), shadow: false)
        ground.categoryBitMask = 1 | OpeningWorld.flameMask

        // Boxes merged by material: (gx, gy) is the footprint's corner, w × d in tiles, standing on y.
        var merged: [ObjectIdentifier: (SCNMaterial, Mesh)] = [:]
        func box(_ gx: Double, _ gy: Double, _ w: Double, _ d: Double, _ hgt: Double, _ m: SCNMaterial, y: Double = 0,
                 geo: Mesh? = nil, tint: F3 = F3(1, 1, 1)) {
            let key = ObjectIdentifier(m)
            var e = merged[key] ?? (m, Mesh())
            e.1.add(geo ?? kit.box, at: at(gx + w / 2, gy + d / 2, y), scale: F3(Float(w * TL), Float(hgt), Float(d * TL)), tint: tint)
            merged[key] = e
        }
        let stone = lit(kit.mottle)
        OpeningKit.repeatTexture(stone.diffuse, 3, 2)
        let stoneTint = linearColor(0xf0d8b2)
        let wood = lit(ui(0x8a6a4a))
        func stripes(_ cols: [String], _ n: Int, vertical: Bool) -> CGImage? {
            OpeningTextures.canvas(vertical ? 64 : 256, vertical ? 256 : 64) { c, wf, hf in
                let w = Double(wf), hh = Double(hf)
                for i in 0..<n {
                    let col = OpeningTextures.hex(cols[i % cols.count])
                    if vertical { OpeningTextures.fillRect(c, col, 0, Double(i) * hh / Double(n), w, hh / Double(n) + 1) } else {
                        OpeningTextures.fillRect(c, col, Double(i) * w / Double(n), 0, w / Double(n) + 1, hh)
                    }
                }
            }
        }

        // the wall, a little higher than a man, open where the two main roads leave
        var wallG = Mesh.roundedBox(F3(1, 1, 1), radius: 0.12, segments: 2)
        wallG.p = wallG.p.map { $0 + F3(0, 0.5, 0) }
        let th = 0.14, WH = 16 / PXM
        var v = -0.5
        while v < 15.5 {
            let w = min(1, 15.5 - v)
            if !(v + w > 7.55 && v < 8.45) {
                box(v, -0.5 - th, w, th, WH, stone, geo: wallG, tint: stoneTint)
                box(v, 15.5, w, th, WH, stone, geo: wallG, tint: stoneTint)
                box(-0.5 - th, v, th, w, WH, stone, geo: wallG, tint: stoneTint)
                box(15.5, v, th, w, WH, stone, geo: wallG, tint: stoneTint)
            }
            v += 1
        }

        var lights: [(D3, Double, Double)] = []
        var parapets = Mesh()
        let kindOf: [TownLook: Int] = [.workshop: 1, .office: 0, .school: 2, .bank: 1, .guide: 0, .agency: 3, .tower: 1, .bazaar: 4]
        for b in TB {
            let inset = 0.14, gx = b.gx + inset, gy = b.gy + inset, w = b.w - inset * 2, d = b.d - inset * 2
            if b.lv <= 0 && b.look != .kiosk && b.look != .mast {
                // an empty plot: scaffolding
                for (u, vv) in [(0.0, 0.0), (1, 0), (0, 1), (1, 1)] { box(gx + u * w - 0.02, gy + vv * d - 0.02, 0.04, 0.04, 7.5, wood) }
                for y in [3.4, 7.2] {
                    box(gx, gy - 0.02, w, 0.03, 0.25, wood, y: y)
                    box(gx, gy + d - 0.01, w, 0.03, 0.25, wood, y: y)
                    box(gx - 0.02, gy, 0.03, d, 0.25, wood, y: y)
                }
                continue
            }
            switch b.look {
            case .hangar:
                // a long barrel roof in red stripes on a low stone body
                box(gx, gy, w, d, 4.6, kit.facades[1])
                let roof = place(OpeningKit.geometry(barrel(), colors: false), lit(stripes(["#b5532c", "#8e3b22"], 14, vertical: false), doubleSided: true),
                                 at(gx + w / 2, gy + d / 2, 4.5))
                roof.simdScale = F3(Float(w * TL * 1.02), 7.6, Float(d * TL * 0.52))
                continue
            case .kiosk:
                // a booking kiosk under an awning in its company's colours
                box(gx + 0.12, gy + 0.12, w - 0.24, d - 0.24, 44 / PXM * 0.8, kit.facades[0])
                let cols = [b.colors.first ?? "#ff5e3a", b.colors.count > 1 ? b.colors[1] : "#ffffff"]
                let aw = place(OpeningKit.geometry(Mesh.roundedBox(F3(1, 1, 1), radius: 0.02, segments: 1), colors: false),
                               lit(stripes(cols, 8, vertical: false)), at(gx + w / 2, gy + d - 0.05, 44 / PXM * 0.62))
                aw.simdScale = F3(Float(w * TL), 0.35, 3.2)
                aw.simdEulerAngles = F3(0.35, 0, 0)
                continue
            case .mast:
                // the wind mast: a striped pole on a tuff plinth, the sock out
                box(b.gx - 0.17, b.gy - 0.17, 0.34, 0.34, 14 / PXM, stone, tint: stoneTint)
                let pole = SCNCone(topRadius: 0.32, bottomRadius: 0.38, height: 128 / PXM)
                pole.radialSegmentCount = 10
                _ = place(pole, lit(stripes(["#ff5e3a", "#fffaf3"], 8, vertical: true)), at(b.gx, b.gy, 14 / PXM + 64 / PXM))
                let sockG = SCNCone(topRadius: 0, bottomRadius: 0.9, height: 5)
                sockG.radialSegmentCount = 12
                let sock = place(sockG, lit(ui(0xff7a4a), doubleSided: true), at(b.gx, b.gy, 14 / PXM + 120 / PXM) + F3(2.6, 0, 0), shadow: false)
                sock.simdEulerAngles = F3(0, 0, Float.pi / 2)
                continue
            default:
                break
            }
            let hpx: Double
            switch b.look {
            case .hotel: hpx = [60, 120, 140, 120][min(3, b.star)]
            case .bazaar: hpx = 60
            case .workshop: hpx = 70
            case .office: hpx = b.lv == 2 ? 104 : 74
            case .school: hpx = 90
            case .bank: hpx = 85
            case .guide: hpx = 48
            case .agency: hpx = 100
            case .tower: hpx = 270
            default: hpx = 60
            }
            let K = b.look == .hotel ? [0, 1, 3, 4][min(3, b.star)] : kindOf[b.look] ?? 0, hgt = hpx / PXM
            box(gx, gy, w, d, hgt, kit.facades[K])
            // windows that light up when night falls after the landing, on the two faces the camera sees
            var fl = 2.2
            while fl < hgt - 1.5 {
                for (face, n) in [(0, w), (1, d)] {
                    let count = max(1, Int((n * 1.6).rounded()))
                    for k in 0..<count where rnd.next() < 0.55 {
                        let u = (Double(k) + 0.5) / Double(count)
                        let pt = face == 1 ? at(gx + w + 0.01, gy + u * d, fl) : at(gx + u * w, gy + d + 0.01, fl)
                        lights.append((D3(pt), face == 1 ? 0 : Double.pi / 2, 1.1))
                    }
                }
                fl += 3.4
            }
            parapets.add(kit.parapet, at: at(gx + w / 2, gy + d / 2, hgt + 0.2), scale: F3(Float(w * TL + 0.5), 0.5, Float(d * TL + 0.5)))
            // a storey set back on the bigger hotels
            if b.look == .hotel && b.star >= 1 { box(gx + w * 0.2, gy + d * 0.2, w * 0.55, d * 0.55, hgt * 0.28, kit.facades[(K + 2) % 5], y: hgt) }
        }

        // the fairy chimneys round the edge, and the trees, where the town has them
        var tuff = Mesh(), basalt = Mesh()
        for (i, e) in [(0.3, 6.6, 150.0), (16.4, 11.2, 140), (0.4, 12.6, 130), (7.7, 0.3, 120), (5.6, 15.2, 150), (0.5, 3.0, 160), (12.8, 0.2, 140)].enumerated() {
            let (gx, gy, hpx) = e
            let hgt = hpx / PXM, r = hgt * 0.19
            tuff.add(kit.chimneys[i % kit.chimneys.count], at: at(gx, gy, -0.4), rot: simd_quatf(angle: Float(Double(i) * 1.7), axis: F3(0, 1, 0)),
                     scale: F3(Float(r), Float(hgt), Float(r)))
            if i % 2 == 0 {
                basalt.add(kit.cap, at: at(gx, gy, hgt * 0.985 - 0.4), scale: F3(Float(r * 0.55), Float(r * 0.38), Float(r * 0.5)), tint: kit.basaltColor)
            }
        }
        _ = place(OpeningKit.geometry(tuff), kit.tuff)
        _ = place(OpeningKit.geometry(basalt), kit.basalt)
        let leaf = [lit(ui(0x4f6a3a)), lit(kit.mottle), lit(kit.mottle)]
        leaf[1].multiply.contents = ui(0x7aa04a)
        leaf[2].multiply.contents = ui(0x8aa84e)
        var crownBall = Mesh.icosphere(1)
        crownBall.p = crownBall.p.map { $0 * 2.8 }
        let ball = OpeningKit.geometry(crownBall, colors: false)
        for (i, (gx, gy)) in [(7.1, 6.9), (14.55, 3.35), (14.85, 4.5), (3.4, 8.9), (14.6, 7.3), (10.8, 4.4), (4.3, 7.0), (8.4, 15)].enumerated() {
            let trunk = SCNCone(topRadius: 0.25, bottomRadius: 0.35, height: 2.4)
            trunk.radialSegmentCount = 8
            _ = place(trunk, wood, at(gx, gy, 1.2))
            if i % 3 != 0 {
                let g = ball.copy() as? SCNGeometry ?? ball
                _ = place(g, leaf[1 + i % 2], at(gx, gy, 4.6))
            } else {
                let cone = SCNCone(topRadius: 0, bottomRadius: 1.5, height: 9)
                cone.radialSegmentCount = 10
                _ = place(cone, leaf[0], at(gx, gy, 6.4))
            }
        }

        for (_, e) in merged where !e.1.isEmpty { _ = place(OpeningKit.geometry(e.1), e.0) }
        if !parapets.isEmpty { _ = place(OpeningKit.geometry(parapets), lit(kit.mottle)) }
        if !lights.isEmpty { _ = place(OpeningWorld.windows(lights), litWindows, shadow: false) }
        return (root, fogged)
    }

    /// The hangar's barrel roof: half a cylinder of radius 1 along x (−0.5 … 0.5), arched over y, closed at both ends;
    /// u runs round the arch, so the stripes run along the roof.
    private static func barrel() -> Mesh {
        var m = Mesh()
        let segs = 28
        for x in [Float(-0.5), Float(0.5)] {
            for s in 0...segs {
                let th = Float(s) / Float(segs) * Float.pi
                m.p.append(F3(x, sin(th), cos(th)))
                m.uv.append(F2(Float(s) / Float(segs), x + 0.5))
            }
        }
        for s in 0..<segs {
            let a = UInt32(s), b = UInt32(s + 1), c = UInt32(segs + 1 + s), d = UInt32(segs + 2 + s)
            m.i += [a, c, b, b, c, d]
        }
        for x in [Float(-0.5), Float(0.5)] {
            let center = UInt32(m.p.count)
            m.p.append(F3(x, 0, 0))
            m.uv.append(F2(0.5, 0))
            let ring = UInt32(m.p.count)
            for s in 0...segs {
                let th = Float(s) / Float(segs) * Float.pi
                m.p.append(F3(x, sin(th), cos(th)))
                m.uv.append(F2(0.5, 0))
            }
            for s in 0..<UInt32(segs) { m.i += x > 0 ? [center, ring + s + 1, ring + s] : [center, ring + s, ring + s + 1] }
        }
        m.computeNormals()
        return m
    }
}
