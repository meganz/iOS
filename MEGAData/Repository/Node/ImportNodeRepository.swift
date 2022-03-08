import Foundation

extension ImportNodeRepository {
    static let `default` = ImportNodeRepository(sdk: MEGASdkManager.sharedMEGASdk(), chatSdk: MEGASdkManager.sharedMEGAChatSdk(), myChatFilesFolder: MyChatFilesFolderNodeAccess.shared)
}

struct ImportNodeRepository: ImportNodeRepositoryProtocol {
    private let sdk: MEGASdk
    private let chatSdk: MEGAChatSdk
    private let myChatFilesFolder: MyChatFilesFolderNodeAccess

    init(sdk: MEGASdk, chatSdk: MEGAChatSdk, myChatFilesFolder: MyChatFilesFolderNodeAccess) {
        self.sdk = sdk
        self.chatSdk = chatSdk
        self.myChatFilesFolder = myChatFilesFolder
    }
    
    func importChatNode(_ node: MEGANode, completion: @escaping (Result<MEGANode, ExportFileErrorEntity>) -> Void) {
        if node.owner == chatSdk.myUserHandle {
            completion(.success(node))
        } else {
            if let remoteNode = sdk.node(forFingerprint: node.fingerprint ?? ""), remoteNode.owner == chatSdk.myUserHandle {
                completion(.success(remoteNode))
            } else {
                myChatFilesFolder.loadNode { myChatFilesNode, error in
                    if let chatFilesNode = myChatFilesNode {
                        sdk.copy(node, newParent: chatFilesNode, delegate: MEGAGenericRequestDelegate(completion: { (request, error) in
                            guard let resultNode = sdk.node(forHandle: request.nodeHandle) else {
                                MEGALogWarning("Coud not find node for handle \(request.nodeHandle)")
                                completion(.failure(.generic))
                                return
                            }
                            completion(.success(resultNode))
                        }))
                    } else {
                        MEGALogWarning("Coud not load MyChatFiles target folder doe tu error \(String(describing: error))")
                        completion(.failure(.generic))
                    }
                }
            }
        }
    }
}

