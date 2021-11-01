//
//  SwiftUI Router
//  Created by Freek (github.com/frzi) 2021
//

import Combine
import SwiftUI

/// Entry for a routing environment.
///
/// The Router holds the state of the current path (i.e. the URI).
/// Wrap your entire app (or the view that initiates a routing environment) using this view.
///
/// ```swift
/// Router {
/// 	HomeView()
///
/// 	Route("/news") {
/// 		NewsHeaderView()
/// 	}
/// }
/// ```
///
/// # Routers in Routers
/// It's possible to have a Router somewhere in the child hierarchy of another Router. *However*, these will
/// work completely independent of each other. It is not possible to navigate from one Router to another; whether
/// via `NavLink` or programmatically.
///
/// - Note: A Router's base path (root) is always `/`.
public struct Router<Content: View>: View {
	@StateObject private var navigator: Navigator
	private let content: Content

	/// Initialize a Router environment.
	/// - Parameter initialPath: The initial path the `Router` should start at once initialized.
	/// - Parameter content: Content views to render inside the Router environment.
	public init(initialPath: String = "/", @ViewBuilder content: () -> Content) {
		_navigator = StateObject(wrappedValue: Navigator(initialPath: initialPath))
		self.content = content()
	}
	
	/// Initialize a Router environment.
	///
	/// Provide an already initialized instance of `Navigator` to use inside a Router environment.
	///
	/// - Important: This is considered an advanced usecase for *SwiftUI Router* used only for specific design patterns.
	/// It is stronlgy adviced to use the `init(initialPath:content:)` initializer instead.
	///
	/// - Parameter navigator: A pre-initialized instance of `Navigator`.
	/// - Parameter content: Content views to render inside the Router environment.
	public init(navigator: Navigator, @ViewBuilder content: () -> Content) {
		_navigator = StateObject(wrappedValue: navigator)
		self.content = content()
	}
	
	public var body: some View {
		content
			.environmentObject(navigator)
			.environmentObject(SwitchRoutesEnvironment())
			.environment(\.relativePath, "/")
	}
}

// MARK: - Relative path environment key
/// NOTE: This has actually become quite redundant thanks to `RouteInformation`'s changes.
/// Remove and use `RouteInformation` environment objects instead?
struct RelativeRouteEnvironment: EnvironmentKey {
	static var defaultValue = "/"
}

extension EnvironmentValues {
	var relativePath: String {
		get { self[RelativeRouteEnvironment.self] }
		set { self[RelativeRouteEnvironment.self] = newValue }
	}
}
