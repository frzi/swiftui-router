//
//  ContentView.swift
//  RouterPrototype
//
//  Created by Freek Zijlmans on 14/08/2019.
//  Copyright © 2019 Freek Zijlmans. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        Router {
            App()
        }
    }
}

private struct App: View {
    @EnvironmentObject private var route: RouteData
    
    var body: some View {
        VStack {
            AddressBar()
            
            Switch {
                Route(path: "/", exact: true, content: Root)

                Route(path: "/home", exact: true) { route in
                    Home(route: route)
                }
                
                Route(path: "/about", exact: true) { _ in
                    About()
                }
                
                Route(path: "/redirect", exact: true) { _ in
                    Redirect(to: "/")
                        .animation(.none)
                }
                
                Route(content: Default)
            }
            .animation(.easeInOut)
            
            Spacer()
        }
    }
}

struct AddressBar: View {
    @EnvironmentObject private var routerContext: HistoryData
    
    var body: some View {
        HStack {
            HStack {
                Text(routerContext.path)
                Spacer()
            }
            .padding(6)
            .background(Color.primary.opacity(0.1))
            .cornerRadius(8)
            
            Button(action: { self.routerContext.goBack() }) {
                Image(systemName: "arrow.left.circle")
            }
            .disabled(!routerContext.canGoBack)
            
            Button(action: { self.routerContext.goForward() }) {
                Image(systemName: "arrow.right.circle")
            }
            .disabled(!routerContext.canGoForward)
        }.padding()
    }
}

@ViewBuilder
private func Root(route: RouteDescription) -> some View {
    LinkButton(to: "/home") {
        Text("Home")
    }
    
    LinkButton(to: "/about") {
        Text("About")
    }
    
    LinkButton(to: "/happiness") {
        Text("Happiness")
    }
    
    LinkButton(to: "/redirect") {
        Text("Redirect back here")
    }
    
    Spacer()
}

private func Home(route: RouteDescription) -> some View {
    VStack {
        Text("Welcome to the SwiftUIRouter prototype! Thanks for checking it out!")
            .font(Font.system(size: 20))
        
        LinkButton(to: "/") {
            Text("Root")
        }
        
        LinkButton(to: "/about") {
            Text("About")
        }
        
        Spacer()
    }
    .padding()
}

@ViewBuilder
private func About() -> some View {
    Text("""
        SwiftUIRouter is based on React Router.
        As of now it's still just a proof of concept. The idea is to navigate through your app more like a website.
        (and thus make things like deeplinking more accessible and easier to accomplish)
        It should also allow for more versatile navigation compared to NavigationView and NavigationLink.
        """)
        .padding()
    
    LinkButton(to: "/") {
        Text("Root")
    }
}

private func Default(route: RouteDescription) -> some View {
    VStack {
        Text("Error 404")
            .font(Font.system(size: 30, weight: .bold))
                
        Text("\(route.path) not found")
            .foregroundColor(.red)
            .fontWeight(.bold)
        
        LinkButton(to: "/") {
            Text("Root")
        }
        
        Spacer()
    }
    .padding()
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
