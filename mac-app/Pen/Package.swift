// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "Pen",
    platforms: [
       .macOS(.v13)
    ],
    products: [
        .executable(name: "Pen", targets: ["Pen"]),
        .executable(name: "check-default-prompts", targets: ["check-default-prompts"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/mysql-kit.git", exact: "4.10.1")
    ],
    targets: [
        .executableTarget(
            name: "Pen",
            dependencies: [
                .product(name: "MySQLKit", package: "mysql-kit")
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
        ),
        .executableTarget(
            name: "check-default-prompts",
            dependencies: [
                .product(name: "MySQLKit", package: "mysql-kit")
            ],
            path: "Sources",
            sources: ["check-default-prompts.swift"]
        )
    ]
)
