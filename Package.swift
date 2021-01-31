// swift-tools-version:5.3

import PackageDescription

let package = Package(
	name: "SwiftUIRouter",
	platforms: [
		.macOS(.v10_15),
		.iOS(.v14),
		.tvOS(.v14),
		.watchOS(.v6)
	],
	products: [
		.library(
			name: "SwiftUIRouter",
			targets: ["SwiftUIRouter"]),
	],
	dependencies: [],
	targets: [
		.target(
			name: "SwiftUIRouter",
			dependencies: []),
		.testTarget(
			name: "SwiftUIRouterTests",
			dependencies: ["SwiftUIRouter"]),
	]
)
