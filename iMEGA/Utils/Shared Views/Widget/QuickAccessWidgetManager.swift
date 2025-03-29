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
    
    enum WidgetType: CaseIterable, Sendable {
        case recents
        case favourites
    }
    
    enum WidgetManagerStatus: Sendable {
        case uninitialised
        case initialised
    }
    private typealias WidgetManagerStatusContinuation = AsyncStream<WidgetManagerStatus>.Continuation
    private let updateWidgetContentSubject = PassthroughSubject<WidgetType, Never>()

    @Atomic
    private var task: Task<Void, Never>?
    
    deinit {
        task?.cancel()
    }
    
    override init() {
        self.recentItemsUseCase = RecentItemsUseCase(repo: RecentItemsRepository(store: MEGAStore.shareInstance()))
        self.recentNodesUseCase = RecentNodesUseCase(
            recentNodesRepository: RecentNodesRepository.newRepo,
            contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(repo: UserAttributeRepository.newRepo),
            userUpdateRepository: UserUpdateRepository.newRepo,
            requestStatesRepository: RequestStatesRepository.newRepo,
            nodeRepository: NodeRepository.newRepo,
            hiddenNodesFeatureFlagEnabled: { DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes) })
        self.favouriteItemsUseCase = FavouriteItemsUseCase(repo: FavouriteItemsRepository(store: MEGAStore.shareInstance()))
        self.favouriteNodesUseCase = FavouriteNodesUseCase(
            repo: FavouriteNodesRepository.newRepo,
            nodeRepository: NodeRepository.newRepo,
            sensitiveDisplayPreferenceUseCase: SensitiveDisplayPreferenceUseCase(
                sensitiveNodeUseCase: SensitiveNodeUseCase(
                    nodeRepository: NodeRepository.newRepo,
                    accountUseCase: AccountUseCase(
                        repository: AccountRepository.newRepo)
                ),
                contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(
                    repo: UserAttributeRepository.newRepo),
                hiddenNodesFeatureFlagEnabled: { DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes) }))
        self.widgetCentre = WidgetCenter.shared
        super.init()
    }

    init(
        recentItemsUseCase: some RecentItemsUseCaseProtocol = RecentItemsUseCase(repo: RecentItemsRepository(store: MEGAStore.shareInstance())),
        recentNodesUseCase: some RecentNodesUseCaseProtocol = RecentNodesUseCase(
            recentNodesRepository: RecentNodesRepository.newRepo,
            contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(repo: UserAttributeRepository.newRepo),
            userUpdateRepository: UserUpdateRepository.newRepo,
            requestStatesRepository: RequestStatesRepository.newRepo,
            nodeRepository: NodeRepository.newRepo,
            hiddenNodesFeatureFlagEnabled: { DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes) }),
        favouriteItemsUseCase: some FavouriteItemsUseCaseProtocol = FavouriteItemsUseCase(repo: FavouriteItemsRepository(store: MEGAStore.shareInstance())),
        favouriteNodesUseCase: some FavouriteNodesUseCaseProtocol = FavouriteNodesUseCase(
            repo: FavouriteNodesRepository.newRepo,
            nodeRepository: NodeRepository.newRepo,
            sensitiveDisplayPreferenceUseCase: SensitiveDisplayPreferenceUseCase(
                sensitiveNodeUseCase: SensitiveNodeUseCase(
                    nodeRepository: NodeRepository.newRepo,
                    accountUseCase: AccountUseCase(
                        repository: AccountRepository.newRepo)
                ),
                contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(
                    repo: UserAttributeRepository.newRepo),
                hiddenNodesFeatureFlagEnabled: { DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes) })),
        widgetCentre: some WidgetCentreProtocol = WidgetCenter.shared
    ) {
        self.recentItemsUseCase = recentItemsUseCase
        self.recentNodesUseCase = recentNodesUseCase
        self.favouriteItemsUseCase = favouriteItemsUseCase
        self.favouriteNodesUseCase = favouriteNodesUseCase
        self.widgetCentre = widgetCentre
        
        super.init()
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
        
    @objc func startWidgetManager() async {
        
        let (stream, continuation) = AsyncStream.makeStream(of: WidgetManagerStatus.self, bufferingPolicy: .bufferingNewest(1))
        continuation.yield(.uninitialised)
        $task.mutate { $0 = monitorAllWidgetChanges(continuation: continuation) }
        
        _ = await stream.first(where: { $0 == .initialised })
    }
    
    @objc func reloadWidgetItemData() {
        WidgetType.allCases.forEach(updateWidgetContentSubject.send(_:))
    }
    
    @objc func stopWidgetManager() {
        $task.mutate {
            $0?.cancel()
            $0 = nil
        }
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
    
    private func monitorAllWidgetChanges(continuation: WidgetManagerStatusContinuation) -> Task<Void, Never> {
        Task {
            await withTaskGroup(of: Void.self) { taskGroup in
                let cases = WidgetType.allCases
                let taskStartedStream = AsyncStream.makeStream(of: WidgetType.self, bufferingPolicy: .bufferingNewest(cases.count))

                taskGroup.addTasksUnlessCancelled(for: cases, priority: .background) { [weak self] type in
                    guard let self else { return }
                    switch type {
                    case .favourites:
                        await monitorFavouriteContentUpdate(
                            taskStartedContinuation: taskStartedStream.continuation)
                    case .recents:
                        await monitorRecentsContentUpdate(
                            taskStartedContinuation: taskStartedStream.continuation)
                    }
                }
                
                // Ensure all monitors have started, and then initialise manager to start receiving requests
                var uniqueWidgetTypes = cases
                for await widgetType in taskStartedStream.stream {
                    uniqueWidgetTypes.remove(object: widgetType)
                    if uniqueWidgetTypes.isEmpty {
                        taskStartedStream.continuation.finish()
                        break
                    }
                }
                
                continuation.yield(.initialised)
                continuation.finish()
            }
        }
    }
    
    private func monitorFavouriteContentUpdate(taskStartedContinuation: AsyncStream<WidgetType>.Continuation) async {
        let createFavouriteWidgetNodes = updateWidgetContentSubject
            .filter { $0 == .favourites }
            .debounceImmediate(for: .seconds(1), scheduler: DispatchQueue.global(qos: .background))
            .values
        
        taskStartedContinuation.yield(.favourites)
        
        for await _ in createFavouriteWidgetNodes {
            guard !Task.isCancelled else {
                break
            }
            await createFavouritesItemsData()
        }
    }
    
    private func monitorRecentsContentUpdate(taskStartedContinuation: AsyncStream<WidgetType>.Continuation) async {
        
        let createFavouriteWidgetNodes = updateWidgetContentSubject
            .filter { $0 == .recents }
            .debounceImmediate(for: .seconds(1), scheduler: DispatchQueue.global(qos: .background))
            .values
        
        taskStartedContinuation.yield(.recents)
        
        for await _ in createFavouriteWidgetNodes {
            guard !Task.isCancelled else {
                break
            }
            await createRecentItemsData()
        }
    }

    private func createRecentItemsData() async {
        do {
            let recentActions = try await recentNodesUseCase.recentActionBuckets(limitCount: MEGAQuickAccessWidgetMaxDisplayItems, excludeSensitive: true)
            try Task.checkCancellation()
            var recentItems = [RecentItemEntity]()
            recentActions.forEach { (bucket) in
                bucket.nodes.forEach({ (node) in
                    recentItems.append(RecentItemEntity(base64Handle: node.base64Handle, name: node.name, timestamp: bucket.date, isUpdate: bucket.isUpdate))
                })
            }
            do {
                try await recentItemsUseCase.resetRecentItems(by: recentItems)
                reloadWidgetContentOfKind(kind: MEGARecentsQuickAccessWidget)
            } catch {
                MEGALogError("Error creating recent items data for widget")
            }
        } catch {
            MEGALogError("Error creating recent items data for widget")
        }
    }

    private func createFavouritesItemsData() async {
        do {
            let favouriteItems = try await favouriteNodesUseCase.allFavouriteNodes(searchString: nil, excludeSensitives: true, limit: MEGAQuickAccessWidgetMaxDisplayItems)
                .map { FavouriteItemEntity(base64Handle: $0.base64Handle, name: $0.name, timestamp: Date()) }
            
            try Task.checkCancellation()
            
            try await favouriteItemsUseCase.createFavouriteItems(favouriteItems)
            
            try Task.checkCancellation()
            
            reloadWidgetContentOfKind(kind: MEGAFavouritesQuickAccessWidget)
        } catch {
            MEGALogError("Error creating favourite items data for widget: \(error.localizedDescription)")
        }
    }
}
