
import Foundation
import WidgetKit

@available(iOS 14.0, *)
class QuickAccessWidgetManager: NSObject {
    
    private let recentItemsUseCase: RecentItemsUseCaseProtocol
    private let recentNodesUseCase: RecentNodesUseCaseProtocol
    private let favouriteItemsUseCase: FavouriteItemsUseCaseProtocol
    private let favouriteNodesUseCase: FavouriteNodesUseCaseProtocol

    override init() {
        self.recentItemsUseCase = RecentItemsUseCase(repo: RecentItemsRepository(store: MEGAStore.shareInstance()))
        self.recentNodesUseCase = RecentNodesUseCase(repo: RecentNodesRepository(sdk: MEGASdkManager.sharedMEGASdk()))
        self.favouriteItemsUseCase = FavouriteItemsUseCase(repo: FavouriteItemsRepository(store: MEGAStore.shareInstance()))
        self.favouriteNodesUseCase = FavouriteNodesUseCase(repo: FavouriteNodesRepository(sdk: MEGASdkManager.sharedMEGASdk()))
    }

    @objc public static func reloadAllWidgetsContent() {
        #if arch(arm64) || arch(i386) || arch(x86_64)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
    
    @objc public static func reloadWidgetContentOfKind(kind: String) {
        #if arch(arm64) || arch(i386) || arch(x86_64)
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
        #endif
    }
    
    @objc func createWidgetItemData() {
        createRecentItemsData {
            self.createFavouritesItemsData()
        }
    }
    
    @objc func createQuickAccessWidgetItemsDataIfNeeded(for nodeList: MEGANodeList) {
        guard let nodes = nodeList.mnz_nodesArrayFromNodeList() else {
            return
        }
        
        var shouldCreateRecentItems = false
        var shouldCreateFavouriteItems = false
        
        for node in nodes {
            if (node.isFolder() && node.hasChangedType(.new)) || node.hasChangedType(.removed) {
                shouldCreateRecentItems = false
            } else {
                shouldCreateRecentItems = true
            }
            
            if node.hasChangedType(.attributes) && node.isRemoteChange() {
                shouldCreateFavouriteItems = true
            }
        }
        
        if shouldCreateRecentItems {
            createRecentItemsData {
                if shouldCreateFavouriteItems {
                    self.createFavouritesItemsData()
                }
            }
        } else {
            self.createFavouritesItemsData()
        }
    }
    
    @objc func insertFavouriteItem(for node: MEGANode) {
        favouriteItemsUseCase.insertFavouriteItem(FavouriteItemEntity(base64Handle: node.base64Handle, name: node.name, timestamp: Date()))
        QuickAccessWidgetManager.reloadWidgetContentOfKind(kind: MEGAQuickAccessWidget)
    }
    
    @objc func deleteFavouriteItem(for node: MEGANode) {
        favouriteItemsUseCase.deleteFavouriteItem(with: node.base64Handle)
        QuickAccessWidgetManager.reloadWidgetContentOfKind(kind: MEGAQuickAccessWidget)
    }
    
    //MARK: - Private
    func createRecentItemsData(completion: (() -> Void)? = nil) {
        
        recentNodesUseCase.recentActionBuckets(completion: { (result) in
            switch result {
            case .success(let recentActions):
                var recentItems = [RecentItemEntity]()
                recentActions.forEach { (bucket) in
                    bucket.nodesList.mnz_nodesArrayFromNodeList()?.forEach({ (node) in
                        recentItems.append(RecentItemEntity(base64Handle: node.base64Handle, name: node.name, timestamp: bucket.timestamp, isUpdate: bucket.isUpdate))
                    })
                }
                self.recentItemsUseCase.resetRecentItems(by: Array(recentItems.prefix(8))) { (result) in
                    switch result {
                    case .success(_):
                        QuickAccessWidgetManager.reloadWidgetContentOfKind(kind: MEGAQuickAccessWidget)
                    case .failure(_):
                        MEGALogError("Error creating recent items data for widget")
                    }
                    if let completion = completion {
                        completion()
                    }
                }
            case .failure(_):
                MEGALogError("Error creating recent items data for widget")
            }
        })
        
    }
    
    func createFavouritesItemsData(completion: (() -> Void)? = nil) {
        
        favouriteNodesUseCase.favouriteNodes { (result) in
            switch result {
            case .success(let nodes):
                var favouriteItems = [FavouriteItemEntity]()
                nodes.forEach {
                    favouriteItems.append(FavouriteItemEntity(base64Handle: $0.base64Handle, name: $0.name, timestamp: Date()))
                }
                self.favouriteItemsUseCase.createFavouriteItems(favouriteItems) { (result) in
                    switch result {
                    case .success(_):
                        QuickAccessWidgetManager.reloadWidgetContentOfKind(kind: MEGAQuickAccessWidget)
                    case .failure(_):
                        MEGALogError("Error creating favourite items data for widget")
                    }
                    if let completion = completion {
                        completion()
                    }
                }
            case .failure(_):
                MEGALogError("Error creating favourite items data for widget")
            }
        }
    }
}
