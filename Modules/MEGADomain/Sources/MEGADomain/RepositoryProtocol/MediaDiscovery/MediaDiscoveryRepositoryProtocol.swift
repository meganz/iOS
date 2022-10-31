public protocol MediaDiscoveryRepositoryProtocol: RepositoryProtocol {
    func loadNodes(forParent parent: NodeEntity) async throws -> [NodeEntity]
    func startMonitoringNodesUpdate()
    func stopMonitoringNodesUpdate()
}
