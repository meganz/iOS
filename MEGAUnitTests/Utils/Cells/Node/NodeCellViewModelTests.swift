import XCTest
@testable import MEGA
import MEGADomain
import MEGADomainMock

final class NodeCellViewModelTests: XCTestCase {
    
    func testAction_initForReuse() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeModel = NodeEntity()
        let mockNodeDataUC = MockNodeDataUseCase()
        let mockNodeThumbnailUC = MockThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeUseCase: mockNodeDataUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        test(viewModel: viewModel,
             action: .initForReuse,
             expectedCommands: [.config(mockNodeModel)])
    }
    
    func testAction_manageLabel_unknown() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeModel = NodeEntity()
        let mockNodeDataUC = MockNodeDataUseCase()
        let mockNodeThumbnailUC = MockThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeUseCase: mockNodeDataUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        test(viewModel: viewModel,
             action: .manageLabel,
             expectedCommands: [.hideLabel(true)])
        XCTAssertEqual(mockNodeModel.label, .unknown)
    }
    
    func testAction_manageLabel_red() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeModel = NodeEntity(label: .red)
        let mockNodeDataUC = MockNodeDataUseCase(labelString: Asset.Images.Labels.redSmall.name)
        let mockNodeThumbnailUC = MockThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeUseCase: mockNodeDataUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        test(viewModel: viewModel,
             action: .manageLabel,
             expectedCommands: [.hideLabel(false),
                                .setLabel(Asset.Images.Labels.redSmall.name)])
        XCTAssertEqual(mockNodeModel.label, .red)
    }
    
    func testAction_manageLabel_orange() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeModel = NodeEntity(label: .orange)
        let mockNodeDataUC = MockNodeDataUseCase(labelString: Asset.Images.Labels.orangeSmall.name)
        let mockNodeThumbnailUC = MockThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeUseCase: mockNodeDataUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        test(viewModel: viewModel,
             action: .manageLabel,
             expectedCommands: [.hideLabel(false),
                                .setLabel(Asset.Images.Labels.orangeSmall.name)])
        XCTAssertEqual(mockNodeModel.label, .orange)
    }
    
    func testAction_manageLabel_yellow() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeModel = NodeEntity(label: .yellow)
        let mockNodeDataUC = MockNodeDataUseCase(labelString: Asset.Images.Labels.yellowSmall.name)
        let mockNodeThumbnailUC = MockThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeUseCase: mockNodeDataUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        test(viewModel: viewModel,
             action: .manageLabel,
             expectedCommands: [.hideLabel(false),
                                .setLabel(Asset.Images.Labels.yellowSmall.name)])
        XCTAssertEqual(mockNodeModel.label, .yellow)
    }
    
    func testAction_manageLabel_green() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeModel = NodeEntity(label: .green)
        let mockNodeDataUC = MockNodeDataUseCase(labelString: Asset.Images.Labels.greenSmall.name)
        let mockNodeThumbnailUC = MockThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeUseCase: mockNodeDataUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        test(viewModel: viewModel,
             action: .manageLabel,
             expectedCommands: [.hideLabel(false),
                                .setLabel(Asset.Images.Labels.greenSmall.name)])
        XCTAssertEqual(mockNodeModel.label, .green)
    }
    
    func testAction_manageLabel_blue() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeModel = NodeEntity(label: .blue)
        let mockNodeDataUC = MockNodeDataUseCase(labelString: Asset.Images.Labels.blueSmall.name)
        let mockNodeThumbnailUC = MockThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeUseCase: mockNodeDataUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        test(viewModel: viewModel,
             action: .manageLabel,
             expectedCommands: [.hideLabel(false),
                                .setLabel(Asset.Images.Labels.blueSmall.name)])
        XCTAssertEqual(mockNodeModel.label, .blue)
    }
    
    func testAction_manageLabel_purple() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeModel = NodeEntity(label: .purple)
        let mockNodeDataUC = MockNodeDataUseCase(labelString: Asset.Images.Labels.purpleSmall.name)
        let mockNodeThumbnailUC = MockThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeUseCase: mockNodeDataUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        test(viewModel: viewModel,
             action: .manageLabel,
             expectedCommands: [.hideLabel(false),
                                .setLabel(Asset.Images.Labels.purpleSmall.name)])
        XCTAssertEqual(mockNodeModel.label, .purple)
    }
    
    func testAction_manageLabel_grey() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeModel = NodeEntity(label: .grey)
        let mockNodeDataUC = MockNodeDataUseCase(labelString: Asset.Images.Labels.greySmall.name)
        let mockNodeThumbnailUC = MockThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeUseCase: mockNodeDataUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        test(viewModel: viewModel,
             action: .manageLabel,
             expectedCommands: [.hideLabel(false),
                                .setLabel(Asset.Images.Labels.greySmall.name)])
        XCTAssertEqual(mockNodeModel.label, .grey)
    }
    
    func testAction_manageThumbnail_isFolder() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeModel = NodeEntity(isFolder: true)
        let mockNodeDataUC = MockNodeDataUseCase()
        let mockNodeThumbnailUC = MockThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeUseCase: mockNodeDataUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        test(viewModel: viewModel,
             action: .manageThumbnail,
             expectedCommands: [.hideVideoIndicator(true),
                                .setIcon("folder")])
    }
    
    func testAction_manageThumbnail_isFile_noThumbnail() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeModel = NodeEntity(isFile: true)
        let mockNodeDataUC = MockNodeDataUseCase()
        let mockNodeThumbnailUC = MockThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeUseCase: mockNodeDataUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        test(viewModel: viewModel,
             action: .manageThumbnail,
             expectedCommands: [.hideVideoIndicator(true),
                                .setIcon("generic")])
    }
    
    func testAction_manageThumbnail_isFile_hasThumbnail() throws {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeModel = NodeEntity(isFile: true, hasThumbnail: true)
        let mockNodeDataUC = MockNodeDataUseCase()
        let thumbnailURL = try XCTUnwrap(URL(string: "file://thumbnail/abc"))
        let mockNodeThumbnailUC = MockThumbnailUseCase(loadThumbnailResult: .success(ThumbnailEntity(url: thumbnailURL, type: .thumbnail)))
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeUseCase: mockNodeDataUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        test(viewModel: viewModel,
             action: .manageThumbnail,
             expectedCommands: [.hideVideoIndicator(true),
                                .setThumbnail("/abc")])
    }
    
    func testAction_hasVersions_false() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeModel = NodeEntity()
        let mockNodeDataUC = MockNodeDataUseCase()
        let mockNodeThumbnailUC = MockThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeUseCase: mockNodeDataUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        test(viewModel: viewModel,
             action: .hasVersions,
             expectedCommands: [.setVersions(mockNodeDataUC.hasVersions(nodeHandle: .invalid))])
    }
    
    func testAction_hasVersions_true() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeModel = NodeEntity()
        let mockNodeDataUC = MockNodeDataUseCase(versions: true)
        let mockNodeThumbnailUC = MockThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeUseCase: mockNodeDataUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        test(viewModel: viewModel,
             action: .hasVersions,
             expectedCommands: [.setVersions(mockNodeDataUC.hasVersions(nodeHandle: .invalid))])
    }
    
    func testAction_isDownloaded_false() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeModel = NodeEntity()
        let mockNodeDataUC = MockNodeDataUseCase()
        let mockNodeThumbnailUC = MockThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeUseCase: mockNodeDataUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        test(viewModel: viewModel,
             action: .isDownloaded,
             expectedCommands: [.setDownloaded(mockNodeDataUC.isDownloaded(nodeHandle: .invalid))])
    }
    
    func testAction_isDownloaded_true() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeModel = NodeEntity(isFile: true)
        let mockNodeDataUC = MockNodeDataUseCase(downloaded: true)
        let mockNodeThumbnailUC = MockThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeUseCase: mockNodeDataUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        test(viewModel: viewModel,
             action: .isDownloaded,
             expectedCommands: [.setDownloaded(mockNodeDataUC.isDownloaded(nodeHandle: .invalid))])
    }
    
    func testAction_moreTouchUpInside() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeModel = NodeEntity()
        let mockNodeDataUC = MockNodeDataUseCase()
        let mockNodeThumbnailUC = MockThumbnailUseCase()
        let mockAccountUC = MockAccountUseCase()
        
        let viewModel = NodeCellViewModel(nodeOpener: nodeOpener,
                                          nodeModel: mockNodeModel,
                                          nodeUseCase: mockNodeDataUC,
                                          nodeThumbnailUseCase: mockNodeThumbnailUC,
                                          accountUseCase: mockAccountUC)
        
        let sender = UIView()
        test(viewModel: viewModel,
             action: .moreTouchUpInside(sender),
             expectedCommands: [])
    }
}
