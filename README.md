SwiftUI Router
==============
> Merely a proof of concept for now.

[![SwiftUI](https://img.shields.io/badge/SwiftUI-orange.svg)](https://developer.apple.com/xcode/swiftui)
[![Swift](https://img.shields.io/badge/Swift-5.1-orange.svg)](https://swift.org)
[![Xcode](https://img.shields.io/badge/Xcode-11.0-blue.svg)](https://developer.apple.com/xcode)
[![MIT](https://img.shields.io/badge/license-MIT-green.svg)](https://opensource.org/licenses/MIT)

Inspired by [React Router](https://github.com/ReactTraining/react-router), SwiftUI Router allows you to program (relatively) easy navigation in your app, much like a website. Without the hassle of NavigationView and NavigationButton. SwiftUI Router borrows the following objects from React Router: Link (named LinkButton), Redirect, Route, Router and Switch. Their behaviours should be similar to that of React Router.

**Note**: This project is very much a prototype/proof-of-concept. There are an unreasonable amount of kinks in the code and some basic features missing.

![demo](https://raw.githubusercontent.com/frzi/SwiftUIRouter/master/swiftui-router-demo.gif)

## Router (entry)
```swift
Router {
    RootView()
}
```
The `Router` view initiates a routing environment. Wrap your entire app (or at least, the part that needs navigation) in a `Router`.

## LinkButton
```swift
LinkButton(to: "/my/path") {
    Text("Go to next page")
}
```
Wrapper around a `Button` view to easily navigate to another path.

## Redirect
```swift
Redirect(to: "/notfound", replace: true)
```
When rendered, will redirect instantly to the given path. Set `replace: true` to prevent the redirect to be added to the history stack.

## Route
```swift
Route(path: "/home", exact: false) { props in
    HomeView()
}
```
Will only render its children when the environment's path matches that of the `Route`. `exact` requires the environment path and route path to match *exactly*. If `false`, the route will also render if the environment path is e.g. **"/home/and/anything/deeper"**.

A `RouteDescription` object is passed to the closure. This allows you to perform some additional logic. **Note**: This feature is unfinished and pretty much useless at its current state. `¯\_(ツ)_/¯`

## Switch
```swift
Switch {
    Route(path: "/list/details") { _ in 
        DetailsView()
    }

    Route(path: "/list") { _ in 
        ListView()
    }

    Route {
        HomeView()
    }
}
```
The `Switch` view will only render the first matching `Route` view. This will allow you to render fallback routes. **Note**: due to the `@ViewBuilder` limit, only 10 direct ancestor `Route`s are possible.

#### Animation
You can add a `.animation()` property to the `Switch` to animate the `Route` transitions.

## HistoryData
```swift
@EnvironmentObject private var history: HistoryData
```

#### `path: String`
The current environment path. (Computed value)

#### `go(to: String, replace: Bool = false)`
Perform a navigation to a new path. Set `replace` to `true` to prevent the navigation from being added to the history stack.

#### `goBack(count: Int = 1)`, `goForward(count: Int = 1)`
Go back or forward. `count` is clamped and will prevent from going out of bounds.

#### `canGoBack: Bool`, `canGoForward: Bool`
Returns whether you can go back or forward.

-----

## Todo
* Allow for (optional) parameters in paths.
* Fix history stack having some odd behaviour when returning to the root.
* Limit the `Switch` view only to `Route` ancestors?
