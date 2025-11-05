// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
import Foundation
import PackageDescription

// Packages consuming Tracy must manually enable profiling by defining the
// environment variable `SWIFT_TRACY_ENABLE`
let enableTracy = ProcessInfo.processInfo.environment["SWIFT_TRACY_ENABLE"].isSet
let enableCUDA = ProcessInfo.processInfo.environment["SWIFT_TRACY_CUDA_ENABLE"].isSet
let libraryType = ProcessInfo.processInfo.environment["BUILD_STATIC_LIBRARIES"].isSet ? Product.Library.LibraryType.static : nil

var dependencies: [Target.Dependency] = ["capstone"]
var sources: [String] = []
var swiftSettings: [SwiftSetting] = []
var cSettings: [CSetting] = []
var cxxSettings: [CXXSetting] = []

if !enableTracy {
    // swiftlint:disable:next logger_over_print
    print("Tracy profiling is DISABLED. Enable it through the SWIFT_TRACY_ENABLE environment variable.")
}
else {
    swiftSettings += [
        .define("SWIFT_TRACY_ENABLE"),
    ]
    sources += [
        "tracy-init.cpp",
        "tracy-client.cpp",
        "tracy-demangle.cpp",
        "tracy-interpose.c",
    ]
    cSettings += [
        .unsafeFlags([
            "-O3",
            "-march=native",
            "-Wall", // we can replace these with .enableWarning in 6.2
            "-Wextra",
            "-Wpedantic",
            "-fcolor-diagnostics",
        ]),
        .define("TRACY_ENABLE"),
        .define("TRACY_DEMANGLE"),
        .define("TRACY_DELAYED_INIT"),
        .define("TRACY_MANUAL_LIFETIME"),
        .define("TRACY_IGNORE_MEMORY_FAULTS"),
        .define("TRACY_NO_FRAME_IMAGE"),
        .headerSearchPath("tracy/public"),
    ]
    cxxSettings += [
        .unsafeFlags([
            "-O3",
            "-march=native",
            "-Wall",
            "-Wextra",
            "-Wpedantic",
            "-fcolor-diagnostics",
        ]),
        .define("TRACY_ENABLE"),
        .define("TRACY_DEMANGLE"),
        .define("TRACY_DELAYED_INIT"),
        .define("TRACY_MANUAL_LIFETIME"),
        .define("TRACY_IGNORE_MEMORY_FAULTS"),
        .define("TRACY_NO_FRAME_IMAGE"),
        .headerSearchPath("tracy/public"),
    ]
}

if enableTracy, !enableCUDA {
    // swiftlint:disable:next logger_over_print
    print("Tracy CUDA profiling is DISABLED. Enable it through the SWIFT_TRACY_CUDA_ENABLE environment variable.")
}
else {
    dependencies += [
        .product(name: "CUPTI", package: "swift-cuda"),
    ]
    cSettings += [
        .define("TRACY_CUDA_ENABLE"),
    ]
    cxxSettings += [
        .define("TRACY_CUDA_ENABLE"),
    ]
}

let package = Package(
    name: "swift-tracy",
    platforms: [.macOS(.v10_15)],
    products: [
        .library(name: "Tracy", type: libraryType, targets: ["Tracy"]),
        .library(name: "TracyC", type: libraryType, targets: ["TracyC"]),
    ],

    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
        .package(url: "git@gitlab.com:PassiveLogic/compiler/swift-cuda.git", from: "0.3.0"),
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
            swiftSettings: swiftSettings
        ),
        .target(
            name: "TracyC",
            dependencies: dependencies,
            path: "Sources/tracy-cbits",
            // We must explicitly add the main source file and public header
            // path, otherwise swift will try to compile everything it can find,
            // including code we don't care about (e.g. tests, examples) as well
            // as obviously non-source files (e.g. README.md---yes, really...)
            sources: sources,
            publicHeadersPath: ".",
            cSettings: cSettings,
            cxxSettings: cxxSettings
        ),
        .macro(
            name: "TracyMacros",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ],
            path: "Sources/tracy-macros"
        ),
        .systemLibrary(
            name: "capstone",
            pkgConfig: "capstone",
            providers: [
                .apt(["libcapstone-dev"]),
                .brew(["capstone"]),
            ]
        ),
    ],
    cLanguageStandard: .c11,
    cxxLanguageStandard: .cxx17
)

private extension String? {
    var isSet: Bool {
        if let value = self {
            return value.isEmpty || value == "1" || value.lowercased() == "true"
        }
        return false
    }
}
