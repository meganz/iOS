import Foundation
import MEGADomain
import Testing

/// Covers the two ways of naming where a download lands.
///
/// A caller has either a folder to drop the node into or the exact file to write, and both have to
/// end up as the same pair -- folder plus name -- so that whoever maps it for the SDK has one shape
/// to map and no branch to get wrong.
@Suite("DownloadDestinationEntity Tests")
struct DownloadDestinationEntityTests {
    private static let folder = URL(filePath: "/tmp/Documents", directoryHint: .isDirectory)

    @Test("a folder on its own leaves the node under the name it has on MEGA")
    func folderWithoutAName() {
        let destination = DownloadDestinationEntity.folder(Self.folder)

        #expect(destination.folder.path == Self.folder.path)
        #expect(destination.name == nil)
    }

    @Test("a folder and a name stores the node in that folder, renamed")
    func folderWithAName() {
        let destination = DownloadDestinationEntity.folder(Self.folder, name: "photo.jpg")

        #expect(destination.folder.path == Self.folder.path)
        #expect(destination.name == "photo.jpg")
    }

    @Test("a file is split into the folder holding it and the name it is held under")
    func fileIsSplit() {
        let destination = DownloadDestinationEntity.file(Self.folder.appendingPathComponent("photo.jpg"))

        #expect(destination.folder.path == Self.folder.path)
        #expect(destination.name == "photo.jpg")
    }

    @Test("the two ways of naming the same place describe the same destination")
    func theTwoSpellingsAgree() {
        #expect(
            DownloadDestinationEntity.file(Self.folder.appendingPathComponent("photo.jpg"))
                == .folder(Self.folder, name: "photo.jpg")
        )
    }
}
