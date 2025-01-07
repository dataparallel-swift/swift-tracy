// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import CompilerPluginSupport
import PackageDescription

// Packages consuming Tracy must manually enable profiling by defining the
// environment variable `SWIFT_TRACY_ENABLE`
let enabled     = ProcessInfo.processInfo.environment["SWIFT_TRACY_ENABLE"].isSet
let libraryType = ProcessInfo.processInfo.environment["BUILD_STATIC_LIBRARIES"].isSet ? Product.Library.LibraryType.static : nil

let package = Package(
    name: "swift-tracy",
    platforms: [.macOS(.v10_15)],
    products: [
        .library(name: "Tracy", type: libraryType, targets: ["Tracy"]),
    ],

    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax", from: "600.0.0-prerelease-2024-05-28")
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
            swiftSettings: !enabled ? [] : [
                .define("SWIFT_TRACY_ENABLE")
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
            cxxSettings: !enabled ? [] : [
                .unsafeFlags(["-march=native"]),
                .define("TRACY_ENABLE"),
                .define("TRACY_DELAYED_INIT"),
                .define("TRACY_MANUAL_LIFETIME"),
                .define("TRACY_IGNORE_MEMORY_FAULTS"),
                .define("TRACY_NO_FRAME_IMAGE"),
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
        .systemLibrary(
            name: "capstone",
            pkgConfig: "capstone",
            providers: [
                .apt(["libcapstone-dev"]),
                .brew(["capstone"])
            ]
        ),
    ]
)

fileprivate extension String? {
  var isSet: Bool {
    if let v = self {
      return v.isEmpty || v == "1" || v == "true"
    }
    return false
  }
}

