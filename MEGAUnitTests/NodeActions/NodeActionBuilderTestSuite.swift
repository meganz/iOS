@testable import MEGA
import MEGASDKRepoMock
import Testing

@Suite("NodeActionBuilderTestSuite")
struct NodeActionBuilderTestSuite {
    @Suite("calls singleSelectBuild")
    struct SingleSelectBuild {
        @Suite("When Display Mode is .photosTimeline")
        struct DisplayModePhotosTimeline {
            private let displayMode = DisplayMode.photosTimeline
            
            @Test("when accessLevel is owner")
            @MainActor func accessOwner() {
                let actions = NodeActionBuilder()
                    .setDisplayMode(displayMode)
                    .setAccessLevel(.accessOwner)
                    .build()
                
                #expect(actions.types == [.info, .favourite, .label, .download, .shareLink, .shareFolder, .rename, .move, .copy, .moveToRubbishBin])
            }
            
            @Test("when AddToDestination set", arguments: [
                (NodeActionAddToDestination.albums, MegaNodeActionType?.some(.addToAlbum)),
                (.albumsAndVideos, .addTo),
                (.none, nil)
            ])
            @MainActor func setAddToDestination(destination: NodeActionAddToDestination, expectedAction: MegaNodeActionType?) {
                let actions = NodeActionBuilder()
                    .setDisplayMode(displayMode)
                    .setAccessLevel(.accessOwner)
                    .setAddToDestination(destination)
                    .build()
                
                let expectedResults: [MegaNodeActionType] = [.info, .favourite, .label, .download, .shareLink, .shareFolder, .rename, .move, expectedAction, .copy, .moveToRubbishBin]
                    .compactMap { $0 }
                
                #expect(actions.types == expectedResults)
            }
        }

        @Suite("When Display Mode is .photosAlbums")
        struct DisplayModePhotosAlbums {
            static let displayMode = DisplayMode.photosAlbum

            @Suite("calls singleSelectBuild")
            struct SingleSelectBuild {

                @Test("when accessLevel is owner")
                @MainActor func accessOwner() {
                    let actions = NodeActionBuilder()
                        .setDisplayMode(displayMode)
                        .setAccessLevel(.accessOwner)
                        .build()

                    #expect(actions.types == [.info, .favourite, .label, .download, .shareLink, .shareFolder, .rename, .move, .copy])
                }

                @Test("when AddToDestination set", arguments: [
                    (NodeActionAddToDestination.albums, MegaNodeActionType?.some(.addToAlbum)),
                    (.albumsAndVideos, .addTo),
                    (.none, nil)
                ])
                @MainActor func setAddToDestination(destination: NodeActionAddToDestination, expectedAction: MegaNodeActionType?) {
                    let actions = NodeActionBuilder()
                        .setDisplayMode(displayMode)
                        .setAccessLevel(.accessOwner)
                        .setAddToDestination(destination)
                        .build()

                    #expect(actions.types == [.info, .favourite, .label, .download, .shareLink, .shareFolder, .rename, .move, expectedAction, .copy].compactMap { $0 })
                }
            }
        }
    }
    
    @Suite("calls multiselectBuild")
    struct MultiSelectBuild {
        @Suite("When Display Mode is .photosTimeline")
        struct DisplayModePhotosTimeline {
            private let displayMode = DisplayMode.photosTimeline
            
            @Test("when all media are files")
            @MainActor func mediaFiles() {
                let actions = NodeActionBuilder()
                    .setNodeSelectionType(.files, selectedNodeCount: 4)
                    .setAreMediaFiles(true)
                    .setDisplayMode(displayMode)
                    .multiselectBuild()
                
                #expect(actions.types == [.download, .shareLink, .exportFile, .sendToChat, .saveToPhotos, .move, .copy, .moveToRubbishBin])
            }
            
            @Test("when one node inherits sensitivity on a active account paying account.")
            @MainActor func containsHiddenFilesWithValidAccountType() {
                let actions = NodeActionBuilder()
                    .setAccessLevel(.accessOwner)
                    .setNodeSelectionType(.files, selectedNodeCount: 4)
                    .setDisplayMode(displayMode)
                    .setIsHiddenNodesFeatureEnabled(true)
                    .setHasValidProOrUnexpiredBusinessAccount(true)
                    .setIsHidden(true)
                    .multiselectBuild()
                
                let expectedResults: [MegaNodeActionType] = [.download, .shareLink, .exportFile, .sendToChat, .unhide, .move, .copy, .moveToRubbishBin]
                #expect(actions.types == expectedResults)
            }
            
            @Test("when no nodes inherit sensitivity")
            @MainActor func noNodesInheritSensitivity() {
                let actions = NodeActionBuilder()
                    .setAccessLevel(.accessOwner)
                    .setNodeSelectionType(.files, selectedNodeCount: 4)
                    .setDisplayMode(displayMode)
                    .setIsHiddenNodesFeatureEnabled(true)
                    .setIsHidden(false)
                    .multiselectBuild()
                
                let expectedResults: [MegaNodeActionType] = [.download, .shareLink, .exportFile, .sendToChat, .hide, .move, .copy, .moveToRubbishBin]
                #expect(actions.types == expectedResults)
            }
            
            @Test("when nodes contain sensitive node and contains a mix of folders and files")
            @MainActor func containsSensitiveFileAndFolderNodes() {
                let actions = NodeActionBuilder()
                    .setAccessLevel(.accessOwner)
                    .setNodeSelectionType(.filesAndFolders, selectedNodeCount: 4)
                    .setDisplayMode(displayMode)
                    .setIsHiddenNodesFeatureEnabled(true)
                    .setIsHidden(false)
                    .multiselectBuild()
                
                let expectedResults: [MegaNodeActionType] = [.download, .shareLink, .hide, .move, .copy, .moveToRubbishBin]

                #expect(actions.types == expectedResults)
            }
            
            @Test("when isHidden equals nil, on a active account paying account", arguments: [
                NodeSelectionType.folders,
                .files,
                .filesAndFolders])
            @MainActor func whenIsHiddenIsNilOnActiveAccount(selectionType: NodeSelectionType) {
                let actions = NodeActionBuilder()
                    .setNodeSelectionType(selectionType, selectedNodeCount: 4)
                    .setDisplayMode(displayMode)
                    .setIsHiddenNodesFeatureEnabled(true)
                    .setHasValidProOrUnexpiredBusinessAccount(true)
                    .setIsHidden(nil)
                    .multiselectBuild()

                let expectedResult = actions.types.notContains(where: { [.hide, .unhide].contains($0) })

                #expect(expectedResult)
            }
            
            static func addToDestinationArguments() -> [(NodeActionAddToDestination, MegaNodeActionType?)] {
                [
                    (.albums, .addToAlbum),
                    (.albumsAndVideos, .addTo),
                    (.none, nil)
                ]
            }
            
            @Test("when AddToDestination set", arguments: addToDestinationArguments())
            @MainActor func setAddToDestination(destination: NodeActionAddToDestination, expectedAction: MegaNodeActionType?) {
                let actions = NodeActionBuilder()
                    .setDisplayMode(displayMode)
                    .setNodeSelectionType(.files, selectedNodeCount: 4)
                    .setAddToDestination(destination)
                    .multiselectBuild()
                
                let expectedResults =  [.download, .shareLink, .exportFile, .sendToChat, .move, expectedAction, .copy, .moveToRubbishBin]
                    .compactMap { $0 }

                #expect(actions.types == expectedResults)
            }
        }
    }
    
    @Suite("When Display Mode is .photosAlbums")
    struct DisplayModePhotosAlbums {

        let displayMode = DisplayMode.photosAlbum

        @Test("when all media are files")
        @MainActor  func mediaFiles() {
            let actions = NodeActionBuilder()
                .setNodeSelectionType(.files, selectedNodeCount: 4)
                .setAreMediaFiles(true)
                .setDisplayMode(displayMode)
                .multiselectBuild()
            #expect(actions.types == [.download, .shareLink, .exportFile, .sendToChat, .moveToRubbishBin])
        }

        @Test("when one node inherits sensitivity on a active account paying account.")
        @MainActor func containsHiddenFilesWithValidAccountType() {
            let actions = NodeActionBuilder()
                .setAccessLevel(.accessOwner)
                .setNodeSelectionType(.files, selectedNodeCount: 4)
                .setDisplayMode(displayMode)
                .setIsHiddenNodesFeatureEnabled(true)
                .setHasValidProOrUnexpiredBusinessAccount(true)
                .setIsHidden(true)
                .multiselectBuild()

            #expect(actions.types == [.download, .shareLink, .exportFile, .sendToChat, .unhide, .moveToRubbishBin])
        }

        @Test("when no nodes inherit sensitivity")
        @MainActor func noNodesInheritSensitivity() {
            let actions = NodeActionBuilder()
                .setAccessLevel(.accessOwner)
                .setNodeSelectionType(.files, selectedNodeCount: 4)
                .setDisplayMode(displayMode)
                .setIsHiddenNodesFeatureEnabled(true)
                .setIsHidden(false)
                .multiselectBuild()

            #expect(actions.types == [.download, .shareLink, .exportFile, .sendToChat, .hide, .moveToRubbishBin])
        }

        @Test("when isHidden equals nil, on a active account paying account", arguments: [
            NodeSelectionType.folders,
            .files,
            .filesAndFolders])
        @MainActor func whenIsHiddenIsNilOnActiveAccount(selectionType: NodeSelectionType) {
            let actions = NodeActionBuilder()
                .setNodeSelectionType(selectionType, selectedNodeCount: 4)
                .setDisplayMode(displayMode)
                .setIsHiddenNodesFeatureEnabled(true)
                .setHasValidProOrUnexpiredBusinessAccount(true)
                .setIsHidden(nil)
                .multiselectBuild()

            #expect(actions.types.notContains(where: { [.hide, .unhide].contains($0) }))
        }

        @Test("when AddToDestination set, no destination action should be provided", arguments: [
            NodeActionAddToDestination.albums,
            .albumsAndVideos,
            .none
        ])
        @MainActor func setAddToDestination(destination: NodeActionAddToDestination) {
            let actions = NodeActionBuilder()
                .setDisplayMode(displayMode)
                .setNodeSelectionType(.files, selectedNodeCount: 4)
                .setAddToDestination(destination)
                .multiselectBuild()

            #expect(actions.types == [.download, .shareLink, .exportFile, .sendToChat, .moveToRubbishBin])
        }
    }
    
    @Suite("When show actions for Transfers")
    struct TransfersActionsTests {
        
        @Test(
            "When the current Transfer should display 'View in folder' or not",
            arguments: [
                (false, [MegaNodeActionType.shareLink, .clear]),
                (true, [.viewInFolder, .shareLink, .clear])
            ]
        )
        @MainActor func showViewInFolderTransfer(
            viewInFolder: Bool,
            expectedActions: [MegaNodeActionType]
        ) {
            let actions = NodeActionBuilder()
                .setDisplayMode(.transfers)
                .setViewInFolder(viewInFolder)
                .build()
            
            #expect(actions.types == expectedActions)
        }
    }
}

extension [NodeAction] {
    var types: [MegaNodeActionType] {
        map(\.type)
    }
}
