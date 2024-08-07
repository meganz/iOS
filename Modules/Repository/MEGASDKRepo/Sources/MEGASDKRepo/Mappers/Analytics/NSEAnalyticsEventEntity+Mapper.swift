import MEGADomain

extension NSEAnalyticsEventEntity: AnalyticsEventProtocol {
    var code: Int {
        switch self {
        case .delayBetweenChatdAndApi: 99300
        case .delayBetweenApiAndPushserver: 99301
        case .delayBetweenPushserverAndNSE: 99302
        case .willExpireAndMessageNotFound: 99303
        }
    }
    
    var description: String {
        switch self {
        case .delayBetweenChatdAndApi:
            "Delay between chatd and api"
        case .delayBetweenApiAndPushserver:
            "Delay between api and pushserver"
        case .delayBetweenPushserverAndNSE:
            "Delay between pushserver and Apple/device/NSE"
        case .willExpireAndMessageNotFound:
            "NSE will expire and message not found"
        }
    }
}
