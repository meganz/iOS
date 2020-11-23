import Foundation

enum HomeLocalisation: String {

    // MARK: - File Uploading Options

    case photos
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
            return AMLocalizedString(
                "choosePhotoVideo",
                "Menu option from the `Add` section that allows the user to choose a photo or video to upload it to MEGA"
            )
        case .capture:
            return AMLocalizedString(
                "capturePhotoVideo",
                "Menu option from the `Add` section that allows the user to capture a video or a photo and upload it directly to MEGA."
            )
        case .imports:
            return AMLocalizedString(
                "uploadFrom",
                "Option given on the `Add` section to allow the user upload something from another cloud storage provider."
            )
        case .documentScan:
            return AMLocalizedString(
                "Scan Document",
                "Menu option from the `Add` section that allows the user to scan document and upload it directly to MEGA"
            )


        case .uploadWithNumber:
            return AMLocalizedString(
                "Upload (%d)",
                "Used in Photos app browser view to send the photos from the view to the cloud."
            )

        case .upload:
            return AMLocalizedString(
                "upload",
                "Used in Photos app browser view as a disabled action when there is no assets selected"
            )

        case .searchYourFiles:
            return AMLocalizedString(
                "Search Your Files",
                "Search placeholder text in search bar on home screen"
            )
        }
    }
}
