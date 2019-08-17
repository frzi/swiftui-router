//
//  Redirect.swift
//  RouterPrototype
//
//  Created by Freek Zijlmans on 14/08/2019.
//  Copyright © 2019 Freek Zijlmans. All rights reserved.
//

import SwiftUI

public struct Redirect: View {

    @EnvironmentObject private var environment: HistoryData
    
    public let to: String
    
    private func commit() {
        environment.go(to, replace: true)
    }
    
    public var body: some View {
        Text("Redirecting")
            .onAppear(perform: commit)
    }
}
