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
/// ```swift
/// Route(path: "settings") {
/// 	SettingsView()
/// }
/// ```
///
/// ## Path parameters (aka placeholders)
/// Paths may contain one or several parameters. Parameters are placeholders that will be replaced by the
/// corresponding component of the matching path. Parameters are prefixed with a colon (:). The values of the
/// parameters are provided via the `RouteInformation` object passed to the contents of the `Route`.
/// Parameters can be marked as optional by postfixing them with a question mark (?).
///
/// **Note:** Only alphanumeric characters (A-Z, a-z, 0-9) are valid for parameters.
/// ```swift
/// Route("/news/:id") { routeInfo in
/// 	NewsItemView(id: routeInfo.parameters["id"]!)
/// }
/// ```
///
/// ## Validation and parameter transform
/// `Route`s are given the opportunity to add an extra layer of validation. Use the `validator` argument to pass
/// down a validator function. This function is given a `RouteInformation` object, containing the path parameters.
/// This function can then return a new value to pass down to `content`, or return `nil` to invalidate the path
/// matching.
/// ```swift
/// func validate(info: RouteInformation) -> UUID? {
/// 	UUID(info.parameters["uuid"]!)
/// }
/// // Will only render if `uuid` is a valid UUID.
/// Route(path: "user/:uuid", validator: validate) { uuid in
/// 	UserScreen(userId: uuid)
/// }
/// ```
///
/// ## Path relativity
/// Every path found in a `Route`'s hierarchy is relative to the path of said `Route`. With the exception of paths
/// starting with `/`. This allows you to develop parts of your app more like separate 'sub' apps.
/// ```swift
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
///
/// - Note: A `Route`'s default path is `*`, meaning it will always match.
public struct Route<ValidatedData, Content: View>: View {
	
	public typealias Validator = (RouteInformation) -> ValidatedData?

	@Environment(\.relativePath) private var relativePath
	@EnvironmentObject private var navigator: Navigator
	@EnvironmentObject private var switchEnvironment: SwitchRoutesEnvironment
	@StateObject private var pathMatcher = PathMatcher()
	
	private let content: (ValidatedData) -> Content
	private let path: String
	private let validator: Validator

	/// - Parameter path: A path glob to test with the current path. See documentation for `Route`.
	/// - Parameter validator: A function that validates and transforms the route parameters.
	/// - Parameter content: Views to render. The validated data is passed as an argument.
	public init(
		path: String = "*",
		validator: @escaping Validator,
		@ViewBuilder content: @escaping (ValidatedData) -> Content
	) {
		self.content = content
		self.path = path
		self.validator = validator
	}

	public var body: some View {
		let resolvedGlob = resolvePaths(relativePath, path)
		
		var validatedData: ValidatedData?
		var routeInformation: RouteInformation?

		if !switchEnvironment.isActive || (switchEnvironment.isActive && !switchEnvironment.isResolved) {
			do {
				if let matchInformation = try pathMatcher.match(glob: resolvedGlob, with: navigator.path),
				   let validated = validator(matchInformation)
				{
					validatedData = validated
					routeInformation = matchInformation
					
					if switchEnvironment.isActive {
						switchEnvironment.isResolved = true
					}
				}
			}
			catch {
				print("Unable to compile path glob '\(path)' to Regex.")
				fatalError(error.localizedDescription)
			}
		}

		return Group {
			if let validatedData = validatedData,
			   let routeInformation = routeInformation
			{
				content(validatedData)
					.environment(\.relativePath, routeInformation.path)
					.environmentObject(routeInformation)
					.environmentObject(SwitchRoutesEnvironment())
			}
		}
	}
}

public extension Route where ValidatedData == RouteInformation {
	/// - Parameter path: A path glob to test with the current path. See documentation for `Route`.
	/// - Parameter content: Views to render. An `RouteInformation` is passed containing route parameters.
	init(path: String = "*", @ViewBuilder content: @escaping (RouteInformation) -> Content) {
		self.path = path
		self.validator = { $0 }
		self.content = content
	}
	
	/// - Parameter path: A path glob to test with the current path. See documentation for `Route`.
	/// - Parameter content: Views to render.
	init(path: String = "*", @ViewBuilder content: @escaping () -> Content) {
		self.path = path
		self.validator = { $0 }
		self.content = { _ in content() }
	}
}


// MARK: -
/// Information passed to the contents of a `Route`. As well as accessible as an environment object
/// inside the hierarchy of a `Route`.
/// ```swift
/// @EnvironmentObject var routeInformation: RouteInformation
/// ```
/// This object contains the resolved parameters (variables) of the `Route`'s path, as well as the relative path
/// for all views inside the hierarchy.
public final class RouteInformation: ObservableObject {
	public let path: String
	public let parameters: [String : String]
	
	init(path: String, parameters: [String : String] = [:]) {
		self.path = path
		self.parameters = parameters
	}
}


// MARK: -
/// Object that will (lazily) compile regex from the given path glob, compare it with another path and return
/// any parsed information (like identifiers).
final class PathMatcher: ObservableObject {

	private static let variablesRegex = try! NSRegularExpression(pattern: #":([^\/\?]+)"#, options: [])

	private struct CompiledRegex {
		let path: String
		let matchRegex: NSRegularExpression
		let parameters: Set<String>
	}
	
	enum CompileError: Error {
		case badParameter(String, culprit: String)
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
		let variableMatches = Self.variablesRegex.matches(in: glob, options: [], range: nsrange)

		for match in variableMatches where match.numberOfRanges > 1 {
			if let range = Range(match.range(at: 1), in: glob) {
				let variable = String(glob[range])

				#if DEBUG
				// In debug mode perform an extra check whether parameters contain invalid characters or
				// whether the parameters starts with something besides a letter.
				if let range = variable.range(of: "(^[^A-Za-z]|[^A-Za-z0-9])", options: .regularExpression) {
					throw CompileError.badParameter(variable, culprit: String(variable[range]))
				}
				#endif
				
				variables.insert(variable)
			}
		}

		// Create a new regex that will eventually match and extract the parameters from a path.
		let endsWithAsterisk = glob.last == "*"
		
		var pattern = glob
			.replacingOccurrences(of: "^[^/]/$", with: "", options: .regularExpression) // Trailing slash.
			.replacingOccurrences(of: #"\/?\*"#, with: "", options: .regularExpression) // Trailing asterisk.
		
		for variable in variables {
			pattern = pattern.replacingOccurrences(
				of: "/:" + variable,
				with: "/(?<" + variable + ">[^/?]+)", // Named capture group.
				options: .regularExpression)
		}
		pattern = "^" +
			(pattern.isEmpty ? "" : "(\(pattern))") +
			(endsWithAsterisk ? "(/.*)?$" : "$")

		let regex = try NSRegularExpression(pattern: pattern, options: [])
		
		cached = CompiledRegex(path: glob, matchRegex: regex, parameters: variables)

		return cached!
	}

	func match(glob: String, with path: String) throws -> RouteInformation? {
		let compiled = try compileRegex(glob)
		
		var nsrange = NSRange(path.startIndex..<path.endIndex, in: path)
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
		
		// Resolve the glob to get a new relative path.
		// We only want the part the glob is directly referencing.
		// I.e., if the glob is `/news/article/*` and the navigation path is `/news/article/1/details`,
		// we only want "/news/article".
		nsrange = matches[0].range(at: 1) // Should be the entire capture group.
		guard nsrange.location != NSNotFound,
			let range = Range(nsrange, in: path) else {
			return nil
		}
		
		let resolvedGlob = String(path[range])
		
		return RouteInformation(path: resolvedGlob, parameters: parameterValues)
	}
}
