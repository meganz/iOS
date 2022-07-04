
protocol ImportNodeRepositoryProtocol: RepositoryProtocol {
    func importChatNode(_ node: MEGANode, completion: @escaping (Result<MEGANode, ExportFileErrorEntity>) -> Void)
}
