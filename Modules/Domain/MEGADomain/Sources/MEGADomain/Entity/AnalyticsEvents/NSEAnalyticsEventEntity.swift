public enum NSEAnalyticsEventEntity: Sendable {
    case delayBetweenChatdAndApi
    case delayBetweenApiAndPushserver
    case delayBetweenPushserverAndNSE
    case willExpireAndMessageNotFound
}
