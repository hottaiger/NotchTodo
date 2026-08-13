import SwiftUI

/// 矢量像素鱼：用贝塞尔曲线画一条流线型侧视鱼（头朝右）。
/// 保持 Canvas 绘制（矢量，任意尺寸清晰），动画：整体游漂 + 尾鳍摆动 + 收起抖动。
struct PixelFishView: View {
    static let collapseShakeDelay: TimeInterval = 0.5
    let collapseAnimationID: UInt
    let shouldReduceMotion: Bool
    @State private var shakeOffset: CGFloat = 0
    @State private var swimBob: CGFloat = 0
    @State private var tailWag = false
    @State private var shakeWorkItems: [DispatchWorkItem] = []

    private static let bodyMid = Color(red: 0.33, green: 0.85, blue: 0.82)
    private static let bodyLight = Color(red: 0.60, green: 1.00, blue: 0.93)
    private static let finDark = Color(red: 0.19, green: 0.50, blue: 0.58)
    private static let bodyTail = Color.white
    private static let eye = Color(red: 0.06, green: 0.15, blue: 0.16)

    var body: some View {
        Canvas { context, size in
            let w = size.width, h = size.height
            // 尾鳍摆动：tailWag 时上下尖反向偏移（reduce motion 时归位）
            let flip: CGFloat = shouldReduceMotion ? 0 : (tailWag ? 1 : -1)
            // 尾鳍（V 形分叉，白色）
            let tail = Path { p in
                p.move(to: CGPoint(x: 0.27 * w, y: 0.5 * h))
                p.addLine(to: CGPoint(x: 0.02 * w, y: (0.26 + 0.05 * flip) * h))
                p.addLine(to: CGPoint(x: 0.15 * w, y: 0.5 * h))
                p.addLine(to: CGPoint(x: 0.02 * w, y: (0.74 + 0.05 * flip) * h))
                p.closeSubpath()
            }
            context.fill(tail, with: .color(Self.bodyTail))
            // 身体（流线型，头朝右）
            let body = Path { p in
                p.move(to: CGPoint(x: 0.22 * w, y: 0.5 * h))
                p.addCurve(to: CGPoint(x: 0.52 * w, y: 0.16 * h), control1: CGPoint(x: 0.26 * w, y: 0.32 * h), control2: CGPoint(x: 0.38 * w, y: 0.16 * h))
                p.addCurve(to: CGPoint(x: 0.9 * w, y: 0.5 * h), control1: CGPoint(x: 0.78 * w, y: 0.16 * h), control2: CGPoint(x: 0.9 * w, y: 0.36 * h))
                p.addCurve(to: CGPoint(x: 0.52 * w, y: 0.84 * h), control1: CGPoint(x: 0.9 * w, y: 0.64 * h), control2: CGPoint(x: 0.78 * w, y: 0.84 * h))
                p.addCurve(to: CGPoint(x: 0.22 * w, y: 0.5 * h), control1: CGPoint(x: 0.38 * w, y: 0.84 * h), control2: CGPoint(x: 0.26 * w, y: 0.68 * h))
                p.closeSubpath()
            }
            context.fill(body, with: .color(Self.bodyMid))
            // 背部高光（细月牙）
            let sheen = Path { p in
                p.move(to: CGPoint(x: 0.30 * w, y: 0.32 * h))
                p.addCurve(to: CGPoint(x: 0.60 * w, y: 0.24 * h), control1: CGPoint(x: 0.42 * w, y: 0.30 * h), control2: CGPoint(x: 0.50 * w, y: 0.24 * h))
                p.addCurve(to: CGPoint(x: 0.50 * w, y: 0.34 * h), control1: CGPoint(x: 0.55 * w, y: 0.26 * h), control2: CGPoint(x: 0.45 * w, y: 0.32 * h))
                p.closeSubpath()
            }
            context.fill(sheen, with: .color(Self.bodyLight))
            // 背鳍
            let dorsal = Path { p in
                p.move(to: CGPoint(x: 0.38 * w, y: 0.19 * h))
                p.addLine(to: CGPoint(x: 0.40 * w, y: 0.04 * h))
                p.addLine(to: CGPoint(x: 0.58 * w, y: 0.17 * h))
                p.closeSubpath()
            }
            context.fill(dorsal, with: .color(Self.finDark))
            // 腹鳍
            let ventral = Path { p in
                p.move(to: CGPoint(x: 0.44 * w, y: 0.81 * h))
                p.addLine(to: CGPoint(x: 0.46 * w, y: 0.96 * h))
                p.addLine(to: CGPoint(x: 0.60 * w, y: 0.83 * h))
                p.closeSubpath()
            }
            context.fill(ventral, with: .color(Self.finDark))
            // 眼睛
            context.fill(Path(ellipseIn: CGRect(x: 0.70 * w, y: 0.40 * h, width: 0.10 * w, height: 0.12 * h)), with: .color(Self.eye))
        }
        .frame(width: 34, height: 22)
        .offset(y: swimBob)
        .offset(x: shakeOffset)
        .accessibilityHidden(true)
        .onAppear {
            startAnimations()
            if collapseAnimationID > 0 { shakeIfAllowed() }
        }
        .onChange(of: collapseAnimationID) { _, _ in
            shakeIfAllowed()
        }
        .onDisappear {
            cancelShake()
        }
    }

    /// 整体上下游漂 + 尾鳍摆动（两态往返）。
    private func startAnimations() {
        guard !shouldReduceMotion else { return }
        withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
            swimBob = -2
        }
        withAnimation(.easeInOut(duration: 0.30).repeatForever(autoreverses: true)) {
            tailWag = true
        }
    }

    private func shakeIfAllowed() {
        cancelShake()
        guard !shouldReduceMotion else { return }

        scheduleShake(offset: -2, after: Self.collapseShakeDelay, duration: 0.045)
        scheduleShake(offset: 2, after: Self.collapseShakeDelay + 0.045, duration: 0.055)
        scheduleShake(offset: -1, after: Self.collapseShakeDelay + 0.10, duration: 0.04)
        scheduleShake(offset: 0, after: Self.collapseShakeDelay + 0.14, duration: 0.04)
    }

    private func scheduleShake(offset: CGFloat, after delay: TimeInterval, duration: TimeInterval) {
        let workItem = DispatchWorkItem {
            withAnimation(.linear(duration: duration)) {
                shakeOffset = offset
            }
        }
        shakeWorkItems.append(workItem)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func cancelShake() {
        shakeWorkItems.forEach { $0.cancel() }
        shakeWorkItems.removeAll()
        shakeOffset = 0
    }
}
