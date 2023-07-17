import MEGADomain

extension DownloadAnalyticsEventEntity: AnalyticsEventProtocol {
    var code: Int {
        switch self {
        case .makeAvailableOfflinePhotosVideos: return 99317
        case .saveToPhotos: return 99318
        case .makeAvailableOffline: return 99319
        case .exportFile: return 99320
        }
    }
    
    var description: String {
        switch self {
        case .makeAvailableOfflinePhotosVideos: return "Number of users use the 'make available offline' action to download photos and videos"
        case .saveToPhotos: return "Number of users use the 'Save to Photos' action"
        case .makeAvailableOffline: return "Number of users use the 'make available offline' action to download the different file types (except photos and videos)"
        case .exportFile: return "Number of users use the 'Export file' action to share a file outside the app"
        }
    }
}
