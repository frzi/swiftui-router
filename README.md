<img src="Docs/Images/logo.svg" alt="SwiftUI Router" width="600">

> Easy and maintainable app navigation with path-based routing for SwiftUI.

![SwiftUI](https://img.shields.io/github/v/release/frzi/SwiftUIRouter?style=for-the-badge)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-blue.svg?style=for-the-badge&logo=swift&logoColor=black)](https://developer.apple.com/xcode/swiftui)
[![Swift](https://img.shields.io/badge/Swift-5.3-orange.svg?style=for-the-badge&logo=swift)](https://swift.org)
[![Xcode](https://img.shields.io/badge/Xcode-13-blue.svg?style=for-the-badge&logo=Xcode&logoColor=white)](https://developer.apple.com/xcode)
[![MIT](https://img.shields.io/badge/license-MIT-black.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

With **SwiftUI Router** you can power your SwiftUI app with path-based routing. By utilizing a path-based system, navigation in your app becomes more flexible and easier to maintain.

## Index
* [Installation](#installation-)
* [Documentation](#documentation-)
* [Examples](#examples-)
* [Usage](#usage-)
* [License](#license-)

## Installation 🛠
In Xcode add the dependency to your project via *File > Add Packages > Search or Enter Package URL* and use the following url:
```
https://github.com/frzi/SwiftUIRouter.git
```

Once added, import the package in your code:
```swift
import SwiftUIRouter
```
*Bada bing bada boom you're ready to go.*

<br>

## Documentation 📚
- [Animating routes](/Docs/AnimatingRoutes.md)

<br>

## Examples 👀
- [SwiftUI Router Examples](https://github.com/frzi/SwiftUIRouter-Examples) contains:  
  ┗ [RandomUsers](https://github.com/frzi/SwiftUIRouter-Examples/tree/main/RandomUsers)  
  ┗ [Swiping](https://github.com/frzi/SwiftUIRouter-Examples/tree/main/Swiping)  
  ┗ [TabViews](https://github.com/frzi/SwiftUIRouter-Examples/tree/main/TabViewRouting)

<br>

## Usage 🚀
Below a quick rundown of the available views and objects and their basic features. For further details, please check out the documentation in the Swift files.

### `Router`
```swift
Router {
	RootView()
}
```
The entry of a routing environment. Wrap your entire app (or just the part that needs routing) inside a `Router`. This view will initialize all necessary environment values needed for routes.

<br>

### `Route`
```swift
Route("news/*") {
	NewsScreen()
}
Route("settings") {
	SettingsScreen()
}
Route("user/:id?") { info in
	UserScreen(id: info.parameters["id"])
}
```
A view that will only render its contents if its path matches that of the environment. Use `/*` to also match deeper paths. E.g.: the path `news/*` will match the following environment paths: `/news`, `/news/latest`, `/news/article/1` etc.

#### Parameters
Paths can contain parameters (aka placeholders) that can be read individually. A parameter's name is prefixed with a colon (`:`). Additionally, a parameter can be considered optional by suffixing it with a question mark (`?`). The parameters are passed down as a `[String : String]` in an `RouteInformation` object to a `Route`'s contents.  
**Note**: Parameters may only exist of alphanumeric characters (A-Z, a-z and 0-9) and *must* start with a letter.

#### Parameter validation
```swift
func validateUserID(routeInfo: RouteInformation) -> UUID? {
	UUID(routeInfo.parameters["id"] ?? "")
}

Route("user/:id", validator: validateUserID) { userID in
	UserScreen(userID: userID)
}
```
A `Route` provides an extra step for validating parameters in a path.  

Let's say your `Route` has the path `/user/:id`. By default, the `:id` parameter can be *anything*. But in this case you only want valid [UUIDs](https://developer.apple.com/documentation/foundation/uuid). Using a `Route`'s `validator` argument, you're given a chance to validate (and transform) the parameter's value.  

A validator is a simple function that's passed a `RouteInformation` object (containing the parameters) and returns the transformed value as an optional. The new transformed value is passed down to your view instead of the default `RouteInformation` object. If the transformed value is `nil` the `Route` will prevent rendering its contents.

<br>

### `NavLink`
```swift
NavLink(to: "/news/latest") {
	Text("Latest news")
}
```
A wrapper around a `Button` that will navigate to the given path if pressed.

<br>

### `SwitchRoutes`
```swift
SwitchRoutes {
	Route("latest") {
		LatestNewsScreen()
	}
	Route("article/:id") { info in
		NewsArticleScreen(articleID: info.parameters["id"]!)
	}
	Route(":unknown") {
		ErrorScreen()
	}
	Route {
		NewsScreen()
	}
}
```
A view that will only render the first `Route` whose path matches the environment path. This is useful if you wish to work with fallbacks. This view can give a slight performance boost as it prevents `Route`s from path matching once a previous `Route`'s path is already resolved.

<br>

### `Navigate`
```swift
Navigate(to: "/error-404")
```
This view will automatically navigate to another path once rendered. One may consider using this view in a fallback `Route` inside a `SwitchRoutes`.

<br>

### `Navigator`
```swift
@EnvironmentObject var navigator: Navigator
```
An environment object containg the data of the `Router`. With this object you can programmatically navigate to another path, go back in the history stack or go forward.

<br>

### `RouteInformation`
```swift
@EnvironmentObject var routeInformation: RouteInformation
```
A lightweight object containing information of the current `Route`. A `RouteInformation` contains the current path and a `[String : String]` with all the parsed parameters.  

This object is passed down by default in a `Route` to its contents. It's also accessible as an environment object.

<br>

## License 📄
[MIT License](LICENSE).
