// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "Pen",
    platforms: [
       .macOS(.v13)
    ],
    products: [
        .executable(name: "Pen", targets: ["Pen"]),
        .executable(name: "check-default-prompts", targets: ["check-default-prompts"]),
        .executable(name: "check-user-preferences", targets: ["check-user-preferences"])
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
        ),
        .executableTarget(
            name: "check-user-preferences",
            dependencies: [
                .product(name: "MySQLKit", package: "mysql-kit")
            ],
            path: "Sources",
            sources: ["check-user-preferences.swift"]
        ),
        .executableTarget(
            name: "create-content-history-table",
            dependencies: [
                .product(name: "MySQLKit", package: "mysql-kit")
            ],
            path: "Sources",
            sources: ["create-content-history-table.swift"]
        ),
        .executableTarget(
            name: "alter-content-history-table",
            dependencies: [
                .product(name: "MySQLKit", package: "mysql-kit")
            ],
            path: "Sources",
            sources: ["alter-content-history-table.swift"]
        ),
        .executableTarget(
            name: "check-content-history-table",
            dependencies: [
                .product(name: "MySQLKit", package: "mysql-kit")
            ],
            path: "Sources",
            sources: ["check-content-history-table.swift"]
        )
    ]
)
