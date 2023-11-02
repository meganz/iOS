public enum AnalyticsEventEntity: Equatable {
    case mediaDiscovery(MediaDiscoveryAnalyticsEventEntity)
    case meetings(MeetingsAnalyticsEventEntity)
    case nse(NSEAnalyticsEventEntity)
    case download(DownloadAnalyticsEventEntity)
    case accountPlans(AccountPlanAnalyticsEventEntity)
    case getLink(GetLinkAnalyticsEventEntity)
}
