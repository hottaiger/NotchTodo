import SwiftUI

struct PixelFishView: View {
    static let collapseShakeDelay: TimeInterval = 0.5
    let collapseAnimationID: UInt
    let shouldReduceMotion: Bool
    @State private var shakeOffset: CGFloat = 0
    @State private var swimBob: CGFloat = 0
    @State private var tailWag = false
    @State private var shakeWorkItems: [DispatchWorkItem] = []

    var body: some View {
        Canvas { context, _ in
            // 尾鳍（x <= 4，鱼尾在左）按 tailWag 上下摆动；reduce motion 时归位。
            let tailDelta: CGFloat = shouldReduceMotion ? 0 : (tailWag ? -2 : 2)
            for pixel in Self.pixels {
                let y = pixel.y + (pixel.x <= 4 ? tailDelta : 0)
                context.fill(Path(CGRect(x: pixel.x, y: y, width: 2, height: 2)), with: .color(pixel.color))
            }
        }
        .frame(width: 28, height: 16)
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

    /// 整体上下游漂 + 尾鳍逐帧摆动（两态往返）。
    private func startAnimations() {
        guard !shouldReduceMotion else { return }
        withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
            swimBob = -2
        }
        withAnimation(.easeInOut(duration: 0.28).repeatForever(autoreverses: true)) {
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

    // 经典侧视像素鱼（朝右，尾在左）："<" 形尾（白色，上下尖连身）+ 流线身体（背亮→腹深）+ 眼睛 + 背腹鳍。
    private static let bodyLight = Color(red: 0.60, green: 1.00, blue: 0.93)
    private static let bodyMid = Color(red: 0.33, green: 0.85, blue: 0.82)
    private static let bodyDark = Color(red: 0.19, green: 0.50, blue: 0.58)
    private static let bodyTail = Color.white
    private static let eye = Color(red: 0.06, green: 0.15, blue: 0.16)

    private static let pixels: [(x: CGFloat, y: CGFloat, color: Color)] = [
        // 背鳍
        (18, 0, bodyLight), (20, 0, bodyLight),
        // 尾上尖 + 身体上（亮）
        (0, 2, bodyTail),
        (6, 2, bodyLight), (8, 2, bodyLight), (10, 2, bodyLight), (12, 2, bodyLight), (14, 2, bodyLight), (16, 2, bodyLight), (18, 2, bodyLight), (20, 2, bodyLight), (22, 2, bodyLight),
        // 尾（连身）+ 身体中 + 眼睛 + 嘴
        (0, 4, bodyTail), (2, 4, bodyTail), (4, 4, bodyTail),
        (6, 4, bodyMid), (8, 4, bodyMid), (10, 4, bodyMid), (12, 4, bodyMid), (14, 4, eye), (16, 4, bodyMid), (18, 4, bodyMid), (20, 4, bodyMid), (22, 4, bodyMid), (24, 4, bodyMid),
        // 尾下尖 + 身体腹（深）
        (0, 6, bodyTail),
        (6, 6, bodyDark), (8, 6, bodyDark), (10, 6, bodyDark), (12, 6, bodyDark), (14, 6, bodyDark), (16, 6, bodyDark), (18, 6, bodyDark), (20, 6, bodyDark), (22, 6, bodyDark),
        // 腹鳍
        (18, 8, bodyMid), (20, 8, bodyMid)
    ]
}
