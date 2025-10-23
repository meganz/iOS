import MEGAL10n

enum CameraUploadProgressSections: Int, Sendable, Hashable {
    case inProgress
    
    var title: String {
        switch self {
        case .inProgress: Strings.Localizable.CameraUploads.Progress.Section.InProgress.title
        }
    }
}

enum CameraUploadProgressSectionRow: Hashable, Equatable {
    case inProgress(CameraUploadInProgressRowViewModel)
}
