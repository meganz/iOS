import Foundation
@testable import MEGA
import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGASdk
import Testing
import UIKit

@MainActor
struct DocumentPreviewContextTests {
    @Test
    func fileLink_preservesOriginalURLWithoutBecomingFolderLink() {
        let link = "https://example.invalid/file/test#fixture"
        let sut = DocumentPreviewContext(
            isLink: true, fileLink: link, isFromSharedItem: false
        )

        #expect(sut.isLink)
        #expect(sut.fileLink == link)
        #expect(!sut.isFolderLink)
        #expect(sut.chatId == nil)
        #expect(sut.messageId == nil)
    }

    @Test
    func folderLink_hasLinkContextWithoutFileURL() {
        let sut = DocumentPreviewContext(
            isLink: true, fileLink: nil, isFromSharedItem: false
        )

        #expect(sut.isFolderLink)
        #expect(sut.fileLink == nil)
    }

    @Test(arguments: [false, true])
    func accountNode_preservesSharedItemWithoutBecomingLink(isFromSharedItem: Bool) {
        let sut = DocumentPreviewContext(
            isLink: false, fileLink: nil, isFromSharedItem: isFromSharedItem
        )

        #expect(!sut.isLink)
        #expect(!sut.isFolderLink)
        #expect(sut.isFromSharedItem == isFromSharedItem)
    }

    @Test
    func chatAttachment_preservesPairWithoutLinkOrSharedItemFlags() {
        let sut = DocumentPreviewContext(chatId: 11, messageId: 22)

        #expect(sut.chatId == 11)
        #expect(sut.messageId == 22)
        #expect(!sut.isLink)
        #expect(!sut.isFolderLink)
        #expect(!sut.isFromSharedItem)
        #expect(sut.fileLink == nil)
    }

    @Test
    func genericDelegate_receivesFolderContext() {
        let context = DocumentPreviewContext(
            isLink: true, fileLink: nil, isFromSharedItem: false
        )
        let presenter = UIViewController()
        let sut = DocumentPreviewNodeActionDelegate.makeGenericDelegate(
            context: context, presenter: presenter
        )

        #expect(sut.isNodeFromFolderLink)
        #expect(sut.chatId == nil)
        #expect(sut.messageId == nil)
    }

    @Test
    func genericDelegate_fileLinkDoesNotUseFolderSDK() {
        let context = DocumentPreviewContext(
            isLink: true,
            fileLink: "https://example.invalid/file/test#fixture",
            isFromSharedItem: false
        )
        let presenter = UIViewController()
        let sut = DocumentPreviewNodeActionDelegate.makeGenericDelegate(
            context: context, presenter: presenter
        )

        #expect(!sut.isNodeFromFolderLink)
        #expect(sut.chatId == nil)
        #expect(sut.messageId == nil)
    }

    @Test
    func genericDelegate_receivesChatPairForDownload() {
        let presenter = UIViewController()
        let sut = DocumentPreviewNodeActionDelegate.makeGenericDelegate(
            context: DocumentPreviewContext(chatId: 11, messageId: 22),
            presenter: presenter
        )

        #expect(sut.chatId == 11)
        #expect(sut.messageId == 22)
        #expect(!sut.isNodeFromFolderLink)
    }
}
