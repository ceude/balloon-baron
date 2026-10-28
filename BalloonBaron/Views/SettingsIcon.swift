import SwiftUI

/// Line icons for the settings rows (`SET_IC`), drawn like the side buttons' `ProtoIcon`: 24×24, round strokes.
struct SettingsIcon: View {
    enum Kind { case trophy, game, moon, people, sound, haptic, bell, cloud, copy, paste, bag, shield, mail, info, trash, chevron, down, close, film }
    let kind: Kind
    var color: Color = Theme.ink
    var width: CGFloat = 2

    var body: some View {
        Canvas { ctx, size in
            let k = min(size.width, size.height) / 24
            ctx.stroke(Self.path(kind).applying(CGAffineTransform(scaleX: k, y: k)), with: .color(color),
                       style: StrokeStyle(lineWidth: width * k, lineCap: .round, lineJoin: .round))
        }
        .accessibilityHidden(true)
    }

    private static func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

    private static func line(_ path: inout Path, _ pts: [CGPoint]) {
        guard let first = pts.first else { return }
        path.move(to: first)
        for q in pts.dropFirst() { path.addLine(to: q) }
    }

    private static func round(_ path: inout Path, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) {
        path.addRoundedRect(in: CGRect(x: x, y: y, width: w, height: h), cornerSize: CGSize(width: r, height: r))
    }

    static func path(_ kind: Kind) -> Path {
        var path = Path()
        switch kind {
        case .trophy:
            line(&path, [p(8, 9), p(8, 4), p(16, 4), p(16, 9)])
            path.addArc(center: p(12, 9), radius: 4, startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
            path.move(to: p(8, 6)); path.addLine(to: p(5, 6)); path.addLine(to: p(5, 7.5))
            path.addCurve(to: p(8, 10.5), control1: p(5, 9.2), control2: p(6.3, 10.5))
            path.move(to: p(16, 6)); path.addLine(to: p(19, 6)); path.addLine(to: p(19, 7.5))
            path.addCurve(to: p(16, 10.5), control1: p(19, 9.2), control2: p(17.7, 10.5))
            line(&path, [p(12, 13), p(12, 16.5)])
            round(&path, 9.5, 16.5, 5, 3.5, 0.8)
            line(&path, [p(8.5, 20), p(15.5, 20)])
        case .film:
            // a clapperboard with a play mark
            round(&path, 4, 10, 16, 10, 2)
            line(&path, [p(4.5, 10), p(4, 6.6), p(19.4, 4.2), p(20, 7.6)])
            line(&path, [p(8.6, 5.9), p(10.2, 9)])
            line(&path, [p(13.6, 5.1), p(15.2, 8.3)])
            line(&path, [p(10.5, 12.8), p(14.6, 15), p(10.5, 17.2)])
            path.closeSubpath()
        case .game:
            round(&path, 3.5, 8.5, 17, 9.5, 4.5)
            line(&path, [p(8.5, 11), p(8.5, 15)])
            line(&path, [p(6.5, 13), p(10.5, 13)])
            path.addEllipse(in: CGRect(x: 14.8, y: 11.3, width: 1.4, height: 1.4))
            path.addEllipse(in: CGRect(x: 16.8, y: 13.3, width: 1.4, height: 1.4))
        case .sound:
            line(&path, [p(4, 9.5), p(7, 9.5), p(11.5, 5.5), p(11.5, 18.5), p(7, 14.5), p(4, 14.5)])
            path.closeSubpath()
            path.move(to: p(15, 9)); path.addQuadCurve(to: p(15, 15), control: p(17.6, 12))
            path.move(to: p(17.5, 6.5)); path.addQuadCurve(to: p(17.5, 17.5), control: p(22.4, 12))
        case .haptic:
            round(&path, 8, 3.5, 8, 17, 2)
            line(&path, [p(11, 17.5), p(13, 17.5)])
            for (x, a, b) in [(4.5, 9.0, 15.0), (2.5, 10.5, 13.5), (19.5, 9.0, 15.0), (21.5, 10.5, 13.5)] as [(CGFloat, CGFloat, CGFloat)] {
                line(&path, [p(x, a), p(x, b)])
            }
        case .moon:
            // A crescent: two arcs of radius 8 meeting at (19.5, 14.5) and (9.5, 4.5).
            path.move(to: p(19.5, 14.5))
            path.addArc(center: p(17.15, 6.85), radius: 8, startAngle: .degrees(73), endAngle: .degrees(197), clockwise: false)
            path.addArc(center: p(11.85, 12.15), radius: 8, startAngle: .degrees(253), endAngle: .degrees(17), clockwise: true)
            path.closeSubpath()
        case .people:
            path.addEllipse(in: CGRect(x: 6, y: 5, width: 6, height: 6))
            path.move(to: p(3.5, 19)); path.addQuadCurve(to: p(14.5, 19), control: p(9, 10.5))
            path.addEllipse(in: CGRect(x: 14, y: 6.5, width: 5, height: 5))
            path.move(to: p(15, 13.8)); path.addQuadCurve(to: p(20.5, 19), control: p(20, 13.5))
        case .bell:
            path.move(to: p(6, 16.5)); path.addLine(to: p(6, 11))
            path.addArc(center: p(12, 11), radius: 6, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
            path.addLine(to: p(18, 16.5)); path.addLine(to: p(19.5, 18.5)); path.addLine(to: p(4.5, 18.5)); path.closeSubpath()
            path.move(to: p(10, 20.5)); path.addQuadCurve(to: p(14, 20.5), control: p(12, 22.6))
            line(&path, [p(12, 3), p(12, 5)])
        case .cloud:
            path.move(to: p(7, 18.5))
            path.addCurve(to: p(6.4, 9.5), control1: p(3.2, 18.5), control2: p(2.6, 10.2))
            path.addCurve(to: p(17.8, 11.1), control1: p(8.3, 4.4), control2: p(16.6, 5))
            path.addCurve(to: p(17.5, 18.5), control1: p(20.7, 11.4), control2: p(21.2, 18.5))
            path.closeSubpath()
            line(&path, [p(9.5, 13.5), p(11.5, 15.5), p(15, 12)])
        case .copy:
            round(&path, 8.5, 8.5, 11, 12, 2)
            path.move(to: p(15.5, 8.5)); path.addLine(to: p(15.5, 5.5))
            path.addQuadCurve(to: p(13.5, 3.5), control: p(15.5, 3.5)); path.addLine(to: p(6.5, 3.5))
            path.addQuadCurve(to: p(4.5, 5.5), control: p(4.5, 3.5)); path.addLine(to: p(4.5, 14.5))
            path.addQuadCurve(to: p(6.5, 16.5), control: p(4.5, 16.5)); path.addLine(to: p(8.5, 16.5))
        case .paste:
            round(&path, 5, 5.5, 14, 15.5, 1.8)
            round(&path, 9, 3.5, 6, 3.2, 1)
            line(&path, [p(12, 10.5), p(12, 17)])
            line(&path, [p(9.5, 14.5), p(12, 17), p(14.5, 14.5)])
        case .bag:
            line(&path, [p(5, 8), p(19, 8), p(18, 20.5), p(6, 20.5)])
            path.closeSubpath()
            path.move(to: p(9, 8)); path.addLine(to: p(9, 6.5))
            path.addArc(center: p(12, 6.5), radius: 3, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
            path.addLine(to: p(15, 8))
            line(&path, [p(12, 11), p(12, 17)])
            line(&path, [p(10, 15), p(12, 17), p(14, 15)])
        case .shield:
            path.move(to: p(12, 3.5)); path.addLine(to: p(19, 6)); path.addLine(to: p(19, 11.5))
            path.addQuadCurve(to: p(12, 20.5), control: p(19, 18))
            path.addQuadCurve(to: p(5, 11.5), control: p(5, 18))
            path.addLine(to: p(5, 6)); path.closeSubpath()
            line(&path, [p(9.5, 12), p(11.5, 14), p(15, 10.5)])
        case .mail:
            round(&path, 3.5, 5.5, 17, 13, 2)
            line(&path, [p(4, 7), p(12, 13), p(20, 7)])
        case .info:
            path.addEllipse(in: CGRect(x: 3.5, y: 3.5, width: 17, height: 17))
            line(&path, [p(12, 11), p(12, 16.5)])
            line(&path, [p(12, 7.8), p(12, 7.85)])
        case .trash:
            line(&path, [p(4.5, 7), p(19.5, 7)])
            line(&path, [p(9.5, 7), p(9.5, 4.5), p(14.5, 4.5), p(14.5, 7)])
            line(&path, [p(6.5, 7), p(7.5, 20), p(16.5, 20), p(17.5, 7)])
            line(&path, [p(10.5, 11), p(10.5, 16.5)])
            line(&path, [p(13.5, 11), p(13.5, 16.5)])
        case .chevron:
            line(&path, [p(9.5, 6), p(15.5, 12), p(9.5, 18)])
        case .down:
            line(&path, [p(6, 9.5), p(12, 15.5), p(18, 9.5)])
        case .close:
            line(&path, [p(6, 6), p(18, 18)])
            line(&path, [p(18, 6), p(6, 18)])
        }
        return path
    }
}
