@testable import MEGA
import MEGAAppSDKRepoMock
import MEGADomain
import Testing

@Suite("AudioPlayerConfigEntity")
struct AudioPlayerConfigEntityTests {
    private static let node = MockNode(handle: 1)
    private static let link = "exampleFileLink"
    private static let chatId: HandleEntity = 2
    private static let messageId: HandleEntity = 1
    private static let audioFiles = ["relatedFile1.mp3", "relatedFile2.mp3"]
    private static let mixedFiles = ["relatedFile1.mp3", "relatedFile2.mov", "relatedFile3.jpeg", "relatedFile4.txt"]
    private static let nonAudio = ["relatedFile1.mov", "relatedFile2.mov", "relatedFile3.jpeg", "relatedFile4.txt"]
    
    private static func makeSUT(
        node: MockNode? = nil,
        isFolderLink: Bool = false,
        fileLink: String? = nil,
        messageId: HandleEntity? = nil,
        chatId: HandleEntity? = nil,
        relatedFiles: [String]? = nil,
        allNodes: [MockNode]? = nil,
        shouldResetPlayer: Bool = false
    ) -> AudioPlayerConfigEntity {
        AudioPlayerConfigEntity(
            node: node,
            isFolderLink: isFolderLink,
            fileLink: fileLink,
            messageId: messageId,
            chatId: chatId,
            relatedFiles: relatedFiles,
            allNodes: allNodes,
            shouldResetPlayer: shouldResetPlayer
        )
    }
    
    @Suite("isFolderLink")
    struct IsFolderLink {
        @Test("returns true when isFolderLink is true")
        func returnsTrueWhenFlagIsTrue() {
            let sut = makeSUT(isFolderLink: true)
            #expect(sut.isFolderLink)
        }
        
        @Test("returns false when isFolderLink is false")
        func returnsFalseWhenFlagIsFalse() {
            let sut = makeSUT(isFolderLink: false)
            #expect(!sut.isFolderLink)
        }
    }
    
    @Suite("node")
    struct NodeSuite {
        @Test("returns provided node when set")
        func returnsProvidedNodeWhenSet() {
            let sut = makeSUT(node: node)
            #expect(sut.node == node)
        }
        
        @Test("returns nil when node not set")
        func returnsNilWhenNodeNotSet() {
            let sut = makeSUT()
            #expect(sut.node == nil)
        }
    }
    
    @Suite("chatId")
    struct ChatIdSuite {
        @Test("returns provided chatId when set")
        func returnsChatIdWhenSet() {
            let sut = makeSUT(chatId: chatId)
            #expect(sut.chatId == chatId)
        }
        
        @Test("returns nil when chatId not set")
        func returnsNilWhenChatIdNotSet() {
            let sut = makeSUT()
            #expect(sut.chatId == nil)
        }
    }
    
    @Suite("isFileLink")
    struct IsFileLinkSuite {
        @Test("returns true when fileLink exists")
        func returnsTrueWhenFileLinkExists() {
            let sut = makeSUT(fileLink: link)
            #expect(sut.isFileLink)
        }
        
        @Test("returns false when relatedFiles exist instead of fileLink")
        func returnsFalseWhenOnlyRelatedFilesExist() {
            let sut = makeSUT(relatedFiles: audioFiles)
            #expect(!sut.isFileLink)
        }
    }
    
    @Suite("playerType")
    struct PlayerTypeSuite {
        @Test("returns .folderLink when isFolderLink is true")
        func returnsFolderLinkWhenFlagIsTrue() {
            let sut = makeSUT(isFolderLink: true)
            #expect(sut.playerType == .folderLink)
        }
        
        @Test("returns .fileLink when fileLink exists")
        func returnsFileLinkWhenFileLinkExists() {
            let sut = makeSUT(fileLink: link)
            #expect(sut.playerType == .fileLink)
        }
        
        @Test("returns .offline when relatedFiles exist")
        func returnsOfflineWhenRelatedFilesExist() {
            let sut = makeSUT(relatedFiles: audioFiles)
            #expect(sut.playerType == .offline)
        }
        
        @Test("returns .default when no special values provided")
        func returnsDefaultWhenNoSpecialValues() {
            let sut = makeSUT()
            #expect(sut.playerType == .default)
        }
    }
    
    @Suite("nodeOriginType")
    struct NodeOriginTypeSuite {
        @Test("returns .folderLink when isFolderLink is true")
        func returnsFolderLinkWhenFlagIsTrue() {
            let sut = makeSUT(isFolderLink: true)
            #expect(sut.nodeOriginType == .folderLink)
        }
        
        @Test("returns .fileLink when fileLink exists")
        func returnsFileLinkWhenFileLinkExists() {
            let sut = makeSUT(fileLink: link)
            #expect(sut.nodeOriginType == .fileLink)
        }
        
        @Test("returns .chat when chat and message ids exist")
        func returnsChatWhenChatAndMessageIdsExist() {
            let sut = makeSUT(messageId: messageId, chatId: chatId)
            #expect(sut.nodeOriginType == .chat)
        }
    }
    
    @Suite("relatedFiles")
    struct RelatedFilesSuite {
        @Test("keeps only audio files when all are audio")
        func keepsAllAudioFiles() {
            let sut = makeSUT(relatedFiles: audioFiles)
            #expect(sut.relatedFiles == audioFiles)
        }
        
        @Test("filters out all when files are non-audio")
        func filtersOutAllNonAudioFiles() {
            let sut = makeSUT(relatedFiles: nonAudio)
            #expect(sut.relatedFiles?.isEmpty == true)
        }
        
        @Test("keeps only audio files when mixed with non-audio")
        func keepsOnlyAudioFromMixedFiles() {
            let sut = makeSUT(relatedFiles: mixedFiles)
            #expect(sut.relatedFiles == [mixedFiles[0]])
        }
    }
}
