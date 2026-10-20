// swift-tools-version:6.0
// For `swift test`. The app bundle itself is built by build.sh (see compile.sh).
import PackageDescription

let package = Package(
    name: "ExerciseMoose",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "ExerciseMoose", path: "Sources/ExerciseMoose"),
        .testTarget(name: "ExerciseMooseTests", dependencies: ["ExerciseMoose"], path: "Tests/ExerciseMooseTests"),
    ],
    swiftLanguageModes: [.v5]
)
