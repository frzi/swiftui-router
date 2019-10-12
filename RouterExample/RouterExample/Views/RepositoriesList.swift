//
//  RepositoriesList.swift
//  RouterExample
//
//  Created by Freek Zijlmans on 23/08/2019.
//  Copyright © 2019 Freek Zijlmans. All rights reserved.
//

import Dispatch
import Foundation
import SwiftUI

// MARK: -
struct RepositoriesRoute: View {
    
    @EnvironmentObject private var routeData: RouteData
    
    let username: String
    
    var body: some View {
        Group {
            Switch {
                Route(path: self.routeData.match + "/:repo") { route in
                    VStack {
                        Text(route.parameters.repo!)
                        Spacer()
                    }
                }
                
                Route {
                    RepositoriesList(username: self.username)
                }
            }
            .animation(.easeInOut)
            .transition(.opacity)
        }
    }
}

// MARK: -
/// Shows the repositories of the current user.
private struct RepositoriesList: View {
    
    @ObservedObject private var fetcher = RepositoriesFetcher()

    let username: String
    
    private func onAppear() {
        fetcher.request(user: username)
    }
    
    var body: some View {
        ZStack {
            List {
                ForEach(fetcher.repositories) { repository in
                    RepositoryListCell(repository: repository)
                }
            }
            .onAppear(perform: onAppear)
            
            ActivityIndicator(isAnimating: fetcher.isBusy)
        }
    }
}

// MARK: -
private func RepositoryListCell(repository: Repository) -> some View {
    Link(to: "/" + repository.fullName) {
        VStack(alignment: .leading) {
            Text(repository.name)
            
            HStack {
                Text(repository.language ?? "???")
                    .padding([.trailing], 10)
                
                Text("\(repository.forks) forks")
                
                Spacer()
                
                Text("⭐️ \(repository.stargazersCount)")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding([.top, .bottom], 6)
    }
}
