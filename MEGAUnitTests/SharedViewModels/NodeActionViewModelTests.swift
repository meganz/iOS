@testable import MEGA
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import Testing

struct NodeActionViewModelTests {
    static let sut = makeSUT()
    
    @Suite("Calls addToDestination")
    struct AddToDestination {
        @Suite("When Display Mode is CloudDrive")
        struct DisplayModeIsCloudDrive {
            private let displayMode: DisplayMode = .cloudDrive
            
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
            
            @Test("Always return .none destination if isFromSharedItem equals true, regardless of DisplayMode", arguments: DisplayMode.allCases)
            func addToDestinationWhenSharedItemIsTrue(displayMode: DisplayMode) {
                #expect(sut.addToDestination(nodes: .png, from: displayMode, isFromSharedItem: true) == .none)
            }
        }
        
        @Suite("When Display Mode is PhotosTimeline")
        struct DisplayModeIsPhotosTimeline {
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
            private static let unsupportedDisplayModes: [DisplayMode] = DisplayMode
                .allCases
                .filter { [.cloudDrive, .photosTimeline].notContains($0) }
            
            @Test("Always return .none destination", arguments: unsupportedDisplayModes)
            func unsupportedDisplayMode(displayMode: DisplayMode) {
                #expect(sut.addToDestination(nodes: .mp4, from: displayMode, isFromSharedItem: false) == .none)
            }
        }
    }
    
    @Suite("Calls isHidden")
    struct IsHidden {
        @Test("When node feature is off should return nil")
        func nodeFeatureOffIrrespectiveOfNodesSharedOrBackup() async {
            let node = NodeEntity(handle: 65, isMarkedSensitive: true)
            let remoteFeatureFlagUseCase = MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: false])
            let sut = makeSUT(remoteFeatureFlagUseCase: remoteFeatureFlagUseCase)
            let result = await sut.isHidden([node], isFromSharedItem: Bool.random(), containsBackupNode: Bool.random())
            #expect(result == nil)
        }
        
        @Test("When invalid account should return false")
        func invalidAccount() async throws {
            let nodes = makeSensitiveNodes(count: 100)
            let remoteFeatureFlagUseCase = MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true])
            let sut = makeSUT(
                sensitiveNodeUseCase: MockSensitiveNodeUseCase(isAccessible: false),
                remoteFeatureFlagUseCase: remoteFeatureFlagUseCase)
            
            let result = await sut.isHidden(nodes, isFromSharedItem: false, containsBackupNode: false)
            let unwrappedResult = try #require(result as Bool?, "Result should be not nil")
            #expect(!unwrappedResult)
        }
        
        @Test("When contains only sensitive nodes should return true")
        func nodesContainsOnlySensitiveNodes() async throws {
            let nodes = makeSensitiveNodes(count: 100)
            let remoteFeatureFlagUseCase = MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true])
            let sut = makeSUT(
                sensitiveNodeUseCase: MockSensitiveNodeUseCase(isAccessible: true),
                remoteFeatureFlagUseCase: remoteFeatureFlagUseCase)
            
            let result = await sut.isHidden(nodes, isFromSharedItem: false, containsBackupNode: false)
            let unwrappedResult = try #require(result as Bool?, "Result should be not nil")
            #expect(unwrappedResult)
        }
        
        @Test("When contains nodes not marked as sensitive should return false")
        func nodesContainsNodeNotMarkedAsSensitive() async throws {
            var nodes = makeSensitiveNodes(count: 100)
            nodes.append(NodeEntity(handle: HandleEntity(nodes.count + 1), isMarkedSensitive: false))
            let remoteFeatureFlagUseCase = MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true])
            let sut = makeSUT(
                sensitiveNodeUseCase: MockSensitiveNodeUseCase(isAccessible: true),
                remoteFeatureFlagUseCase: remoteFeatureFlagUseCase)
            
            let result = await sut.isHidden(nodes, isFromSharedItem: false, containsBackupNode: false)
            let unwrappedResult = try #require(result as Bool?, "Result should be not nil")
            #expect(!unwrappedResult)
        }
        
        @Test("When is from shared items returns nil", arguments: [true, false])
        func isFromSharedItemIsTrue(isMarkedSensitive: Bool) async throws {
            let node = NodeEntity(handle: 65, isMarkedSensitive: isMarkedSensitive)
            let remoteFeatureFlagUseCase = MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true])
            let sut = makeSUT(remoteFeatureFlagUseCase: remoteFeatureFlagUseCase)
            let result = await sut.isHidden([node], isFromSharedItem: true, containsBackupNode: false)
            #expect(result == nil)
        }
        
        @Test("When nodes is empty returns nil")
        func nodesEmpty() async throws {
            let remoteFeatureFlagUseCase = MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true])
            let sut = makeSUT(
                remoteFeatureFlagUseCase: remoteFeatureFlagUseCase
            )
            let result = await sut.isHidden([], isFromSharedItem: false, containsBackupNode: false)
            #expect(result == nil)
        }
        
        @Test("When nodes contain node that inherit sensitivity returns nil")
        func nodesContainNodeThatInheritSensitivity() async throws {
            let nodeNotSensitive = NodeEntity(handle: 1, isMarkedSensitive: false)
            let nodeInheritingSensitivity = NodeEntity(handle: 2, isMarkedSensitive: false)
            let nodes = [nodeNotSensitive, nodeInheritingSensitivity]
            let isInheritingSensitivityResults: [HandleEntity: Result<Bool, any Error>] = [
                nodeNotSensitive.handle: .success(false),
                nodeInheritingSensitivity.handle: .success(true)
            ]
            let sensitiveNodeUseCase = MockSensitiveNodeUseCase(
                isAccessible: true,
                isInheritingSensitivityResults: isInheritingSensitivityResults)
            
            let remoteFeatureFlagUseCase = MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true])
            let sut = makeSUT(
                sensitiveNodeUseCase: sensitiveNodeUseCase,
                remoteFeatureFlagUseCase: remoteFeatureFlagUseCase
            )
            let result = await sut.isHidden(nodes, isFromSharedItem: false, containsBackupNode: false)
            #expect(result == nil)
        }
        
        @Test("When nodes contain backup node returns nil")
        func nodesContainBackupNode() async {
            let node = NodeEntity(handle: 1)
            
            let isHidden = await sut.isHidden([node], isFromSharedItem: false, containsBackupNode: true)
            
            #expect(isHidden == nil)
        }
    }
    
    @Suite("Calls hasValidProOrUnexpiredBusinessAccount")
    struct HasValidProOrUnexpiredBusinessAccount {
        @Test("Test has valid pro or unexpired business account", arguments: [true, false])
        func onAccountValidity(isAccessible: Bool) {
            let sensitiveNodeUseCase = MockSensitiveNodeUseCase(isAccessible: isAccessible)
            
            let sut = makeSUT(sensitiveNodeUseCase: sensitiveNodeUseCase)
            
            #expect(sut.hasValidProOrUnexpiredBusinessAccount == isAccessible)
        }
    }
    
    @Suite("Calls isSensitive")
    struct IsSensitive {
        @Test("When feature flag disable returns false")
        func featureFlagDisabled() async {
            let remoteFeatureFlagUseCase = MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: false])
            let sut = makeSUT(remoteFeatureFlagUseCase: remoteFeatureFlagUseCase)
            let node = NodeEntity(handle: 1, isMarkedSensitive: true)
            
            let isSenstive = await sut.isSensitive(node: node)
            
            #expect(!isSenstive)
        }
        
        @Test("When invalid account returns false")
        func invalidAccount() async {
            let remoteFeatureFlagUseCase = MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true])
            let sut = makeSUT(
                sensitiveNodeUseCase: MockSensitiveNodeUseCase(isAccessible: false),
                remoteFeatureFlagUseCase: remoteFeatureFlagUseCase)
            let node = NodeEntity(handle: 1, isMarkedSensitive: true)
            
            let isSenstive = await sut.isSensitive(node: node)
            
            #expect(!isSenstive)
        }
        
        @Test("When feature flag enabled and node is sensitive returns true")
        func featureFlagEnabledAndNodeIsSensitive() async {
            let remoteFeatureFlagUseCase = MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true])
            let sut = makeSUT(
                sensitiveNodeUseCase: MockSensitiveNodeUseCase(isAccessible: true),
                remoteFeatureFlagUseCase: remoteFeatureFlagUseCase)
            let node = NodeEntity(handle: 1, isMarkedSensitive: true)
            
            let isSenstive = await sut.isSensitive(node: node)
            
            #expect(isSenstive)
        }
        
        @Test("When feature flag enabled and parent node is not sensitive returns true")
        func featureFlagEnabledAndParentNodeIsSensitive() async {
            let remoteFeatureFlagUseCase = MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true])
            let sensitiveNodeUseCase = MockSensitiveNodeUseCase(
                isAccessible: true,
                isInheritingSensitivityResult: .success(true))
            let sut = makeSUT(
                sensitiveNodeUseCase: sensitiveNodeUseCase,
                remoteFeatureFlagUseCase: remoteFeatureFlagUseCase)
            let node = NodeEntity(handle: 1, isMarkedSensitive: false)
            
            let isSenstive = await sut.isSensitive(node: node)
            
            #expect(isSenstive)
        }
    }
    
    @Suite("Call isRestorable")
    struct IsRestorable {
        @Test("It is not restorable because it is backup node")
        func isBackupNode() {
            let result = sut.isRestorable(node: NodeEntity(), isBackupNode: true)
            #expect(!result)
        }
        
        @Test("It is not restorable because it is not in the rubbish bin")
        func isNotBackupNodeAndNodeIsNotInRubbishBin() {
            let result = sut.isRestorable(node: NodeEntity(), isBackupNode: false)
            #expect(!result)
        }
        
        @Test("It is restorable because it is not backup node and node is in Rubbish bin")
        func isNotBackupNodeAndNodeIsInRubbishBin() {
            let node = NodeEntity(handle: 1)
            let nodeUseCase = MockNodeUseCase(nodeInRubbishBin: node)
            let sut = makeSUT(nodeUseCase: nodeUseCase)
            let result = sut.isRestorable(node: node, isBackupNode: false)
            #expect(result)
        }
        
        @Test("It is not restorable because it is backup node and it is not in the rubbish bin")
        func isBackupNodeAndNodeIsInRubbishBin() {
            let node = NodeEntity(handle: 1)
            let nodeUseCase = MockNodeUseCase(nodeInRubbishBin: node)
            let sut = makeSUT(nodeUseCase: nodeUseCase)
            let result = sut.isRestorable(node: NodeEntity(), isBackupNode: true)
            #expect(!result)
        }
    }
    
    @Suite("Call files and folders")
    struct FilesAndFolders {
        @Test func filesAndFolders() {
            let result = sut.filesAndFolders(nodeHandle: 1)
            #expect(result.0 == 0)
            #expect(result.1 == 0)
        }
    }

    @Suite("Calls isModificationTimeUndefined")
    struct IsModificationTimeUndefined {
        @Test(
            arguments: [
                (Date(), false),
                (Date(timeIntervalSince1970: 1), false),
                (Date(timeIntervalSince1970: 0), true)
            ],
        )
        func isModificationTimeUndefined(
            modificationTime: Date,
            expectedValue: Bool
        ) {
            let sut = makeSUT()
            let node = NodeEntity(modificationTime: modificationTime)

            let result = sut.isModificationTimeUndefined(for: node)

            #expect(result == expectedValue)
        }
    }

    private static func makeSUT(
        systemGeneratedNodeUseCase: some SystemGeneratedNodeUseCaseProtocol = MockSystemGeneratedNodeUseCase(nodesForLocation: [:]),
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol = MockSensitiveNodeUseCase(),
        maxDetermineSensitivityTasks: Int = 10,
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = MockRemoteFeatureFlagUseCase(),
        nodeUseCase: some NodeUseCaseProtocol = MockNodeUseCase()
    ) -> NodeActionViewModel {
        NodeActionViewModel(
            systemGeneratedNodeUseCase: systemGeneratedNodeUseCase,
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            maxDetermineSensitivityTasks: maxDetermineSensitivityTasks,
            remoteFeatureFlagUseCase: remoteFeatureFlagUseCase,
            nodeUseCase: nodeUseCase)
    }
    
    private static func makeSensitiveNodes(count: Int = 5) -> [NodeEntity] {
        (0..<count).map {
            NodeEntity(handle: HandleEntity($0), isMarkedSensitive: true)
        }
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
