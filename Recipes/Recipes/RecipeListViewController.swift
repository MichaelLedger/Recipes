/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The recipe list view controller.
*/

import UIKit
import Combine

class RecipeListViewController: UIViewController {

    static let storyboardID = "RecipeList"
    static func instantiateFromStoryboard() -> RecipeListViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        return storyboard.instantiateViewController(identifier: storyboardID) as? RecipeListViewController
    }

    @IBOutlet weak var collectionView: UICollectionView!

    enum Section: Int {
        case main
    }

    private var dataSource: UICollectionViewDiffableDataSource<Section, Recipe>!

    private var collectionName: String? // Name of a recipe collection.
    private var selectedDataType: TabBarItem = .all
    private var selectedRecipe: Recipe? {
        guard
            let indexPathsForSelectedItems = collectionView.indexPathsForSelectedItems,
            let selectedIndexPath = indexPathsForSelectedItems.first,
            let selectedRecipe = dataSource.itemIdentifier(for: selectedIndexPath)
        else { return nil }
        
        return selectedRecipe
    }
    
    private var dataStoreSubscriber: AnyCancellable?
    private var newRecipeSubscriber: AnyCancellable?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let tabBarController = self.tabBarController,
           let dataType = TabBarItem(rawValue: tabBarController.selectedIndex) {
            selectedDataType = dataType
        }

        configureCollectionView()
        configureDataSource()
        
        // Listen for recipe changes in the data store.
        dataStoreSubscriber = dataStore.$allRecipes
            .receive(on: RunLoop.main)
            .sink { [weak self] recipes in
                self?.apply(recipes)
            }
     
        newRecipeSubscriber = NotificationCenter.default.publisher(for: .newRecipe)
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] notification in
                guard let recipeEditor = RecipeEditorViewController.instantiateFromStoryboard()
                else { return }
                
                let navigationController = UINavigationController(rootViewController: recipeEditor)
                self?.present(navigationController, animated: true, completion: nil)
            })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        #if targetEnvironment(macCatalyst)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        #endif
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let navController = segue.destination as? UINavigationController else { return }
        
        // Prevent the user from dismissing the recipe editor by swiping down.
        if let recipeEditor = navController.topViewController as? RecipeEditorViewController {
            recipeEditor.isModalInPresentation = true
        }
    }
    
}

extension RecipeListViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {

        guard let recipe = dataSource.itemIdentifier(for: indexPath) else { return nil }
        
        let configuration = UIContextMenuConfiguration(
            identifier: nil,
            previewProvider: nil) { (menuElements) -> UIMenu? in
         
            let favoriteAction = UIAction(title: "Favorite", state: recipe.isFavorite ? .on : .off) { (action) in
                var recipeToUpdate = recipe
                recipeToUpdate.isFavorite.toggle()
                _ = dataStore.update(recipeToUpdate)
            }
            
            let deleteAction = UIAction(title: "Delete") { (action) in
                _ = dataStore.delete(recipe)
            }
            
            return UIMenu(title: "", options: [], children: [favoriteAction, deleteAction])
        }
        return configuration
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let recipeDetailViewController = RecipeDetailViewController.instantiateFromStoryboard() else { return }
        
        recipeDetailViewController.recipe = dataSource.itemIdentifier(for: indexPath)
        let navigationController = UINavigationController(rootViewController: recipeDetailViewController)
        showDetailViewController(navigationController, sender: self)
    }

}

extension RecipeListViewController {
    func configureCollectionView() {
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true
        collectionView.collectionViewLayout = createCollectionViewLayout()
    }
    
    func createCollectionViewLayout() -> UICollectionViewLayout {
        let recipeItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let recipeItem = NSCollectionLayoutItem(layoutSize: recipeItemSize)
        recipeItem.contentInsets = NSDirectionalEdgeInsets(top: 5.0, leading: 10.0, bottom: 5.0, trailing: 10.0)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalWidth(0.375))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: recipeItem, count: 2)
        
        let section = NSCollectionLayoutSection(group: group)
        let layout = UICollectionViewCompositionalLayout(section: section)
        
        return layout
    }
    
}

extension RecipeListViewController {
    
    func configureDataSource() {
        // Register the cell that displays a recipe in the collection view.
        collectionView.register(RecipeListCell.nib, forCellWithReuseIdentifier: RecipeListCell.reuseIdentifier)

        // Create a diffable data source, and configure the cell with recipe data.
        dataSource = UICollectionViewDiffableDataSource <Section, Recipe>(collectionView: self.collectionView) { (
            collectionView: UICollectionView,
            indexPath: IndexPath,
            recipe: Recipe) -> UICollectionViewCell? in
        
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RecipeListCell.reuseIdentifier, for: indexPath)
            
            if let recipeListCell = cell as? RecipeListCell {
                recipeListCell.configure(with: recipe)
            }
        
            return cell
        }
    }
    
    func apply(_ recipes: [Recipe]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Recipe>()
        snapshot.appendSections([.main])
        switch selectedDataType {
        case .favorites:
            snapshot.appendItems(recipes.filter { $0.isFavorite })
        case .recents:
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            snapshot.appendItems(recipes.filter { $0.addedOnDate > thirtyDaysAgo })
        case .collections:
            if let collectionName = self.collectionName {
                let recipeCollection = recipes.filter { $0.collections.contains(collectionName) }
                snapshot.appendItems(recipeCollection)
            }
        default:
            snapshot.appendItems(recipes)
        }
        dataSource.apply(snapshot, animatingDifferences: true)
    }

}

extension RecipeListViewController {
    
    func showRecipes(_ tabBarItem: TabBarItem) {
        selectedDataType = tabBarItem
        apply(dataStore.allRecipes)
    }
    
    func showRecipes(from collection: String) {
        selectedDataType = .collections
        collectionName = collection
        apply(dataStore.allRecipes)
    }

}

// MARK: - Unwind Segues
extension RecipeListViewController {
    
    @IBAction func cancelRecipeEditor(_ unwindSegue: UIStoryboardSegue) {
        // Do nothing.
    }
    
    @IBAction func saveRecipeEditor(_ unwindSegue: UIStoryboardSegue) {
        guard
            let recipeEditor = unwindSegue.source as? RecipeEditorViewController,
            let recipe = recipeEditor.editedRecipe()
        else { return }

        let recipeToSelect = dataStore.add(recipe)

        if UIDevice.current.userInterfaceIdiom == .pad {
            if let indexPath = dataSource.indexPath(for: recipeToSelect) {
                collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .top)
                self.collectionView(collectionView, didSelectItemAt: indexPath)
            }
        }
    }

}
