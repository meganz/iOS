@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

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
        let mockNodeDataUC = MockNodeDataUseCase(labelString: "redSmall")
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
                                .setLabel("redSmall")])
        XCTAssertEqual(mockNodeModel.label, .red)
    }
    
    func testAction_manageLabel_orange() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeModel = NodeEntity(label: .orange)
        let mockNodeDataUC = MockNodeDataUseCase(labelString: "orangeSmall")
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
                                .setLabel("orangeSmall")])
        XCTAssertEqual(mockNodeModel.label, .orange)
    }
    
    func testAction_manageLabel_yellow() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeModel = NodeEntity(label: .yellow)
        let mockNodeDataUC = MockNodeDataUseCase(labelString: "yellowSmall")
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
                                .setLabel("yellowSmall")])
        XCTAssertEqual(mockNodeModel.label, .yellow)
    }
    
    func testAction_manageLabel_green() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeModel = NodeEntity(label: .green)
        let mockNodeDataUC = MockNodeDataUseCase(labelString: "greenSmall")
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
                                .setLabel("greenSmall")])
        XCTAssertEqual(mockNodeModel.label, .green)
    }
    
    func testAction_manageLabel_blue() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeModel = NodeEntity(label: .blue)
        let mockNodeDataUC = MockNodeDataUseCase(labelString: "blueSmall")
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
                                .setLabel("blueSmall")])
        XCTAssertEqual(mockNodeModel.label, .blue)
    }
    
    func testAction_manageLabel_purple() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeModel = NodeEntity(label: .purple)
        let mockNodeDataUC = MockNodeDataUseCase(labelString: "purpleSmall")
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
                                .setLabel("purpleSmall")])
        XCTAssertEqual(mockNodeModel.label, .purple)
    }
    
    func testAction_manageLabel_grey() {
        let nodeOpener = NodeOpener(navigationController: UINavigationController())
        let mockNodeModel = NodeEntity(label: .grey)
        let mockNodeDataUC = MockNodeDataUseCase(labelString: "greySmall")
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
                                .setLabel("greySmall")])
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
                                .setIcon(.filetypeFolder)])
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
                                .setIcon(.filetypeGeneric)])
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
