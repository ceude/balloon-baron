import SceneKit
import UIKit
import simd

/// SceneKit glue for the opening film: meshes into geometries, the materials, and the two shader snippets (three.js's
/// exponential-squared fog, which SceneKit's own linear fog can't match and which must leave the sky alone, and the sky).
enum OpeningKit {
    /// `FogExp2` on every fogged material, computed from the fragment's distance to the eye.
    static let fogModifier = """
    #pragma arguments
    float3 oFogColor;
    float oFogDensity;
    #pragma body
    float oFogD = oFogDensity * length(_surface.position);
    _output.color.rgb = mix(_output.color.rgb, oFogColor, 1.0 - exp(-oFogD * oFogD));
    """

    /// The sky dome: a gradient from the horizon to the zenith, the sun's glow and disk (bright enough to bloom), darker
    /// below the horizon. The direction is the view ray in world space.
    static let skyModifier = """
    #pragma arguments
    float3 oSunDir;
    float3 oZen;
    float3 oHor;
    float3 oGlow;
    float oSunK;
    #pragma body
    float3 oD = normalize((scn_frame.inverseViewTransform * float4(_surface.position, 0.0)).xyz);
    float oH = clamp(oD.y, -0.2, 1.0);
    float3 oC = mix(oHor, oZen, pow(max(oH, 0.0), 0.5));
    float oS = max(dot(oD, oSunDir), 0.0);
    oC += oGlow * (pow(oS, 5.0) * 0.6 + pow(oS, 48.0) * 0.9) * (0.25 + 0.75 * oSunK);
    oC += float3(1.0, 0.93, 0.8) * smoothstep(0.9993, 0.9997, oS) * 4.0 * oSunK;
    oC = mix(oC, oHor * 0.5, smoothstep(0.0, -0.2, oD.y));
    _output.color = float4(oC, 1.0);
    """

    static func vector(_ v: F3) -> NSValue { NSValue(scnVector3: SCNVector3(v.x, v.y, v.z)) }

    /// A linear-light color for lights and constant materials (three.js keeps its colors linear).
    static func color(_ c: F3, _ a: CGFloat = 1) -> UIColor {
        let space = CGColorSpace(name: CGColorSpace.extendedLinearSRGB) ?? CGColorSpaceCreateDeviceRGB()
        if let cg = CGColor(colorSpace: space, components: [CGFloat(c.x), CGFloat(c.y), CGFloat(c.z), a]) { return UIColor(cgColor: cg) }
        return UIColor(red: CGFloat(c.x), green: CGFloat(c.y), blue: CGFloat(c.z), alpha: a)
    }

    /// The mesh as one geometry: positions, normals, texture coordinates (flipped to SceneKit's top-left origin) and
    /// linear vertex colors, 32-bit indices.
    static func geometry(_ m: Mesh, colors: Bool = true) -> SCNGeometry {
        let n = m.p.count
        var pos = [Float](), nrm = [Float](), tex = [Float](), col = [Float]()
        pos.reserveCapacity(n * 3)
        nrm.reserveCapacity(n * 3)
        tex.reserveCapacity(n * 2)
        for k in 0..<n {
            let p = m.p[k]
            pos += [p.x, p.y, p.z]
            let q = k < m.n.count ? m.n[k] : F3(0, 1, 0)
            nrm += [q.x, q.y, q.z]
            let t = k < m.uv.count ? m.uv[k] : F2(0, 0)
            tex += [t.x, 1 - t.y]
            if colors {
                let c = k < m.c.count ? m.c[k] : F3(1, 1, 1)
                col += [c.x, c.y, c.z, 1]
            }
        }
        func source(_ a: [Float], _ sem: SCNGeometrySource.Semantic, _ comps: Int) -> SCNGeometrySource {
            let data = a.withUnsafeBufferPointer { Data(buffer: $0) }
            return SCNGeometrySource(data: data, semantic: sem, vectorCount: n, usesFloatComponents: true, componentsPerVector: comps,
                                     bytesPerComponent: 4, dataOffset: 0, dataStride: comps * 4)
        }
        var sources = [source(pos, .vertex, 3), source(nrm, .normal, 3), source(tex, .texcoord, 2)]
        if colors { sources.append(source(col, .color, 4)) }
        let idx = m.i.withUnsafeBufferPointer { Data(buffer: $0) }
        let element = SCNGeometryElement(data: idx, primitiveType: .triangles, primitiveCount: m.i.count / 3, bytesPerIndex: 4)
        return SCNGeometry(sources: sources, elements: [element])
    }

    /// Points (stars, dust): `size` in scene units, clamped on screen to the radii (pixels).
    static func points(_ pts: [F3], size: CGFloat, minRadius: CGFloat, maxRadius: CGFloat) -> SCNGeometry {
        var pos = [Float]()
        pos.reserveCapacity(pts.count * 3)
        for p in pts { pos += [p.x, p.y, p.z] }
        let data = pos.withUnsafeBufferPointer { Data(buffer: $0) }
        let src = SCNGeometrySource(data: data, semantic: .vertex, vectorCount: pts.count, usesFloatComponents: true, componentsPerVector: 3,
                                    bytesPerComponent: 4, dataOffset: 0, dataStride: 12)
        let idx = (0..<UInt32(pts.count)).map { $0 }.withUnsafeBufferPointer { Data(buffer: $0) }
        let el = SCNGeometryElement(data: idx, primitiveType: .point, primitiveCount: pts.count, bytesPerIndex: 4)
        el.pointSize = size
        el.minimumPointScreenSpaceRadius = minRadius
        el.maximumPointScreenSpaceRadius = maxRadius
        return SCNGeometry(sources: [src], elements: [el])
    }

    /// An unlit material that ignores the lights (`MeshBasicMaterial`, sprites).
    static func flat(_ contents: Any?, additive: Bool = false, doubleSided: Bool = false) -> SCNMaterial {
        let m = SCNMaterial()
        m.lightingModel = .constant
        m.diffuse.contents = contents
        m.isDoubleSided = doubleSided
        if additive {
            m.blendMode = .add
            m.writesToDepthBuffer = false
        }
        return m
    }

    static func repeatTexture(_ p: SCNMaterialProperty, _ sx: Float, _ sy: Float) {
        p.wrapS = .repeat
        p.wrapT = .repeat
        p.contentsTransform = SCNMatrix4MakeScale(sx, sy, 1)
    }

    static func mipmapped(_ p: SCNMaterialProperty) {
        p.mipFilter = .linear
        p.minificationFilter = .linear
        p.magnificationFilter = .linear
        p.maxAnisotropy = 4
    }

    /// A flat sprite that always faces the camera (three.js's `Sprite`).
    static func sprite(_ material: SCNMaterial, size: CGFloat = 1) -> SCNNode {
        let plane = SCNPlane(width: size, height: size)
        plane.materials = [material]
        let node = SCNNode(geometry: plane)
        node.constraints = [SCNBillboardConstraint()]
        node.castsShadow = false
        return node
    }

    static func quat(_ x: Double, _ y: Double, _ z: Double) -> simd_quatf {
        // three.js's Euler order XYZ: the matrix is Rx · Ry · Rz.
        simd_quatf(angle: Float(x), axis: F3(1, 0, 0)) * simd_quatf(angle: Float(y), axis: F3(0, 1, 0)) * simd_quatf(angle: Float(z), axis: F3(0, 0, 1))
    }
}
