//
//  SwiftUI Router
//  Created by Freek Zijlmans on 16/02/2021.
//

import SwiftUI

/// EnvironmentObject storing the state of a Router.
///
/// Use this object to programmatically navigate to a new path, jump forward or back in the history, to clear the
/// history, or to find out whether the user can go back or forward.
///
/// - Note: This EnvironmentObject is available in all children of a `Router`.
///
/// ```swift
/// @EnvironmentObject var navigator: Navigator
/// ```
public final class Navigator: ObservableObject {

	@Published private var historyStack: [String]
	@Published private var forwardStack: [String] = []
	
	/// Last navigation that occurred.
	@Published public private(set) var lastAction: NavigationAction?
	
	private let initialPath: String
		
    public init(initialPath: String = "/") {
        self.initialPath = initialPath
        self.historyStack = [initialPath]
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
	/// The given path is always relative to the current environment path.
	/// This means you can use `/` to navigate using an absolute path and `..` to go up a directory.
	///
	/// ```swift
	/// navigator.navigate("news") // Relative.
	/// navigator.navigate("/settings/user") // Absolute.
	/// navigator.navigate("..") // Up one, relatively.
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
			historyStack[historyStack.endIndex - 1] = path
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
		guard canGoBack else {
			return
		}

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
		guard canGoForward else {
			return
		}

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

extension Navigator: Equatable {
	public static func == (lhs: Navigator, rhs: Navigator) -> Bool {
		lhs === rhs
	}
}


// MARK: -
/// Information about a navigation that occurred.
public struct NavigationAction: Equatable {
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
	
	init(currentPath: String, previousPath: String, action: Action) {
		self.action = action
		self.currentPath = currentPath
		self.previousPath = previousPath
		
		// Check whether the navigation went higher, deeper or sideways.
		if currentPath.count > previousPath.count
			&& (currentPath.starts(with: previousPath + "/") || previousPath == "/")
		{
			direction = .deeper
		}
		else {
			let currentComponents = currentPath.split(separator: "/")
			let previousComponents = previousPath.split(separator: "/")

			if currentComponents.count == previousComponents.count
				&& currentComponents.dropLast(1) == previousComponents.dropLast(1)
			{
				direction = .sideways
			}
			else {
				direction = .higher
			}
		}
	}
}
