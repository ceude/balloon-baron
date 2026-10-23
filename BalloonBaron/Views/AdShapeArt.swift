import SwiftUI
import BalloonBaronCore

/// A brand's product-shaped balloon (the holding's ad desk): a soda bottle, a rocket or a sneaker, each hanging over
/// a small basket. Port of the prototype's `adShapeSvg`, drawn in its 64×64 box and scaled so `size` is the full width.
/// Used big over the town and small on the holding's cards.
enum AdShapeArt {
    static func draw(_ ctx: inout GraphicsContext, _ shape: AdShape, center: CGPoint, size: CGFloat) {
        var g = ctx
        g.translateBy(x: center.x - size / 2, y: center.y - size / 2)
        g.scaleBy(x: size / 64, y: size / 64)
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }
        func fill(_ path: Path, _ hex: String) { g.fill(path, with: .color(Color(hex: hex))) }
        func basket(_ y: CGFloat, _ h: CGFloat) {
            fill(Path(roundedRect: CGRect(x: 26, y: y, width: 12, height: h), cornerRadius: 1.5), "#8a5a34")
        }
        switch shape {
        case .rocket:
            var body = Path()
            body.move(to: p(32, 4))
            body.addCurve(to: p(44, 36), control1: p(41, 12), control2: p(44, 24))
            body.addLine(to: p(44, 48))
            body.addLine(to: p(20, 48))
            body.addLine(to: p(20, 36))
            body.addCurve(to: p(32, 4), control1: p(20, 24), control2: p(23, 12))
            body.closeSubpath()
            fill(body, "#eef2f8")
            var nose = Path()
            nose.move(to: p(32, 4))
            nose.addCurve(to: p(42, 19), control1: p(37, 8), control2: p(40, 13))
            nose.addLine(to: p(22, 19))
            nose.addCurve(to: p(32, 4), control1: p(24, 13), control2: p(27, 8))
            nose.closeSubpath()
            fill(nose, "#e5432f")
            let window = Path(ellipseIn: CGRect(x: 27, y: 25, width: 10, height: 10))
            fill(window, "#5aa9e6")
            g.stroke(window, with: .color(Color(hex: "#2b5ab8")), lineWidth: 2)
            var fins = Path()
            fins.move(to: p(20, 38)); fins.addLine(to: p(12, 50)); fins.addLine(to: p(20, 50)); fins.closeSubpath()
            fins.move(to: p(44, 38)); fins.addLine(to: p(52, 50)); fins.addLine(to: p(44, 50)); fins.closeSubpath()
            fill(fins, "#e5432f")
            basket(52, 7)
        case .shoe:
            var shoe = Path()
            shoe.move(to: p(8, 40))
            shoe.addCurve(to: p(22, 22), control1: p(8, 32), control2: p(14, 24))
            shoe.addLine(to: p(26, 30))
            shoe.addCurve(to: p(42, 32), control1: p(30, 32), control2: p(36, 32))
            shoe.addCurve(to: p(56, 42), control1: p(50, 32), control2: p(56, 36))
            shoe.addLine(to: p(56, 46))
            shoe.addLine(to: p(8, 46))
            shoe.closeSubpath()
            fill(shoe, "#14a39a")
            fill(Path(CGRect(x: 8, y: 46, width: 48, height: 4)), "#ffffff")
            var laces = Path()
            laces.move(to: p(24, 30)); laces.addLine(to: p(38, 32))
            laces.move(to: p(22, 34)); laces.addLine(to: p(36, 36))
            g.stroke(laces, with: .color(.white), lineWidth: 2)
            basket(54, 6)
        case .bottle:
            var bottle = Path()
            bottle.move(to: p(27, 6))
            bottle.addLine(to: p(37, 6))
            bottle.addLine(to: p(37, 14))
            bottle.addCurve(to: p(46, 32), control1: p(43, 18), control2: p(46, 24))
            bottle.addLine(to: p(46, 50))
            bottle.addArc(tangent1End: p(46, 55), tangent2End: p(41, 55), radius: 5)
            bottle.addLine(to: p(23, 55))
            bottle.addArc(tangent1End: p(18, 55), tangent2End: p(18, 50), radius: 5)
            bottle.addLine(to: p(18, 32))
            bottle.addCurve(to: p(27, 14), control1: p(18, 24), control2: p(21, 18))
            bottle.closeSubpath()
            fill(bottle, "#e5432f")
            fill(Path(CGRect(x: 18, y: 30, width: 28, height: 12)), "#ffffff")
            // A brand name, not a word: the same in every language.
            g.draw(Text(verbatim: "FIZZ").font(.custom("BarlowCondensed-ExtraBold", fixedSize: 9)).foregroundColor(Color(hex: "#e5432f")),
                   at: p(32, 36.2), anchor: .center)
            basket(56, 6)
        }
    }
}
