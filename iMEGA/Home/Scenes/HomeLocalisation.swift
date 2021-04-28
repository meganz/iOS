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
            return NSLocalizedString(
                "choosePhotoVideo", comment:
                "Menu option from the `Add` section that allows the user to choose a photo or video to upload it to MEGA"
            )
        case .textFile:
            return NSLocalizedString(
                "new_text_file", comment:
                "Menu option from the `Add` section that allows the user to create a new text file and upload it directly to MEGA"
            )
        case .capture:
            return NSLocalizedString(
                "capturePhotoVideo", comment:
                "Menu option from the `Add` section that allows the user to capture a video or a photo and upload it directly to MEGA."
            )
        case .imports:
            return NSLocalizedString(
                "uploadFrom", comment:
                "Option given on the `Add` section to allow the user upload something from another cloud storage provider."
            )
        case .documentScan:
            return NSLocalizedString(
                "Scan Document", comment:
                "Menu option from the `Add` section that allows the user to scan document and upload it directly to MEGA"
            )

        case .uploadWithNumber:
            return NSLocalizedString(
                "Upload (%d)", comment:
                "Used in Photos app browser view to send the photos from the view to the cloud."
            )

        case .upload:
            return NSLocalizedString(
                "upload", comment:
                "Used in Photos app browser view as a disabled action when there is no assets selected"
            )

        case .searchYourFiles:
            return NSLocalizedString(
                "Search Your Files", comment: 
                "Search placeholder text in search bar on home screen"
            )
        }
    }
}
