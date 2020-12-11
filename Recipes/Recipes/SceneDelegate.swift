/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main scene delegate.
*/

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var splitViewDelegate = SplitViewDelegate()
    var toolbarDelegate = ToolbarDelegate()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if #available(iOS 14, *) {
            if window?.traitCollection.userInterfaceIdiom == .pad {
                if let splitViewController = createThreeColumnSplitViewController() {
                    window?.rootViewController = splitViewController
                }
            }
        }
        
        configureSplitViewController()
        
        #if targetEnvironment(macCatalyst)
        guard let windowScene = scene as? UIWindowScene else { return }
        
        let toolbar = NSToolbar(identifier: "main")
        toolbar.delegate = toolbarDelegate
        toolbar.displayMode = .iconOnly
        
        if let titlebar = windowScene.titlebar {
            titlebar.toolbar = toolbar
            titlebar.toolbarStyle = .automatic
        }
        #endif
    }

    private func configureSplitViewController() {
        guard
            let window = window,
            let splitViewController = window.rootViewController as? UISplitViewController
        else {
            fatalError()
        }

        splitViewController.delegate = splitViewDelegate
    }

}

@available(iOS 14, *)
extension SceneDelegate {
    
    private func createThreeColumnSplitViewController() -> UISplitViewController? {
        guard
            let recipeListViewController = RecipeListViewController.instantiateFromStoryboard(),
            let recipeDetailViewController = RecipeDetailViewController.instantiateFromStoryboard()
        else { return nil }
        
        let sidebarViewController = SidebarViewController()
        
        // Configure the split view controller.
        let splitViewController = UISplitViewController(style: .tripleColumn)
        splitViewController.primaryBackgroundStyle = .sidebar
        splitViewController.preferredDisplayMode = .twoBesideSecondary
        
        // Add view controllers to the split view controller.
        splitViewController.setViewController(sidebarViewController, for: .primary)
        splitViewController.setViewController(recipeListViewController, for: .supplementary)
        splitViewController.setViewController(recipeDetailViewController, for: .secondary)
        
        return splitViewController
    }
    
}
