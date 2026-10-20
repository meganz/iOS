import Foundation
import MEGADomain
import MEGADomainMock
import MEGAL10n
import Testing
@testable import Home

@Suite("RecentParentFolderNameTests")
struct RecentParentFolderNameTests {
    private static let undecryptedFolder = NodeEntity(name: "NO_KEY", handle: 1, isFolder: true, isNodeKeyDecrypted: false)
    private static let decryptedFolder = NodeEntity(name: "Holidays", handle: 2, isFolder: true)

    @Test(
        "Recents row shows the undecrypted placeholder instead of the SDK name of an undecrypted parent folder",
        arguments: [
            (undecryptedFolder, Strings.Localizable.SharedItems.Tab.Incoming.undecryptedFolderName),
            (decryptedFolder, "Holidays")
        ]
    )
    @MainActor func rowParentFolderName(parent: NodeEntity, expected: String) {
        let sut = RecentActionBucketModelMapper(userNameProvider: StubUserNameProvider())

        #expect(sut.map(from: makeBucket(parent: parent)).parentFolderName == expected)
    }

    @Test("Recents row shows no parent folder name when the parent is missing")
    @MainActor func rowWithoutParent() {
        let sut = RecentActionBucketModelMapper(userNameProvider: StubUserNameProvider())

        #expect(sut.map(from: makeBucket(parent: nil)).parentFolderName.isEmpty)
    }

    @Test(
        "Bucket details subtitle shows the undecrypted placeholder instead of the SDK name of an undecrypted parent folder",
        arguments: [
            (undecryptedFolder, Strings.Localizable.SharedItems.Tab.Incoming.undecryptedFolderName),
            (decryptedFolder, "Holidays")
        ]
    )
    func bucketDetailsSubtitle(parent: NodeEntity, expectedFolderName: String) {
        let title = RecentActionBucketItemsTitleUseCase().title(for: makeBucket(parent: parent), editingState: .inactive)

        #expect(
            title.displayableSubtitle
                == Strings.Localizable.Recents.BucketDetails.subtitle(2).replacingOccurrences(of: "[A]", with: expectedFolderName)
        )
    }

    @Test(
        "Bucket carousel header shows the undecrypted placeholder instead of the SDK name of an undecrypted parent folder",
        arguments: [
            (undecryptedFolder, Strings.Localizable.SharedItems.Tab.Incoming.undecryptedFolderName),
            (decryptedFolder, "Holidays")
        ]
    )
    @MainActor func carouselHeaderTitle(parent: NodeEntity, expected: String) {
        let sut = RecentBucketCarouselSheetViewModel(bucket: makeBucket(parent: parent), actionHandler: { _ in })

        #expect(sut.header.title == expected)
    }

    private func makeBucket(parent: NodeEntity?) -> Home.RecentActionBucketEntity {
        Home.RecentActionBucketEntity(
            id: "bucket",
            date: Date(timeIntervalSince1970: 0),
            parent: parent,
            type: .mixedFiles([
                NodeEntity(name: "report.pdf", handle: 10, isFile: true),
                NodeEntity(name: "notes.txt", handle: 11, isFile: true)
            ]),
            changesType: .newFiles,
            changesOwnerType: .currentUser,
            shareOriginType: .inShare,
            nodeAccessType: .read
        )
    }
}

private struct StubUserNameProvider: UserNameProviderProtocol {
    func displayName(for user: UserEntity) -> String? { nil }
}
