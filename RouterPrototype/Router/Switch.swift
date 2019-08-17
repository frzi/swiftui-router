//
//  Switch.swift
//  RouterPrototype
//
//  Created by Freek Zijlmans on 15/08/2019.
//  Copyright © 2019 Freek Zijlmans. All rights reserved.
//

import SwiftUI

public final class SwitchEnviroment: ObservableObject {

    let isActive: Bool
    var isResolved: Bool = false
    
    init(active: Bool = false) {
        isActive = active
    }
}

public struct Switch<Content: View>: View {
    
    @EnvironmentObject var history: HistoryData
    
    private let contents: () -> Content
    
    init(@ViewBuilder contents: @escaping () -> Content) {
        self.contents = contents
    }
    
    public var body: some View {
        contents()
            .environmentObject(SwitchEnviroment(active: true))
    }
}
