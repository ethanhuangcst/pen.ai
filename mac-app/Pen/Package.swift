// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "Pen",
    platforms: [
       .macOS(.v13)
    ],
    products: [
        .executable(name: "Pen", targets: ["Pen"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/mysql-kit.git", exact: "4.10.1"),
        .package(url: "https://github.com/IBM-Swift/Swift-SMTP.git", from: "5.0.0")
    ],
    targets: [
        .executableTarget(
            name: "Pen",
            dependencies: [
                .product(name: "MySQLKit", package: "mysql-kit"),
                .product(name: "SwiftSMTP", package: "Swift-SMTP")
            ],
            path: "Sources",
            sources: ["App", "Models", "Services", "Views"],
            resources: [
                .process("../Resources/Assets"),
                .process("../Resources/config"),
                .process("../Resources/en.lproj"),
                .process("../Resources/zh-Hans.lproj")
            ]
        ),
        .testTarget(
            name: "PenTests",
            dependencies: ["Pen"],
            path: "Tests"
        )
    ]
)
