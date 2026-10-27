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

/// The autopilot's mark (prototype `#auto`): two triangles pointing on, drawn like the padlock, in the text colour.
struct FastForwardGlyph: View {
    var size: CGFloat = 14

    var body: some View {
        Canvas { ctx, sz in
            let h = sz.height, w = sz.width / 2
            for i in 0..<2 {
                let x = CGFloat(i) * w
                var p = Path()
                p.move(to: CGPoint(x: x, y: h * 0.08))
                p.addLine(to: CGPoint(x: x + w, y: h / 2))
                p.addLine(to: CGPoint(x: x, y: h * 0.92))
                p.closeSubpath()
                ctx.fill(p, with: .foreground)
                ctx.stroke(p, with: .foreground, style: StrokeStyle(lineWidth: h * 0.12, lineJoin: .round))
            }
        }
        .frame(width: size * 1.25, height: size)
        .accessibilityHidden(true)
    }
}

/// The autopilot's strip over the day's buttons (prototype `.autobar`): the day running, its result, or why it
/// stopped with the tally.
struct AutopilotStrip: View {
    let note: GameStore.AutoNote

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            if let why = note.stop {
                Text(loc("auto.stop.\(why.rawValue)")).font(Theme.font(16, .heavy, condensed: true))
                Text(loc("auto.days", num(note.days))).font(Theme.font(14, .semibold))
                money(note.net ?? 0)
                if note.accidents > 0 { Text(loc("auto.accidents", num(note.accidents))).font(Theme.font(14, .semibold)) }
            } else {
                FastForwardGlyph(size: 13).alignmentGuide(.firstTextBaseline) { $0[.bottom] - 1 }
                Text(loc("auto.day", num(note.day))).font(Theme.font(16, .heavy, condensed: true))
                if let net = note.net { money(net) }
                Text(loc("auto.tapToStop")).font(Theme.font(11.5)).opacity(0.65)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .foregroundStyle(Color(hex: "#fff8e6"))
        .padding(.horizontal, 16).padding(.vertical, 9)
        .background(Color(red: 27 / 255, green: 24 / 255, blue: 64 / 255).opacity(0.86), in: Capsule())
        .shadow(color: .black.opacity(0.25), radius: 10, y: 8)
        .padding(.horizontal, 16)
    }

    private func money(_ v: Int) -> some View {
        Text((v >= 0 ? "+" : "−") + eur(abs(v))).font(Theme.font(14, .bold))
            .foregroundStyle(Color(hex: v >= 0 ? "#7be0a0" : "#ff9a86"))
    }
}
