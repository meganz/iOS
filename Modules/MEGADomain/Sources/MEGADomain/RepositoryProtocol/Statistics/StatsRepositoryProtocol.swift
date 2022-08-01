import Foundation

public protocol StatsRepositoryProtocol: RepositoryProtocol {
    func sendStatsEvent(_ event: StatsEventEntity)
}
