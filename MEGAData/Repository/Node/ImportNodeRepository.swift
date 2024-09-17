import Foundation
import MEGADomain
import MEGASDKRepo
import MEGASwift

struct ImportNodeRepository: ImportNodeRepositoryProtocol {
    static var newRepo: ImportNodeRepository {
        ImportNodeRepository(sdk: MEGASdk.shared, chatSdk: MEGAChatSdk.shared, myChatFilesFolder: MyChatFilesFolderNodeAccess.shared)
    }
    
    private let sdk: MEGASdk
    private let chatSdk: MEGAChatSdk
    private let myChatFilesFolder: MyChatFilesFolderNodeAccess
    
    init(sdk: MEGASdk, chatSdk: MEGAChatSdk, myChatFilesFolder: MyChatFilesFolderNodeAccess) {
        self.sdk = sdk
        self.chatSdk = chatSdk
        self.myChatFilesFolder = myChatFilesFolder
    }
    
    func importChatNode(
        _ node: NodeEntity,
        messageId: HandleEntity,
        chatId: HandleEntity
    ) async throws -> NodeEntity {
        if node.ownerHandle == chatSdk.myUserHandle {
            return node
        } else {
            if let remoteNode = sdk.node(forFingerprint: node.fingerprint ?? ""), remoteNode.owner == chatSdk.myUserHandle {
                return remoteNode.toNodeEntity()
            } else {
                return try await withAsyncThrowingValue { completion in
                    myChatFilesFolder.loadNode { myChatFilesNode, error in
                        if let chatFilesNode = myChatFilesNode {
                            guard let megaNode = chatSdk.chatNode(handle: node.handle, messageId: messageId, chatId: chatId) else {
                                MEGALogWarning("Coud not find node for handle \(node.handle)")
                                completion(.failure(ExportFileErrorEntity.couldNotFindNodeByHandle))
                                return
                            }
                            sdk.copy(megaNode, newParent: chatFilesNode, delegate: RequestDelegate { (result) in
                                switch result {
                                case .success(let request):
                                    guard let resultNode = sdk.node(forHandle: request.nodeHandle) else {
                                        MEGALogWarning("Coud not find node for handle \(request.nodeHandle)")
                                        completion(.failure(ExportFileErrorEntity.generic))
                                        return
                                    }
                                    completion(.success(resultNode.toNodeEntity()))
                                case .failure:
                                    completion(.failure(ExportFileErrorEntity.generic))
                                }
                            })
                        } else {
                            MEGALogWarning("Coud not load MyChatFiles target folder due to error \(String(describing: error))")
                            completion(.failure(ExportFileErrorEntity.generic))
                        }
                    }
                }
                
            }
        }
    }
}
