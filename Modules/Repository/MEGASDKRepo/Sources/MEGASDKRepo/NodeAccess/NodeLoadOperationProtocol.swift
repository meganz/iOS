import MEGADomain
import MEGAFoundation

protocol NodeLoadOperationProtocol where Self: AsyncOperation {
    func loadNodeFromRemote()
    func validateLoadedHandle(_ handle: HandleEntity)
    func createNode()
    func setTargetFolder(forHandle handle: HandleEntity)
}
