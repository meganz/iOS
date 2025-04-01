@testable import MEGA
import MEGAL10n
import XCTest

final class HomeLocalisationTests: XCTestCase {
    
    func testLocalisation_rawValueIsPhoto() {
        let expectedChoosePhotoValue = Strings.Localizable.choosePhotoVideo
        let localizedPhotoValue = HomeLocalisation.photos.rawValue
        XCTAssertEqual(expectedChoosePhotoValue, localizedPhotoValue, "Localized string for 'photo' should be \(expectedChoosePhotoValue)")
    }
    
    func testLocalisation_rawValueIsTextFile() {
        let expectedTextFileValue = Strings.Localizable.newTextFile
        let localizedTextFileValue = HomeLocalisation.textFile.rawValue
        XCTAssertEqual(expectedTextFileValue, localizedTextFileValue, "Localized string for 'textFile' should be \(expectedTextFileValue)")
    }
    
    func testLocalisation_rawValueIsCapture() {
        let expectedCaptureValue = Strings.Localizable.capturePhotoVideo
        let localizedCaptureValue = HomeLocalisation.capture.rawValue
        XCTAssertEqual(expectedCaptureValue, localizedCaptureValue, "Localized string for 'capture' should be \(expectedCaptureValue)")
    }
    
    func testLocalisation_rawValueIsImports() {
        let expectedImportsValue = Strings.Localizable.CloudDrive.Upload.importFromFiles
        let localizedImportsValue = HomeLocalisation.imports.rawValue
        XCTAssertEqual(expectedImportsValue, localizedImportsValue, "Localized string for 'imports' should be \(expectedImportsValue)")
    }
    
    func testLocalisation_rawValueIsDocumentScan() {
        let expectedDocumentScanValue = Strings.Localizable.scanDocument
        let localizedDocumentScanValue = HomeLocalisation.documentScan.rawValue
        XCTAssertEqual(expectedDocumentScanValue, localizedDocumentScanValue, "Localized string for 'documentScan' should be \(expectedDocumentScanValue)")
    }
    
    func testLocalisation_rawValueIsUpload() {
        let expectedUploadValue = Strings.Localizable.upload
        let localizedUploadValue = HomeLocalisation.upload.rawValue
        XCTAssertEqual(expectedUploadValue, localizedUploadValue, "Localized string for 'upload' should be \(expectedUploadValue)")
    }
    
    func testLocalisation_rawValueIsSearchYourFiles() {
        let expectedSearchYourFilesValue = Strings.Localizable.searchYourFiles
        let localizedSearchYourFilesValue = HomeLocalisation.searchYourFiles.rawValue
        XCTAssertEqual(expectedSearchYourFilesValue, localizedSearchYourFilesValue, "Localized string for 'searchYourFiles' should be \(expectedSearchYourFilesValue)")
    }
}
