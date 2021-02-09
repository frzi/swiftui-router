import XCTest
@testable import SwiftUIRouter

final class SwiftUIRouterTests: XCTestCase {
	
	func testCorrectMatches() {
		let pathMatcher = PathMatcher()
		
		// Test if the globs and paths match.
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
		]
		
		for (glob, path) in notNil {
			XCTAssertNotNil(
				try? pathMatcher.match(glob: glob, with: path),
				"Glob \(glob) does not match \(path)."
			)
		}
	}
	
	func testIncorrectMatches() {
		let pathMatcher = PathMatcher()

		// Test if the globs and paths *don't* match.
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
	
	func testPathMatcherVariables() {
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
	
	func testPathMatcherRegex() {
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

	// MARK: -
	static var allTests = [
		("testPathMatcherRegex", testPathMatcherRegex),
		("testCorrectMatches", testCorrectMatches),
		("testIncorrectMatches", testIncorrectMatches),
		("testPathMatcherVariables", testPathMatcherVariables),
	]
}
