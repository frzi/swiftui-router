//
//  Router.swift
//  RouterPrototype
//
//  Created by Freek Zijlmans on 14/08/2019.
//  Copyright © 2019 Freek Zijlmans. All rights reserved.
//

import Combine
import SwiftUI

// MARK: - Router
/// Entry of a routing system.
public struct Router<Content: View>: View {
    
    private let content: Content
    private let root: String
    
    public init(root: String = "/", @ViewBuilder content: () -> Content) {
        self.root = root
        self.content = content()
    }
    
    public var body: some View {
        content
            .environmentObject(HistoryData())
            .environmentObject(RouteData())
            .environmentObject(SwitchEnviroment())
    }
}

// MARK: - Router environment object.
/// This object allows ancestors to modify the path and history.
public final class HistoryData: ObservableObject {
    
    @Published private var historyStack: [String] = []
    private var forwardStack: [String] = []
        
    // MARK: Getters.
    public var canGoBack: Bool { !historyStack.isEmpty }
    public var canGoForward: Bool { !forwardStack.isEmpty }
    public var path: String { historyStack.last ?? "/" }
    
    // MARK: Methods.
    public func go(_ path: String, replace: Bool = false) {
        forwardStack.removeAll()
        if replace {
            historyStack[max(historyStack.count - 1, 0)] = path
        }
        else {
            historyStack.append(path)
        }
    }
    
    public func goBack(count: Int = 1) {
        let total = min(count, historyStack.count)
        let start = historyStack.count - total
        forwardStack.insert(contentsOf: historyStack[start...], at: 0)
        historyStack.removeLast(total)
    }
    
    public func goForward(count: Int = 1) {
        let total = min(count, forwardStack.count)
        let start = forwardStack.count - total
        historyStack.append(contentsOf: forwardStack[start...])
        forwardStack.removeLast(total)
    }
}

// MARK: - Route environment object.
/// Contains the data of the current route.
public final class RouteData: ObservableObject {
    
    public let match: String
    public let path: String
    
    init(match: String = "", path: String = "") {
        self.match = match
        self.path = path
    }
}
