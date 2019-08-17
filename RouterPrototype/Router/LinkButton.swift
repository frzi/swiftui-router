//
//  LinkButton.swift
//  RouterPrototype
//
//  Created by Freek Zijlmans on 14/08/2019.
//  Copyright © 2019 Freek Zijlmans. All rights reserved.
//

import SwiftUI

public struct LinkButton<Label: View>: View {

    @EnvironmentObject private var environment: HistoryData

    private let content: Label
    private let to: String
    
    init(to: String, @ViewBuilder content: () -> Label) {
        self.content = content()
        self.to = to
    }
    
    private func onClick() {
        environment.go(to)
    }
    
    public var body: some View {
        Button(action: onClick) {
            content
        }
    }
}
