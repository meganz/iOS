import MEGADomain

extension AnalyticsEventEntity: AnalyticsEventProtocol {
    public var code: Int {
        switch self {
        case .mediaDiscovery(let mediaDiscoveryAnalyticsEventEntity):
            return mediaDiscoveryAnalyticsEventEntity.code
        case .meetings(let meetingsAnalyticsEventEntity):
            return meetingsAnalyticsEventEntity.code
        case .nse(let nseAnalyticsEventEntity):
            return nseAnalyticsEventEntity.code
        case .download(let downloadAnalyticsEventEntity):
            return downloadAnalyticsEventEntity.code
        case .accountPlans(let accountPlanAnalyticsEventEntity):
            return accountPlanAnalyticsEventEntity.code
        case .getLink(let getLinkAnalyticsEventEntity):
            return getLinkAnalyticsEventEntity.code
        }
    }
    
    public var description: String {
            switch self {
            case .mediaDiscovery(let mediaDiscoveryAnalyticsEventEntity):
                return mediaDiscoveryAnalyticsEventEntity.description
            case .meetings(let meetingsAnalyticsEventEntity):
                return meetingsAnalyticsEventEntity.description
            case .nse(let nseAnalyticsEventEntity):
                return nseAnalyticsEventEntity.description
            case .download(let downloadAnalyticsEventEntity):
                return downloadAnalyticsEventEntity.description
            case .accountPlans(let accountPlanAnalyticsEventEntity):
                return accountPlanAnalyticsEventEntity.description
            case .getLink(let getLinkAnalyticsEventEntity):
                return getLinkAnalyticsEventEntity.description
            }
    }
}
