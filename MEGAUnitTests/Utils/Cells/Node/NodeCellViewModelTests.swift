import XCTest
@testable import MEGA

final class NodeCellViewModelTests: XCTestCase {
    
    func testAction_initForReuse() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeModel = NodeModel(nodeEntity: NodeEntity())
        let mockNodeActionUC = MockNodeActionUseCase()
        let mockNodeThumbnailUC = MockNodeThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeActionUseCase: mockNodeActionUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        test(viewModel: viewModel,
             action: .initForReuse,
             expectedCommands: [.config(mockNodeModel)])
    }
    
    func testAction_manageLabel_unknown() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeModel = NodeModel(nodeEntity: NodeEntity())
        let mockNodeActionUC = MockNodeActionUseCase()
        let mockNodeThumbnailUC = MockNodeThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeActionUseCase: mockNodeActionUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        test(viewModel: viewModel,
             action: .manageLabel,
             expectedCommands: [.hideLabel(true)])
        XCTAssertEqual(mockNodeModel.label, .unknown)
    }
    
    func testAction_manageLabel_red() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeEntity = NodeEntity(label: .red)
        let mockNodeModel = NodeModel(nodeEntity: NodeEntity())
        let mockNodeActionUC = MockNodeActionUseCase()
        mockNodeActionUC.labelString = "RedSmall"
        let mockNodeThumbnailUC = MockNodeThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeActionUseCase: mockNodeActionUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        test(viewModel: viewModel,
             action: .manageLabel,
             expectedCommands: [.hideLabel(false),
                                .setLabel(mockNodeActionUC.labelString)])
        XCTAssertEqual(mockNodeModel.label, .red)
    }
    
    func testAction_manageLabel_orange() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeEntity = NodeEntity(label: .orange)
        let mockNodeModel = NodeModel(nodeEntity: NodeEntity())
        let mockNodeActionUC = MockNodeActionUseCase()
        mockNodeActionUC.labelString = "OrangeSmall"
        let mockNodeThumbnailUC = MockNodeThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeActionUseCase: mockNodeActionUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        test(viewModel: viewModel,
             action: .manageLabel,
             expectedCommands: [.hideLabel(false),
                                .setLabel(mockNodeActionUC.labelString)])
        XCTAssertEqual(mockNodeModel.label, .orange)
    }
    
    func testAction_manageLabel_yellow() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeEntity = NodeEntity(label: .yellow)
        let mockNodeModel = NodeModel(nodeEntity: NodeEntity())
        let mockNodeActionUC = MockNodeActionUseCase()
        mockNodeActionUC.labelString = "YellowSmall"
        let mockNodeThumbnailUC = MockNodeThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeActionUseCase: mockNodeActionUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        test(viewModel: viewModel,
             action: .manageLabel,
             expectedCommands: [.hideLabel(false),
                                .setLabel(mockNodeActionUC.labelString)])
        XCTAssertEqual(mockNodeModel.label, .yellow)
    }
    
    func testAction_manageLabel_green() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeEntity = NodeEntity(label: .green)
        let mockNodeModel = NodeModel(nodeEntity: NodeEntity())
        let mockNodeActionUC = MockNodeActionUseCase()
        mockNodeActionUC.labelString = "GreenSmall"
        let mockNodeThumbnailUC = MockNodeThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeActionUseCase: mockNodeActionUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        test(viewModel: viewModel,
             action: .manageLabel,
             expectedCommands: [.hideLabel(false),
                                .setLabel(mockNodeActionUC.labelString)])
        XCTAssertEqual(mockNodeModel.label, .green)
    }
    
    func testAction_manageLabel_blue() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeEntity = NodeEntity(label: .blue)
        let mockNodeModel = NodeModel(nodeEntity: NodeEntity())
        let mockNodeActionUC = MockNodeActionUseCase()
        mockNodeActionUC.labelString = "BlueSmall"
        let mockNodeThumbnailUC = MockNodeThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeActionUseCase: mockNodeActionUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        test(viewModel: viewModel,
             action: .manageLabel,
             expectedCommands: [.hideLabel(false),
                                .setLabel(mockNodeActionUC.labelString)])
        XCTAssertEqual(mockNodeModel.label, .blue)
    }
    
    func testAction_manageLabel_purple() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeEntity = NodeEntity(label: .purple)
        let mockNodeModel = NodeModel(nodeEntity: NodeEntity())
        let mockNodeActionUC = MockNodeActionUseCase()
        mockNodeActionUC.labelString = "PurpleSmall"
        let mockNodeThumbnailUC = MockNodeThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeActionUseCase: mockNodeActionUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        test(viewModel: viewModel,
             action: .manageLabel,
             expectedCommands: [.hideLabel(false),
                                .setLabel(mockNodeActionUC.labelString)])
        XCTAssertEqual(mockNodeModel.label, .purple)
    }
    
    func testAction_manageLabel_grey() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeEntity = NodeEntity(label: .grey)
        let mockNodeModel = NodeModel(nodeEntity: NodeEntity())
        let mockNodeActionUC = MockNodeActionUseCase()
        mockNodeActionUC.labelString = "GreySmall"
        let mockNodeThumbnailUC = MockNodeThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeActionUseCase: mockNodeActionUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        test(viewModel: viewModel,
             action: .manageLabel,
             expectedCommands: [.hideLabel(false),
                                .setLabel(mockNodeActionUC.labelString)])
        XCTAssertEqual(mockNodeModel.label, .grey)
    }
    
    func testAction_manageThumbnail_isFolder() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeEntity = NodeEntity(isFolder: true)
        let mockNodeModel = NodeModel(nodeEntity: NodeEntity())
        let mockNodeActionUC = MockNodeActionUseCase()
        let mockNodeThumbnailUC = MockNodeThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeActionUseCase: mockNodeActionUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        test(viewModel: viewModel,
             action: .manageThumbnail,
             expectedCommands: [.setIcon("folder")])
    }
    
    func testAction_manageThumbnail_isFile_noThumbnail() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeEntity = NodeEntity(isFile: true)
        let mockNodeModel = NodeModel(nodeEntity: NodeEntity())
        let mockNodeActionUC = MockNodeActionUseCase()
        let mockNodeThumbnailUC = MockNodeThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeActionUseCase: mockNodeActionUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        test(viewModel: viewModel,
             action: .manageThumbnail,
             expectedCommands: [.setIcon("")])
    }
    
    func testAction_manageThumbnail_isFile_hasThumbnail() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeEntity = NodeEntity(isFile: true, hasThumbnail: true)
        let mockNodeModel = NodeModel(nodeEntity: NodeEntity())
        let mockNodeActionUC = MockNodeActionUseCase()
        let mockNodeThumbnailUC = MockNodeThumbnailUseCase()
        mockNodeThumbnailUC.thumbnailFilePath = "testAction_manageThumbnail"
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeActionUseCase: mockNodeActionUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        mockNodeThumbnailUC.getThumbnail(destinationFilePath: mockNodeThumbnailUC.thumbnailFilePath) { [weak self] result in
            switch result {
            case .success(let thumbnailFilePath):
                self?.test(viewModel: viewModel,
                     action: .manageThumbnail,
                     expectedCommands: [.setThumbnail(thumbnailFilePath)])
            
            case .failure:
                self?.test(viewModel: viewModel,
                     action: .manageThumbnail,
                     expectedCommands: [.setIcon("")])
            }
        }
    }
    
    func testAction_manageThumbnail_isFile_hasThumbnail_isDownloaded() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeEntity = NodeEntity(isFile: true, hasThumbnail: true)
        let mockNodeModel = NodeModel(nodeEntity: NodeEntity())
        let mockNodeActionUC = MockNodeActionUseCase()
        let mockNodeThumbnailUC = MockNodeThumbnailUseCase()
        mockNodeThumbnailUC.thumbnailFilePath = "testAction_manageThumbnail"
        mockNodeThumbnailUC.isThumbnailDownloaded = true
        mockNodeThumbnailUC.getThumbnailResult = .success(mockNodeThumbnailUC.thumbnailFilePath)
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeActionUseCase: mockNodeActionUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        test(viewModel: viewModel,
             action: .manageThumbnail,
             expectedCommands: [.hideVideoIndicator(true),
                                .setThumbnail(mockNodeThumbnailUC.thumbnailFilePath)])
    }
    
    func testAction_getFilesAndFolders_emptyFolder() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeModel = NodeModel(nodeEntity: NodeEntity())
        let mockNodeActionUC = MockNodeActionUseCase()
        let mockNodeThumbnailUC = MockNodeThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeActionUseCase: mockNodeActionUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        let secondaryLabelText = NSLocalizedString("emptyFolder", comment: "Title shown when a folder doesn't have any files")
        test(viewModel: viewModel,
             action: .getFilesAndFolders,
             expectedCommands: [.setSecondaryLabel(secondaryLabelText)])
    }
    
    func testAction_getFilesAndFolders_oneFile() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeModel = NodeModel(nodeEntity: NodeEntity())
        let mockNodeActionUC = MockNodeActionUseCase()
        mockNodeActionUC.filesAndFolders = (1 , 0)
        let mockNodeThumbnailUC = MockNodeThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeActionUseCase: mockNodeActionUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        var filesAndFoldersString = NSLocalizedString("oneFile", comment: "Subtitle shown on folders that gives you information about its content. This case \"{1} file\"")
        filesAndFoldersString = filesAndFoldersString.replacingOccurrences(of: "%d", with: String(mockNodeActionUC.filesAndFolders.0))
        test(viewModel: viewModel,
             action: .getFilesAndFolders,
             expectedCommands: [.setSecondaryLabel(filesAndFoldersString)])
    }
    
    func testAction_getFilesAndFolders_fiveFiles() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeModel = NodeModel(nodeEntity: NodeEntity())
        let mockNodeActionUC = MockNodeActionUseCase()
        mockNodeActionUC.filesAndFolders = (5 , 0)
        let mockNodeThumbnailUC = MockNodeThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeActionUseCase: mockNodeActionUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        var filesAndFoldersString = NSLocalizedString("files", comment: "Subtitle shown on folders that gives you information about its content. This case \"{1+} files\"")
        filesAndFoldersString = filesAndFoldersString.replacingOccurrences(of: "%d", with: String(mockNodeActionUC.filesAndFolders.0))
        test(viewModel: viewModel,
             action: .getFilesAndFolders,
             expectedCommands: [.setSecondaryLabel(filesAndFoldersString)])
    }
    
    func testAction_getFilesAndFolders_oneFolder() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeModel = NodeModel(nodeEntity: NodeEntity())
        let mockNodeActionUC = MockNodeActionUseCase()
        mockNodeActionUC.filesAndFolders = (0 , 1)
        let mockNodeThumbnailUC = MockNodeThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeActionUseCase: mockNodeActionUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        var filesAndFoldersString = NSLocalizedString("oneFolder", comment: "Subtitle shown on folders that gives you information about its content. This case \"{1} folder\"")
        filesAndFoldersString = filesAndFoldersString.replacingOccurrences(of: "%d", with: String(mockNodeActionUC.filesAndFolders.1))
        test(viewModel: viewModel,
             action: .getFilesAndFolders,
             expectedCommands: [.setSecondaryLabel(filesAndFoldersString)])
    }
    
    func testAction_getFilesAndFolders_threeFolders() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeModel = NodeModel(nodeEntity: NodeEntity())
        let mockNodeActionUC = MockNodeActionUseCase()
        mockNodeActionUC.filesAndFolders = (0 , 3)
        let mockNodeThumbnailUC = MockNodeThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeActionUseCase: mockNodeActionUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        var filesAndFoldersString = NSLocalizedString("folders", comment: "Subtitle shown on folders that gives you information about its content. This case \"{1+} folders\"")
        filesAndFoldersString = filesAndFoldersString.replacingOccurrences(of: "%d", with: String(mockNodeActionUC.filesAndFolders.1))
        test(viewModel: viewModel,
             action: .getFilesAndFolders,
             expectedCommands: [.setSecondaryLabel(filesAndFoldersString)])
    }
    
    func testAction_getFilesAndFolders_oneFileAndOneFolder() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeModel = NodeModel(nodeEntity: NodeEntity())
        let mockNodeActionUC = MockNodeActionUseCase()
        mockNodeActionUC.filesAndFolders = (1 , 1)
        let mockNodeThumbnailUC = MockNodeThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeActionUseCase: mockNodeActionUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        let filesAndFoldersString = NSLocalizedString("folderAndFile", comment: "Subtitle shown on folders that gives you information about its content. This case \"{1} folder • {1} file\"")
        test(viewModel: viewModel,
             action: .getFilesAndFolders,
             expectedCommands: [.setSecondaryLabel(filesAndFoldersString)])
    }
    
    func testAction_getFilesAndFolders_oneFileAndTwoFolders() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeModel = NodeModel(nodeEntity: NodeEntity())
        let mockNodeActionUC = MockNodeActionUseCase()
        mockNodeActionUC.filesAndFolders = (1 , 2)
        let mockNodeThumbnailUC = MockNodeThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeActionUseCase: mockNodeActionUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        var filesAndFoldersString = NSLocalizedString("foldersAndFile", comment: "Subtitle shown on folders that gives you information about its content. This case \"{1} folder • {1+} file\"")
        filesAndFoldersString = filesAndFoldersString.replacingOccurrences(of: "%d", with: String(mockNodeActionUC.filesAndFolders.1))
        test(viewModel: viewModel,
             action: .getFilesAndFolders,
             expectedCommands: [.setSecondaryLabel(filesAndFoldersString)])
    }
    
    func testAction_getFilesAndFolders_twoFilesAndOneFolder() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeModel = NodeModel(nodeEntity: NodeEntity())
        let mockNodeActionUC = MockNodeActionUseCase()
        mockNodeActionUC.filesAndFolders = (2 , 1)
        let mockNodeThumbnailUC = MockNodeThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeActionUseCase: mockNodeActionUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        var filesAndFoldersString = NSLocalizedString("folderAndFiles", comment: "Subtitle shown on folders that gives you information about its content. This case \"{1} folder • {1+} file\"")
        filesAndFoldersString = filesAndFoldersString.replacingOccurrences(of: "%d", with: String(mockNodeActionUC.filesAndFolders.0))
        test(viewModel: viewModel,
             action: .getFilesAndFolders,
             expectedCommands: [.setSecondaryLabel(filesAndFoldersString)])
    }
    
    func testAction_getFilesAndFolders_threeFilesAndThreeFolders() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeModel = NodeModel(nodeEntity: NodeEntity())
        let mockNodeActionUC = MockNodeActionUseCase()
        mockNodeActionUC.filesAndFolders = (3 , 3)
        let mockNodeThumbnailUC = MockNodeThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeActionUseCase: mockNodeActionUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        var filesAndFoldersString = NSLocalizedString("foldersAndFiles", comment: "Subtitle shown on folders that gives you information about its content. This case \"[A] = {1+} folders ‚ [B] = {1+} files\"")
        filesAndFoldersString = filesAndFoldersString.replacingOccurrences(of: "[A]", with: String(mockNodeActionUC.filesAndFolders.0))
        filesAndFoldersString = filesAndFoldersString.replacingOccurrences(of: "[B]", with: String(mockNodeActionUC.filesAndFolders.1))
        test(viewModel: viewModel,
             action: .getFilesAndFolders,
             expectedCommands: [.setSecondaryLabel(filesAndFoldersString)])
    }
    
    func testAction_hasVersions_false() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeModel = NodeModel(nodeEntity: NodeEntity())
        let mockNodeActionUC = MockNodeActionUseCase()
        let mockNodeThumbnailUC = MockNodeThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeActionUseCase: mockNodeActionUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        test(viewModel: viewModel,
             action: .hasVersions,
             expectedCommands: [.setVersions(mockNodeActionUC.hasVersions())])
    }
    
    func testAction_hasVersions_true() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeModel = NodeModel(nodeEntity: NodeEntity())
        let mockNodeActionUC = MockNodeActionUseCase()
        mockNodeActionUC.versions = true
        let mockNodeThumbnailUC = MockNodeThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeActionUseCase: mockNodeActionUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        test(viewModel: viewModel,
             action: .hasVersions,
             expectedCommands: [.setVersions(mockNodeActionUC.hasVersions())])
    }
    
    func testAction_isBeingDownloaded_false() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeModel = NodeModel(nodeEntity: NodeEntity())
        let mockNodeActionUC = MockNodeActionUseCase()
        let mockNodeThumbnailUC = MockNodeThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeActionUseCase: mockNodeActionUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        test(viewModel: viewModel,
             action: .isBeingDownloaded,
             expectedCommands: [.setBeingDownloaded(mockNodeActionUC.isBeingDownloaded())])
    }
    
    func testAction_isBeingDownloaded_true() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeModel = NodeModel(nodeEntity: NodeEntity())
        let mockNodeActionUC = MockNodeActionUseCase()
        mockNodeActionUC.beingDownloaded = true
        let mockNodeThumbnailUC = MockNodeThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeActionUseCase: mockNodeActionUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        test(viewModel: viewModel,
             action: .isBeingDownloaded,
             expectedCommands: [.setBeingDownloaded(mockNodeActionUC.isBeingDownloaded())])
    }
    
    func testAction_isDownloaded_false() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeModel = NodeModel(nodeEntity: NodeEntity())
        let mockNodeActionUC = MockNodeActionUseCase()
        let mockNodeThumbnailUC = MockNodeThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeActionUseCase: mockNodeActionUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        test(viewModel: viewModel,
             action: .isDownloaded,
             expectedCommands: [.setDownloaded(mockNodeActionUC.isDownloaded())])
    }
    
    func testAction_isDownloaded_true() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeEntity = NodeEntity(isFile: true)
        let mockNodeModel = NodeModel(nodeEntity: NodeEntity())
        let mockNodeActionUC = MockNodeActionUseCase()
        mockNodeActionUC.downloaded = true
        let mockNodeThumbnailUC = MockNodeThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeActionUseCase: mockNodeActionUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        test(viewModel: viewModel,
             action: .isDownloaded,
             expectedCommands: [.setDownloaded(mockNodeActionUC.isDownloaded())])
    }
    
    func testAction_moreTouchUpInside() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeModel = NodeModel(nodeEntity: NodeEntity())
        let mockNodeActionUC = MockNodeActionUseCase()
        let mockNodeThumbnailUC = MockNodeThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeActionUseCase: mockNodeActionUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        let sender = UIView()
        test(viewModel: viewModel,
             action: .moreTouchUpInside(sender),
             expectedCommands: [])
    }
}
