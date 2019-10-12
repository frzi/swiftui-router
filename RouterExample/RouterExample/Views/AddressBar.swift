//
//  AddressBar.swift
//  RouterExample
//
//  Created by Freek Zijlmans on 23/08/2019.
//  Copyright © 2019 Freek Zijlmans. All rights reserved.
//

import Foundation
import SwiftUI

struct AddressBar: View {
    
    @EnvironmentObject private var history: HistoryData

    private func onBackPressed() {
        history.goBack()
    }
    
    private func onForwardPressed() {
        history.goForward()
    }
    
    private func onOpenPressed() {
        if let url = URL(string: "https://github.com" + history.path) {
            UIApplication.shared.open(url, options: [:])
        }
    }
    
    var body: some View {
        HStack {
            HStack {
                Text(history.path)
                    .lineLimit(1)

                Spacer()
            }
            .padding(6)
            .background(Color.primary.opacity(0.08))
            .cornerRadius(5)

            Button(action: onBackPressed) {
                Image(systemName: "arrow.left.circle")
                    .imageScale(.large)
                    .padding(4)
            }
            .disabled(!history.canGoBack)
            
            Button(action: onForwardPressed) {
                Image(systemName: "arrow.right.circle")
                    .imageScale(.large)
                    .padding(4)
            }
            .disabled(!history.canGoForward)
            
            Button(action: onOpenPressed) {
                Image(systemName: "safari")
                    .imageScale(.large)
                    .padding(4)
            }
        }
        .padding()
    }
}
