import MEGADomain
import MEGAPresentation

protocol NameCollisionViewRouting: Routing {
    func showNameCollisionsView()
    func resolvedUploadCollisions(_ transfers: [CancellableTransfer])
    func dismiss()
    func showCopyOrMoveSuccess()
    func showCopyOrMoveError()
    func showProgressIndicator()
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
                    self?.isVersioningEnabled = true // default value
                }
            }
        })
    }
    
    func cancelResolveNameCollisions() {
        router.dismiss()
    }
    
    func onViewAppeared() {
        loadNextUnresolvedCollision()
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
        if applyToAllEnabled {
            if action == .merge {
                applyMergeActionToAllFolderCollisions()
            } else {
                switch collisionType {
                case .upload:
                    applyToAllUploadCollisions(action)
                case .copy, .move:
                    applyToAllMoveOrCopyCollisions(action)
                }
            }
            loadNextUnresolvedCollision()
        } else {
           applySingleAction(action)
        }
    }
    
    func actionsForCurrentDuplicatedItem() -> [NameCollisionAction] {
        var actions = [NameCollisionAction]()
        if duplicatedItem.isFile {
            if isVersioningEnabled && collisionType == .upload {
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
    
    // MARK: - Private
    
    private func applyMergeActionToAllFolderCollisions() {
        for i in 0..<collisions.count {
            var collision = collisions[i]
            if !collision.isFile {
                collision.collisionAction = .merge
            }
            collisions[i] = collision
        }
        applyToAllEnabled = false
        loadNextUnresolvedCollision()
        calculateRemainingCollisions()
    }
    
    private func applyToAllUploadCollisions(_ action: NameCollisionActionType) {
        for i in 0..<collisions.count {
            var collision = collisions[i]
            collision.collisionAction = action
            if action == .rename {
                transfers?.forEach({ transfer in
                    transfer.name = nameCollisionUseCase.renameNode(named: collision.name as NSString, inParent: collision.parentHandle)
                })
            }
            collisions[i] = collision
        }
        if action == .cancel {
            transfers?.removeAll()
        }
    }
    
    private func applyToAllMoveOrCopyCollisions(_ action: NameCollisionActionType) {
        router.showProgressIndicator()
        for i in 0..<collisions.count {
            var collision = collisions[i]
            collision.collisionAction = action
            if action == .rename {
                collision.renamed = nameCollisionUseCase.renameNode(named: collision.name as NSString, inParent: collision.parentHandle)
            }
            collisions[i] = collision
        }
        if action == .cancel {
            nodes?.removeAll()
        }
    }
    
    private func applySingleAction(_ action: NameCollisionActionType) {
        guard var collision = collision, let index = collisions.firstIndex(of: collision) else {
            router.dismiss()
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
        loadNextUnresolvedCollision()
        calculateRemainingCollisions()
    }

    private func loadNextUnresolvedCollision() {
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
        loadThumbnails()
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
                    guard let fileUrl = collision.fileUrl else { return }
                    thumbnailUrl = fileUrl
                    loadThumbnails(forFirstItem: nil, collisionHandle: collision.collisionNodeHandle)
                case .move, .copy:
                    loadThumbnails(forFirstItem: collision.nodeHandle, collisionHandle: collision.collisionNodeHandle)
                }
            }
        }
    }
    
    private func cancelLoading() {
        loadingTask?.cancel()
    }
    
    private func loadThumbnails(forFirstItem handle: HandleEntity?, collisionHandle: HandleEntity?) {
        loadingTask = Task { @MainActor in
            if let handle {
                guard let node = nameCollisionUseCase.node(for: handle) else { return }
                guard let url = try? await thumbnailUseCase.loadThumbnail(for: node, type: .thumbnail).url else { return }
                thumbnailUrl = url
            }
            
            if let collisionHandle {
                guard let node = nameCollisionUseCase.node(for: collisionHandle) else { return }
                guard let url = try? await thumbnailUseCase.loadThumbnail(for: node, type: .thumbnail).url else { return }
                thumbnailCollisionUrl = url
            }
        }
    }
}
