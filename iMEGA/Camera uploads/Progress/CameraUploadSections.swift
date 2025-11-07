import MEGAL10n

enum CameraUploadProgressSections: Int, Sendable, Hashable {
    case inProgress
    case inQueue
    
    var title: String {
        switch self {
        case .inProgress: Strings.Localizable.CameraUploads.Progress.Section.InProgress.title
        case .inQueue: Strings.Localizable.CameraUploads.Progress.Section.InQueue.title
        }
    }
}

enum CameraUploadProgressSectionRow: Hashable, Equatable {
    case inProgress(CameraUploadInProgressRowViewModel)
    case inQueue(CameraUploadInQueueRowViewModel)
}
