import XCTest
@testable import SwiftUIRouter

final class SwiftUIRouterTests: XCTestCase {

	/// Test cleaning/resolving of paths.
	func testPathResolving() {
		let paths: [(String, String)] = [
			("///unnecessary///slashes", "/unnecessary/slashes"),
			("non/absolute", "/non/absolute"),
			("home//", "/home"),
		]
		
		for (dirty, cleaned) in paths {
			XCTAssertTrue(
				resolvePaths("/", dirty) == cleaned,
				"Path \(dirty) did not resolve to \(cleaned)"
			)
		}
	}
	
	/// Test if the globs and paths match.
	func testCorrectMatches() {
		let pathMatcher = PathMatcher()
		
		let notNil: [(String, String)] = [
			("/", "/"),
			("/*", "/"),
			("/*", "/hello/world"),
			("/hello/*", "/hello"),
			("/hello/*", "/hello/world"),
			("/:id", "/hello"),
			("/:id?", "/"),
			("/:id?", "/hello"),
			("/:id/*", "/hello"),
			("/:id/*", "/hello/world"),
			("/news/latest", "/news/latest"),
		]
		
		for (glob, path) in notNil {
			let resolvedGlob = resolvePaths("/", glob)
			
			XCTAssertNotNil(
				try? pathMatcher.match(glob: resolvedGlob, with: path),
				"Glob \(glob) does not match \(path)."
			)
		}
	}
	
	/// Test if the globs and paths *don't* match.
	func testIncorrectMatches() {
		let pathMatcher = PathMatcher()

		let isNil: [(String, String)] = [
			("/", "/hello"),
			("/hello", "/world"),
		]
		
		for (glob, path) in isNil {
			XCTAssertNil(
				try? pathMatcher.match(glob: glob, with: path),
				"Glob \(glob) matches \(path), but it shouldn't."
			)
		}
	}
	
	/// Tests if the variables exist and equate.
	func testPathVariables() {
		let pathMatcher = PathMatcher()
		
		let tests: [(String, String, [String : String])] = [
			("/:id?", "/", [:]),
			("/:id?", "/hello", ["id": "hello"]),
			("/:id", "/hello", ["id": "hello"]),
			("/:foo/:bar", "/hello/world", ["foo": "hello", "bar": "world"]),
			("/:foo/:bar?", "/hello/", ["foo": "hello"]),
			("/user/:id/*", "/user/5", ["id": "5"]),
		]
		
		for (glob, path, params) in tests {
			guard let routeInformation = try? pathMatcher.match(glob: glob, with: path) else {
				XCTFail("Glob \(glob) returned `nil` for path \(path)")
				continue
			}

			for (expectedKey, expectedValue) in params {
				XCTAssertTrue(
					routeInformation.parameters[expectedKey] == expectedValue,
					"Glob \(glob) for path \(path) returns incorrect parameter for \(expectedKey). " +
					"Expected: \(expectedValue), got: \(routeInformation.parameters[expectedKey] ?? "`nil`")."
				)
			}
		}
	}
	
	/// Tests whether glob to Regex compilation doesn't throw.
	func testRegexCompilation() {
		let pathMatcher = PathMatcher()
		
		// Test if the path matcher can compile valid Regex.
		let goodGlobs: [String] = [
			"/",
			"/*",
			"/:id",
			"/:id?",
			"/:id1/:id2",
			"/:id1/:id2?",
			"/:id/*",
		]
		
		for glob in goodGlobs {
			XCTAssertNoThrow(
				try pathMatcher.match(glob: glob, with: ""),
				"Glob \(glob) causes bad Regex." 
			)
		}
	}
	
	/// Test navigation actions.
	func testNavigationAction() {
		// From, to, expected direction.
		let tests: [(String, String, NavigationAction.Direction)] = [
			("/", "/hello", .deeper),
			("/hello", "/world", .sideways),
			("/hello", "/", .higher),
			("/movies/genres", "/movies", .higher),
			("/movies/actors", "/movies/genres", .sideways),
			("/movies/genres", "/news/latest", .higher),
		]
		
		for (from, to, direction) in tests {
			let navigationAction = NavigationAction(currentPath: to, previousPath: from, action: .push)
			XCTAssertTrue(
				navigationAction.direction == direction,
				"Direction from \(from) to \(to) is: \(navigationAction.direction), expected: \(direction)"
			)
		}
	}

	// MARK: -
	static var allTests = [
		("testPathResolving", testPathResolving),
		("testRegexCompilation", testRegexCompilation),
		("testCorrectMatches", testCorrectMatches),
		("testIncorrectMatches", testIncorrectMatches),
		("testPathVariables", testPathVariables),
		("testNavigationAction", testNavigationAction),
	]
}
