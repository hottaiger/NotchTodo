import SwiftUI

struct PixelFishView: View {
    static let collapseShakeDelay: TimeInterval = 0.5
    let collapseAnimationID: UInt
    let shouldReduceMotion: Bool
    @State private var shakeOffset: CGFloat = 0
    @State private var swimBob: CGFloat = 0
    @State private var shakeWorkItems: [DispatchWorkItem] = []

    /// 尾巴逐帧摆动的相位（像素艺术风格，不做插值）。
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
                // 尾鳍像素（x <= 4，鱼尾在左）按相位上下摆动，身体和头部保持不动。
                let y = pixel.y + (pixel.x <= 4 ? phase.tailDelta * 2 : 0)
                context.fill(Path(CGRect(x: pixel.x, y: y, width: 4, height: 4)), with: .color(pixel.color))
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

    private static let pixels: [(x: CGFloat, y: CGFloat, color: Color)] = [
        (0, 4, Color(red: 0.19, green: 0.50, blue: 0.58)),
        (0, 8, Color(red: 0.19, green: 0.50, blue: 0.58)),
        (4, 0, Color(red: 0.19, green: 0.50, blue: 0.58)),
        (4, 4, Color(red: 0.19, green: 0.50, blue: 0.58)),
        (4, 8, Color(red: 0.19, green: 0.50, blue: 0.58)),
        (4, 12, Color(red: 0.19, green: 0.50, blue: 0.58)),
        (8, 4, Color(red: 0.33, green: 0.85, blue: 0.82)),
        (8, 8, Color(red: 0.33, green: 0.85, blue: 0.82)),
        (12, 0, Color(red: 0.33, green: 0.85, blue: 0.82)),
        (12, 4, Color(red: 0.60, green: 1.00, blue: 0.93)),
        (12, 8, Color(red: 0.60, green: 1.00, blue: 0.93)),
        (12, 12, Color(red: 0.33, green: 0.85, blue: 0.82)),
        (16, 0, Color(red: 0.33, green: 0.85, blue: 0.82)),
        (16, 4, Color(red: 0.33, green: 0.85, blue: 0.82)),
        (16, 8, Color(red: 0.33, green: 0.85, blue: 0.82)),
        (16, 12, Color(red: 0.33, green: 0.85, blue: 0.82)),
        (20, 4, Color(red: 0.06, green: 0.15, blue: 0.16)),
        (20, 8, Color(red: 0.33, green: 0.85, blue: 0.82)),
        (24, 4, Color(red: 0.33, green: 0.85, blue: 0.82)),
        (24, 8, Color(red: 0.33, green: 0.85, blue: 0.82))
    ]
}
