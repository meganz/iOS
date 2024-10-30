import MEGAAssets
import MEGADomain
import MEGAL10n
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
        case setIcon(MEGAAssetsImageName)
        case setVersions(Bool)
        case setDownloaded(Bool)
    }
    
    var invokeCommand: ((Command) -> Void)?
    
    private let nodeOpener: NodeOpener
    private var nodeModel: NodeEntity
    private var nodeUseCase: any NodeUseCaseProtocol
    private var nodeThumbnailUseCase: any ThumbnailUseCaseProtocol
    private var accountUseCase: any AccountUseCaseProtocol
    private var loadingTask: Task<Void, Never>?
    
    init(nodeOpener: NodeOpener, nodeModel: NodeEntity, nodeUseCase: any NodeUseCaseProtocol, nodeThumbnailUseCase: any ThumbnailUseCaseProtocol, accountUseCase: any AccountUseCaseProtocol) {
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
        invokeCommand?(.hideVideoIndicator(!nodeModel.fileExtensionGroup.isVideo))
        
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
                self.invokeCommand?(.setIcon(.filetypeFolderCamera))
            } else if nodeModel.name == Strings.Localizable.myChatFiles {
                accountUseCase.getMyChatFilesFolder { [weak self] in
                    switch $0 {
                    case .success(let myChatFilesNodeEntity):
                        if self?.nodeModel.handle == myChatFilesNodeEntity.handle {
                            self?.invokeCommand?(.setIcon(.folderChat))
                        } else {
                            let folderImageName = self?.folderImage(for: self!.nodeModel)
                            self?.invokeCommand?(.setIcon(folderImageName!))
                        }
                        
                    case .failure:
                        let folderImageName = self?.folderImage(for: self!.nodeModel)
                        self?.invokeCommand?(.setIcon(folderImageName!))
                    }
                }
            } else {
                self.invokeCommand?(.setIcon(folderImage(for: nodeModel)))
            }
        } else if nodeModel.isFile {
            self.invokeCommand?(.setIcon(MEGAAssetsImageProvider.fileTypeResource(forFileName: nodeModel.name)))
        }
    }
    
    private func folderImage(for nodeModel: NodeEntity) -> MEGAAssetsImageName {
        if nodeModel.isInShare {
            .folderIncoming
        } else if nodeModel.isOutShare {
            .folderOutgoing
        } else {
            .filetypeFolder
        }
    }
}
