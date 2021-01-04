# Bartender

A mini library to present a single API for Navigation Bars, Touch Bars, and Toolbars in a Mac Catalyst app.

Update your instance of `Bartender` and its items to:
- Update your UINavigationBar in your iOS app
- Update the NSToolbar of your app on Mac Catalyst
- Add the items to the Touch Bar without any additional work.

Example usage:

```swift
private lazy var bartender = Bartender(viewController: self, items: [
    .backNavigation,
    Bartender.Item(identifier: Bartender.Item.Identifier(rawValue: "library.newshelf"),
                   label: "Add new shelf",
                   image: UIImage(systemName: "folder.badge.plus"),
                   selector: #selector(addDidTap))
])
```

Pop back soon for more information and options!
