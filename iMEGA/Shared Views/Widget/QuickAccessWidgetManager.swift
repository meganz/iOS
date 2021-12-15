
import Foundation
import WidgetKit

@available(iOS 14.0, *)
class QuickAccessWidgetManager: NSObject {
    private let recentItemsUseCase: RecentItemsUseCaseProtocol
    private let recentNodesUseCase: RecentNodesUseCaseProtocol
    private let favouriteItemsUseCase: FavouriteItemsUseCaseProtocol
    private let favouriteNodesUseCase: FavouriteNodesUseCaseProtocol
    
    private let debouncer = Debouncer(delay: 1, dispatchQueue: DispatchQueue.global(qos: .background))

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
        self.createRecentItemsDataWithDebounce()
        self.createFavouritesItemsDataWithDebounce()
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
            
            if node.hasChangedType(.attributes) {
                shouldCreateFavouriteItems = true
            }
        }
        
        if shouldCreateRecentItems {
            self.createRecentItemsDataWithDebounce()
        }
        
        if shouldCreateFavouriteItems {
            self.createFavouritesItemsDataWithDebounce()
        }
    }
    
    @objc func insertFavouriteItem(for node: MEGANode) {
        guard let base64Handle = node.base64Handle, let name = node.name else { return }
        favouriteItemsUseCase.insertFavouriteItem(FavouriteItemEntity(base64Handle: base64Handle, name: name, timestamp: Date()))
        QuickAccessWidgetManager.reloadWidgetContentOfKind(kind: MEGAFavouritesQuickAccessWidget)
    }
    
    @objc func deleteFavouriteItem(for node: MEGANode) {
        guard let base64Handle = node.base64Handle else { return }
        favouriteItemsUseCase.deleteFavouriteItem(with: base64Handle)
        QuickAccessWidgetManager.reloadWidgetContentOfKind(kind: MEGAFavouritesQuickAccessWidget)
    }
    
    //MARK: - Private
    private func createRecentItemsDataWithDebounce() {
        debouncer.start {
            self.createRecentItemsData()
        }
    }
    
    private func createRecentItemsData() {
        recentNodesUseCase.getRecentActionBuckets(limitCount: MEGAQuickAccessWidgetMaxDisplayItems) { (result) in
            switch result {
            case .success(let recentActions):
                var recentItems = [RecentItemEntity]()
                recentActions.forEach { (bucket) in
                    bucket.nodes.forEach({ (node) in
                        recentItems.append(RecentItemEntity(base64Handle: node.base64Handle, name: node.name, timestamp: bucket.date, isUpdate: bucket.isUpdate))
                    })
                }
                self.recentItemsUseCase.resetRecentItems(by: recentItems) { (result) in
                    switch result {
                    case .success(_):
                        QuickAccessWidgetManager.reloadWidgetContentOfKind(kind: MEGARecentsQuickAccessWidget)
                    case .failure(_):
                        MEGALogError("Error creating recent items data for widget")
                    }
                }
            case .failure(_):
                MEGALogError("Error creating recent items data for widget")
            }
        }
    }
    
    private func createFavouritesItemsDataWithDebounce() {
        debouncer.start {
            self.createFavouritesItemsData()
        }
    }
    
    private func createFavouritesItemsData() {
        favouriteNodesUseCase.getFavouriteNodes(limitCount: MEGAQuickAccessWidgetMaxDisplayItems) { (result) in
            switch result {
            case .success(let nodes):
                var favouriteItems = [FavouriteItemEntity]()
                nodes.forEach {
                    favouriteItems.append(FavouriteItemEntity(base64Handle: $0.base64Handle, name: $0.name, timestamp: Date()))
                }
                self.favouriteItemsUseCase.createFavouriteItems(favouriteItems) { (result) in
                    switch result {
                    case .success(_):
                        QuickAccessWidgetManager.reloadWidgetContentOfKind(kind: MEGAFavouritesQuickAccessWidget)
                    case .failure(_):
                        MEGALogError("Error creating favourite items data for widget")
                    }
                }
            case .failure(_):
                MEGALogError("Error creating favourite items data for widget")
            }
        }
    }
}
