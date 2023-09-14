//
//  SwiftUI Router
//  Created by Freek (github.com/frzi) 2023
//

import Observation
import SwiftUI

/// EnvironmentObject storing the state of a Router.
///
/// Use this object to programmatically navigate to a new path, to jump forward or back in the history, to clear the
/// history, or to find out whether the user can go back or forward.
///
/// - Note: This EnvironmentObject is available inside the hierarchy of a `Router`.
///
/// ```swift
/// @Environment(Navigator.self) var navigator
/// ```
@Observable public final class Navigator {
	private var historyStack: [String]
	private var forwardStack: [String] = []
	
	/// Last navigation that occurred.
	public private(set) var lastAction: NavigationAction?
	
	/// The path the `Router` was initialized with.
	public let initialPath: String

	/// Initialize a `Navigator` to be fed to `Router` manually.
	///
	/// Initialize an instance of `Navigator` to keep a reference to outside of the SwiftUI lifecycle.
	///
	/// - Important: This is considered an advanced usecase for *SwiftUI Router* used for specific design patterns.
	/// It is strongly advised to reference the `Navigator` via the provided Environment Object instead.
	///
	/// - Parameter initialPath: The initial path the `Navigator` should start at once initialized.
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

	/// The size of the history stack.
	///
	/// The amount of times the `Navigator` 'can go back'.
	public var historyStackSize: Int {
		historyStack.count - 1
	}

	/// The size of the forward stack.
	///
	/// The amount of times the `Navigator` 'can go forward'.
	public var forwardStackSize: Int {
		forwardStack.count
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
	/// - Parameter replace: if `true` will replace the last path in the history stack with the new path.
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

		if replace && !historyStack.isEmpty {
			historyStack[historyStack.endIndex - 1] = path
		}
		else {
			historyStack.append(path)
		}

		lastAction = NavigationAction(
			currentPath: path,
			previousPath: previousPath,
			action: .push
		)
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
		forwardStack.append(contentsOf: historyStack[start...].reversed())
		historyStack.removeLast(total)
		
		lastAction = NavigationAction(
			currentPath: path,
			previousPath: previousPath,
			action: .back
		)
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
			action: .forward
		)
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
		/// Example: `/user/settings` → `/user`. Or `/favorite/music` → `/news/latest`.
		case higher
		/// The new path is deeper in the hierarchy. Example: `/news` → `/news/latest`.
		case deeper
		/// The new path shares the same parent. Example: `/favorite/movies` → `/favorite/music`.
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
