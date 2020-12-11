/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A list of names for custom notifications.
*/

import Foundation

extension Notification.Name {
    static let editRecipe = Notification.Name("editRecipe")
    static let toggleRecipeIsFavorite = Notification.Name("toggleRecipeIsFavorite")
    static let activityItemsConfigurationDidChange = Notification.Name("activityItemsConfigurationDidChange")
    static let newRecipe = Notification.Name("newRecipe")
}

// Custom keys to use with userInfo dictionaries.
enum NotificationKey: String {
    case activityItemsConfiguration
}
