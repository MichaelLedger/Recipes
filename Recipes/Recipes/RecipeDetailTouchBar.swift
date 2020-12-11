/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An extension providing Touch Bar support to `RecipeDetailViewController.`
*/

import UIKit

#if targetEnvironment(macCatalyst)
extension NSTouchBarItem.Identifier {
    static let deleteRecipe = NSTouchBarItem.Identifier("com.example.apple-samplecode.Recipes.deleteRecipe")
    static let editRecipe = NSTouchBarItem.Identifier("com.example.apple-samplecode.Recipes.editRecipe")
    static let toggleRecipeIsFavorite = NSTouchBarItem.Identifier("com.example.apple-samplecode.Recipes.toggleRecipeIsFavorite")
}

extension RecipeDetailViewController: NSTouchBarDelegate {
    
    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        
        touchBar.defaultItemIdentifiers = [
            .flexibleSpace,
            .deleteRecipe,
            .flexibleSpace,
            .editRecipe,
            .toggleRecipeIsFavorite,
            .flexibleSpace
        ]
        
        return touchBar
    }
    
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        let touchBarItem: NSTouchBarItem?
        
        switch identifier {
        case .deleteRecipe:
            guard let image = UIImage(systemName: "trash") else { return nil }
            touchBarItem = NSButtonTouchBarItem(identifier: identifier,
                                                image: image,
                                                target: self,
                                                action: #selector(RecipeDetailViewController.deleteRecipe(_:)))
            
        case .editRecipe:
            guard let image = UIImage(systemName: "square.and.pencil") else { return nil }
            touchBarItem = NSButtonTouchBarItem(identifier: identifier,
                                                image: image,
                                                target: self,
                                                action: #selector(RecipeDetailViewController.editRecipe(_:)))

        case .toggleRecipeIsFavorite:
            guard let recipe = self.recipe else { return nil }
            
            let name = recipe.isFavorite ? "heart.fill" : "heart"
            guard let image = UIImage(systemName: name) else { return nil }

            touchBarItem = NSButtonTouchBarItem(identifier: identifier,
                                                image: image,
                                                target: self,
                                                action: #selector(RecipeDetailViewController.toggleFavorite(_:)))

        default:
            touchBarItem = nil
        }
        
        return touchBarItem
    }
}
#endif
