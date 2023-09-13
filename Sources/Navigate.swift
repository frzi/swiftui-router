//
//  SwiftUI Router
//  Created by Freek (github.com/frzi) 2023
//

import SwiftUI

/// When rendered will automatically perform a navigation to the given path.
///
/// This view allows you to programmatically navigate to a new path in a View's body.
///
/// ```swift
/// SwitchRoutes {
/// 	Route("news", content: NewsView())
/// 	Route {
/// 		// If this Route gets rendered it'll redirect
/// 		// the user to a 'not found' screen.
/// 		Navigate(to: "/not-found")
/// 	}
/// }
/// ```
///
/// - Note: The given path is always relative to the current route environment. See the documentation for `Route` about
/// the specifics of path relativity.
public struct Navigate: View {

	@Environment(Navigator.self) private var navigator
	@Environment(\.relativePath) private var relativePath

	private let path: String
	private let replace: Bool

	/// - Parameter path: New path to navigate to once the View is rendered.
	/// - Parameter replace: if `true` will replace the last path in the history stack with the new path.
	public init(to path: String, replace: Bool = true) {
		self.path = path
		self.replace = replace
	}

	public var body: some View {
		Text("Navigating...")
			.hidden()
			.onAppear {
				if navigator.path != path {
					navigator.navigate(resolvePaths(relativePath, path), replace: replace)
				}
			}
	}
}
