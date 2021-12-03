
enum NodeCellAction: ActionType {
    case initForReuse
    case manageLabel
    case manageThumbnail
    case getFilesAndFolders
    case hasVersions
    case isBeingDownloaded
    case isDownloaded
    case moreTouchUpInside(Any)
}

protocol NodeCellRouting: Routing {}

final class NodeCellViewModel: ViewModelType {
    
    enum Command: CommandType, Equatable {
        case config(NodeModel)
        case hideVideoIndicator(Bool)
        case hideLabel(Bool)
        case setLabel(String)
        case setThumbnail(String)
        case setIcon(String)
        case setSecondaryLabel(String)
        case setVersions(Bool)
        case setBeingDownloaded(Bool)
        case setDownloaded(Bool)
    }
    
    var invokeCommand: ((Command) -> Void)?
    
    private let nodeOpener: NodeOpener
    private var nodeModel: NodeModelProtocol
    private var nodeActionUseCase: NodeActionUseCaseProtocol
    private var nodeThumbnailUseCase: NodeThumbnailUseCaseProtocol
    private var accountUseCase: AccountUseCaseProtocol
    
    init(nodeOpener: NodeOpener, nodeModel: NodeModelProtocol, nodeActionUseCase: NodeActionUseCaseProtocol, nodeThumbnailUseCase: NodeThumbnailUseCaseProtocol, accountUseCase: AccountUseCaseProtocol) {
        self.nodeOpener = nodeOpener
        self.nodeModel = nodeModel
        self.nodeActionUseCase = nodeActionUseCase
        self.nodeThumbnailUseCase = nodeThumbnailUseCase
        self.accountUseCase = accountUseCase
    }
    
    func dispatch(_ action: NodeCellAction) {
        switch action {
        case .initForReuse:
            guard let nodeModel = nodeModel as? NodeModel else { return }
            invokeCommand?(.config(nodeModel))
            
        case .manageLabel:
            manageLabel()
            
        case .manageThumbnail:
            manageThumbnail()
            
        case .getFilesAndFolders:
            getFilesAndFolders()
            
        case .hasVersions:
            hasVersions()
            
        case .isBeingDownloaded:
            isBeingDownloaded()
            
        case .isDownloaded:
            isDownloaded()
            
        case .moreTouchUpInside(let sender):
            moreTouchUpInside(sender)
        }
    }
    
    private func manageLabel() {
        let isLabelUnknown = (nodeModel.label == .unknown)
        invokeCommand?(.hideLabel(isLabelUnknown))
        if !isLabelUnknown {
            let labelString = nodeActionUseCase.labelString(label: nodeModel.label)
            invokeCommand?(.setLabel(labelString))
        }
    }
    
    private func manageThumbnail() {
        if nodeModel.hasThumbnail {
            let thumbnailFilePath = nodeThumbnailUseCase.getThumbnailFilePath(base64Handle: nodeModel.base64Handle)
            if  nodeThumbnailUseCase.isThumbnailDownloaded(thumbnailFilePath: thumbnailFilePath) {
                let name = nodeModel.name as NSString
                let isHidden = !name.mnz_isVideoPathExtension
                invokeCommand?(.hideVideoIndicator((isHidden)))
                
                invokeCommand?(.setThumbnail(thumbnailFilePath))
            } else {
                nodeThumbnailUseCase.getThumbnail(destinationFilePath: thumbnailFilePath) { [weak self] in
                    switch $0 {
                    case .success(let thumbnailFilePath):
                        self?.invokeCommand?(.setThumbnail(thumbnailFilePath))
                        
                    case .failure(_):
                        self?.iconForNode()
                    }
                }
            }
        } else {
            iconForNode()
        }
    }
    
    private func getFilesAndFolders() {
        let numberOfFilesAndFolders = nodeActionUseCase.getFilesAndFolders()
        let numberOfFiles = numberOfFilesAndFolders.0
        let numberOfFolders = numberOfFilesAndFolders.1
        let numberOfFilesAndFoldersString = NSString.mnz_string(byFiles: numberOfFiles, andFolders: numberOfFolders)
        
        invokeCommand?(.setSecondaryLabel(numberOfFilesAndFoldersString))
    }
    
    private func hasVersions() {
        let hasVersions = nodeActionUseCase.hasVersions()
        invokeCommand?(.setVersions(hasVersions))
    }
    
    private func isBeingDownloaded() {
        let isBeingDownloaded = nodeActionUseCase.isBeingDownloaded()
        invokeCommand?(.setBeingDownloaded(isBeingDownloaded))
    }
    
    private func isDownloaded() {
        let isDownloaded = nodeModel.isFile && nodeActionUseCase.isDownloaded()
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
                accountUseCase.getMyChatFilesFolder() { [weak self] in
                    switch $0 {
                    case .success(let myChatFilesNodeEntity):
                        if self?.nodeModel.handle == myChatFilesNodeEntity.handle {
                            let myChatFilesFolderImageName = "folder_chat"
                            self?.invokeCommand?(.setIcon(myChatFilesFolderImageName))
                        } else {
                            let folderImageName = self?.folderImageName(for: self!.nodeModel)
                            self?.invokeCommand?(.setIcon(folderImageName!))
                        }
                        
                    case .failure(_):
                        let folderImageName = self?.folderImageName(for: self!.nodeModel)
                        self?.invokeCommand?(.setIcon(folderImageName!))
                    }
                }
            } else {
                self.invokeCommand?(.setIcon(folderImageName(for: nodeModel)))
            }
        } else if nodeModel.isFile {
            let pathExtension = (nodeModel.name as NSString).pathExtension
            self.invokeCommand?(.setIcon(imageNameForExtension(extensionString: pathExtension)))
        }
    }
    
    private func folderImageName(for nodeModel: NodeModelProtocol) -> String {
        if nodeModel.isInShare {
            return "folder_incoming"
        } else if nodeModel.isOutShare {
            return "folder_outgoing"
        } else {
            return "folder"
        }
    }
    
    private func imageNameForExtension(extensionString: String) -> String {
        let extensionLowercasedString = extensionString.lowercased()
        var imageName: String
        if extensionLowercasedString == "jpg" || extensionLowercasedString == "jpeg" {
            imageName = "image"
        } else {
            let fileTypesDictionary = nodeThumbnailUseCase.iconImagesDictionary()
            guard let filetypeImageName = (fileTypesDictionary[extensionLowercasedString] as? String) else {
                return "generic"
            }
            
            imageName = filetypeImageName
        }
        
        return imageName
    }
}
