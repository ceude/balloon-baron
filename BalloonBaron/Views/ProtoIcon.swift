import SwiftUI

/// The prototype's line icons (24×24 viewBox, ink stroke 1.9, round caps), drawn as paths.
struct ProtoIcon: View {
    enum Kind { case plan, fleet, crew, bank, market, goals, world }
    let kind: Kind
    var color: Color = Theme.ink

    var body: some View {
        Canvas { ctx, size in
            let k = min(size.width, size.height) / 24
            let path = Self.path(kind).applying(CGAffineTransform(scaleX: k, y: k))
            ctx.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 1.9 * k, lineCap: .round, lineJoin: .round))
        }
        .accessibilityHidden(true)
    }

    private static func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

    private static func line(_ path: inout Path, _ pts: [CGPoint]) {
        guard let first = pts.first else { return }
        path.move(to: first)
        for q in pts.dropFirst() { path.addLine(to: q) }
    }

    private static func circle(_ path: inout Path, _ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) {
        path.addEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
    }

    static func path(_ kind: Kind) -> Path {
        var path = Path()
        switch kind {
        case .plan:
            line(&path, [p(3, 18), p(21, 18)])
            path.move(to: p(6.5, 18))
            path.addArc(center: p(12, 18), radius: 5.5, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
            line(&path, [p(12, 6), p(12, 8.5)])
            line(&path, [p(5.2, 9.6), p(6.9, 11.3)])
            line(&path, [p(18.8, 9.6), p(17.1, 11.3)])
        case .fleet:
            // v124.6: ropes and a basket, so it reads as a balloon, not a light bulb
            path.move(to: p(6, 8.5))
            path.addArc(center: p(12, 8.5), radius: 6, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
            path.addCurve(to: p(13.7, 16), control1: p(18, 11.7), control2: p(15, 14.1))
            path.addLine(to: p(10.3, 16))
            path.addCurve(to: p(6, 8.5), control1: p(9, 14.1), control2: p(6, 11.7))
            path.closeSubpath()
            path.move(to: p(12, 2.5))
            path.addCurve(to: p(11.2, 16), control1: p(10.5, 4.2), control2: p(9.9, 11.5))
            path.move(to: p(12, 2.5))
            path.addCurve(to: p(12.8, 16), control1: p(13.5, 4.2), control2: p(14.1, 11.5))
            line(&path, [p(10.4, 16.2), p(10.7, 18.5)])
            line(&path, [p(13.6, 16.2), p(13.3, 18.5)])
            path.addRoundedRect(in: CGRect(x: 9.9, y: 18.5, width: 4.2, height: 3), cornerSize: CGSize(width: 0.8, height: 0.8))
        case .crew:
            circle(&path, 9, 8, 3.2)
            path.move(to: p(3, 20.5))
            path.addCurve(to: p(9, 14.5), control1: p(3, 17.1), control2: p(5.7, 14.5))
            path.addCurve(to: p(15, 20.5), control1: p(12.3, 14.5), control2: p(15, 17.1))
            circle(&path, 17.2, 9, 2.4)
            path.move(to: p(16, 14.4))
            path.addCurve(to: p(21, 20), control1: p(19, 14.7), control2: p(21, 17))
        case .bank:
            line(&path, [p(3, 9.5), p(12, 4), p(21, 9.5)])
            for x: CGFloat in [5.5, 10, 14, 18.5] { line(&path, [p(x, 10.5), p(x, 17.5)]) }
            line(&path, [p(3, 20.5), p(21, 20.5)])
        case .market:
            line(&path, [p(4, 20.5), p(4, 13.5)])
            line(&path, [p(10, 20.5), p(10, 5)])
            line(&path, [p(16, 20.5), p(16, 10.5)])
            line(&path, [p(2.5, 20.5), p(21.5, 20.5)])
        case .goals:
            line(&path, [p(5, 21), p(5, 4)])
            line(&path, [p(5, 4), p(16, 4), p(14, 8), p(16, 12), p(5, 12)])
        case .world:
            circle(&path, 12, 12, 8.5)
            line(&path, [p(3.5, 12), p(20.5, 12)])
            path.move(to: p(12, 3.5))
            path.addCurve(to: p(15.5, 12), control1: p(14.5, 6), control2: p(15.5, 9))
            path.addCurve(to: p(12, 20.5), control1: p(15.5, 15), control2: p(14.5, 18))
            path.addCurve(to: p(8.5, 12), control1: p(9.5, 18), control2: p(8.5, 15))
            path.addCurve(to: p(12, 3.5), control1: p(8.5, 9), control2: p(9.5, 6))
            path.closeSubpath()
        }
        return path
    }
}
