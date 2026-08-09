import AppKit
import SwiftUI

@MainActor
final class NotchPanelController: NSObject, ObservableObject {
    @Published private(set) var isExpanded = false
    private let panel: NotchPanelWindow
    private let store: TaskStore
    private let settings: AppSettings
    private var inactivityTimer: Timer?
    private var globalMonitor: Any?
    private let usesTrailingSummaryLayout: Bool
    private let isNotchAttached: Bool

    init(store: TaskStore, settings: AppSettings) {
        self.store = store
        self.settings = settings
        let screen = NSScreen.main ?? NSScreen.screens[0]
        usesTrailingSummaryLayout = false
        isNotchAttached = DisplayPlacementResolver.notchRightFrame(on: screen, width: 104) != nil
        panel = NotchPanelWindow(contentRect: DisplayPlacementResolver.collapsedFrame(on: screen, placement: settings.externalDisplayPlacement))
        super.init()
        panel.contentView = NSHostingView(rootView: NotchSurfaceView(controller: self, store: store, settings: settings, usesTrailingSummaryLayout: usesTrailingSummaryLayout, isNotchAttached: isNotchAttached))
        panel.orderFrontRegardless()
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
            guard let self, self.isExpanded, !self.panel.frame.contains(event.locationInWindow) else { return }
            DispatchQueue.main.async { [weak self] in self?.collapse() }
        }
    }

    deinit { if let globalMonitor { NSEvent.removeMonitor(globalMonitor) } }

    func toggle() { isExpanded ? collapse() : expand() }

    func expand() {
        let screen = panel.screen ?? NSScreen.main ?? NSScreen.screens[0]
        panel.makeKeyAndOrderFront(nil)
        isExpanded = true
        resize(to: DisplayPlacementResolver.expandedFrame(on: screen, placement: settings.externalDisplayPlacement))
        resetInactivityTimer()
    }

    func collapse() {
        let screen = panel.screen ?? NSScreen.main ?? NSScreen.screens[0]
        isExpanded = false
        inactivityTimer?.invalidate()
        resize(to: DisplayPlacementResolver.collapsedFrame(on: screen, placement: settings.externalDisplayPlacement))
    }

    func registerActivity() { if isExpanded { resetInactivityTimer() } }

    private func resetInactivityTimer() {
        inactivityTimer?.invalidate()
        guard settings.autoCollapseSeconds > 0 else { return }
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: settings.autoCollapseSeconds, repeats: false) { [weak self] _ in
            DispatchQueue.main.async { [weak self] in self?.collapse() }
        }
    }

    private func resize(to frame: NSRect) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? 0 : 0.22
            panel.animator().setFrame(frame, display: true)
        }
    }
}
