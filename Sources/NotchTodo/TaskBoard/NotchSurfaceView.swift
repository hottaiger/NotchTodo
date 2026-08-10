import SwiftUI

struct NotchSurfaceView: View {
    @ObservedObject var controller: NotchPanelController
    @ObservedObject var store: TaskStore
    @ObservedObject var settings: AppSettings
    let usesTrailingSummaryLayout: Bool
    let isNotchAttached: Bool

    static func shouldShowFish(isExpanded: Bool) -> Bool { !isExpanded }
    static func shouldUseFishBackground(isExpanded: Bool) -> Bool { !isExpanded }

    private var fishLeadingInset: CGFloat {
        isNotchAttached ? 18 : 2
    }

    private var fishBackgroundWidth: CGFloat { isNotchAttached ? 50 : 32 }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if controller.isExpanded {
                TaskBoardView(store: store, controller: controller)
            } else {
                CapsuleSummaryView(store: store, showsCount: settings.showsTaskCount, usesTrailingSummaryLayout: usesTrailingSummaryLayout, isNotchAttached: isNotchAttached)
                    .frame(width: 104)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .onTapGesture { controller.expand() }
                    .contextMenu {
                        Button("打开待办看板") { controller.expand() }
                        Divider()
                        Button("退出 NotchTodo", role: .destructive) { NSApp.terminate(nil) }
                    }
            }
            if Self.shouldUseFishBackground(isExpanded: controller.isExpanded) {
                Color.black
                    .frame(width: fishBackgroundWidth, height: 38)
                    .allowsHitTesting(false)
            }
            if Self.shouldShowFish(isExpanded: controller.isExpanded) {
                PixelFishView(
                    collapseAnimationID: controller.collapseAnimationID,
                    shouldReduceMotion: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
                )
                .padding(.leading, fishLeadingInset)
                .padding(.top, 10)
                .allowsHitTesting(false)
            }
        }
        .animation(.spring(response: 0.22, dampingFraction: 0.86), value: controller.isExpanded)
    }
}

private struct CapsuleSummaryView: View {
    @ObservedObject var store: TaskStore
    let showsCount: Bool
    let usesTrailingSummaryLayout: Bool
    let isNotchAttached: Bool

    private var highestPriority: TaskPriority? { store.activeTasks.map(\.priority).max { $0.rawValue < $1.rawValue } }

    var body: some View {
        let summary = HStack(spacing: 8) {
            Circle().fill(color(for: highestPriority)).frame(width: 7, height: 7)
            if showsCount { Text("\(store.activeTasks.count) 项待办").font(.system(size: 12, weight: .semibold)) }
        }
        .foregroundStyle(.white)

        Group {
            if usesTrailingSummaryLayout { HStack { Spacer(minLength: 0); summary }.padding(.trailing, 10) }
            else { summary.frame(maxWidth: .infinity) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
        .clipShape(NotchAttachedCapsuleShape(
            leadingRadius: isNotchAttached ? 0 : 10,
            topTrailingRadius: isNotchAttached ? 0 : 10,
            isNotchAttached: isNotchAttached
        ))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("NotchTodo，\(store.activeTasks.count) 项未完成任务")
        .accessibilityHint("点击展开待办看板")
    }

    private func color(for priority: TaskPriority?) -> Color {
        switch priority { case .high: .red; case .medium: .blue; case .low: .gray; case nil: .gray.opacity(0.55) }
    }
}

struct NotchAttachedCapsuleShape: Shape {
    let leadingRadius: CGFloat
    let topTrailingRadius: CGFloat
    let isNotchAttached: Bool

    static func bottomTrailingRadius(isNotchAttached: Bool, height: CGFloat) -> CGFloat {
        isNotchAttached ? height / 2 : 10
    }

    func path(in rect: CGRect) -> Path {
        let leadingRadius = min(leadingRadius, rect.height / 2)
        let topTrailingRadius = min(topTrailingRadius, rect.height / 2)
        let bottomTrailingRadius = min(
            Self.bottomTrailingRadius(isNotchAttached: isNotchAttached, height: rect.height),
            rect.height / 2
        )
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + leadingRadius, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - topTrailingRadius, y: rect.minY))
        if topTrailingRadius > 0 { path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + topTrailingRadius), control: CGPoint(x: rect.maxX, y: rect.minY)) }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomTrailingRadius))
        if bottomTrailingRadius > 0 { path.addQuadCurve(to: CGPoint(x: rect.maxX - bottomTrailingRadius, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY)) }
        path.addLine(to: CGPoint(x: rect.minX + leadingRadius, y: rect.maxY))
        if leadingRadius > 0 {
            path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - leadingRadius), control: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + leadingRadius))
            path.addQuadCurve(to: CGPoint(x: rect.minX + leadingRadius, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
        } else {
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        }
        return path
    }
}
