// swift-tools-version: 6.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftCxxLinkedList",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .watchOS(.v9),
        .tvOS(.v16),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "LinkedList",
            targets: ["LinkedList", "CxxLinkedList"]
        )
    ],
    targets: [
        .target(
            name: "CxxLinkedList",
            path: "Sources/CxxLinkedList",
            publicHeadersPath: "include",
            cxxSettings: [
                .unsafeFlags(["-Wunsafe-buffer-usage"])
            ]
        ),
        .target(
            name: "LinkedList",
            dependencies: ["CxxLinkedList"],
            path: "Sources/LinkedList",
            swiftSettings: [
                .interoperabilityMode(.Cxx),
                .enableExperimentalFeature("SafeInteropWrappers"),
                .strictMemorySafety()
            ]
        ),
        .target(
            name: "CxxLinkedListTestSupport",
            dependencies: ["CxxLinkedList"],
            path: "Tests/CxxLinkedListTestSupport",
            publicHeadersPath: "include",
            cxxSettings: [
                .unsafeFlags(["-Wunsafe-buffer-usage"])
            ]
        ),
        .executableTarget(
            name: "CxxLinkedListTests",
            dependencies: [
                "CxxLinkedList",
                "CxxLinkedListTestSupport"
            ],
            path: "Tests/CxxLinkedListTests",
            cxxSettings: [
                .unsafeFlags(["-Wunsafe-buffer-usage"])
            ]
        ),
        .testTarget(
            name: "LinkedListTests",
            dependencies: [
                "LinkedList",
                "CxxLinkedList",
                "CxxLinkedListTestSupport"
            ],
            path: "Tests/SwiftCxxLinkedListTests",
            swiftSettings: [
                .interoperabilityMode(.Cxx),
                .enableExperimentalFeature("SafeInteropWrappers"),
                .strictMemorySafety()
            ]
        )
    ],
    cxxLanguageStandard: .cxx20
)
