import SwiftUI

struct PixelFishView: View {
    static let collapseShakeDelay: TimeInterval = 0.5
    static let bubbleCooldown: TimeInterval = 15
    static let bubbleSequenceDuration: TimeInterval = 3
    let collapseAnimationID: UInt
    let shouldReduceMotion: Bool
    @State private var horizontalOffset: CGFloat = 0
    @State private var shakeWorkItems: [DispatchWorkItem] = []
    @State private var bubbleProgress: CGFloat = 0
    @State private var bubbleWorkItem: DispatchWorkItem?

    var body: some View {
        Canvas { context, _ in
            for pixel in Self.pixels {
                context.fill(
                    Path(CGRect(x: pixel.x, y: pixel.y, width: 4, height: 4)),
                    with: .color(pixel.color)
                )
            }
            for bubble in Self.bubbles(progress: bubbleProgress) {
                context.fill(
                    Path(CGRect(x: bubble.x, y: bubble.y, width: 4, height: 4)),
                    with: .color(Color(red: 0.72, green: 1, blue: 0.98).opacity(bubble.opacity))
                )
            }
        }
        .frame(width: 28, height: 16)
        .offset(x: horizontalOffset)
        .accessibilityHidden(true)
        .onChange(of: collapseAnimationID) { _, _ in
            shakeIfAllowed()
        }
        .onAppear {
            if collapseAnimationID > 0 { shakeIfAllowed() }
            startBubblesIfAllowed()
        }
        .onDisappear {
            cancelShake()
            cancelBubbles()
        }
    }

    static func shouldAnimateBubbles(shouldReduceMotion: Bool) -> Bool {
        !shouldReduceMotion
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
                horizontalOffset = offset
            }
        }
        shakeWorkItems.append(workItem)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func cancelShake() {
        shakeWorkItems.forEach { $0.cancel() }
        shakeWorkItems.removeAll()
        horizontalOffset = 0
    }

    private func startBubblesIfAllowed() {
        cancelBubbles()
        guard Self.shouldAnimateBubbles(shouldReduceMotion: shouldReduceMotion) else { return }
        emitBubbleSequence()
    }

    private func emitBubbleSequence() {
        bubbleProgress = 0
        withAnimation(.linear(duration: Self.bubbleSequenceDuration)) {
            bubbleProgress = 1
        }
        scheduleNextBubbleSequence(after: Self.bubbleSequenceDuration + Self.bubbleCooldown)
    }

    private func scheduleNextBubbleSequence(after delay: TimeInterval) {
        let workItem = DispatchWorkItem {
            bubbleWorkItem = nil
            emitBubbleSequence()
        }
        bubbleWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func cancelBubbles() {
        bubbleWorkItem?.cancel()
        bubbleWorkItem = nil
        bubbleProgress = 0
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

    private static func bubbles(progress: CGFloat) -> [(x: CGFloat, y: CGFloat, opacity: Double)] {
        let firstProgress = min(max(progress, 0), 1)
        let secondProgress = min(max((progress - 0.3) / 0.7, 0), 1)
        return [
            (24, 4 - firstProgress * 5, Double(1 - firstProgress)),
            (20, 8 - secondProgress * 7, Double(1 - secondProgress))
        ].filter { $0.opacity > 0 }
    }
}
