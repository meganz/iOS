
public enum AnalyticsEventEntity: Equatable {
    case mediaDiscovery(MediaDiscoveryAnalyticsEventEntity)
    case meetings(MeetingsAnalyticsEventEntity)
    case nse(NSEAnalyticsEventEntity)
    case extensions(ExtensionsAnalyticsEventEntity)
    case download(DownloadAnalyticsEventEntity)
}
