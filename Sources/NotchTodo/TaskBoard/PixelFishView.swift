import SwiftUI

struct PixelFishView: View {
    static let collapseShakeDelay: TimeInterval = 0.5
    let collapseAnimationID: UInt
    let shouldReduceMotion: Bool
    @State private var shakeOffset: CGFloat = 0
    @State private var swimBob: CGFloat = 0
    @State private var shakeWorkItems: [DispatchWorkItem] = []

    /// 尾鳍逐帧摆动的相位（像素艺术风格，不做插值）。
    private enum SwimPhase: CaseIterable {
        case tailUp, center, tailDown
        var tailDelta: CGFloat {
            switch self {
            case .tailUp: -1
            case .center: 0
            case .tailDown: 1
            }
        }
    }

    var body: some View {
        fishLayer
            .frame(width: 28, height: 16)
            .offset(y: swimBob)
            .offset(x: shakeOffset)
            .accessibilityHidden(true)
            .onAppear {
                startSwim()
                if collapseAnimationID > 0 { shakeIfAllowed() }
            }
            .onChange(of: collapseAnimationID) { _, _ in
                shakeIfAllowed()
            }
            .onDisappear {
                cancelShake()
            }
    }

    @ViewBuilder
    private var fishLayer: some View {
        if shouldReduceMotion {
            fishCanvas(tail: .center)
        } else {
            PhaseAnimator([SwimPhase.tailUp, .center, .tailDown, .center]) { phase in
                fishCanvas(tail: phase)
            } animation: { _ in
                .linear(duration: 0.28)
            }
        }
    }

    private func fishCanvas(tail phase: SwimPhase) -> some View {
        Canvas { context, _ in
            for pixel in Self.pixels {
                // 尾鳍（x <= 4，鱼尾在左）按相位上下摆动，身体和头部保持不动。
                let y = pixel.y + (pixel.x <= 4 ? phase.tailDelta * 2 : 0)
                context.fill(Path(CGRect(x: pixel.x, y: y, width: 2, height: 2)), with: .color(pixel.color))
            }
        }
    }

    /// 整体上下游漂（连续动画），让小鱼看起来在水中游动。
    private func startSwim() {
        guard !shouldReduceMotion else { return }
        withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
            swimBob = -2
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

    // 像素鱼（朝右，尾在左）：V 形尾鳍 + 背鳍/腹鳍 + 流线身体（背亮→腹深）+ 眼睛 + 嘴。
    private static let bodyLight = Color(red: 0.60, green: 1.00, blue: 0.93)
    private static let bodyMid = Color(red: 0.33, green: 0.85, blue: 0.82)
    private static let bodyDark = Color(red: 0.19, green: 0.50, blue: 0.58)
    private static let eye = Color(red: 0.06, green: 0.15, blue: 0.16)

    private static let pixels: [(x: CGFloat, y: CGFloat, color: Color)] = [
        // 背鳍
        (12, 0, bodyLight), (14, 0, bodyLight),
        // 身体上（亮）
        (6, 2, bodyLight), (8, 2, bodyLight), (10, 2, bodyLight), (12, 2, bodyLight),
        (14, 2, bodyLight), (16, 2, bodyLight), (18, 2, bodyLight), (20, 2, bodyLight),
        // 尾鳍上 + 身体中 + 眼睛 + 身体中
        (2, 4, bodyMid), (4, 4, bodyMid),
        (6, 4, bodyLight), (8, 4, bodyLight), (10, 4, bodyLight), (12, 4, bodyLight),
        (14, 4, eye),
        (16, 4, bodyMid), (18, 4, bodyMid), (20, 4, bodyMid), (22, 4, bodyMid),
        // 尾尖 + 尾鳍中 + 身体中 + 嘴
        (0, 6, bodyMid), (2, 6, bodyMid), (4, 6, bodyMid),
        (6, 6, bodyMid), (8, 6, bodyMid), (10, 6, bodyMid), (12, 6, bodyMid),
        (14, 6, bodyMid), (16, 6, bodyMid), (18, 6, bodyMid), (20, 6, bodyMid), (22, 6, bodyMid),
        (24, 6, bodyMid),
        // 尾鳍下 + 身体下（深）
        (2, 8, bodyMid), (4, 8, bodyMid),
        (6, 8, bodyDark), (8, 8, bodyDark), (10, 8, bodyDark), (12, 8, bodyDark),
        (14, 8, bodyDark), (16, 8, bodyDark), (18, 8, bodyDark), (20, 8, bodyDark), (22, 8, bodyDark),
        // 身体下（深）
        (6, 10, bodyDark), (8, 10, bodyDark), (10, 10, bodyDark), (12, 10, bodyDark),
        (14, 10, bodyDark), (16, 10, bodyDark), (18, 10, bodyDark), (20, 10, bodyDark),
        // 腹鳍
        (12, 12, bodyMid), (14, 12, bodyMid)
    ]
}
