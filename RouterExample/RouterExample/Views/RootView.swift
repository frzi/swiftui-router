//
//  RootView.swift
//  RouterExample
//
//  Created by Freek Zijlmans on 23/08/2019.
//  Copyright © 2019 Freek Zijlmans. All rights reserved.
//

import SwiftUI

// Entry of the entire app.
struct RootView: View {
    var body: some View {
        Router {
            VStack {
                AddressBar()
                ContentView()
            }
        }
    }
}

private func ContentView() -> some View {
    Switch {
        Route(path: "/:username") { info in
            RepositoriesRoute(username: info.parameters.username!)
        }
        
        Route {
            Suggestions()
        }
    }
}

private struct Suggestions: View {
    private let suggestions: [(name: String, url: String)] = [
        ("Airbnb", "airbnb"),
        ("Apple", "apple"),
        ("Babel", "babel"),
        ("Google", "google"),
        ("Microsoft", "microsoft"),
        ("NVidia", "nvidia"),
    ]
    
    @ViewBuilder
    var body: some View {
        VStack {
            ForEach(suggestions, id: \.url) { suggestion in
                Link(to: "/" + suggestion.url) {
                    Text(suggestion.name)
                }
            }
        }
        Spacer()
    }
}


// MARK: - Preview.
struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
