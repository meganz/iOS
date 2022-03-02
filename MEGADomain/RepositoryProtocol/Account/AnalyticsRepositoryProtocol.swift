
protocol AnalyticsRepositoryProtocol {
    func setAnalyticsEnabled(_ bool: Bool)
    func logEvent(_ name: AnalyticsEventEntity.Name, parameters: [AnalyticsEventEntity.Name : Any]?)
}

