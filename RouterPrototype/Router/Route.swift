//
//  Route.swift
//  RouterPrototype
//
//  Created by Freek Zijlmans on 14/08/2019.
//  Copyright © 2019 Freek Zijlmans. All rights reserved.
//

import SwiftUI

public struct Route<Content: View>: View {
    
    @EnvironmentObject private var history: HistoryData
    @EnvironmentObject private var switchEnvironment: SwitchEnviroment
    
    private let content: (RouteDescription) -> Content
    private let exact: Bool
    private let path: String
    
    public init(path: String = "", exact: Bool = false, content: @escaping (RouteDescription) -> Content) {
        self.path = path
        self.exact = exact
        self.content = content
    }
    
    public var matches: Bool {
        if path.isEmpty {
            return true
        }
        else {
            return exact ? history.path == path : history.path.contains(path)
        }
    }
    
    private var parameters: [String : String] {
        return [:]
    }

    public var body: some View {
        defer {
            if matches && switchEnvironment.isActive {
                switchEnvironment.isResolved = true
            }
        }

        let description = RouteDescription(parameters: parameters,
                                           path: history.path)
        
        return Group {
            if matches && !switchEnvironment.isResolved {
                content(description)
                    .environmentObject(SwitchEnviroment())
                    .environmentObject(RouteData(match: path,
                                                 path: history.path))
            }
        }
    }
}

//
// MARK: -
/// Gives a bit of information regarding the route.
public struct RouteDescription {
    public let parameters: [String : String]
    public let path: String
}
