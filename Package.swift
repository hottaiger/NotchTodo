// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NotchTodo",
    defaultLocalization: "zh-Hans",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "NotchTodo", targets: ["NotchTodo"])],
    targets: [
        .executableTarget(name: "NotchTodo", resources: [.process("Resources")]),
        .testTarget(name: "NotchTodoTests", dependencies: ["NotchTodo"])
    ]
)
