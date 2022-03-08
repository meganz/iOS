
protocol ImportNodeRepositoryProtocol {
    func importChatNode(_ node: MEGANode, completion: @escaping (Result<MEGANode, ExportFileErrorEntity>) -> Void)
}
