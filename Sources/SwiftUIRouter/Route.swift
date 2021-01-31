//
//  SwiftUI Router
//  Created by Freek Zijlmans on 13/01/2021.
//

import Foundation
import SwiftUI

/// A route showing only its children when its path matches with the environment path.
///
/// When the environment path matches a `Route`'s path, its contents will be rendered.
///
/// ```
/// Route(path: "settings") {
/// 	SettingsView()
/// }
/// ```
///
/// ## Validation
/// `Route`s are given the opportunity to add an extra layer of validation. Use the `validator` argument to pass
/// down a validator function. This function is given a `RouteInformation` object, containing the path parameters.
/// This function can then return a new value to pass down to `content`, or return `nil` to invalidate the path
/// matching.
/// ```
/// func validate(info: RouteInformation) -> UUID? {
/// 	UUID(info.parameters.uuid!)
/// }
///
/// Route(path: "user/:uuid", validator: validate) { uuid in
/// 	UserScreen(userId: uuid)
/// }
/// ```
///
/// ## Path relativity
/// Every path found in a `Route`'s hierarchy is relative to the path of said `Route`. With the exception of paths
/// starting with `/`. This allows you to develop parts of your app more like separate 'sub' apps.
/// ```
/// Route("/news") {
/// 	// Goes to `/news/latest`
/// 	NavLink(to: "latest") { Text("Latest news") }
/// 	// Goes to `/home`
/// 	NavLink(to: "/home") { Text("Home") }
/// 	// Route for `/news/unknown/*`
/// 	Route("unknown/*") {
/// 		// Redirects to `/news/error`
/// 		Navigate(to: "../error")
/// 	}
/// }
/// ```
public struct Route<ValidatedData, Content: View>: View {
	
	public typealias Validator = (RouteInformation) -> ValidatedData?

	@Environment(\.relativePath) private var relativePath
	@EnvironmentObject private var navigation: NavigationData
	@EnvironmentObject private var switchEnvironment: SwitchRoutesEnvironment
	@StateObject private var pathMatcher = PathMatcher()
	
	private let content: (ValidatedData) -> Content
	private let path: String
	private let validator: Validator

	/// - Parameter path: A path glob to test with the current path. See documentation for `Route`.
	/// - Parameter validator: A function that validates and transforms the route parameters.
	/// - Parameter content: Views to render. The validated data is passed as an argument.
	public init(
		path: String,
		validator: @escaping Validator,
		@ViewBuilder content: @escaping (ValidatedData) -> Content
	) {
		self.content = content
		self.path = path
		self.validator = validator
	}
	
	public var body: some View {
		let newRelativePath = resolvePaths(relativePath, path)
		
		var validatedData: ValidatedData?
		var routeInformation: RouteInformation?

		if !switchEnvironment.isActive || (switchEnvironment.isActive && !switchEnvironment.isResolved) {
			if let matchInformation = try? pathMatcher.match(glob: newRelativePath, with: navigation.path),
			   let validated = validator(matchInformation)
			{
				validatedData = validated
				routeInformation = matchInformation
				
				if switchEnvironment.isActive {
					switchEnvironment.isResolved = true
				}
			}
		}

		return Group {
			if let validatedData = validatedData,
			   let routeInformation = routeInformation
			{
				content(validatedData)
					.environment(\.relativePath, newRelativePath)
					.environmentObject(routeInformation)
					.environmentObject(SwitchRoutesEnvironment())
			}
		}
	}
}

public extension Route where ValidatedData == RouteInformation {
	/// - Parameter path: A path glob to test with the current path. See documentation for `Route`.
	/// - Parameter content: Views to render. An `RouteInformation` is passed containing route parameters.
	init(path: String, @ViewBuilder content: @escaping (RouteInformation) -> Content) {
		self.path = path
		self.validator = { a in a }
		self.content = content
	}
	
	/// - Parameter path: A path glob to test with the current path. See documentation for `Route`.
	/// - Parameter content: Views to render..
	init(path: String, @ViewBuilder content: @escaping () -> Content) {
		self.path = path
		self.validator = { a in a }
		self.content = { _ in content() }
	}
}


// MARK: -
/// Information passed to the contents of a `Route`.
public final class RouteInformation: ObservableObject {

	/// A convenience wrapper for key-values.
	/// Using dynamicLookup it allows one to to `info.parameters.id`, instead of `info.parameters["id"]`.
	@dynamicMemberLookup
	public struct ParameterValues {
		fileprivate let keyValues: [String : String]
		
		public subscript(dynamicMember member: String) -> String? {
			return keyValues[member]
		}
	}
	
	public let parameters: ParameterValues
	public let path: String
	
	init(parameters: ParameterValues, path: String) {
		self.parameters = parameters
		self.path = path
	}
}


// MARK: -
/// Object that will (lazily) compile regex from the given path glob, compare it with another path and return
/// any parsed information (like identifiers).
final class PathMatcher: ObservableObject {

	private struct CompiledRegex {
		let path: String
		let matchRegex: NSRegularExpression
		let parameters: Set<String>
	}

	private var cached: CompiledRegex?
	
	private func compileRegex(_ glob: String) throws -> CompiledRegex {
		if let cached = cached,
		   cached.path == glob
		{
			return cached
		}
		
		// Extract the variables from the glob.
		var variables = Set<String>()

		let nsrange = NSRange(glob.startIndex..<glob.endIndex, in: glob)
		let variablesRegex = try NSRegularExpression(pattern: #":([^\/\?]+)"#, options: [])
		let variableMatches = variablesRegex.matches(in: glob, options: [], range: nsrange)

		for match in variableMatches where match.numberOfRanges > 1 {
			if let range = Range(match.range(at: 1), in: glob) {
				variables.insert(String(glob[range]))
			}
		}

		// Create a new regex that will eventually match and extract the parameters from a path.
		var pattern = glob.replacingOccurrences(of: "*", with: ".+")
		for variable in variables {
			pattern = pattern.replacingOccurrences(
				of: "/:" + variable,
				with: "(/(?<" + variable + ">[^/?]+))", // Named capture group.
				options: .regularExpression)
		}
		pattern = "^" + pattern + "$"

		let regex = try NSRegularExpression(pattern: pattern, options: [])
		
		cached = CompiledRegex(path: glob, matchRegex: regex, parameters: variables)

		return cached!
	}
	
	func match(glob: String, with path: String) throws -> RouteInformation? {
		let compiled = try compileRegex(glob)
		
		let nsrange = NSRange(path.startIndex..<path.endIndex, in: path)
		let matches = compiled.matchRegex.matches(in: path, options: [], range: nsrange)
		if matches.isEmpty {
			return nil
		}
		
		var parameterValues: [String : String] = [:]

		if !compiled.parameters.isEmpty {
			for variable in compiled.parameters {
				let nsrange = matches[0].range(withName: variable)
				if nsrange.location != NSNotFound,
				   let range = Range(nsrange, in: path)
				{
					parameterValues[variable] = String(path[range])
				}
			}
		}

		return RouteInformation(
			parameters: RouteInformation.ParameterValues(keyValues: parameterValues),
			path: path
		)
	}
}
