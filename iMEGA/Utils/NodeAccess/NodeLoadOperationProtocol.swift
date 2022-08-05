import MEGADomain

protocol NodeLoadOperationProtocol where Self: MEGAOperation {
    func loadNodeFromRemote()
    func validateLoadedHandle(_ handle: HandleEntity)
    func createNode()
    func setTargetFolder(forHandle handle: HandleEntity)
}
