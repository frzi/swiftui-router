//
//  Route.swift
//  RouterPrototype
//
//  Created by Freek Zijlmans on 14/08/2019.
//  Copyright © 2019 Freek Zijlmans. All rights reserved.
//

import SwiftUI

// MARK: Route view
public struct Route<Content: View>: View {
    
    @EnvironmentObject private var history: HistoryData
    @EnvironmentObject private var switchEnvironment: SwitchEnviroment
    
    private let content: (RouteData) -> Content
    private let matcher: PathMatcher
    private let path: String
    
    public init(path: String = "", exact: Bool = false, @ViewBuilder content: @escaping (RouteData) -> Content) {
        self.path = path
        self.content = content
        self.matcher = PathMatcher(match: path, exact: exact)
    }

    public init(path: String = "", exact: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.path = path
        self.content = { _ in content() }
        self.matcher = PathMatcher(match: path, exact: exact)
    }

    public var body: some View {
        // Try to avoid calling `execute` if the Switch is already resolved.
        var parameters: [String : String]?
        var matches = path.isEmpty
            
        if !matches && switchEnvironment.isActive && !switchEnvironment.isResolved {
            parameters = try? matcher.execute(path: history.path)
            matches = parameters != nil
        }
        
        defer {
            if matches && switchEnvironment.isActive {
                switchEnvironment.isResolved = true
            }
        }

        let routeData = RouteData(match: path, path: history.path, parameters: parameters ?? [:])
        
        return Group {
            if matches && !switchEnvironment.isResolved {
                content(routeData)
                    .environmentObject(SwitchEnviroment())
                    .environmentObject(routeData)
            }
        }
    }
}

// MARK: - Route environment object
/// Contains the data of the current route.
public final class RouteData: ObservableObject {
    
    public let match: String
    public let parameters: PathParameters<String>
    public let path: String
    
    init(match: String = "", path: String = "", parameters: [String : String] = [:]) {
        self.match = match
        self.parameters = PathParameters(parameters)
        self.path = path
    }
}

// MARK: - Path Paramters object
/// Dynamic lookup wrapper around a Dictionary.
@dynamicMemberLookup
public class PathParameters<Value> {
    private let data: [String : Value]
    
    init(_ data: [String : Value]) {
        self.data = data
    }
    
    subscript(dynamicMember member: String) -> Value? {
        return data[member]
    }
}
