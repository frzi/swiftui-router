//
//  SwiftUI Router
//  Created by Freek Zijlmans on 13/01/2021.
//

import SwiftUI

/// Wrapper around a `Button` with the ability to navigate to a new URI.
///
/// A button that will navigate to the given path when pressed. Additionally it can provide information
/// whether the current path matches the `NavLink` path. This allows the developer to apply specific styling
/// when the `NavLink` is 'active'. E.g. highlighting or disabling the contents.
///
/// ```swift
/// NavLink(to: "/news/latest") { active in
/// 	Text("Latest news")
/// 		.color(active ? Color.primary : Color.secondary)
/// }
/// ```
///
/// - Note: The given path is always relative to the current route environment. See the documentation for `Route` about
/// the specifics of path relativity.
public struct NavLink<Content: View>: View {

	@EnvironmentObject private var navigation: NavigationData
	@Environment(\.relativePath) private var relativePath
	
	private let content: (Bool) -> Content
	private let path: String
	private let replace: Bool
	
	// MARK: - Initializers.
	/// Button to navigate to a new path.
	///
	/// - Parameter to: New path to navigate to when pressed.
	/// - Parameter replace: Replace the current entry in the history stack.
	/// - Parameter exact: The `Bool` in the `content` parameter will only be `true` if the current path and the
	/// `to` path are an *exact* match.
	/// - Parameter content: Content views. The passed `Bool` indicates whether the current path matches `to` path.
	public init(
		to path: String,
		replace: Bool = false,
		exact: Bool = false,
		@ViewBuilder content: @escaping (Bool) -> Content
	) {
		self.path = path
		self.replace = replace
		self.content = content
	}
	
	public init(to path: String, replace: Bool = false, @ViewBuilder content: @escaping () -> Content) {
		self.init(to: path, replace: replace, exact: false, content: { _ in content() })
	}
	
	// MARK: -
	private func onPressed() {
		let resolvedPath = resolvePaths(relativePath, path)
		if navigation.path != resolvedPath {
			navigation.navigate(resolvedPath, replace: replace)
		}
	}
	
	public var body: some View {
		let absolutePath = resolvePaths(relativePath, path)
		let active = navigation.path.starts(with: absolutePath)
		
		return Button(action: onPressed) {
			content(active)
		}
	}
}
