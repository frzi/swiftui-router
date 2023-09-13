// swift-tools-version:5.9

import PackageDescription

let package = Package(
	name: "SwiftUIRouter",
	platforms: [
		.macOS(.v14),
		.iOS(.v17),
//		.tvOS(.v17),
//		.watchOS(.v10),
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
