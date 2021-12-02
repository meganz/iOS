import Foundation

enum HomeLocalisation: String {

    // MARK: - File Uploading Options

    case photos
    case textFile
    case capture
    case imports
    case documentScan

    // MARK: - Upload From Album TableView

    case uploadWithNumber
    case upload

    // MARK: - Search Bar

    case searchYourFiles

    var rawValue: String {
        switch self {
        case .photos:
            return Strings.Localizable.choosePhotoVideo
        case .textFile:
            return Strings.Localizable.newTextFile
        case .capture:
            return Strings.Localizable.capturePhotoVideo
        case .imports:
            return Strings.Localizable.uploadFrom
        case .documentScan:
            return Strings.Localizable.scanDocument
        case .uploadWithNumber:
            return NSLocalizedString(
                "Upload (%d)", comment:
                "Used in Photos app browser view to send the photos from the view to the cloud."
            )
        case .upload:
            return Strings.Localizable.upload
        case .searchYourFiles:
            return Strings.Localizable.searchYourFiles
        }
    }
}
