/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app delegate.
*/

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        /** The registration domain is volatile.  It does not persist across launches.
            You must register your defaults at each launch; otherwise you will get (system) default values when accessing
            the values of preferences the user (via the Settings app) or your app (via set*:forKey:) has not modified.
            Registering a set of default values ensures that your app always has a known good set of values to operate on.
        */
        registerDefaultsFromSettingsBundle()
        
        return true
    }

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    // MARK: - Preferences
    
    enum BackgroundColors: Int {
        case blue = 1
        case teal = 2
        case indigo = 3
    }
    
    // Locates the file representing the root page of the settings for this app and registers the loaded values as the app's defaults.
    func registerDefaultsFromSettingsBundle() {
        let settingsUrl =
            Bundle.main.url(forResource: "Settings", withExtension: "bundle")!.appendingPathComponent("Root.plist")
        let settingsPlist = NSDictionary(contentsOf: settingsUrl)!
        if let preferences = settingsPlist["PreferenceSpecifiers"] as? [NSDictionary] {
            var defaultsToRegister = [String: Any]()
    
            for prefItem in preferences {
                guard let key = prefItem["Key"] as? String else {
                    continue
                }
                defaultsToRegister[key] = prefItem["DefaultValue"]
            }
            UserDefaults.standard.register(defaults: defaultsToRegister)
        }
    }

}

