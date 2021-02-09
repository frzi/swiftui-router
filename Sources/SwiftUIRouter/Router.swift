//
//  SwiftUI Router
//  Created by Freek Zijlmans on 13/01/2021.
//

import Combine
import SwiftUI

/// Entry for a routing environment.
///
/// The Router holds the state of the current path (i.e. the URI).
/// Wrap your entire app (or the view that initiates a routing environment) using this View.
///
/// ```
/// Router {
/// 	HomeView()
///
/// 	Route(path: "/news") {
/// 		NewsHeaderView()
/// 	}
/// }
/// ```
///
/// # Routers in Routers
/// It's possible to have a Router somewhere in the child hierarchy of another Router. *However*, these will
/// work completely independent of each other. It is not possible to navigate from one Router to another; whether
/// via `NavLink` or pragmatically.
///
/// - Note: A Router's base path is always `/`.
public struct Router<Content: View>: View {

	@StateObject private var navigationData: NavigationData
	private let content: Content

	public init(initialPath: String = "/" ,@ViewBuilder content: () -> Content) {
		_navigationData = StateObject(wrappedValue: NavigationData(initialPath: initialPath))
		self.content = content()
	}
	
	public var body: some View {
		content
			.environmentObject(navigationData)
			.environmentObject(SwitchRoutesEnvironment())
			.environment(\.relativePath, "/")
	}
}


// MARK: - Router environment
/// EnvironmentObject storing the state of a Router.
///
/// Use this object to pragmatically navigate to a new path, jump forward or back in the history, to clear the
/// history, or to find out whether the user can go back or forward.
///
/// - Note: This EnvironmentObject is available in all children of a `Router`.
///
/// ```
/// @EnvironmentObject var navigation: NavigationData
/// ```
public final class NavigationData: ObservableObject {
	
	@Published private var historyStack: [String]
	@Published private var forwardStack: [String] = []
	
	/// Last navigation that occurred.
	@Published private(set) var lastAction: NavigationAction?
	
	let initialPath: String
	let stackLimit: Int
		
	fileprivate init(initialPath: String = "/", stackLimit: Int = 1_000) {
		self.initialPath = initialPath
		self.historyStack = [initialPath]
		self.stackLimit = stackLimit
	}

	// MARK: Getters.
	/// Current navigation path of the Router environment.
	public var path: String {
		historyStack.last ?? initialPath
	}

	public var canGoBack: Bool {
		historyStack.count > 1
	}
		
	public var canGoForward: Bool {
		!forwardStack.isEmpty
	}
	
	// MARK: Methods.
	/// Navigate to a new location.
	///
	/// The given path (`to`) is always relative to the current environment path.
	/// This means you can use `/` to navigate using an absolute path and `../` to go up a directory.
	///
	/// ```
	/// navigation.navigate("news") // Relative.
	/// navigation.navigate("/settings/user") // Absolute.
	/// navigation.navigate("..") // Up one, relatively.
	/// ```
	///
	/// Navigating to the same path as the current path is a noop. If the `DEBUG` flag is enabled, a warning
	/// will be printed to the console.
	///
	/// - Parameter path: Path of the new location to navigate to.
	/// - Parameter replace: if `true`, will not add the current location to the history.
	public func navigate(_ path: String, replace: Bool = false) {
		let path = resolvePaths(self.path, path)
		let previousPath = self.path
		
		guard path != previousPath else {
			#if DEBUG
			print("SwiftUIRouter: Navigating to the same path ignored.")
			#endif
			return
		}
	
		forwardStack.removeAll()
		if replace {
			historyStack[max(historyStack.count - 1, 0)] = path
		}
		else {
			historyStack.append(path)
		}
		
		lastAction = NavigationAction(
			currentPath: path,
			previousPath: previousPath,
			action: .push)
	}

	/// Go back *n* steps in the navigation history.
	///
	/// `total` will always be clamped and thus prevent from going out of bounds.
	///
	/// - Parameter total: Total steps to go back.
	public func goBack(total: Int = 1) {
		let previousPath = path

		let total = min(total, historyStack.count)
		let start = historyStack.count - total
		forwardStack.insert(contentsOf: historyStack[start...], at: 0)
		historyStack.removeLast(total)
		
		lastAction = NavigationAction(
			currentPath: path,
			previousPath: previousPath,
			action: .back)
	}
	
	/// Go forward *n* steps in the navigation history.
	///
	/// `total` will always be clamped and thus prevent from going out of bounds.
	///
	/// - Parameter total: Total steps to go forward.
	public func goForward(total: Int = 1) {
		let previousPath = path

		let total = min(total, forwardStack.count)
		let start = forwardStack.count - total
		historyStack.append(contentsOf: forwardStack[start...])
		forwardStack.removeLast(total)
		
		lastAction = NavigationAction(
			currentPath: path,
			previousPath: previousPath,
			action: .forward)
	}
	
	/// Clear the entire navigation history.
	public func clear() {
		forwardStack.removeAll()
		historyStack = [path]
		lastAction = nil
	}
}


// MARK: -
/// Information about a navigation that occurred.
public struct NavigationAction {
	/// Directional difference between the current path and the previous path.
	public enum Direction {
		/// The new path is higher up in the hierarchy *or* a completely different path.
		case higher
		/// The new path is deeper in the hierarchy.
		case deeper
		/// The new path shares the same parent.
		case sideways
	}
	
	/// The kind of navigation that occurred.
	public enum Action {
		/// Navigated to a new path.
		case push
		/// Navigated back in the stack.
		case back
		/// Navigated forward in the stack.
		case forward
	}
	
	public let action: Action
	public let currentPath: String
	public let previousPath: String
	public let direction: Direction
	
	fileprivate init(currentPath: String, previousPath: String, action: Action) {
		self.action = action
		self.currentPath = currentPath
		self.previousPath = previousPath
		
		// Check whether the navigation went higher, deeper or sideways.
		let previousComponents = previousPath.split(separator: "/")
		let pathComponents = currentPath.split(separator: "/")

		if previousComponents.count > pathComponents.count {
			direction = .higher
		}
		else {
			direction = .sideways
		}
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
