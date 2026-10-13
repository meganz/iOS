import MEGAAssets
import MEGAL10n
import SwiftUI

enum DoMoreWithMegaTile: CaseIterable, Identifiable {
    case cameraUploads
    case scanDoc
    case createAlbum
    case addContacts
    case scheduleMeeting

    var id: Self { self }

    var title: String {
        switch self {
        case .cameraUploads: Strings.Localizable.General.cameraUploads
        case .scanDoc: Strings.Localizable.Home.DoMoreWithMega.scanDoc
        case .createAlbum: Strings.Localizable.CameraUploads.Albums.CreateAlbum.title
        case .addContacts: Strings.Localizable.addContacts
        case .scheduleMeeting: Strings.Localizable.Meetings.ScheduleMeeting.title
        }
    }

    var icon: Image {
        switch self {
        case .cameraUploads: MEGAAssets.Image.camera
        case .scanDoc: MEGAAssets.Image.fileScan
        case .createAlbum: MEGAAssets.Image.rectangleImageStack
        case .addContacts: MEGAAssets.Image.contactsInMenu
        case .scheduleMeeting: MEGAAssets.Image.scheduleMeeting
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .cameraUploads: "home.doMoreWithMega.cameraUploads"
        case .scanDoc: "home.doMoreWithMega.scanDoc"
        case .createAlbum: "home.doMoreWithMega.createAlbum"
        case .addContacts: "home.doMoreWithMega.addContacts"
        case .scheduleMeeting: "home.doMoreWithMega.scheduleMeeting"
        }
    }
}
