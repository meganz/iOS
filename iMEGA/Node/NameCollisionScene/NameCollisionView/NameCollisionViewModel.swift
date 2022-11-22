import MEGADomain

protocol NameCollisionViewRouting: Routing {
    func showNameCollisionsView()
    func resolvedUploadCollisions(_ transfers: [CancellableTransfer])
    func dismiss()
    func showCopyOrMoveSuccess()
    func showCopyOrMoveError()
}

final class NameCollisionViewModel: ObservableObject {
    private let thumbnailUseCase: ThumbnailUseCaseProtocol
    private let nameCollisionUseCase: NameCollisionUseCaseProtocol
    private var fileVersionsUseCase: FileVersionsUseCaseProtocol

    private let router: NameCollisionViewRouting
    private var transfers: [CancellableTransfer]?
    private var nodes: [NodeEntity]?
    private var collisions: [NameCollisionEntity]
    private var collision: NameCollisionEntity?
    private var loadingTask: Task<Void, Never>?
    private let isFolderLink: Bool
    private var applyToAllAction: NameCollisionActionType = .cancel

    var collisionType: NameCollisionType
    
    @Published var duplicatedItem: DuplicatedItem
    @Published var isVersioningEnabled: Bool = false
    @Published var thumbnailUrl: URL?
    @Published var thumbnailCollisionUrl: URL?
    @Published var applyToAllEnabled: Bool = false
    @Published var remainingCollisionsCount: Int = 0
    
    init(router: NameCollisionViewRouting,
         thumbnailUseCase: ThumbnailUseCaseProtocol,
         nameCollisionUseCase: NameCollisionUseCaseProtocol,
         fileVersionsUseCase: FileVersionsUseCaseProtocol,
         transfers: [CancellableTransfer]?,
         nodes: [NodeEntity]?,
         collisions: [NameCollisionEntity],
         collisionType: NameCollisionType,
         isFolderLink: Bool = false) {
        self.router = router
        self.thumbnailUseCase = thumbnailUseCase
        self.nameCollisionUseCase = nameCollisionUseCase
        self.fileVersionsUseCase = fileVersionsUseCase
        self.transfers = transfers
        self.nodes = nodes
        self.collisions = collisions
        self.collisionType = collisionType
        self.isFolderLink = isFolderLink
        self.duplicatedItem = DuplicatedItem(name: "", isFile: false, size: "", date: "", itemPlaceholder: Asset.Images.Photos.photoCardPlaceholder.name)
        fileVersionsUseCase.isFileVersionsEnabled(completion: { [weak self] result in
            switch result {
            case .success(let enabled):
                self?.isVersioningEnabled = enabled
            case .failure(let error):
                if error == .optionNeverSet {
                    self?.isVersioningEnabled = true //default value
                }
            }
        })
    }
    
    func cancelResolveNameCollisions() {
        router.dismiss()
    }
    
    func onViewAppeared() {
        loadNextCollision()
    }
    
    func checkNameCollisions() {
        collisions = nameCollisionUseCase.resolveNameCollisions(for: collisions)
        if collisions.contains(where: { $0.collisionNodeHandle != nil }) {
            calculateRemainingCollisions()
            router.showNameCollisionsView()
        } else {
            processCollisions()
        }
    }
    
    func selectedAction(_ action: NameCollisionActionType) {
        applyToAllAction = action
        
        guard var collision = collision, let index = collisions.firstIndex(of: collision) else {
            return
        }
        collision.collisionAction = action
        cancelLoading()
        
        switch collisionType {
        case .upload:
            guard var transfers = transfers, let transfer = transfers.first(where: { $0.localFileURL == collision.fileUrl }) else {
                return
            }
            switch action {
            case .update, .replace, .merge:
                break
            case .rename:
                transfer.name = duplicatedItem.rename
            case .cancel:
                transfers.remove(object: transfer)
            }
            self.transfers = transfers
        case .copy, .move:
            guard var nodes = nodes, let node = nodes.first(where: { $0.handle == collision.nodeHandle }) else {
                return
            }

            switch action {
            case .update, .replace, .merge:
                break
            case .rename:
                collision.renamed = duplicatedItem.rename
            case .cancel:
                nodes.remove(object: node)
            }
            self.nodes = nodes
        }
        
        collisions[index] = collision
        loadNextCollision()
        calculateRemainingCollisions()
    } 
    
    func actionsForCurrentDuplicatedItem() -> [NameCollisionAction] {
        var actions = [NameCollisionAction]()
        if duplicatedItem.isFile {
            if isVersioningEnabled {
                actions.append(NameCollisionAction(actionType: .update, name: duplicatedItem.name, size: duplicatedItem.size, date: duplicatedItem.date, isFile: duplicatedItem.isFile, imageUrl: thumbnailUrl, itemPlaceholder: duplicatedItem.itemPlaceholder))
            } else {
                actions.append(NameCollisionAction(actionType: .replace, name: duplicatedItem.name, size: duplicatedItem.size, date: duplicatedItem.date, isFile: duplicatedItem.isFile, imageUrl: thumbnailUrl, itemPlaceholder: duplicatedItem.itemPlaceholder))
            }
            actions.append(NameCollisionAction(actionType: .rename, name: duplicatedItem.rename, isFile: duplicatedItem.isFile, imageUrl: thumbnailUrl, itemPlaceholder: duplicatedItem.itemPlaceholder))
            actions.append(NameCollisionAction(actionType: .cancel, name: duplicatedItem.name, size: duplicatedItem.collisionFileSize, date: duplicatedItem.collisionFileDate, isFile: duplicatedItem.isFile, imageUrl: thumbnailCollisionUrl, itemPlaceholder: duplicatedItem.itemPlaceholder))
        } else {
            actions.append(NameCollisionAction(actionType: .merge, isFile: duplicatedItem.isFile, itemPlaceholder: duplicatedItem.itemPlaceholder))
            actions.append(NameCollisionAction(actionType: .cancel, isFile: duplicatedItem.isFile, itemPlaceholder: duplicatedItem.itemPlaceholder))
        }
        return actions
    }
    
    func calculateRemainingCollisions() {
        remainingCollisionsCount = collisions.filter { $0.collisionAction == nil && $0.collisionNodeHandle != nil }.count
    }
    
    //MARK: - Private
    private func loadNextCollision() {
        guard let collision = collisions.first(where: { $0.collisionAction == nil && $0.collisionNodeHandle != nil }) else {
            if collisions.contains(where: { $0.collisionAction != .cancel || $0.collisionNodeHandle == nil }) {
                processCollisions()
            } else {
                router.dismiss()
            }
            return
        }
        self.collision = collision
        
        guard let duplicatedItem = duplicatedItem(from: collision) else {
            router.dismiss()
            return
        }
        
        self.duplicatedItem = duplicatedItem
        
        if applyToAllEnabled {
            if applyToAllAction == .merge {
                if !collision.isFile {
                    selectedAction(applyToAllAction)
                } else {
                    applyToAllEnabled = false
                    loadThumbnails()
                }
            } else {
                selectedAction(applyToAllAction)
            }
        } else {
            loadThumbnails()
        }
    }
    
    private func processCollisions() {
        switch collisionType {
        case .upload:
            router.resolvedUploadCollisions(transfers ?? [])
        case .move:
            Task {
                let moveNodeHandles = try await nameCollisionUseCase.moveNodesFromResolvedCollisions(collisions)
                await finishedTask(for: moveNodeHandles)
            }
        case .copy:
            Task {
                let copyNodeHandles = try await nameCollisionUseCase.copyNodesFromResolvedCollisions(collisions, isFolderLink: isFolderLink)
                await finishedTask(for: copyNodeHandles)
            }
        }
    }
    
    @MainActor
    private func finishedTask(for handles: [HandleEntity]) {
        if handles.count == collisions.count {
            router.showCopyOrMoveSuccess()
        } else {
            router.showCopyOrMoveError()
        }
    }
    
    private func duplicatedItem(from collision: NameCollisionEntity) -> DuplicatedItem? {
        switch collisionType {
        case .upload:
            return duplicatedUploadItem(from: collision)
        case .move, .copy:
            return duplicatedCopyOrMoveItem(from: collision)
        }
    }
    
    private func duplicatedUploadItem(from collision: NameCollisionEntity) -> DuplicatedItem? {
        guard let url = collision.fileUrl, let collisionNodeHandle = collision.collisionNodeHandle else {
            return nil
        }
        
        return DuplicatedItem(
            name: collision.name,
            rename: nameCollisionUseCase.renameNode(named: collision.name as NSString, inParent: collision.parentHandle),
            isFile: collision.isFile,
            size: nameCollisionUseCase.sizeForFile(at: url),
            date: nameCollisionUseCase.creationDateForFile(at: url),
            itemPlaceholder: collision.isFile ? FileTypes().fileType(forFileName: collision.name) : "folder",
            collisionFileSize: nameCollisionUseCase.sizeForNode(handle: collisionNodeHandle),
            collisionFileDate: nameCollisionUseCase.creationDateForNode(handle: collisionNodeHandle),
            collisionNodeHandle: collisionNodeHandle)
    }
    
    private func duplicatedCopyOrMoveItem(from collision: NameCollisionEntity) -> DuplicatedItem? {
        guard let nodeHandle = collision.nodeHandle, let collisionNodeHandle = collision.collisionNodeHandle else {
            return nil
        }
        
        return DuplicatedItem(
            name: collision.name,
            rename: nameCollisionUseCase.renameNode(named: collision.name as NSString, inParent: collision.parentHandle),
            isFile: collision.isFile,
            size: nameCollisionUseCase.sizeForNode(handle: nodeHandle),
            date: nameCollisionUseCase.creationDateForNode(handle: collisionNodeHandle),
            itemPlaceholder: collision.isFile ? FileTypes().fileType(forFileName: collision.name) : "folder",
            collisionFileSize: nameCollisionUseCase.sizeForNode(handle: collisionNodeHandle),
            collisionFileDate: nameCollisionUseCase.creationDateForNode(handle: collisionNodeHandle),
            collisionNodeHandle: collisionNodeHandle)
    }
    
    private func loadThumbnails() {
        thumbnailUrl = nil
        thumbnailCollisionUrl = nil
        cancelLoading()

        if duplicatedItem.isFile {
            if duplicatedItem.name.mnz_isVisualMediaPathExtension {
                guard let collision = collision else {
                    return
                }
                switch collisionType {
                case .upload:
                    guard let fileUrl = collision.fileUrl, let collisionHandle = collision.collisionNodeHandle else { return }
                    thumbnailUrl = fileUrl
                    loadingTask = Task {
                        thumbnailCollisionUrl = await loadNodeThumbnail(for: collisionHandle)
                    }
                case .move, .copy:
                    guard let handle = collision.nodeHandle, let collisionHandle = collision.collisionNodeHandle else { return }
                    loadingTask = Task {
                        thumbnailUrl = await loadNodeThumbnail(for: handle)
                        thumbnailCollisionUrl = await loadNodeThumbnail(for: collisionHandle)
                    }
                }
            }
        }
    }
    
    private func cancelLoading() {
        loadingTask?.cancel()
    }
    
    @MainActor
    private func loadNodeThumbnail(for handle: HandleEntity) async -> URL? {
        guard let node = nameCollisionUseCase.node(for: handle) else { return nil }
        guard let url = try? await thumbnailUseCase.loadThumbnail(for: node, type: .thumbnail) else { return nil }
        return url
    }
}
