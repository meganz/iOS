import MEGADomain

extension NSEAnalyticsEventEntity: AnalyticsEventProtocol {
    var code: Int {
        switch self {
        case .delayBetweenChatdAndApi: return 99300
        case .delayBetweenApiAndPushserver: return 99301
        case .delayBetweenPushserverAndNSE: return 99302
        case .willExpireAndMessageNotFound: return 99303
        }
    }
    
    var description: String {
        switch self {
        case .delayBetweenChatdAndApi:
            return "Delay between chatd and api"
        case .delayBetweenApiAndPushserver:
            return "Delay between api and pushserver"
        case .delayBetweenPushserverAndNSE:
            return "Delay between pushserver and Apple/device/NSE"
        case .willExpireAndMessageNotFound:
            return "NSE will expire and message not found"
        }
    }
}
