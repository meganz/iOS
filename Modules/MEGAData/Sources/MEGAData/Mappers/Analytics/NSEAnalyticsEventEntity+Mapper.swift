import MEGADomain

extension NSEAnalyticsEventEntity: AnalyticsEventProtocol {
    var code: Int {
        get {
            var value: Int
            switch self {
            case .delayBetweenChatdAndApi: value = 99300
            case .delayBetweenApiAndPushserver: value = 99301
            case .delayBetweenPushserverAndNSE: value = 99302
            case .willExpireAndMessageNotFound: value = 99303
            }
            return value
        }
    }
    
    var description: String {
        get {
            var value: String
            switch self {
            case .delayBetweenChatdAndApi: value = "Delay between chatd and api"
            case .delayBetweenApiAndPushserver: value = "Delay between api and pushserver"
            case .delayBetweenPushserverAndNSE:value = "Delay between pushserver and Apple/device/NSE"
            case .willExpireAndMessageNotFound: value = "NSE will expire and message not found"
            }
            return value
        }
    }
}
