//
//  SwiftUI Router
//  Created by Freek (github.com/frzi) 2023
//

import SwiftUI
import Observation

/// Render the first matching `Route` and ignore the rest.
///
/// Use this view when you want to work with 'fallbacks'.
///
/// ```swift
/// SwitchRoutes {
/// 	Route("settings") {
/// 		SettingsView()
/// 	}
/// 	Route(":id") { info in
/// 		ContentView(id: info.params.id!)
/// 	}
/// 	Route {
/// 		HomeView()
/// 	}
/// }
/// ```
/// In the above example, if the environment path is `/settings`, only the first `Route` will be rendered.
/// Because this is the first match. The `Route`s after will not be rendered, despite being a match.
///
/// - Note: Using `SwitchRoute` can give a slight performance boost when working with a lot of sibling `Route`s,
/// as once a path match has been found, all subsequent path matching will be skipped.
public struct SwitchRoutes<Content: View>: View {
	// Required to be present, forcing the `SwitchRoutes` to re-render on path changes.
	@Environment(Navigator.self) private var navigator
	private let contents: () -> Content

	/// - Parameter contents: Routes to switch through.
	public init(@ViewBuilder contents: @escaping () -> Content) {
		self.contents = contents
	}
	
	public var body: some View {
		// Force rerender.
		_ = navigator.path

		return contents()
			.environment(SwitchRoutesEnvironment(active: true))
	}
}

// MARK: - SwitchRoutes environment object.
@Observable final class SwitchRoutesEnvironment {
	/// Tells `Route`s whether they're enclosed in a `SwitchRoutes`.
	let isActive: Bool
	
	/// Tells `Route`s they can ignore the content as a `SwitchRoutes` has found a match.
	var isResolved = false
	
	init(active: Bool = false) {
		isActive = active
	}
}
