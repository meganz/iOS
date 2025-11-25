import MEGAL10n

enum CameraUploadProgressSections: Int, Sendable, Hashable {
    case loadingInProgress
    case loadingInQueue
    case inProgress
    case inQueue
    
    var title: String {
        switch self {
        case .loadingInProgress, .inProgress: Strings.Localizable.CameraUploads.Progress.Section.InProgress.title
        case .loadingInQueue, .inQueue: Strings.Localizable.CameraUploads.Progress.Section.InQueue.title
        }
    }
}

enum CameraUploadProgressSectionRow: Hashable, Equatable {
    case loading(id: UUID)
    case inProgress(CameraUploadInProgressRowViewModel)
    case inQueue(CameraUploadInQueueRowViewModel)
    case emptyInProgress
    case emptyInQueue
}
