//
//  SwiftUI Router
//  Created by Freek Zijlmans on 13/01/2021.
//

import Combine
import SwiftUI

/// Render the first matching `Route` and ignore the rest.
///
/// ```
/// SwitchRoutes {
/// 	Route(path: "settings") {
/// 		SettingsView()
///		}
/// 	Route(path: ":id") { info in
/// 		ContentView(id: info.params.id!)
/// 	}
/// }
/// ```
/// In the above example, if the environment path is `/settings`, only the first `Route` will be rendered.
/// Because this is the first match. The `Route` with a path of `:id`, despite being a match, will be ignored.
public struct SwitchRoutes<Content: View>: View {

	// Required to be present, forcing the `SwitchRoutes` to re-render on path changes.
	@EnvironmentObject private var navigation: NavigationData
	private let contents: () -> Content
	
	/// - Parameter contents: Routes to switch through.
	public init(@ViewBuilder contents: @escaping () -> Content) {
		self.contents = contents
	}
	
	public var body: some View {
		contents()
			.environmentObject(SwitchRoutesEnvironment(active: true))
	}
}

// MARK: - SwitchRoutes environment object.
final class SwitchRoutesEnvironment: ObservableObject {
	/// Tells `Route`s whether to they're enclosed in a `SwitchRoutes`.
	let isActive: Bool
	
	/// Tells `Route`s they can ignore the content, as a `SwitchRoutes` has found a match.
	var isResolved = false
	
	init(active: Bool = false) {
		isActive = active
	}
}
