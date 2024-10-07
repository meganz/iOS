@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import Testing
import XCTest

final class NodeActionViewModelTests: XCTestCase {

    func testIsHidden_hiddenNodeFeatureOffIrrespectiveOfNodesSharedOrBackup_shouldReturnNil() async {
        let node = NodeEntity(handle: 65, isMarkedSensitive: true)
        let featureFlagProvider = MockFeatureFlagProvider(list: [.hiddenNodes: false])
        let sut = makeSUT(featureFlagProvider: featureFlagProvider)
        let result = await sut.isHidden([node], isFromSharedItem: Bool.random(), containsBackupNode: Bool.random())
        XCTAssertNil(result)
    }
    
    func testIsHidden_nodesContainsOnlySensitiveNodes_shouldReturnTrue() async throws {
        let nodes = makeSensitiveNodes(count: 100)
        let featureFlagProvider = MockFeatureFlagProvider(list: [.hiddenNodes: true])
        let sut = makeSUT(featureFlagProvider: featureFlagProvider)
        
        let result = await sut.isHidden(nodes, isFromSharedItem: false, containsBackupNode: false)
        
        XCTAssertTrue(try XCTUnwrap(result))
    }
    
    func testIsHidden_nodesContainsNodeNotMarkedAsSensitive_shouldReturnFalse() async throws {
        var nodes = makeSensitiveNodes(count: 100)
        nodes.append(NodeEntity(handle: HandleEntity(nodes.count + 1), isMarkedSensitive: false))
        let featureFlagProvider = MockFeatureFlagProvider(list: [.hiddenNodes: true])
        let sut = makeSUT(featureFlagProvider: featureFlagProvider)
        
        let result = await sut.isHidden(nodes, isFromSharedItem: false, containsBackupNode: false)
        
        XCTAssertFalse(try XCTUnwrap(result))
    }
    
    func testIsHidden_isFromSharedItemIsTrue_shouldReturnNil() async throws {
        for await isMarkedSensitive in [true, false].async {
            let node = NodeEntity(handle: 65, isMarkedSensitive: isMarkedSensitive)
            let featureFlagProvider = MockFeatureFlagProvider(list: [.hiddenNodes: true])
            let sut = makeSUT(featureFlagProvider: featureFlagProvider)
            let result = await sut.isHidden([node], isFromSharedItem: true, containsBackupNode: false)
            XCTAssertNil(result)
        }
    }
    
    func testIsHidden_nodeIsSystemManaged_shouldReturnNil() async throws {
        let systemNode = NodeEntity(handle: 65)
        let nodes = [
            systemNode,
            NodeEntity(handle: 66, isMarkedSensitive: true)
        ]
        let featureFlagProvider = MockFeatureFlagProvider(list: [.hiddenNodes: true])
        let sut = makeSUT(
            systemGeneratedNodeUseCase: MockSystemGeneratedNodeUseCase(
                nodesForLocation: [.cameraUpload: systemNode]),
            featureFlagProvider: featureFlagProvider
        )
        let result = await sut.isHidden(nodes, isFromSharedItem: false, containsBackupNode: false)
        XCTAssertNil(result)
    }
    
    func testIsHidden_nodeIsSystemManagedAndErrorWasThrown_shouldReturnNil() async throws {
        
        let errors: [any Error] = [
            GenericErrorEntity(),
            CancellationError()
        ]
        
        for await error in errors.async {
            let systemNode = NodeEntity(handle: 65)
            let nodes = [
                systemNode,
                NodeEntity(handle: 66, isMarkedSensitive: true)
            ]
            let featureFlagProvider = MockFeatureFlagProvider(list: [.hiddenNodes: true])
            let sut = makeSUT(
                systemGeneratedNodeUseCase: MockSystemGeneratedNodeUseCase(
                    nodesForLocation: [.cameraUpload: systemNode],
                    containsSystemGeneratedNodeError: error),
                featureFlagProvider: featureFlagProvider
            )
            let result = await sut.isHidden(nodes, isFromSharedItem: false, containsBackupNode: false)
            XCTAssertNil(result)
        }
    }
    
    func testIsHidden_nodesEmpty_shouldReturnNil() async throws {
        let featureFlagProvider = MockFeatureFlagProvider(list: [.hiddenNodes: true])
        let sut = makeSUT(
            featureFlagProvider: featureFlagProvider
        )
        let result = await sut.isHidden([], isFromSharedItem: false, containsBackupNode: false)
        XCTAssertNil(result)
    }
    
    func testIsHidden_nodesContainNodeThatInheritSensitivity_shouldReturnNil() async throws {
        let nodeNotSensitive = NodeEntity(handle: 1, isMarkedSensitive: false)
        let nodeInheritingSensitivity = NodeEntity(handle: 2, isMarkedSensitive: false)
        let nodes = [nodeNotSensitive, nodeInheritingSensitivity]
        let isInheritingSensitivityResults: [HandleEntity: Result<Bool, any Error>] = [
            nodeNotSensitive.handle: .success(false),
            nodeInheritingSensitivity.handle: .success(true)
        ]
        let sensitiveNodeUseCase = MockSensitiveNodeUseCase(
            isInheritingSensitivityResults: isInheritingSensitivityResults)
        
        let featureFlagProvider = MockFeatureFlagProvider(list: [.hiddenNodes: true])
        let sut = makeSUT(
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            featureFlagProvider: featureFlagProvider
        )
        let result = await sut.isHidden(nodes, isFromSharedItem: false, containsBackupNode: false)
        XCTAssertNil(result)
    }
    
    func testIsHidden_nodesContainBackupNode_shouldReturnNil() async {
        let node = NodeEntity(handle: 1)
        let sut = makeSUT()
        
        let isHidden = await sut.isHidden([node], isFromSharedItem: false, containsBackupNode: true)
        
        XCTAssertNil(isHidden)
    }

    func testHasValidProOrUnexpiredBusinessAccount_onAccountValidity_shouldReturnCorrectResult() {
        [true, false]
            .enumerated()
            .forEach { (index, isValid) in
                let accountUseCase = MockAccountUseCase(hasValidProOrUnexpiredBusinessAccount: isValid)
                
                let sut = makeSUT(accountUseCase: accountUseCase)
                
                XCTAssertEqual(sut.hasValidProOrUnexpiredBusinessAccount, isValid,
                               "failed at index: \(index) for expected: \(isValid)")
            }
    }
    
    func testIsSensitive_whenFeatureFlagDisabled_shouldReturnFalse() async {
        // given
        let featureFlagProvider = MockFeatureFlagProvider(list: [.hiddenNodes: false])
        let sut = makeSUT(featureFlagProvider: featureFlagProvider)
        let node = NodeEntity(handle: 1, isMarkedSensitive: true)
        
        // when
        let isSenstive = await sut.isSensitive(node: node)
        
        // then
        XCTAssertFalse(isSenstive)
    }
    
    func testIsSensitive_whenFeatureFlagEnabledAndNodeIsSensitive_shouldReturnTrue() async {
        // given
        let featureFlagProvider = MockFeatureFlagProvider(list: [.hiddenNodes: true])
        let sut = makeSUT(featureFlagProvider: featureFlagProvider)
        let node = NodeEntity(handle: 1, isMarkedSensitive: true)
        
        // when
        let isSenstive = await sut.isSensitive(node: node)
        
        // then
        XCTAssertTrue(isSenstive)
    }
    
    func testIsSensitive_whenFeatureFlagEnabledAndParentNodeIsSensitive_shouldReturnTrue() async {
        // given
        let featureFlagProvider = MockFeatureFlagProvider(list: [.hiddenNodes: true])
        let sensitiveNodeUseCase = MockSensitiveNodeUseCase(isInheritingSensitivityResult: .success(true))
        let sut = makeSUT(sensitiveNodeUseCase: sensitiveNodeUseCase,
                          featureFlagProvider: featureFlagProvider)
        let node = NodeEntity(handle: 1, isMarkedSensitive: false)
        
        // when
        let isSenstive = await sut.isSensitive(node: node)
        
        // then
        XCTAssertTrue(isSenstive)
    }
    
    private func makeSUT(
        accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase(),
        systemGeneratedNodeUseCase: some SystemGeneratedNodeUseCaseProtocol = MockSystemGeneratedNodeUseCase(nodesForLocation: [:]),
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol = MockSensitiveNodeUseCase(),
        maxDetermineSensitivityTasks: Int = 10,
        featureFlagProvider: some FeatureFlagProviderProtocol = MockFeatureFlagProvider(list: [:])
    ) -> NodeActionViewModel {
        NodeActionViewModel(
            accountUseCase: accountUseCase,
            systemGeneratedNodeUseCase: systemGeneratedNodeUseCase,
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            maxDetermineSensitivityTasks: maxDetermineSensitivityTasks,
            featureFlagProvider: featureFlagProvider)
    }
    
    private func makeSensitiveNodes(count: Int = 5) -> [NodeEntity] {
        (0..<count).map {
            NodeEntity(handle: HandleEntity($0), isMarkedSensitive: true)
        }
    }
}

@Suite("NodeActionViewModelTests")
struct NodeActionViewModelTestSuite {
    
    @Suite("Calls addToDestination")
    struct AddToDestination {
        
        @Suite("When Feature Flag is off")
        struct FeatureFlagOffTests {
            
            private let sut = AddToDestination.makeSUT(featureFlagAddToEnabled: false)
            private static func arguments() -> [(DisplayMode, Bool)] {
                [true, false]
                    .flatMap { isFromSharedItem in DisplayMode.allCases.map({ ($0, isFromSharedItem) }) }
            }
                        
            @Test("Always return .none destination for all displayModes and isFromSharedItem flag", arguments: arguments())
            func addToDestination(displayMode: DisplayMode, isFromSharedItem: Bool) {
                #expect(sut.addToDestination(nodes: [], from: displayMode, isFromSharedItem: isFromSharedItem) == .none)
            }
        }
        
        @Suite("When Feature Flag is on")
        struct FeatureFlagOnTests {
            let sut = AddToDestination.makeSUT(featureFlagAddToEnabled: true)

            @Test("Always return .none destination if isFromSharedItem equals true, regardless of DisplayMode", arguments: DisplayMode.allCases)
            func addToDestinationWhenSharedItemIsTrue(displayMode: DisplayMode) {
                #expect(sut.addToDestination(nodes: .png, from: displayMode, isFromSharedItem: true) == .none)
            }
            
            @Suite("When Display Mode is CloudDrive")
            struct DisplayModeIsCloudDrive {
                private let displayMode: DisplayMode = .cloudDrive
                private let sut = AddToDestination.makeSUT(featureFlagAddToEnabled: true)

                @Test("When all nodes are visual media and at least one node is an image, destination should be .albums", arguments: [
                    .png,
                    .pngAndJpg,
                    .png + .mp4
                ])
                func oneOrMoreImage(nodes: [NodeEntity]) {
                    #expect(sut.addToDestination(nodes: nodes, from: displayMode, isFromSharedItem: false) == .albums)
                }
                
                @Test("When all nodes are video files, destination should be .albumsAndVideos", arguments: [
                    [NodeEntity].mp4,
                    .mp4AndMov
                ])
                func allVideo(nodes: [NodeEntity]) {
                    #expect(sut.addToDestination(nodes: nodes, from: displayMode, isFromSharedItem: false) == .albumsAndVideos)
                }
                
                @Test("When there is at least one non-visual-media node, destination should be .none", arguments: [
                    [NodeEntity].nonAudioVisual,
                    .mp4 + .nonAudioVisual
                ])
                func containsNonVisualMedia(nodes: [NodeEntity]) {
                    #expect(sut.addToDestination(nodes: nodes, from: displayMode, isFromSharedItem: false) == .none)
                }
            }
            
            @Suite("When Display Mode is PhotosTimeline")
            struct DisplayModeIsPhotosTimeline {
                
                private let sut = AddToDestination.makeSUT(featureFlagAddToEnabled: true)
                private let displayMode: DisplayMode = .photosTimeline
                
                @Test("When all nodes are visual media, destination should always be .albums", arguments: [
                    [NodeEntity].pngAndJpg,
                    .png + .mp4,
                    .mp4AndMov
                ])
                func allAreVisualMedia(nodes: [NodeEntity]) {
                    #expect(sut.addToDestination(nodes: nodes, from: displayMode, isFromSharedItem: false) == .albums)
                }
                
                @Test("When there is at least one non-visual-media node, destination should be .none", arguments: [
                    [NodeEntity].nonAudioVisual,
                    [NodeEntity].nonAudioVisual + .mp4
                ])
                func containsNonVisualMedia(nodes: [NodeEntity]) {
                    #expect(sut.addToDestination(nodes: nodes, from: displayMode, isFromSharedItem: false) == .none)
                }
            }
            
            @Suite("When Display Mode is unsupported")
            struct DisplayModeIsUnsupported {
                private let sut = AddToDestination.makeSUT(featureFlagAddToEnabled: true)
                private static let unsupportedDisplayModes: [DisplayMode] = DisplayMode
                    .allCases
                    .filter { [.cloudDrive, .photosTimeline].notContains($0) }
                
                @Test("Always return .none destination", arguments: unsupportedDisplayModes)
                func unsupportedDisplayMode(displayMode: DisplayMode) {
                    #expect(sut.addToDestination(nodes: .mp4, from: displayMode, isFromSharedItem: false) == .none)
                }
            }
        }
                
        private static func makeSUT(
            accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase(),
            featureFlagAddToEnabled: Bool = false
        ) -> NodeActionViewModel {
            NodeActionViewModelTestSuite.makeSUT(
                featureFlagList: [.addToAlbumAndPlaylists: featureFlagAddToEnabled]
            )
        }
    }
    
    private static func makeSUT(
        accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase(),
        systemGeneratedNodeUseCase: some SystemGeneratedNodeUseCaseProtocol = MockSystemGeneratedNodeUseCase(nodesForLocation: [:]),
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol = MockSensitiveNodeUseCase(),
        maxDetermineSensitivityTasks: Int = 10,
        featureFlagList: [FeatureFlagKey: Bool] = [:]
    ) -> NodeActionViewModel {
        NodeActionViewModel(
            accountUseCase: accountUseCase,
            systemGeneratedNodeUseCase: systemGeneratedNodeUseCase,
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            maxDetermineSensitivityTasks: maxDetermineSensitivityTasks,
            featureFlagProvider: MockFeatureFlagProvider(list: featureFlagList))
    }
}

extension [NodeEntity] {
    static let png = [NodeEntity(name: "file.png", isFile: true)]
    static let pngAndJpg = [NodeEntity(name: "file.png", isFile: true), NodeEntity(name: "file.jpg", isFile: true)]
    static let mp4 = [NodeEntity(name: "file.mp4", isFile: true)]
    static let mp4AndMov = [NodeEntity(name: "file.mp4", isFile: true), NodeEntity(name: "file.mov", isFile: true)]
    static let nonAudioVisual = [NodeEntity(name: "document.pdf", isFile: true), NodeEntity(name: "Folder", isFile: false, isFolder: true)]
}

extension DisplayMode {
    static var allCases: [DisplayMode] {
        [.unknown, .cloudDrive, .rubbishBin, .sharedItem, .nodeInfo, .nodeVersions, .folderLink, .nodeInsideFolderLink, .recents, .publicLinkTransfers, .transfers, .transfersFailed, .chatAttachment, .chatSharedFiles, .previewDocument, .textEditor, .backup, .mediaDiscovery, .photosFavouriteAlbum, .photosAlbum, .photosTimeline, .previewPdfPage, .albumLink, .videoPlaylistContent]
    }
}
