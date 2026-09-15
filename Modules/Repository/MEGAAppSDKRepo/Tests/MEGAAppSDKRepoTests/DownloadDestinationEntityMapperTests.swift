import Foundation
import MEGAAppSDKRepo
import MEGADomain
import Testing

/// Covers the destination as the SDK reads it.
///
/// The SDK reads a local path two ways: one ending in a separator is a folder to store the node
/// inside, anything else is the exact path to store it as. `URL.path` drops the separator even for a
/// directory URL, so a folder handed over unchanged reads as a file path and writes the node one
/// level above the folder that was asked for.
@Suite("DownloadDestinationEntity mapper Tests")
struct DownloadDestinationEntityMapperTests {

    @Test("a folder reaches the SDK as a folder, not as the file path it would otherwise read as")
    func folderPathEndsInASeparator() {
        let destination = DownloadDestinationEntity.folder(URL(fileURLWithPath: "/tmp/Documents"))

        #expect(destination.toSDKLocalPath == "/tmp/Documents/")
    }

    @Test("a folder whose path already ends in a separator is not given a second one")
    func folderPathIsNotDoubled() {
        let destination = DownloadDestinationEntity.folder(URL(fileURLWithPath: "/tmp/Documents", isDirectory: true))

        #expect(destination.toSDKLocalPath == "/tmp/Documents/")
    }

    @Test("a file is handed over as its folder, with its own name as the one to store it under")
    func fileIsHandedOverAsFolderAndName() {
        let destination = DownloadDestinationEntity.file(URL(fileURLWithPath: "/tmp/Documents/photo.jpg"))

        #expect(destination.toSDKLocalPath == "/tmp/Documents/")
        #expect(destination.toSDKCustomName == "photo.jpg")
    }

    @Test("a folder on its own names nothing, leaving the node the name it has on MEGA")
    func folderHasNoCustomName() {
        #expect(DownloadDestinationEntity.folder(URL(fileURLWithPath: "/tmp/Documents")).toSDKCustomName == nil)
    }

    @Test("a path holding characters a URL would escape reaches the SDK unescaped")
    func pathIsNotPercentEncoded() {
        let destination = DownloadDestinationEntity.folder(URL(fileURLWithPath: "/tmp/My Documents"))

        // The SDK takes a filesystem path; percent encoding it would name a folder that is not there.
        #expect(destination.toSDKLocalPath == "/tmp/My Documents/")
    }
}
