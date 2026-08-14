// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "IrrigaSIM",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .iOSApplication(
            name: "IrrigaSIM",
            targets: ["AppModule"],
            bundleIdentifier: "com.irrigasim.ios",
            teamIdentifier: "",
            developmentRegion: "pt-BR",
            displayVersion: "1.0",
            bundleVersion: "1",
            supportedDeviceFamilies: [.pad, .phone],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft
            ],
            appIcon: .placeholder(icon: .init(iconName: "AppIcon")),
            accentColor: .asset(name: "AccentColor"),
            supportedInterfaceOrientationsForPad: [
                .portrait,
                .portraitUpsideDown,
                .landscapeLeft,
                .landscapeRight
            ]
        )
    ],
    dependencies: [
        // KMP Shared module
        .package(url: "https://github.com/nicklama/kmp-swift-package.git", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            dependencies: [],
            path: "iosApp"
        )
    ]
)
