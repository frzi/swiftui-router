//
//  SwiftUI Router
//  Created by Freek (github.com/frzi) 2023
//

import Foundation

func normalizePath(paths: String...) -> String {
	NSString(string: paths.joined(separator: "/")).standardizingPath
}

func resolvePaths(_ lhs: String, _ rhs: String) -> String {
	let path = rhs.first == "/" ? rhs : lhs + "/" + rhs
	return NSString(string: path).standardizingPath
}
