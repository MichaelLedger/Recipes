/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The recipe detail view controller.
*/

import UIKit
import os
import Combine

class RecipeDetailViewController: UIViewController, RecipeController {

    static let storyboardID = "RecipeDetail"
    static func instantiateFromStoryboard() -> RecipeDetailViewController? {
        let storyboard = UIStoryboard(name: "RecipeDetail", bundle: .main)
        return storyboard.instantiateViewController(identifier: storyboardID) as? RecipeDetailViewController
    }
    
    var recipe: Recipe? {
        didSet {
            updateUI()
            configureActivityItems()
        }
    }
    
    @IBOutlet weak var recipeFavoriteButton: UIBarButtonItem!
    
    private var topChildController: RecipeController?
    private var bottomChildController: RecipeController?

    var noRecipeView: UIView!
    
    private var dataStoreSubscriber: AnyCancellable?
    private var editRecipeSubscriber: AnyCancellable?
    private var toggleRecipeIsFavoriteSubscriber: AnyCancellable?
    
    // KVO for preference changes.
    private var backgroundColorObserver: NSKeyValueObservation?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Listen for preference changes for the view's background color.
        backgroundColorObserver = UserDefaults.standard.observe(\.nameColorKey, options: [.initial, .new], changeHandler: { (defaults, change) in
            self.updatePreferredBackgroundColor(colorValue: AppDelegate.BackgroundColors(rawValue: change.newValue ?? 0) ?? AppDelegate.BackgroundColors.blue)
        })
        
        addNoRecipeView()
        
        if let childController = children.first(where: { $0 is RecipeDetailTopViewController }) as? RecipeDetailTopViewController {
            childController.recipe = recipe
            topChildController = childController
        }

        if let childController = children.first(where: { $0 is RecipeDetailBottomViewController }) as? RecipeDetailBottomViewController {
            bottomChildController = childController
            
            // Replace the bottom controller with one specific to iPad.
            if traitCollection.userInterfaceIdiom == .pad {
                if let storyboard = self.storyboard {
                    if let newChildController = RecipeDetailBottomAltViewController.instantiate(with: storyboard) {
                        let containerView = childController.view.superview
                        hideContent(controller: childController)
                        displayContent(controller: newChildController, to: containerView)
                        bottomChildController = newChildController
                    }
                }
            }
            
            bottomChildController?.recipe = recipe
        }
        
        // Listen for recipe changes in the data store.
        dataStoreSubscriber = dataStore.$allRecipes
            .receive(on: RunLoop.main)
            .sink { [weak self] recipes in
                guard
                    let recipe = self?.recipe,
                    let updatedRecipe = recipes.first(where: { $0.id == recipe.id })
                else { return }
                
                self?.recipe = updatedRecipe
            }
        
        let notificationCenter = NotificationCenter.default
        editRecipeSubscriber = notificationCenter.publisher(for: .editRecipe)
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] notification in
                self?.editRecipe(notification.object)
            })
        
        toggleRecipeIsFavoriteSubscriber = notificationCenter.publisher(for: .toggleRecipeIsFavorite)
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] notification in
                self?.toggleFavorite(notification.object)
            })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let splitViewController = self.splitViewController {
            navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
            navigationItem.leftItemsSupplementBackButton = true
        }
        
        navigationController?.setToolbarHidden(false, animated: animated)
        
        #if targetEnvironment(macCatalyst)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        navigationController?.setToolbarHidden(true, animated: animated)
        #endif
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configureActivityItems()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setToolbarHidden(true, animated: animated)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard
            let navController = segue.destination as? UINavigationController,
            let recipeEditor = navController.topViewController as? RecipeEditorViewController
            else {
                return
        }
        
        recipeEditor.recipe = self.recipe
        recipeEditor.isModalInPresentation = true
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func delete(_ sender: Any?) {
        deleteRecipe(sender)
    }
}

// MARK: - Actions

extension RecipeDetailViewController {
    
    @IBAction func toggleFavorite(_ sender: Any?) {
        guard var recipe = self.recipe else { return }
        
        recipe.isFavorite.toggle()
        self.recipe = dataStore.update(recipe)
    }
    
    @IBAction func deleteRecipe(_ sender: Any?) {
        guard let recipe = self.recipe else { return }
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { (action) in
            if dataStore.delete(recipe) {
                self.recipe = nil
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        #if targetEnvironment(macCatalyst)
        let preferredStyle = UIAlertController.Style.alert
        #else
        let preferredStyle = UIAlertController.Style.actionSheet
        #endif
        
        let alert = UIAlertController(title: "Are you sure you want to delete \(recipe.title)?", message: nil, preferredStyle: preferredStyle)
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        if let popoverPresentationController = alert.popoverPresentationController {
            popoverPresentationController.barButtonItem = sender as? UIBarButtonItem
        }
        
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func shareRecipe(_ sender: Any?) {
        guard let recipe = self.recipe else { return }
        
        let items: [Any] = [recipe.title, recipe.fullImage]
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activityViewController.completionWithItemsHandler = { activity, completed, items, error in
            os_log("Activity completed: %s", completed ? "true" : "false")
        }

        // Configure the popover presentation controller for iPad.
        if let popover = activityViewController.popoverPresentationController {
            if let barButtonItem = sender as? UIBarButtonItem {
                popover.barButtonItem = barButtonItem
            }
        }
        present(activityViewController, animated: true, completion: nil)
    }
    
    @objc
    func editRecipe(_ sender: Any?) {
        if recipe != nil {
            guard let recipeEditor = RecipeEditorViewController.instantiateFromStoryboard() else { return }
            recipeEditor.recipe = recipe
            let navigationController = UINavigationController(rootViewController: recipeEditor)
            present(navigationController, animated: true, completion: nil)
        }
    }
    
}

// MARK: - UI Helpers

extension RecipeDetailViewController {
    
    fileprivate func updateUI() {
        loadViewIfNeeded()

        guard  let recipe = self.recipe
        else {
            toggleNoRecipeView(show: true)
            return
        }

        self.title = recipe.title
        topChildController?.recipe = recipe
        bottomChildController?.recipe = recipe
        
        let imageName = recipe.isFavorite ? "heart.fill" : "heart"
        recipeFavoriteButton.image = UIImage(systemName: imageName)
        
        toggleNoRecipeView(show: false)
    }
    
    fileprivate func addNoRecipeView() {
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.systemBackground
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.textColor = UIColor.systemGray2
        label.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        label.adjustsFontForContentSizeCategory = true
        label.text = "No Recipe Selected"
        
        noRecipeView = UIView()
        noRecipeView.translatesAutoresizingMaskIntoConstraints = false
        noRecipeView.alpha = 1.0
        noRecipeView.addSubview(backgroundView)
        noRecipeView.addSubview(label)
        self.view.addSubview(noRecipeView)

        NSLayoutConstraint.activate([
            noRecipeView.topAnchor.constraint(equalTo: self.view.topAnchor),
            noRecipeView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            noRecipeView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            noRecipeView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            
            backgroundView.topAnchor.constraint(equalTo: noRecipeView.topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: noRecipeView.bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: noRecipeView.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: noRecipeView.trailingAnchor),

            label.centerXAnchor.constraint(equalTo: noRecipeView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: noRecipeView.centerYAnchor),
            label.widthAnchor.constraint(equalTo: noRecipeView.widthAnchor)
        ])
    }
    
    fileprivate func toggleNoRecipeView(show: Bool) {
        UIViewPropertyAnimator.runningPropertyAnimator(
            withDuration: 0.2,
            delay: 0.0,
            options: .curveEaseIn,
            animations: {
                self.noRecipeView.alpha = show ? 1.0 : 0.0
                if show == true {
                    self.title = nil
                    self.navigationController?.isToolbarHidden = true
                    self.navigationItem.rightBarButtonItem = nil
                }
            },
            completion: nil
        )
    }
    
    fileprivate func displayContent(controller: UIViewController, to view: UIView?) {
        guard let view = view else { return }
        
        addChild(controller)
        controller.view.frame = view.bounds
        view.addSubview(controller.view)
        controller.didMove(toParent: self)
    }
    
    fileprivate func hideContent(controller: UIViewController) {
        controller.willMove(toParent: nil)
        controller.view.removeFromSuperview()
        controller.removeFromParent()
    }
}

// MARK: - Unwind Segues

extension RecipeDetailViewController {
    
    @IBAction func cancelRecipeEditor(_ unwindSegue: UIStoryboardSegue) {
        // Do nothing.
    }
    
    @IBAction func saveRecipeEditor(_ unwindSegue: UIStoryboardSegue) {
        guard
            let recipeEditor = unwindSegue.source as? RecipeEditorViewController,
            let recipe = recipeEditor.editedRecipe()
        else { return }
        
        self.recipe = dataStore.update(recipe)
    }

}

extension RecipeDetailViewController {
    
    private func configureActivityItems() {
        guard let recipe = self.recipe else { return }
        
        let configuration = UIActivityItemsConfiguration(objects: [recipe.fullImage])
        configuration.metadataProvider = { key in
            switch key {
            case .title, .messageBody:
                return recipe.title
            default:
                return nil
            }
        }
        
        NotificationCenter.default.post(name: .activityItemsConfigurationDidChange,
                                        object: self,
                                        userInfo: [NotificationKey.activityItemsConfiguration: configuration])
    }
}

// MARK: - User Defaults

// Extend UserDefaults for quick access to nameColorKey.
extension UserDefaults {
    @objc dynamic var nameColorKey: Int {
        return integer(forKey: RecipeDetailViewController.nameColorKey)
    }
}

// MARK: - Preferred Background Color
extension RecipeDetailViewController {
    static let nameColorKey = "nameColorKey" // Key for obtains the preference view color.
    
    private func updatePreferredBackgroundColor(colorValue: AppDelegate.BackgroundColors) {
//        let viewColor = UserDefaults.standard.integer(forKey: RecipeDetailViewController.nameColorKey)
//        let colorValue = AppDelegate.BackgroundColors(rawValue: viewColor)
        switch colorValue {
        case .blue:
            if let childController = children.first(where: { $0 is RecipeDetailTopViewController }) as? RecipeDetailTopViewController {
                childController.titleLabel.textColor = UIColor.systemBlue
            }
        case .teal:
            if let childController = children.first(where: { $0 is RecipeDetailTopViewController }) as? RecipeDetailTopViewController {
                childController.titleLabel.textColor = UIColor.systemTeal
            }
        case .indigo:
            if let childController = children.first(where: { $0 is RecipeDetailTopViewController }) as? RecipeDetailTopViewController {
                childController.titleLabel.textColor = UIColor.systemIndigo
            }
//        default:
//            Swift.debugPrint("Invalid color!")
        }
    }
}
