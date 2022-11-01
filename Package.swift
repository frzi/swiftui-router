// swift-tools-version:5.7.1

import PackageDescription

let package = Package(
	name: "SwiftUIRouter",
	platforms: [
		.macOS(.v13),
		.iOS(.v16),
		.tvOS(.v16),
		.watchOS(.v9),
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
			dependencies: [],
			path: "Sources"),
		.testTarget(
			name: "SwiftUIRouterTests",
			dependencies: ["SwiftUIRouter"]),
	]
)
