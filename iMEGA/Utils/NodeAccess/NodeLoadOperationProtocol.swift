
protocol NodeLoadOperationProtocol where Self: MEGAOperation {
    func loadNodeFromRemote()
    func validateLoadedHandle(_ handle: NodeHandle)
    func createNode()
    func setTargetFolder(forHandle handle: NodeHandle)
}
