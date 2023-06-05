import CoreSpotlight
import MobileCoreServices
import Combine
import MEGADomain

final class SpotlightIndexer: NSObject {
    private let sdk: MEGASdk
    private let favouritesUseCase: FavouriteNodesUseCaseProtocol
    private let preferenceUseCase = PreferenceUseCase.default
    
    @PreferenceWrapper(key: .favouritesIndexed, defaultValue: false)
    private var favouritesIndexed: Bool
    private var passcodeEnabled: Bool
    private lazy var subscriptions = Set<AnyCancellable>()
    private lazy var indexSerialQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .background
        queue.name = "nz.mega.spotlight.favouritesIndexing"
        return queue
    }()
    
    private enum Constants {
        static let favouritesId = "favourites"
    }
    
    @objc init(sdk: MEGASdk, passcodeEnabled: Bool = false) {
        self.sdk = sdk
        let favoritesRepository = FavouriteNodesRepository(sdk: sdk)
        self.favouritesUseCase = FavouriteNodesUseCase(repo: favoritesRepository)
        self.passcodeEnabled = passcodeEnabled
        super.init()
        sdk.add(self)
        $favouritesIndexed.useCase = self.preferenceUseCase
    }
    
    @objc func indexFavourites() {
        guard shouldIndexFavourites() else {
            return
        }
        self.favouritesUseCase.getAllFavouriteNodes { [unowned self] result in
            self.indexSerialQueue.addOperation {
                switch result {
                case .success(let nodeEntities):
                    nodeEntities.publisher
                        .collect(100)
                        .sink { (nodes) in
                            let items = nodes.map { self.searchableItem(node: $0) }
                            
                            CSSearchableIndex.default().indexSearchableItems(items) { error in
                                if let error = error {
                                    MEGALogError("[Spotlight] Indexing favourites error: \(error.localizedDescription)")
                                } else {
                                    MEGALogDebug("[Spotlight] \(items.count) Favourites indexed")
                                }
                            }
                        }
                        .store(in: &self.subscriptions)
                    
                    self.favouritesIndexed = true
                    
                case .failure:
                    MEGALogError("[Spotlight] Error getting all favourites nodes")
                }
            }
        }
    }
    
    @objc func deindexAllSearchableItems() {
        CSSearchableIndex.default().deleteAllSearchableItems(completionHandler: { error in
            if let error = error {
                MEGALogDebug("[Spotlight] Deindexing all searchable items error: \(error.localizedDescription)")
            } else {
                MEGALogDebug("[Spotlight] All searchable items deindexed")
            }
        })
        favouritesIndexed = false
    }
    
    // MARK: - Private
    
    private func index(node: NodeEntity) {
        let item = searchableItem(node: node)
        CSSearchableIndex.default().indexSearchableItems([item]) { error in
            if let error = error {
                MEGALogError("[Spotlight] Indexing \(node.base64Handle) error: \(error.localizedDescription)")
            } else {
                MEGALogDebug("[Spotlight] \(node.base64Handle) indexed")
            }
        }
    }
    
    private func deindex(node: NodeEntity) {
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [node.base64Handle], completionHandler: { error in
            if let error = error {
                MEGALogError("[Spotlight] Deindexing \(node.base64Handle) error: \(error.localizedDescription)")
            } else {
                MEGALogDebug("[Spotlight] \(node.base64Handle) deindexed")
            }
        })
    }
    
    private func searchableItem(node: NodeEntity) -> CSSearchableItem {
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeData as String)
        attributeSet.title = node.name
        
        if node.isFile {
            attributeSet.contentDescription = ByteCountFormatter.string(fromByteCount: Int64(node.size), countStyle: .file)
            attributeSet.thumbnailData = Asset.Images.Generic.spotlightFile.image.pngData()
        } else {
            if let n = sdk.node(forHandle: node.handle) {
                attributeSet.contentDescription = sdk.nodePath(for: n)
            }
            attributeSet.thumbnailData = Asset.Images.Generic.spotlightFolder.image.pngData()
        }
        
        let item = CSSearchableItem(uniqueIdentifier: "\(node.base64Handle)", domainIdentifier: Constants.favouritesId, attributeSet: attributeSet)
        return item
    }
    
    private func shouldIndexFavourites() -> Bool {
        let isIndexingAvailable = CSSearchableIndex.isIndexingAvailable()
        guard !favouritesIndexed, !passcodeEnabled, isIndexingAvailable else {
            MEGALogDebug("[Spotlight] Favourites indexed: \(favouritesIndexed)")
            MEGALogDebug("[Spotlight] Passcode enabled: \(passcodeEnabled)")
            MEGALogDebug("[Spotlight] Is indexing available: \(isIndexingAvailable)")
            return false
        }
        return true
    }
}

extension SpotlightIndexer: MEGAGlobalDelegate {
    func onNodesUpdate(_ api: MEGASdk, nodeList: MEGANodeList?) {
        indexSerialQueue.addOperation {
            guard let nodeEntities = nodeList?.toNodeEntities() else { return }
            
            nodeEntities.forEach { node in
                if node.changeTypes.contains(.name) {
                    if node.isFavourite {
                        self.index(node: node)
                    }
                }
                
                if node.changeTypes.contains(.favourite) {
                    if node.isFavourite {
                        self.index(node: node)
                    } else {
                        self.deindex(node: node)
                    }
                }
                
                if node.changeTypes.contains(.removed) && node.isFavourite {
                    self.deindex(node: node)
                }
            }
        }
    }
}
