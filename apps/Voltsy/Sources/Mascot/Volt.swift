// apps/Voltsy/Sources/Mascot/Volt.swift
// Volt — the Voltsy mascot, drawn as a parametric SwiftUI vector (no external tool).
// The translucent body fill IS the battery level; expression + tint follow VoltState.
// First visual cut; lives in the app target while we iterate, then moves to a VoltMascot package.
import SwiftUI
import VoltsyCore

// MARK: - Palette (HealthTint -> colors)

private struct VoltPalette {
    let fillTop: Color, fillBottom: Color, glow: Color
    static func forTint(_ tint: HealthTint) -> VoltPalette {
        switch tint {
        case .green: VoltPalette(fillTop: Color(red: 0.47, green: 0.86, blue: 0.47),
                                 fillBottom: Color(red: 0.20, green: 0.70, blue: 0.37),
                                 glow: Color(red: 0.69, green: 0.99, blue: 0.62))
        case .amber: VoltPalette(fillTop: Color(red: 1.00, green: 0.82, blue: 0.36),
                                 fillBottom: Color(red: 0.96, green: 0.61, blue: 0.15),
                                 glow: Color(red: 1.00, green: 0.90, blue: 0.55))
        case .red:   VoltPalette(fillTop: Color(red: 1.00, green: 0.51, blue: 0.45),
                                 fillBottom: Color(red: 0.89, green: 0.26, blue: 0.28),
                                 glow: Color(red: 1.00, green: 0.63, blue: 0.57))
        }
    }
}

private let inkColor = Color(red: 0.15, green: 0.19, blue: 0.25)

// MARK: - VoltView

public struct VoltView: View {
    public let state: VoltState
    public var size: CGFloat

    public init(state: VoltState, size: CGFloat = 220) {
        self.state = state
        self.size = size
    }

    private var p: VoltPalette { .forTint(state.tint) }
    private var mood: VoltMood { state.mood }
    private var bodyW: CGFloat { size * 0.60 }
    private var bodyH: CGFloat { size * 0.80 }
    private var corner: CGFloat { bodyW * 0.42 }
    private var fill: CGFloat { max(0.04, min(1.0, CGFloat(state.bellyFill))) }

    public var body: some View {
        ZStack {
            Ellipse().fill(Color.black.opacity(0.08))
                .frame(width: bodyW * 0.92, height: bodyW * 0.16)
                .offset(y: bodyH * 0.56)
            legs
            arms
            bodyShell
            face.offset(y: -bodyH * 0.07)
            accessory
        }
        .frame(width: size, height: size)
        .rotationEffect(.degrees(mood == .critical ? 7 : 0))
    }

    // MARK: Body shell + belly fill + terminal nub

    private var bodyShell: some View {
        let shape = RoundedRectangle(cornerRadius: corner, style: .continuous)
        return ZStack {
            RoundedRectangle(cornerRadius: bodyW * 0.09)
                .fill(Color(red: 0.82, green: 0.86, blue: 0.90))
                .frame(width: bodyW * 0.30, height: bodyH * 0.075)
                .offset(y: -bodyH * 0.525)
            ZStack(alignment: .bottom) {
                shape.fill(Color(red: 0.96, green: 0.98, blue: 0.99))
                LinearGradient(colors: [p.fillTop, p.fillBottom], startPoint: .top, endPoint: .bottom)
                    .frame(width: bodyW, height: bodyH * fill)
                    .overlay(alignment: .top) {
                        Rectangle().fill(p.glow).frame(height: 3).blur(radius: 1)
                    }
            }
            .frame(width: bodyW, height: bodyH)
            .clipShape(shape)
            shape.strokeBorder(inkColor.opacity(0.22), lineWidth: 3)
            Capsule().fill(Color.white.opacity(0.35))
                .frame(width: bodyW * 0.13, height: bodyH * 0.40)
                .rotationEffect(.degrees(9))
                .offset(x: -bodyW * 0.24, y: -bodyH * 0.07)
                .blur(radius: 2)
        }
        .frame(width: bodyW, height: bodyH)
    }

    // MARK: Face

    private var face: some View {
        let eyeW = bodyW * 0.21
        let gap = bodyW * 0.18
        return VStack(spacing: bodyH * 0.03) {
            ZStack {
                HStack(spacing: gap) { eye(eyeW); eye(eyeW) }
                if mood == .energetic || mood == .charging || mood == .content {
                    HStack(spacing: gap + eyeW * 1.1) {
                        cheek; cheek
                    }
                    .offset(y: eyeW * 0.7)
                }
            }
            mouth.frame(width: bodyW * 0.34, height: bodyH * 0.13)
        }
    }

    private var cheek: some View {
        Circle().fill(Color(red: 1.0, green: 0.6, blue: 0.62).opacity(0.6))
            .frame(width: bodyW * 0.12, height: bodyW * 0.09)
    }

    @ViewBuilder private func eye(_ w: CGFloat) -> some View {
        switch mood {
        case .charging, .zen, .content:
            ArcEye().stroke(inkColor, style: .init(lineWidth: w * 0.20, lineCap: .round))
                .frame(width: w, height: w * 0.55)
        case .critical:
            XEye().stroke(inkColor, style: .init(lineWidth: w * 0.18, lineCap: .round))
                .frame(width: w * 0.9, height: w * 0.9)
        case .tired:
            ZStack(alignment: .bottom) {
                Ellipse().fill(Color.white).frame(width: w, height: w)
                Circle().fill(inkColor).frame(width: w * 0.5, height: w * 0.5)
            }
            .frame(width: w, height: w * 0.5, alignment: .bottom)
            .clipped()
            .overlay(alignment: .top) {
                Capsule().fill(inkColor).frame(width: w, height: w * 0.13)
            }
        case .overcharged, .overheating:
            ZStack {
                Ellipse().fill(Color.white).frame(width: w, height: w * 0.85)
                Circle().fill(inkColor).frame(width: w * 0.42, height: w * 0.42)
            }
        default:
            ZStack {
                Ellipse().fill(Color.white).frame(width: w, height: w * 1.05)
                Circle().fill(inkColor).frame(width: w * 0.55, height: w * 0.55).offset(y: w * 0.05)
                Circle().fill(Color.white).frame(width: w * 0.20, height: w * 0.20)
                    .offset(x: -w * 0.12, y: -w * 0.08)
            }
        }
    }

    @ViewBuilder private var mouth: some View {
        switch mood {
        case .energetic, .charging:
            OpenMouth().fill(Color(red: 0.52, green: 0.20, blue: 0.22))
        case .content, .zen:
            Smile().stroke(inkColor, style: .init(lineWidth: bodyW * 0.035, lineCap: .round))
                .frame(height: bodyH * 0.05)
        case .tired:
            Circle().fill(Color(red: 0.52, green: 0.20, blue: 0.22))
                .frame(width: bodyW * 0.12, height: bodyW * 0.14)
        case .critical, .overcharged, .overheating:
            Wavy().stroke(inkColor, style: .init(lineWidth: bodyW * 0.035, lineCap: .round))
                .frame(height: bodyH * 0.05)
        default:
            Smile().stroke(inkColor, style: .init(lineWidth: bodyW * 0.035, lineCap: .round))
                .frame(height: bodyH * 0.05)
        }
    }

    // MARK: Limbs

    private var arms: some View {
        let armL = bodyH * 0.30
        let up = mood == .energetic || mood == .charging
        return HStack {
            Capsule().fill(Color(red: 0.86, green: 0.89, blue: 0.92))
                .frame(width: armL * 0.32, height: armL)
                .rotationEffect(.degrees(up ? -35 : (mood == .tired ? 18 : -8)), anchor: .top)
                .offset(x: -bodyW * 0.04, y: up ? -bodyH * 0.05 : bodyH * 0.05)
            Spacer()
            Capsule().fill(Color(red: 0.86, green: 0.89, blue: 0.92))
                .frame(width: armL * 0.32, height: armL)
                .rotationEffect(.degrees(up ? 35 : (mood == .tired ? -18 : 8)), anchor: .top)
                .offset(x: bodyW * 0.04, y: up ? -bodyH * 0.05 : bodyH * 0.05)
        }
        .frame(width: bodyW * 1.35)
    }

    private var legs: some View {
        HStack(spacing: bodyW * 0.18) {
            Capsule().fill(inkColor.opacity(0.85)).frame(width: bodyW * 0.16, height: bodyH * 0.14)
            Capsule().fill(inkColor.opacity(0.85)).frame(width: bodyW * 0.16, height: bodyH * 0.14)
        }
        .offset(y: bodyH * 0.50)
    }

    // MARK: Mood accessories

    @ViewBuilder private var accessory: some View {
        switch mood {
        case .overheating:
            SweatDrop().fill(Color(red: 0.45, green: 0.78, blue: 0.98))
                .frame(width: bodyW * 0.12, height: bodyW * 0.18)
                .offset(x: bodyW * 0.34, y: -bodyH * 0.18)
        case .energetic:
            HStack(spacing: bodyW * 1.0) { spark; spark }
                .offset(y: -bodyH * 0.42)
        case .zen:
            Text("z z z").font(.system(size: size * 0.07, weight: .bold))
                .foregroundStyle(inkColor.opacity(0.5))
                .offset(x: bodyW * 0.4, y: -bodyH * 0.4)
        case .charging:
            Image(systemName: "bolt.fill").font(.system(size: size * 0.10))
                .foregroundStyle(Color.yellow)
                .offset(x: bodyW * 0.44, y: -bodyH * 0.02)
        default:
            EmptyView()
        }
    }

    private var spark: some View {
        Image(systemName: "sparkle").font(.system(size: size * 0.07))
            .foregroundStyle(p.glow)
    }
}

// MARK: - Shapes

private struct ArcEye: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY), control: CGPoint(x: r.midX, y: r.minY))
        return p
    }
}

private struct XEye: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY)); p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.move(to: CGPoint(x: r.maxX, y: r.minY)); p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        return p
    }
}

private struct Smile: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY), control: CGPoint(x: r.midX, y: r.maxY * 1.6))
        return p
    }
}

private struct Wavy: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let step = r.width / 4
        p.move(to: CGPoint(x: r.minX, y: r.midY))
        p.addQuadCurve(to: CGPoint(x: r.minX + step * 2, y: r.midY),
                       control: CGPoint(x: r.minX + step, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.midY),
                       control: CGPoint(x: r.minX + step * 3, y: r.maxY))
        return p
    }
}

private struct OpenMouth: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.addEllipse(in: CGRect(x: r.midX - r.width * 0.28, y: r.minY,
                                width: r.width * 0.56, height: r.height))
        return p
    }
}

private struct SweatDrop: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY * 0.7), control: CGPoint(x: r.maxX, y: r.midY))
        p.addArc(center: CGPoint(x: r.midX, y: r.maxY * 0.72), radius: r.width * 0.5,
                 startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.minY), control: CGPoint(x: r.minX, y: r.midY))
        return p
    }
}
