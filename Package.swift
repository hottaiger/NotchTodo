// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NotchTodo",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "NotchTodo", targets: ["NotchTodo"])],
    targets: [
        .executableTarget(name: "NotchTodo"),
        .testTarget(name: "NotchTodoTests", dependencies: ["NotchTodo"])
    ]
)
