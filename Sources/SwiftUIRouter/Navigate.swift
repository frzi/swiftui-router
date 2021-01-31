//
//  SwiftUI Router
//  Created by Freek Zijlmans on 13/01/2021.
//

import SwiftUI

/// When rendered will automatically perform a navigation to the given path.
///
/// This view allows you to pragmatically navigate to a new path in a View's body.
///
/// ```
/// SwitchRoutes {
/// 	Route(path: "news") { NewsView() }
///		Route {
///			// If this Route gets rendered redirect
///			// the user to a 'not found' screen.
///			Navigate(to: "/not-found", replace: true)
/// 	}
/// }
/// ```
///
/// - Remark: In most cases you will probably want `replace` to be set to `true`.
/// However, for the sake of consistency with other Views using a `replace` parameter, it defaults to `false`.
///
/// - Note: The given path is always relative to the current route environment. See the documentation for `Route` about
/// the specifics of path relativity.
public struct Navigate: View {

	@EnvironmentObject private var navigation: NavigationData
	@Environment(\.relativePath) private var relativePath

	private let path: String
	private let replace: Bool
	
	/// - Parameter path: New path to navigate to once the View is rendered.
	/// - Parameter replace: Prevent the current path for being placed in the *back history* stack.
	public init(to path: String, replace: Bool = false) {
		self.path = path
		self.replace = replace
	}

	public var body: some View {
		Text("Navigating...")
			.hidden()
			.onAppear {
				if navigation.path != path {
					navigation.navigate(resolvePaths(relativePath, path), replace: replace)
				}
			}
	}
}
