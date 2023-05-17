import MEGADomain
import MEGAPresentation

enum NodeCellAction: ActionType {
    case initForReuse
    case manageLabel
    case manageThumbnail
    case hasVersions
    case isDownloaded
    case moreTouchUpInside(Any)
}

protocol NodeCellRouting: Routing {}

final class NodeCellViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case config(NodeEntity)
        case hideVideoIndicator(Bool)
        case hideLabel(Bool)
        case setLabel(String)
        case setThumbnail(String)
        case setIcon(String)
        case setVersions(Bool)
        case setDownloaded(Bool)
    }
    
    var invokeCommand: ((Command) -> Void)?
    
    private let nodeOpener: NodeOpener
    private var nodeModel: NodeEntity
    private var nodeUseCase: NodeUseCaseProtocol
    private var nodeThumbnailUseCase: ThumbnailUseCaseProtocol
    private var accountUseCase: AccountUseCaseProtocol
    private var loadingTask: Task<Void, Never>?
    
    init(nodeOpener: NodeOpener, nodeModel: NodeEntity, nodeUseCase: NodeUseCaseProtocol, nodeThumbnailUseCase: ThumbnailUseCaseProtocol, accountUseCase: AccountUseCaseProtocol) {
        self.nodeOpener = nodeOpener
        self.nodeModel = nodeModel
        self.nodeUseCase = nodeUseCase
        self.nodeThumbnailUseCase = nodeThumbnailUseCase
        self.accountUseCase = accountUseCase
    }
    
    func dispatch(_ action: NodeCellAction) {
        switch action {
        case .initForReuse:
            invokeCommand?(.config(nodeModel))
            
        case .manageLabel:
            manageLabel()
            
        case .manageThumbnail:
            manageThumbnail()
            
        case .hasVersions:
            hasVersions()
            
        case .isDownloaded:
            isDownloaded()
            
        case .moreTouchUpInside(let sender):
            moreTouchUpInside(sender)
        }
    }
    
    func cancelLoading() {
        loadingTask?.cancel()
        loadingTask = nil
    }
    
    // MARK: - Private
    
    private func manageLabel() {
        let isLabelUnknown = (nodeModel.label == .unknown)
        invokeCommand?(.hideLabel(isLabelUnknown))
        
        if !isLabelUnknown {
            let labelString = nodeUseCase.labelString(label: nodeModel.label)
            invokeCommand?(.setLabel(labelString))
        }
    }
    
    private func manageThumbnail() {
        invokeCommand?(.hideVideoIndicator(!(nodeModel.name as NSString).mnz_isVideoPathExtension))
        
        loadingTask = Task { [weak self] in
            do {
                guard let node = self?.nodeModel else { return }
                
                let thumbnail = try await self?.nodeThumbnailUseCase.loadThumbnail(for: node, type: .thumbnail)
                
                if let thumbnail {
                    self?.invokeCommand?(.setThumbnail(thumbnail.url.path))
                }
            } catch {
                MEGALogDebug("[Node Cell:] \(error) happened when manageThumbnail.")
                self?.iconForNode()
            }
        }
    }
    
    func getFilesAndFolders() -> String {
        let numberOfFilesAndFolders = nodeUseCase.getFilesAndFolders(nodeHandle: nodeModel.handle)
        let numberOfFiles = numberOfFilesAndFolders.0
        let numberOfFolders = numberOfFilesAndFolders.1
        let numberOfFilesAndFoldersString = NSString.mnz_string(byFiles: numberOfFiles, andFolders: numberOfFolders)
        return numberOfFilesAndFoldersString
    }
    
    private func hasVersions() {
        let hasVersions = nodeUseCase.hasVersions(nodeHandle: nodeModel.handle)
        invokeCommand?(.setVersions(hasVersions))
    }
    
    private func isDownloaded() {
        let isDownloaded = nodeModel.isFile && nodeUseCase.isDownloaded(nodeHandle: nodeModel.handle)
        invokeCommand?(.setDownloaded(isDownloaded))
    }
    
    private func moreTouchUpInside(_ sender: Any) {
        nodeOpener.openNodeActions(nodeModel.handle, sender: sender)
    }
    
    private func iconForNode() {
        if nodeModel.isFolder {
            if nodeModel.name == Strings.Localizable.cameraUploadsLabel {
                let cameraUploadsFolderImageName = "folder_image"
                self.invokeCommand?(.setIcon(cameraUploadsFolderImageName))
            } else if nodeModel.name == Strings.Localizable.myChatFiles {
                accountUseCase.getMyChatFilesFolder { [weak self] in
                    switch $0 {
                    case .success(let myChatFilesNodeEntity):
                        if self?.nodeModel.handle == myChatFilesNodeEntity.handle {
                            let myChatFilesFolderImageName = "folder_chat"
                            self?.invokeCommand?(.setIcon(myChatFilesFolderImageName))
                        } else {
                            let folderImageName = self?.folderImageName(for: self!.nodeModel)
                            self?.invokeCommand?(.setIcon(folderImageName!))
                        }
                        
                    case .failure:
                        let folderImageName = self?.folderImageName(for: self!.nodeModel)
                        self?.invokeCommand?(.setIcon(folderImageName!))
                    }
                }
            } else {
                self.invokeCommand?(.setIcon(folderImageName(for: nodeModel)))
            }
        } else if nodeModel.isFile {
            let imageName = FileTypes().fileType(forFileName: nodeModel.name)
            self.invokeCommand?(.setIcon(imageName))
        }
    }
    
    private func folderImageName(for nodeModel: NodeEntity) -> String {
        if nodeModel.isInShare {
            return "folder_incoming"
        } else if nodeModel.isOutShare {
            return "folder_outgoing"
        } else {
            return Asset.Images.Filetypes.folder.name
        }
    }
}
