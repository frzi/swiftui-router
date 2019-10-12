//
//  Redirect.swift
//  RouterPrototype
//
//  Created by Freek Zijlmans on 14/08/2019.
//  Copyright © 2019 Freek Zijlmans. All rights reserved.
//

import SwiftUI

public struct Redirect: View {

    @EnvironmentObject private var history: HistoryData
    
    public let to: String
    
    public var body: some View {
        Text("Redirecting")
            .onAppear {
                self.history.go(self.to, replace: true)
            }
    }
}
