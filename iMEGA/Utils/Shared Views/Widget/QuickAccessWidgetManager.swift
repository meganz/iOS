@preconcurrency import Combine
import Foundation
import MEGADomain
import MEGAFoundation
import MEGAPresentation
import MEGASDKRepo
import MEGASwift
import WidgetKit

final class QuickAccessWidgetManager: NSObject, @unchecked Sendable {
    private let recentItemsUseCase: any RecentItemsUseCaseProtocol
    private let recentNodesUseCase: any RecentNodesUseCaseProtocol
    private let favouriteItemsUseCase: any FavouriteItemsUseCaseProtocol
    private let favouriteNodesUseCase: any FavouriteNodesUseCaseProtocol
    private let widgetCentre: any WidgetCentreProtocol
    
    enum WidgetType: CaseIterable {
        case recents
        case favourites
    }
    
    private let updateWidgetContentSubject = PassthroughSubject<WidgetType, Never>()
    
    @Atomic 
    private var task: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }
    
    deinit {
        task?.cancel()
    }
    
    override init() {
        self.recentItemsUseCase = RecentItemsUseCase(repo: RecentItemsRepository(store: MEGAStore.shareInstance()))
        self.recentNodesUseCase = RecentNodesUseCase(repo: RecentNodesRepository.newRepo)
        self.favouriteItemsUseCase = FavouriteItemsUseCase(repo: FavouriteItemsRepository(store: MEGAStore.shareInstance()))
        self.favouriteNodesUseCase = FavouriteNodesUseCase(
            repo: FavouriteNodesRepository.newRepo,
            nodeRepository: NodeRepository.newRepo,
            contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(repo: UserAttributeRepository.newRepo),
            hiddenNodesFeatureFlagEnabled: { DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes) })
        self.widgetCentre = WidgetCenter.shared
        super.init()
        
        $task.mutate { $0 = monitorAllWidgetChanges() }
    }

    init(
        recentItemsUseCase: some RecentItemsUseCaseProtocol = RecentItemsUseCase(repo: RecentItemsRepository(store: MEGAStore.shareInstance())),
        recentNodesUseCase: some RecentNodesUseCaseProtocol = RecentNodesUseCase(repo: RecentNodesRepository.newRepo),
        favouriteItemsUseCase: some FavouriteItemsUseCaseProtocol = FavouriteItemsUseCase(repo: FavouriteItemsRepository(store: MEGAStore.shareInstance())),
        favouriteNodesUseCase: some FavouriteNodesUseCaseProtocol = FavouriteNodesUseCase(
            repo: FavouriteNodesRepository.newRepo,
            nodeRepository: NodeRepository.newRepo,
            contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(repo: UserAttributeRepository.newRepo),
            hiddenNodesFeatureFlagEnabled: { DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes) }),
        widgetCentre: some WidgetCentreProtocol = WidgetCenter.shared
    ) {
        self.recentItemsUseCase = recentItemsUseCase
        self.recentNodesUseCase = recentNodesUseCase
        self.favouriteItemsUseCase = favouriteItemsUseCase
        self.favouriteNodesUseCase = favouriteNodesUseCase
        self.widgetCentre = widgetCentre
        
        super.init()
        
        $task.mutate { $0 = monitorAllWidgetChanges() }
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
        WidgetType.allCases.forEach(updateWidgetContentSubject.send(_:))
    }

    @objc func updateWidgetContent(with nodeList: MEGANodeList) {
        let updatedNodes = nodeList.toNodeEntities()
        
        guard updatedNodes.isNotEmpty else {
            return
        }
        
        let shouldRecreateRecentItems = updatedNodes.contains { node in
            if node.isFolder {
                false
            } else {
                node.changeTypes.intersection([.new, .removed, .sensitive, .name]).isNotEmpty
            }
        }
        
        let shouldRecreateFavouriteItems = updatedNodes.contains { node in
            if node.changeTypes.intersection([.name, .new]).isNotEmpty {
                node.isFavourite
            } else {
                node.changeTypes.intersection([.removed, .sensitive, .favourite]).isNotEmpty
            }
        }
        
        if shouldRecreateRecentItems {
            updateWidgetContentSubject.send(.recents)
        }
        
        if shouldRecreateFavouriteItems {
            updateWidgetContentSubject.send(.favourites)
        }
    }
    
    // MARK: - Private
    
    func reloadWidgetContentOfKind(kind: String) {
        #if arch(arm64) || arch(i386) || arch(x86_64)
        widgetCentre.reloadTimelines(ofKind: kind)
        #endif
    }
    
    private func monitorAllWidgetChanges() -> Task<Void, Never> {
        Task {
            await withTaskGroup(of: Void.self) { taskGroup in
                taskGroup.addTasksUnlessCancelled(for: WidgetType.allCases, priority: .background) { [weak self] type in
                    guard let self else { return }
                    
                    switch type {
                    case .favourites:
                        await monitorFavouriteContentUpdate()
                    case .recents:
                        await monitorRecentsContentUpdate()
                    }
                }
            }
        }
    }
    
    private func monitorFavouriteContentUpdate() async {
        
        let createFavouriteWidgetNodes = updateWidgetContentSubject.filter { $0 == .favourites }
            .debounceImmediate(for: .seconds(1), scheduler: DispatchQueue.global(qos: .background))
            .values
        
        for await _ in createFavouriteWidgetNodes {
            await createFavouritesItemsData()
        }
    }
    
    private func monitorRecentsContentUpdate() async {
        
        let createFavouriteWidgetNodes = updateWidgetContentSubject.filter { $0 == .recents }
            .debounceImmediate(for: .seconds(1), scheduler: DispatchQueue.global(qos: .background))
            .values
        
        for await _ in createFavouriteWidgetNodes {
            await createRecentItemsData()
        }
    }

    private func createRecentItemsData() async {
        do {
            let recentActions = try await recentNodesUseCase.recentActionBuckets(limitCount: MEGAQuickAccessWidgetMaxDisplayItems)
            var recentItems = [RecentItemEntity]()
            recentActions.forEach { (bucket) in
                bucket.nodes.forEach({ (node) in
                    recentItems.append(RecentItemEntity(base64Handle: node.base64Handle, name: node.name, timestamp: bucket.date, isUpdate: bucket.isUpdate))
                })
            }
            self.recentItemsUseCase.resetRecentItems(by: recentItems) { [weak self] (result) in
                switch result {
                case .success:
                    self?.reloadWidgetContentOfKind(kind: MEGARecentsQuickAccessWidget)
                case .failure:
                    MEGALogError("Error creating recent items data for widget")
                }
            }
        } catch {
            MEGALogError("Error creating recent items data for widget")
        }
    }

    private func createFavouritesItemsData() async {
        
        do {
            let favouriteItems = try await favouriteNodesUseCase.allFavouriteNodes(searchString: nil, excludeSensitives: true, limit: MEGAQuickAccessWidgetMaxDisplayItems)
                .map { FavouriteItemEntity(base64Handle: $0.base64Handle, name: $0.name, timestamp: Date()) }
            
            try await favouriteItemsUseCase.createFavouriteItems(favouriteItems)
            
            reloadWidgetContentOfKind(kind: MEGAFavouritesQuickAccessWidget)
        } catch {
            MEGALogError("Error creating favourite items data for widget: \(error.localizedDescription)")
        }
    }
}
