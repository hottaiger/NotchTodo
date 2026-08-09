import SwiftUI

struct OnboardingView: View {
    let finish: () -> Void
    var body: some View { VStack(spacing: 16) { Image(systemName: "checklist.checked").font(.system(size: 36)); Text("欢迎使用 NotchTodo").font(.title2.bold()); Text("点击刘海区域打开待办看板。Option + Space 可随时切换。\n所有数据只保存在这台 Mac 上。").multilineTextAlignment(.center).foregroundStyle(.secondary); Button("开始使用", action: finish).keyboardShortcut(.defaultAction) }.padding(32).frame(width: 380) }
}
