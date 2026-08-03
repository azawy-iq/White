// swift-tools-version: 5.9
let package = Package(
    name: "WhiteStudio",
    platforms: [.iOS(.16)],
    products: [
        .library(name: "WhiteStudio", targets: ["WhiteStudio"])
    ],
    targets: [
        .target(name: "WhiteStudio", path: "WhiteStudio")
    ]
)
