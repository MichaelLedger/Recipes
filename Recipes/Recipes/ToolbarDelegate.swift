/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The toolbar delegate.
*/

import UIKit
import Combine

class ToolbarDelegate: NSObject {

    #if targetEnvironment(macCatalyst)
    private let shareItem = NSSharingServicePickerToolbarItem(itemIdentifier: .shareRecipe)
    private let activityItemsConfigurationSubscriber: AnyCancellable?
    
    override init() {
        self.activityItemsConfigurationSubscriber = NotificationCenter.default
            .publisher(for: .activityItemsConfigurationDidChange)
            .receive(on: RunLoop.main)
            .map({ $0.userInfo?[NotificationKey.activityItemsConfiguration] as? UIActivityItemsConfiguration })
            .assign(to: \NSSharingServicePickerToolbarItem.activityItemsConfiguration, on: shareItem)
    }
    #endif
    
}

#if targetEnvironment(macCatalyst)
extension NSToolbarItem.Identifier {
    static let editRecipe = NSToolbarItem.Identifier("com.example.apple-samplecode.Recipes.editRecipe")
    static let toggleRecipeIsFavorite = NSToolbarItem.Identifier("com.example.apple-samplecode.Recipes.toggleRecipeIsFavorite")
    static let shareRecipe = NSToolbarItem.Identifier("com.example.apple-samplecode.Recipes.shareRecipe")
}

extension ToolbarDelegate {
    
    @objc
    func editRecipe(_ sender: Any?) {
        NotificationCenter.default.post(name: .editRecipe, object: self)
    }
    
    @objc
    func toggleRecipeIsFavorite(_ sender: Any?) {
        NotificationCenter.default.post(name: .toggleRecipeIsFavorite, object: self)
    }
    
}

extension ToolbarDelegate: NSToolbarDelegate {
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        let identifiers: [NSToolbarItem.Identifier] = [
            .toggleSidebar,
            .flexibleSpace,
            .editRecipe,
            .toggleRecipeIsFavorite,
            .shareRecipe
        ]
        return identifiers
    }
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return toolbarDefaultItemIdentifiers(toolbar)
    }
    
    func toolbar(_ toolbar: NSToolbar,
                 itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        
        var toolbarItem: NSToolbarItem?
        
        switch itemIdentifier {
        case .toggleSidebar:
            toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)
        
        case .editRecipe:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.image = UIImage(systemName: "square.and.pencil")
            item.label = "Edit Recipe"
            item.action = #selector(editRecipe(_:))
            item.target = self
            toolbarItem = item

        case .toggleRecipeIsFavorite:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.image = UIImage(systemName: "heart")
            item.label = "Toggle Favorite"
            item.action = #selector(toggleRecipeIsFavorite(_:))
            item.target = self
            toolbarItem = item
            
        case .shareRecipe:
            toolbarItem = shareItem

        default:
            toolbarItem = nil
        }
        
        return toolbarItem
    }
    
}
#endif
