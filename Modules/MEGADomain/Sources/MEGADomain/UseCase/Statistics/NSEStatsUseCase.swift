
public protocol NSEStatsUseCaseProtocol {
    func sendDelayBetweenChatdAndApiStats()
    func sendDelayBetweenApiAndPushserverStats()
    func sendDelayBetweenPushserverAndNSEStats()
    func sendNSEWillExpireAndMessageNotFoundStats()
}

public struct NSEStatsUseCase<T: StatsRepositoryProtocol>: NSEStatsUseCaseProtocol {
    private let repo: T
    
    public init(repo: T) {
        self.repo = repo
    }
    
    public func sendDelayBetweenChatdAndApiStats() {
        repo.sendStatsEvent(.delayBetweenChatdAndApi)
    }
    
    public func sendDelayBetweenApiAndPushserverStats() {
        repo.sendStatsEvent(.delayBetweenApiAndPushserver)
    }
    
    public func sendDelayBetweenPushserverAndNSEStats() {
        repo.sendStatsEvent(.delayBetweenPushserverAndNSE)
    }
    
    public func sendNSEWillExpireAndMessageNotFoundStats() {
        repo.sendStatsEvent(.nseWillExpireAndMessageNotFound)
    }
}
