//
//  SwiftUI Router
//  Created by Freek Zijlmans on 14/01/2021.
//

import Foundation

func normalizePath(paths: String...) -> String {
	NSString(string: paths.joined(separator: "/")).standardizingPath
}

func resolvePaths(_ lhs: String, _ rhs: String) -> String {
	let path = rhs.first == "/" ? rhs : lhs + "/" + rhs
	return NSString(string: path).standardizingPath
}
