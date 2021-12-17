import XCTest
@testable import SwiftUIRouter

final class SwiftUIRouterTests: XCTestCase {

	/// Test equitability of navigator
	func testNavigatorIsEquatable() {
		let nav1 = Navigator(initialPath: "/")
		let nav2: Navigator = nav1

		// 1.
		nav1.navigate("/foo")
		XCTAssertEqual(nav1, nav2)
		// 2.
		nav1.goBack()
		XCTAssertEqual(nav1, nav2)
		// 3.
		nav2.navigate("/foo")
		nav2.goBack() // => "/"
		XCTAssertEqual(nav1, nav2)
		
		let nav3 = Navigator(initialPath: "/")
		XCTAssertNotEqual(nav1, nav3)
		
		// Test if navigation actions are equatable.
		nav2.navigate("/foo")
		nav3.navigate("/foo")
		XCTAssertTrue(
			nav2.lastAction == nav3.lastAction,
			"Both navigation actions to /foo are not equal."
		)
		
		nav3.goBack()
		XCTAssertTrue(
			nav2.lastAction != nav3.lastAction,
			"Different navigation actions are still equal."
		)
	}

	/// Test cleaning/resolving of paths.
	func testPathResolving() {
		let paths: [(String, String)] = [
			("/", "/"),
			("///unnecessary///slashes", "/unnecessary/slashes"),
			("non/absolute", "/non/absolute"),
			("home//", "/home"),
			("trailing/slash/", "/trailing/slash"),
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
			("/user/:id/*", "/user/1"),
			("/user/:id/*", "/user/1/settings"),
			("/user/:id?", "/user"),
			("/user/:id?", "/user/mark"),
			("/user/:id/:group?", "/user/mark"),
			("/user/:id/:group?", "/user/mark/admin"),
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

		// Glob, path
		let isNil: [(String, String)] = [
			("/", "/hello"),
			("/hello", "/world"),
			("/foo/:bar?/hello", "/foo/hello"),
			("/movie", "/movies"),
			("/movie/*", "/movies"),
			("/movie/*", "/movies/actor"),
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
			"/:Movie/*",
			"/:i", // Single character.
		]
		
		for glob in goodGlobs {
			XCTAssertNoThrow(
				try pathMatcher.match(glob: glob, with: ""),
				"Glob \(glob) causes bad Regex." 
			)
		}
		
		// These bad globs should throw at Regex compilation.
		let badGlobs: [String] = [
			"/:0abc", // Starting with numerics.
			"/:user-id", // Illegal characters.
			"/:foo_bar",
			"/:😀"
		]
		
		for glob in badGlobs {
			XCTAssertThrowsError(
				try pathMatcher.match(glob: glob, with: ""),
				"Glob \(glob) should've thrown an error, but didn't."
			)
		}
	}
	
	/// Test the `Navigator.navigate()` method.
	func testNavigating() {
		let navigator = Navigator()
		
		// 1: Simple relative navigation.
		navigator.navigate("news")
		XCTAssertTrue(navigator.path == "/news")
		
		// 2: Absolute navigation.
		navigator.navigate("/settings/user")
		XCTAssertTrue(navigator.path == "/settings/user")
		
		// 3: Going up one level.
		navigator.navigate("..")
		XCTAssertTrue(navigator.path == "/settings")
		
		// 4: Going up redundantly.
		navigator.navigate("../../../../..")
		XCTAssertTrue(navigator.path == "/")
		
		// 5: Go back.
		navigator.goBack()
		XCTAssertTrue(navigator.path == "/settings")
		
		// 6: Go back twice.
		navigator.goBack(total: 2)
		XCTAssertTrue(navigator.path == "/news")
		
		// 7: Go forward.
		navigator.goForward()
		XCTAssertTrue(navigator.path == "/settings/user")
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
}
