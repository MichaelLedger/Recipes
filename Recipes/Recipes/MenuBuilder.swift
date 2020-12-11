/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An app delegate extension responsible for building the menu system.
*/

import UIKit

extension AppDelegate {
    /** Add the various menus to the menu bar.
        The system only asks UIApplication and UIApplicationDelegate for the main menus.
        Main menus appear regardless of who is in the responder chain.
    
        Note: These menus and menu commands are localized to Chinese (Simplified) in this sample.
        To change the app to run in to Chinese, refer to Xcode Help on Testing localizations:
            https://help.apple.com/xcode/mac/current/#/dev499a9529e
    */
    override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)
        
        // Ensure that the builder is modifying the menu bar system.
        guard builder.system == UIMenuSystem.main else { return }
        
        let newRecipeCommand = UIKeyCommand(title: "New Recipe",
                                            action: #selector(newRecipe(_:)),
                                            input: "n",
                                            modifierFlags: [.command])
        let newRecipeMenu = UIMenu(title: "", options: .displayInline, children: [newRecipeCommand])
        builder.insertChild(newRecipeMenu, atStartOfMenu: .file)
    }

    @objc
    func newRecipe(_ sender: Any) {
        NotificationCenter.default.post(name: .newRecipe, object: self)
    }
}
