// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Aura",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Aura",
            targets: ["Aura"])
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.20.0")
    ],
    targets: [
        .target(
            name: "Aura",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk")
            ])
    ]
)
