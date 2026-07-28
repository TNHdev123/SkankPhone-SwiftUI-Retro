// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SkankPhoneSwiftUIRetro",
    platforms: [.iOS(.v15)],
    products: [
        .executable(name: "SkankPhoneSwiftUIRetro", targets: ["SkankPhoneSwiftUIRetro"])
    ],
    targets: [
        .executableTarget(name: "SkankPhoneSwiftUIRetro", path: "Sources/SkankPhoneSwiftUIRetro")
    ]
)
