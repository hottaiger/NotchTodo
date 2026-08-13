import SwiftUI

/// 像素苹果：经典 8-bit 造型（红果身 + 茎 + 双叶 + 高光）。
/// 动画：整体游漂 + 收起抖动（苹果不摆尾）。
struct AppleView: View {
    static let collapseShakeDelay: TimeInterval = 0.5
    let collapseAnimationID: UInt
    let shouldReduceMotion: Bool
    @State private var shakeOffset: CGFloat = 0
    @State private var swimBob: CGFloat = 0
    @State private var shakeWorkItems: [DispatchWorkItem] = []

    private static let red = Color(red: 0.88, green: 0.23, blue: 0.23)
    private static let hi = Color(red: 0.98, green: 0.75, blue: 0.72)
    private static let stem = Color(red: 0.55, green: 0.35, blue: 0.15)
    private static let leaf = Color(red: 0.30, green: 0.72, blue: 0.32)

    private static let pixels: [(CGFloat, CGFloat, Color)] = [
        // 叶
        (10, 4, leaf), (12, 4, leaf),
        (8, 6, leaf), (10, 6, leaf), (12, 6, leaf), (14, 6, leaf),
        // 茎
        (4, 8, stem), (6, 8, stem),
        // 果身
        (8, 10, red), (10, 10, red), (12, 10, red), (14, 10, red), (16, 10, red),
        (4, 12, red), (6, 12, red), (8, 12, red), (10, 12, red), (12, 12, red), (14, 12, red), (16, 12, red), (18, 12, red),
        (2, 14, red), (4, 14, red), (6, 14, red), (8, 14, red), (10, 14, red), (12, 14, red), (14, 14, red), (16, 14, red), (18, 14, red), (20, 14, red),
        (2, 16, red), (4, 16, red), (6, 16, hi), (8, 16, red), (10, 16, red), (12, 16, red), (14, 16, red), (16, 16, red), (18, 16, red), (20, 16, red),
        (2, 18, red), (4, 18, red), (6, 18, red), (8, 18, red), (10, 18, red), (12, 18, red), (14, 18, red), (16, 18, red), (18, 18, red), (20, 18, red),
        (2, 20, red), (4, 20, red), (6, 20, red), (8, 20, red), (10, 20, red), (12, 20, red), (14, 20, red), (16, 20, red), (18, 20, red), (20, 20, red),
        (4, 22, red), (6, 22, red), (8, 22, red), (10, 22, red), (12, 22, red), (14, 22, red), (16, 22, red), (18, 22, red),
        (6, 24, red), (8, 24, red), (10, 24, red), (12, 24, red), (14, 24, red), (16, 24, red)
    ]

    var body: some View {
        Canvas { context, _ in
            for p in Self.pixels {
                context.fill(Path(CGRect(x: p.0, y: p.1, width: 2, height: 2)), with: .color(p.2))
            }
        }
        .frame(width: 28, height: 28)
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

    private func startSwim() {
        guard !shouldReduceMotion else { return }
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
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
