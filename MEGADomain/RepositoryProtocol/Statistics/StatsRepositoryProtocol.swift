import Foundation

protocol StatsRepositoryProtocol: RepositoryProtocol {
    func sendStatsEvent(_ event: StatsEventEntity)
}
