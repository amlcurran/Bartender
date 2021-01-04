//
//  Bartender.swift
//  Bookshelf
//
//  Created by Alex Curran on 31/12/2020.
//  Copyright © 2020 Alex Curran. All rights reserved.
//

import UIKit

class Bartender: NSObject {

    struct Item: Identifiable {
        let identifier: Identifier
        let label: String
        let image: UIImage?
        let selector: Selector?

        typealias ID = Identifier

        var id: Identifier {
            identifier
        }

        struct Identifier: Hashable {
            let rawValue: String
        }

        static let backNavigation = Item(identifier: Identifier(rawValue: "navigation"),
                                               label: "Back",
                                               image: UIImage(systemName: "chevron.left"),
                                               selector: nil)
    }

    private weak var viewController: UIViewController?
    private var wasNavigationBarHidden: Bool = false

    init(viewController: UIViewController, items: [Bartender.Item]) {
        self.viewController = viewController
        self.items = items
        super.init()
        defer {
            self.items = items
        }
    }

    var items: [Item] {
        didSet {
            #if targetEnvironment(macCatalyst)
            viewController?.touchBar = nil
            #endif
            willMove(toParent: viewController?.parent)
            didMove(toParent: viewController?.parent)
            viewController?.navigationItem.rightBarButtonItems = items
                .filter { $0.identifier != Bartender.Item.backNavigation.identifier }
                .map { item in
                    UIBarButtonItem(image: item.image, style: .plain, target: viewController, action: item.selector)
                }
        }
    }

    func didMove(toParent parent: UIViewController?) {
        if parent != nil {
            #if targetEnvironment(macCatalyst)
            addToToolbar()
            #endif
        }
    }

    func willMove(toParent parent: UIViewController?) {
        if parent == nil {
            #if targetEnvironment(macCatalyst)
            removeFromToolbar()
            #endif
        }
    }

    func willAppear(_ animated: Bool) {
        #if targetEnvironment(macCatalyst)
        wasNavigationBarHidden = (viewController?.parent as? UINavigationController)?.isNavigationBarHidden ?? false
        (viewController?.parent as? UINavigationController)?.setNavigationBarHidden(true, animated: animated)
        addToToolbar()
        #endif
    }

    func willDisappear(_ animated: Bool) {
        #if targetEnvironment(macCatalyst)
        if !wasNavigationBarHidden {
            (viewController?.parent as? UINavigationController)?.setNavigationBarHidden(false, animated: animated)
        }
        removeFromToolbar()
        #endif
    }

    @objc
    func goBack() {
        (viewController?.parent as? UINavigationController)?.popViewController(animated: true)
    }

    func canGoBack() -> Bool {
        ((viewController?.parent as? UINavigationController)?.viewControllers.count ?? 0) > 1
    }

    static func setUpToolbar(in window: UIWindow?) {
        #if targetEnvironment(macCatalyst)
        window?.windowScene?.titlebar.ifNotNil {
            let toolbar = NSToolbar(identifier: "main")
            toolbar.displayMode = .iconOnly
            $0.toolbar = toolbar
            $0.toolbarStyle = .automatic
            $0.separatorStyle = .none
        }
        MacBridgeInterface.load { interface in
            interface.styleTitleBar()
        }
        #endif
    }

}

#if targetEnvironment(macCatalyst)

extension Bartender: NSTouchBarDelegate {

    func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.defaultItemIdentifiers = items
            .map { $0.identifier }
            .map { NSTouchBarItem.Identifier($0.rawValue) }
        return touchBar
    }

    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        return items
            .first { $0.identifier.rawValue == identifier.rawValue }
            .map { item in
                let touchBarItem = NSButtonTouchBarItem(identifier: identifier)
                touchBarItem.title = item.label
                touchBarItem.image = item.image
                touchBarItem.action = item.selector
                return touchBarItem
            }
    }

}

extension Bartender: NSToolbarDelegate {

    func addToToolbar() {
        UIApplication.shared.currentKeyWindow?.titleToolbar.ifNotNil { toolbar in
            toolbar.delegate = self
            addAll(to: toolbar)
        }
    }

    func removeFromToolbar() {
        UIApplication.shared.currentKeyWindow?.titleToolbar.ifNotNil { toolbar in
            toolbar.delegate = nil
            removeAll(from: toolbar)
        }
    }

    fileprivate func addAll(to toolbar: NSToolbar) {
        toolbar.removeAllItems()
        items.forEach { item in
            toolbar.insertItem(withItemIdentifier: NSToolbarItem.Identifier(item.identifier.rawValue), at: 0)
        }
    }

    fileprivate func removeAll(from toolbar: NSToolbar) {
        items.forEach { item in
            if let index = toolbar.items.firstIndex(where: { $0.itemIdentifier.rawValue == item.identifier.rawValue }) {
                toolbar.removeItem(at: index)
            }
        }
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.flexibleSpace] + items
            .map { $0.identifier }
            .map { NSToolbarItem.Identifier($0.rawValue) }
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarDefaultItemIdentifiers(toolbar)
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        if itemIdentifier.rawValue == "navigation" {
            let navigationItem = NSToolbarItem(itemIdentifier: itemIdentifier)
            navigationItem.isNavigational = true
            navigationItem.label = "Back"
            navigationItem.image = UIImage(systemName: "chevron.left")
            navigationItem.target = canGoBack() ? self : nil
            navigationItem.action = #selector(goBack)
            navigationItem.isEnabled = canGoBack()
            return navigationItem
        } else {
         return items.first { $0.identifier.rawValue == itemIdentifier.rawValue }
            .map { item in
                let toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)
                toolbarItem.label = item.label
                toolbarItem.image = item.image
                item.image.ifNil { debugPrint("Item \(item.identifier.rawValue) is missing an image; it won't show on the toolbar") }
                toolbarItem.action = item.selector
                return toolbarItem
            }
        }
    }
}

extension NSToolbar {

    func removeAllItems() {
        for i in (0..<items.count).reversed() {
            removeItem(at: i)
        }
    }

}

private extension UIWindow {

    var titleToolbar: NSToolbar? {
        windowScene?.titlebar?.toolbar
    }

}

private extension UIApplication {

    var currentKeyWindow: UIWindow? {
        windows.first(where: \.isKeyWindow)
    }

}

#endif
