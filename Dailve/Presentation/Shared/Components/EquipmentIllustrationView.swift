import SwiftUI

/// Simplified vector illustrations for each equipment type.
struct EquipmentIllustrationView: View {
    let equipment: Equipment
    let size: CGFloat

    init(equipment: Equipment, size: CGFloat = 60) {
        self.equipment = equipment
        self.size = size
    }

    var body: some View {
        Canvas { context, canvasSize in
            let w = canvasSize.width
            let h = canvasSize.height
            guard w > 0, h > 0 else { return }
            draw(equipment, in: context, width: w, height: h)
        }
        .frame(width: size, height: size)
    }

    // MARK: - Drawing

    private func draw(_ equipment: Equipment, in context: GraphicsContext, width w: CGFloat, height h: CGFloat) {
        let stroke = DS.Color.activity
        let fill = DS.Color.activity.opacity(0.15)
        let lineWidth: CGFloat = 2

        switch equipment {
        case .barbell:
            drawBarbell(context, w: w, h: h, stroke: stroke, fill: fill, lineWidth: lineWidth)
        case .dumbbell:
            drawDumbbell(context, w: w, h: h, stroke: stroke, fill: fill, lineWidth: lineWidth)
        case .machine:
            drawMachine(context, w: w, h: h, stroke: stroke, fill: fill, lineWidth: lineWidth)
        case .cable:
            drawCable(context, w: w, h: h, stroke: stroke, fill: fill, lineWidth: lineWidth)
        case .bodyweight:
            drawBodyweight(context, w: w, h: h, stroke: stroke, fill: fill, lineWidth: lineWidth)
        case .band:
            drawBand(context, w: w, h: h, stroke: stroke, fill: fill, lineWidth: lineWidth)
        case .kettlebell:
            drawKettlebell(context, w: w, h: h, stroke: stroke, fill: fill, lineWidth: lineWidth)
        case .other:
            drawOther(context, w: w, h: h, stroke: stroke, fill: fill, lineWidth: lineWidth)
        }
    }

    // MARK: - Barbell

    private func drawBarbell(_ ctx: GraphicsContext, w: CGFloat, h: CGFloat, stroke: Color, fill: Color, lineWidth: CGFloat) {
        let cy = h * 0.5
        // Bar
        var bar = Path()
        bar.addRoundedRect(in: CGRect(x: w * 0.1, y: cy - 2, width: w * 0.8, height: 4), cornerSize: CGSize(width: 2, height: 2))
        ctx.fill(bar, with: .color(stroke))

        // Left plates
        let plateRects = [
            CGRect(x: w * 0.12, y: cy - h * 0.3, width: w * 0.08, height: h * 0.6),
            CGRect(x: w * 0.22, y: cy - h * 0.25, width: w * 0.06, height: h * 0.5),
        ]
        // Right plates (mirrored)
        let rightPlateRects = [
            CGRect(x: w * 0.8, y: cy - h * 0.3, width: w * 0.08, height: h * 0.6),
            CGRect(x: w * 0.72, y: cy - h * 0.25, width: w * 0.06, height: h * 0.5),
        ]

        for rect in plateRects + rightPlateRects {
            var plate = Path()
            plate.addRoundedRect(in: rect, cornerSize: CGSize(width: 2, height: 2))
            ctx.fill(plate, with: .color(fill))
            ctx.stroke(plate, with: .color(stroke), lineWidth: lineWidth)
        }
    }

    // MARK: - Dumbbell

    private func drawDumbbell(_ ctx: GraphicsContext, w: CGFloat, h: CGFloat, stroke: Color, fill: Color, lineWidth: CGFloat) {
        let cy = h * 0.5
        // Handle
        var handle = Path()
        handle.addRoundedRect(in: CGRect(x: w * 0.3, y: cy - 3, width: w * 0.4, height: 6), cornerSize: CGSize(width: 3, height: 3))
        ctx.fill(handle, with: .color(stroke))

        // Left weight
        var left = Path()
        left.addRoundedRect(in: CGRect(x: w * 0.15, y: cy - h * 0.28, width: w * 0.18, height: h * 0.56), cornerSize: CGSize(width: 4, height: 4))
        ctx.fill(left, with: .color(fill))
        ctx.stroke(left, with: .color(stroke), lineWidth: lineWidth)

        // Right weight
        var right = Path()
        right.addRoundedRect(in: CGRect(x: w * 0.67, y: cy - h * 0.28, width: w * 0.18, height: h * 0.56), cornerSize: CGSize(width: 4, height: 4))
        ctx.fill(right, with: .color(fill))
        ctx.stroke(right, with: .color(stroke), lineWidth: lineWidth)
    }

    // MARK: - Machine

    private func drawMachine(_ ctx: GraphicsContext, w: CGFloat, h: CGFloat, stroke: Color, fill: Color, lineWidth: CGFloat) {
        // Frame (vertical pillar)
        var frame = Path()
        frame.addRoundedRect(in: CGRect(x: w * 0.15, y: h * 0.08, width: w * 0.12, height: h * 0.84), cornerSize: CGSize(width: 3, height: 3))
        ctx.fill(frame, with: .color(fill))
        ctx.stroke(frame, with: .color(stroke), lineWidth: lineWidth)

        // Weight stack
        for i in 0..<5 {
            let y = h * 0.12 + CGFloat(i) * h * 0.1
            var plate = Path()
            plate.addRoundedRect(in: CGRect(x: w * 0.32, y: y, width: w * 0.28, height: h * 0.07), cornerSize: CGSize(width: 2, height: 2))
            ctx.fill(plate, with: .color(i < 3 ? fill : fill.opacity(0.5)))
            ctx.stroke(plate, with: .color(stroke.opacity(i < 3 ? 1 : 0.4)), lineWidth: 1)
        }

        // Seat
        var seat = Path()
        seat.addRoundedRect(in: CGRect(x: w * 0.4, y: h * 0.72, width: w * 0.45, height: h * 0.08), cornerSize: CGSize(width: 4, height: 4))
        ctx.fill(seat, with: .color(fill))
        ctx.stroke(seat, with: .color(stroke), lineWidth: lineWidth)

        // Back pad
        var pad = Path()
        pad.addRoundedRect(in: CGRect(x: w * 0.72, y: h * 0.35, width: w * 0.1, height: h * 0.38), cornerSize: CGSize(width: 4, height: 4))
        ctx.fill(pad, with: .color(fill))
        ctx.stroke(pad, with: .color(stroke), lineWidth: lineWidth)

        // Guide rail (connecting cable)
        var cable = Path()
        cable.move(to: CGPoint(x: w * 0.46, y: h * 0.12))
        cable.addLine(to: CGPoint(x: w * 0.46, y: h * 0.72))
        ctx.stroke(cable, with: .color(stroke.opacity(0.5)), lineWidth: 1)
    }

    // MARK: - Cable

    private func drawCable(_ ctx: GraphicsContext, w: CGFloat, h: CGFloat, stroke: Color, fill: Color, lineWidth: CGFloat) {
        // Top pulley housing
        var housing = Path()
        housing.addRoundedRect(in: CGRect(x: w * 0.3, y: h * 0.05, width: w * 0.4, height: h * 0.12), cornerSize: CGSize(width: 4, height: 4))
        ctx.fill(housing, with: .color(fill))
        ctx.stroke(housing, with: .color(stroke), lineWidth: lineWidth)

        // Pulley circle
        var pulley = Path()
        pulley.addEllipse(in: CGRect(x: w * 0.43, y: h * 0.07, width: w * 0.14, height: h * 0.08))
        ctx.stroke(pulley, with: .color(stroke), lineWidth: lineWidth)

        // Cable line
        var cable = Path()
        cable.move(to: CGPoint(x: w * 0.5, y: h * 0.17))
        cable.addLine(to: CGPoint(x: w * 0.5, y: h * 0.7))
        ctx.stroke(cable, with: .color(stroke), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))

        // Handle
        var handle = Path()
        handle.addRoundedRect(in: CGRect(x: w * 0.3, y: h * 0.7, width: w * 0.4, height: h * 0.06), cornerSize: CGSize(width: 3, height: 3))
        ctx.fill(handle, with: .color(fill))
        ctx.stroke(handle, with: .color(stroke), lineWidth: lineWidth)

        // Grip ends
        var leftGrip = Path()
        leftGrip.addRoundedRect(in: CGRect(x: w * 0.25, y: h * 0.68, width: w * 0.06, height: h * 0.1), cornerSize: CGSize(width: 2, height: 2))
        ctx.fill(leftGrip, with: .color(stroke))

        var rightGrip = Path()
        rightGrip.addRoundedRect(in: CGRect(x: w * 0.69, y: h * 0.68, width: w * 0.06, height: h * 0.1), cornerSize: CGSize(width: 2, height: 2))
        ctx.fill(rightGrip, with: .color(stroke))
    }

    // MARK: - Bodyweight

    private func drawBodyweight(_ ctx: GraphicsContext, w: CGFloat, h: CGFloat, stroke: Color, fill: Color, lineWidth: CGFloat) {
        let cx = w * 0.5
        // Head
        var head = Path()
        head.addEllipse(in: CGRect(x: cx - w * 0.08, y: h * 0.06, width: w * 0.16, height: h * 0.16))
        ctx.fill(head, with: .color(fill))
        ctx.stroke(head, with: .color(stroke), lineWidth: lineWidth)

        // Torso
        var torso = Path()
        torso.move(to: CGPoint(x: cx, y: h * 0.22))
        torso.addLine(to: CGPoint(x: cx, y: h * 0.55))
        ctx.stroke(torso, with: .color(stroke), lineWidth: lineWidth)

        // Arms (push-up pose, slightly out)
        var arms = Path()
        arms.move(to: CGPoint(x: cx - w * 0.25, y: h * 0.4))
        arms.addLine(to: CGPoint(x: cx, y: h * 0.3))
        arms.addLine(to: CGPoint(x: cx + w * 0.25, y: h * 0.4))
        ctx.stroke(arms, with: .color(stroke), lineWidth: lineWidth)

        // Legs
        var legs = Path()
        legs.move(to: CGPoint(x: cx - w * 0.15, y: h * 0.85))
        legs.addLine(to: CGPoint(x: cx, y: h * 0.55))
        legs.addLine(to: CGPoint(x: cx + w * 0.15, y: h * 0.85))
        ctx.stroke(legs, with: .color(stroke), lineWidth: lineWidth)

        // Feet
        var leftFoot = Path()
        leftFoot.addEllipse(in: CGRect(x: cx - w * 0.18, y: h * 0.83, width: w * 0.06, height: h * 0.06))
        ctx.fill(leftFoot, with: .color(stroke))
        var rightFoot = Path()
        rightFoot.addEllipse(in: CGRect(x: cx + w * 0.12, y: h * 0.83, width: w * 0.06, height: h * 0.06))
        ctx.fill(rightFoot, with: .color(stroke))
    }

    // MARK: - Band

    private func drawBand(_ ctx: GraphicsContext, w: CGFloat, h: CGFloat, stroke: Color, fill: Color, lineWidth: CGFloat) {
        // Elastic band loop shape
        var band = Path()
        band.move(to: CGPoint(x: w * 0.2, y: h * 0.3))
        band.addQuadCurve(to: CGPoint(x: w * 0.8, y: h * 0.3), control: CGPoint(x: w * 0.5, y: h * 0.05))
        band.addQuadCurve(to: CGPoint(x: w * 0.65, y: h * 0.7), control: CGPoint(x: w * 0.85, y: h * 0.5))
        band.addQuadCurve(to: CGPoint(x: w * 0.2, y: h * 0.3), control: CGPoint(x: w * 0.3, y: h * 0.55))
        ctx.fill(band, with: .color(fill))
        ctx.stroke(band, with: .color(stroke), lineWidth: lineWidth)

        // Stretch lines (indicating elasticity)
        for i in 0..<3 {
            let x = w * 0.35 + CGFloat(i) * w * 0.12
            var line = Path()
            line.move(to: CGPoint(x: x, y: h * 0.2))
            line.addLine(to: CGPoint(x: x + w * 0.04, y: h * 0.15))
            ctx.stroke(line, with: .color(stroke.opacity(0.4)), lineWidth: 1)
        }
    }

    // MARK: - Kettlebell

    private func drawKettlebell(_ ctx: GraphicsContext, w: CGFloat, h: CGFloat, stroke: Color, fill: Color, lineWidth: CGFloat) {
        let cx = w * 0.5

        // Handle (arc)
        var handle = Path()
        handle.addArc(center: CGPoint(x: cx, y: h * 0.28), radius: w * 0.18, startAngle: .degrees(200), endAngle: .degrees(340), clockwise: false)
        ctx.stroke(handle, with: .color(stroke), lineWidth: lineWidth + 1)

        // Body (bell shape — large circle)
        var body = Path()
        body.addEllipse(in: CGRect(x: cx - w * 0.25, y: h * 0.35, width: w * 0.5, height: h * 0.5))
        ctx.fill(body, with: .color(fill))
        ctx.stroke(body, with: .color(stroke), lineWidth: lineWidth)

        // Base flat
        var base = Path()
        base.addRoundedRect(in: CGRect(x: cx - w * 0.15, y: h * 0.8, width: w * 0.3, height: h * 0.06), cornerSize: CGSize(width: 3, height: 3))
        ctx.fill(base, with: .color(stroke.opacity(0.3)))
    }

    // MARK: - Other

    private func drawOther(_ ctx: GraphicsContext, w: CGFloat, h: CGFloat, stroke: Color, fill: Color, lineWidth: CGFloat) {
        let cx = w * 0.5
        let cy = h * 0.5

        // Question-mark style circle
        var circle = Path()
        circle.addEllipse(in: CGRect(x: cx - w * 0.25, y: cy - h * 0.25, width: w * 0.5, height: h * 0.5))
        ctx.fill(circle, with: .color(fill))
        ctx.stroke(circle, with: .color(stroke), lineWidth: lineWidth)

        // Ellipsis dots
        for i in 0..<3 {
            let dotX = cx - w * 0.1 + CGFloat(i) * w * 0.1
            var dot = Path()
            dot.addEllipse(in: CGRect(x: dotX - 3, y: cy - 3, width: 6, height: 6))
            ctx.fill(dot, with: .color(stroke))
        }
    }
}

// MARK: - Previews

#Preview("All Equipment") {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 16) {
        ForEach(Equipment.allCases, id: \.self) { equipment in
            VStack(spacing: 8) {
                EquipmentIllustrationView(equipment: equipment, size: 70)
                Text(equipment.localizedDisplayName)
                    .font(.caption2)
            }
        }
    }
    .padding()
}
