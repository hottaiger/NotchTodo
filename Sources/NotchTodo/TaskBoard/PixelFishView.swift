import SwiftUI

/// 经典 8-bit 侧视像素鱼（头朝右，尾在左）：椭圆身（背亮→腹深）+ 青绿尾鳍（上下叶连身）。
/// 动画：整体游漂 + 尾鳍逐帧摆动 + 收起抖动。
struct PixelFishView: View {
    static let collapseShakeDelay: TimeInterval = 0.5
    let collapseAnimationID: UInt
    let shouldReduceMotion: Bool
    @State private var shakeOffset: CGFloat = 0
    @State private var swimBob: CGFloat = 0
    @State private var shakeWorkItems: [DispatchWorkItem] = []

    private static let bodyLight = Color(red: 0.60, green: 1.00, blue: 0.93)
    private static let bodyMid = Color(red: 0.33, green: 0.85, blue: 0.82)
    private static let bodyDark = Color(red: 0.19, green: 0.50, blue: 0.58)
    private static let eye = Color(red: 0.06, green: 0.15, blue: 0.16)
    private static let fin = Color(red: 0.19, green: 0.50, blue: 0.58)

    private static let pixels: [(CGFloat, CGFloat, Color)] = [
        // 背鳍 r1
        (12, 2, fin), (14, 2, fin), (16, 2, fin),
        // r2 身上(亮)
        (8, 4, bodyLight), (10, 4, bodyLight), (12, 4, bodyLight), (14, 4, bodyLight), (16, 4, bodyLight), (18, 4, bodyLight), (20, 4, bodyLight), (22, 4, bodyLight),
        // r3 尾上叶 + 身(亮)
        (0, 6, bodyMid), (2, 6, bodyMid),
        (6, 6, bodyLight), (8, 6, bodyLight), (10, 6, bodyLight), (12, 6, bodyLight), (14, 6, bodyLight), (16, 6, bodyLight), (18, 6, bodyLight), (20, 6, bodyLight), (22, 6, bodyLight), (24, 6, bodyLight),
        // r4 尾(连身) + 身(中) + 眼(右移) + 嘴
        (0, 8, bodyMid), (2, 8, bodyMid), (4, 8, bodyMid),
        (6, 8, bodyMid), (8, 8, bodyMid), (10, 8, bodyMid), (12, 8, bodyMid), (16, 8, bodyMid), (18, 8, bodyMid), (20, 8, eye), (22, 8, bodyMid), (24, 8, bodyMid), (26, 8, bodyMid),
        // r5 尾下叶 + 身(腹深)
        (0, 10, bodyMid), (2, 10, bodyMid),
        (6, 10, bodyDark), (8, 10, bodyDark), (10, 10, bodyDark), (12, 10, bodyDark), (14, 10, bodyDark), (16, 10, bodyDark), (18, 10, bodyDark), (20, 10, bodyDark), (22, 10, bodyDark), (24, 10, bodyDark),
        // r6 身下(深)
        (8, 12, bodyDark), (10, 12, bodyDark), (12, 12, bodyDark), (14, 12, bodyDark), (16, 12, bodyDark), (18, 12, bodyDark), (20, 12, bodyDark), (22, 12, bodyDark),
        // 腹鳍 r7
        (12, 14, fin), (14, 14, fin), (16, 14, fin)
    ]

    var body: some View {
        Canvas { context, _ in
            for pixel in Self.pixels {
                context.fill(Path(CGRect(x: pixel.0, y: pixel.1, width: 2, height: 2)), with: .color(pixel.2))
            }
        }
        .frame(width: 32, height: 18)
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

    private func startAnimations() {
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
}
