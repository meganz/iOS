@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import Testing

struct NodeActionViewModelTestSuite {
    
    @Suite("Calls addToDestination")
    struct AddToDestination {
        let sut = makeSUT()
        
        @Test("Always return .none destination if isFromSharedItem equals true, regardless of DisplayMode", arguments: DisplayMode.allCases)
        func addToDestinationWhenSharedItemIsTrue(displayMode: DisplayMode) {
            #expect(sut.addToDestination(nodes: .png, from: displayMode, isFromSharedItem: true) == .none)
        }
        
        @Suite("When Display Mode is CloudDrive")
        struct DisplayModeIsCloudDrive {
            private let displayMode: DisplayMode = .cloudDrive
            private let sut = makeSUT()
            
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
            
            private let sut = makeSUT()
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
            private let sut = makeSUT()
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
        systemGeneratedNodeUseCase: some SystemGeneratedNodeUseCaseProtocol = MockSystemGeneratedNodeUseCase(nodesForLocation: [:]),
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol = MockSensitiveNodeUseCase(),
        maxDetermineSensitivityTasks: Int = 10
    ) -> NodeActionViewModel {
        NodeActionViewModel(
            systemGeneratedNodeUseCase: systemGeneratedNodeUseCase,
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            maxDetermineSensitivityTasks: maxDetermineSensitivityTasks)
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
