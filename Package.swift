// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import CompilerPluginSupport
import PackageDescription

let libraryType: Product.Library.LibraryType? = (ProcessInfo.processInfo.environment["BUILD_STATIC_LIBRARIES"] == "true") ? .static : nil

let package = Package(
    name: "swift-tracy",
    platforms: [.macOS(.v10_15)],
    products: [
        .library(name: "Tracy", type: libraryType, targets: ["Tracy"]),
    ],

    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax", from: "510.0.2")
        // .package(url: "https://github.com/apple/swift-syntax", from: "600.0.0-prerelease-2024-05-14")
        // .package(url: "https://github.com/apple/swift-syntax", branch: "main")
    ],

    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Tracy",
            dependencies: [
                "TracyC",
                "TracyMacros",
            ],
            path: "Sources/tracy",
            swiftSettings: [
                .enableExperimentalFeature("CodeItemMacros")
            ]
        ),

        .systemLibrary(
            name: "capstone",
            pkgConfig: "capstone",
            providers: [
                .apt(["libcapstone-dev"]),
                .brew(["capstone"])
            ]
        ),
        .target(
            name: "TracyC",
            dependencies: [
                "capstone",
            ],
            path: "Sources/tracy-cbits",
            // We must explicitly add the main source file and public header
            // path, otherwise swift will try to compile everything it can find,
            // including code we don't care about (e.g. tests, examples) as well
            // as obviously non-source files (e.g. README.md---yes, really...)
            sources: ["tracy-cbits.cpp"],
            publicHeadersPath: ".",
            cxxSettings: [
                .unsafeFlags(["-march=native"])
            ]
        ),

        .macro(
            name: "TracyMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ],
            path: "Sources/tracy-macros"
        ),
    ]
)
