@testable import MEGA
import MEGADomain
import XCTest

final class CancellableTransferResolvedUploadOptionsTests: XCTestCase {

    func testResolvedUploadOptions_whenNameNotSet_keepsOriginalFileName() {
        let sut = CancellableTransfer(
            parentHandle: 1,
            localFileURL: URL(fileURLWithPath: "/tmp/file.txt"),
            type: .upload,
            uploadOptions: UploadOptionsEntity(fileName: "original.txt", appData: "appData")
        )

        let options = sut.resolvedUploadOptions

        XCTAssertEqual(options.fileName, "original.txt")
        XCTAssertEqual(options.appData, "appData")
    }

    func testResolvedUploadOptions_whenNameSetByRename_overridesFileNamePreservingOtherOptions() {
        let sut = CancellableTransfer(
            parentHandle: 1,
            localFileURL: URL(fileURLWithPath: "/tmp/file.txt"),
            type: .upload,
            uploadOptions: UploadOptionsEntity(fileName: "original.txt", appData: "appData")
        )

        sut.setName("file (1).txt")
        let options = sut.resolvedUploadOptions

        XCTAssertEqual(options.fileName, "file (1).txt")
        XCTAssertEqual(options.appData, "appData")
    }
}
