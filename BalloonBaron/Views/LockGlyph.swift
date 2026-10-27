import SwiftUI

/// A small padlock in the game's own line (prototype `LOCK`), never the emoji: the shackle stroked, the body with a
/// keyhole cut out. It takes the colour of the text around it (`foregroundStyle`).
struct LockGlyph: View {
    var size: CGFloat = 12

    var body: some View {
        Canvas { ctx, sz in
            let k = sz.height / 14
            var shackle = Path()
            shackle.move(to: CGPoint(x: 3.3 * k, y: 6.4 * k))
            shackle.addLine(to: CGPoint(x: 3.3 * k, y: 4.6 * k))
            shackle.addArc(center: CGPoint(x: 6 * k, y: 4.6 * k), radius: 2.7 * k, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            shackle.addLine(to: CGPoint(x: 8.7 * k, y: 6.4 * k))
            ctx.stroke(shackle, with: .foreground, style: StrokeStyle(lineWidth: 1.9 * k, lineCap: .round))
            var hole = Path(ellipseIn: CGRect(x: 4.85 * k, y: 8.3 * k, width: 2.3 * k, height: 2.3 * k))
            hole.addRoundedRect(in: CGRect(x: 5.45 * k, y: 9.6 * k, width: 1.1 * k, height: 2.2 * k), cornerSize: CGSize(width: 0.5 * k, height: 0.5 * k))
            ctx.drawLayer { l in
                l.fill(Path(roundedRect: CGRect(x: 1 * k, y: 6 * k, width: 10 * k, height: 7.6 * k), cornerRadius: 2 * k), with: .foreground)
                l.blendMode = .destinationOut
                l.fill(hole, with: .color(.black))
            }
        }
        .frame(width: size * 12 / 14, height: size)
        .accessibilityHidden(true)
    }
}
