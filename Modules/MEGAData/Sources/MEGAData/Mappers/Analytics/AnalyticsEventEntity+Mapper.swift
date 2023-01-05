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
        case .extensions(let extensionsAnalyticsEventEntity):
            return extensionsAnalyticsEventEntity.code
        case .download(let downloadAnalyticsEventEntity):
            return downloadAnalyticsEventEntity.code
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
            case .extensions(let extensionsAnalyticsEventEntity):
                return extensionsAnalyticsEventEntity.description
            case .download(let downloadAnalyticsEventEntity):
                return downloadAnalyticsEventEntity.description
            }
    }
}
