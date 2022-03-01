
protocol AnalyticsRepositoryProtocol {
    func setAnalyticsEnabled(_ bool: Bool)
    func logEvent(_ name: AnalayticsEventEntity.Name, parameters: [AnalayticsEventEntity.Name : Any]?)
}

