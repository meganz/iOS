import MEGADomain
import MEGAData

struct NodeActionRepository: NodeActionRepositoryProtocol {
    static var newRepo: NodeActionRepository {
        NodeActionRepository(sdk: MEGASdk.shared)
    }
    
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    private func removeLink(for node: NodeEntity) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            guard Task.isCancelled == false else {
                continuation.resume(throwing: CancellationError())
                return
            }
            
            guard let megaNode = node.toMEGANode(in: sdk) else { return }
            
            sdk.disableExport(megaNode, delegate: RequestDelegate { result in
                guard Task.isCancelled == false else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                
                switch result {
                case .failure(let error):
                    switch error.type {
                    case .apiEBusinessPastDue:
                        continuation.resume(throwing: RemoveLinkErrorEntity.businessExpired)
                    case .apiENoent:
                        continuation.resume(throwing: RemoveLinkErrorEntity.notFound)
                    default:
                        continuation.resume(throwing: RemoveLinkErrorEntity.generic)
                    }
                case .success:
                    continuation.resume(with: .success)
                }
            })
        }
    }
    
    func fetchnodes() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            guard Task.isCancelled == false else {
                continuation.resume(throwing: CancellationError())
                return
            }
            sdk.fetchNodes(with: RequestDelegate { result in
                guard Task.isCancelled == false else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                switch result {
                case .success:
                    continuation.resume()
                case .failure:
                    continuation.resume(throwing: GenericErrorEntity())
                }
            })
        }
    }
    
    func createFolder(name: String, parent: NodeEntity) async throws -> NodeEntity {
        try await withCheckedThrowingContinuation { continuation in
            guard let parentNode = sdk.node(forHandle: parent.handle) else {
                continuation.resume(throwing: CreateFolderErrorEntity.generic)
                return
            }
            guard Task.isCancelled == false else {
                continuation.resume(throwing: CancellationError())
                return
            }
            sdk.createFolder(withName: name, parent: parentNode, delegate: RequestDelegate { result in
                guard Task.isCancelled == false else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                
                switch result {
                case .success(let request):
                    guard let node = sdk.node(forHandle: request.nodeHandle) else {
                        continuation.resume(throwing: CreateFolderErrorEntity.generic)
                        return
                    }
                    continuation.resume(returning: node.toNodeEntity())
                case .failure(let error):
                    if error.type == .apiEBusinessPastDue {
                        continuation.resume(throwing: CreateFolderErrorEntity.businessExpired)
                    } else {
                        continuation.resume(throwing: CreateFolderErrorEntity.generic)
                    }
                }
            })
        }
    }
    
    func rename(node: NodeEntity, name: String) async throws -> NodeEntity {
        try await withCheckedThrowingContinuation { continuation in
            guard let megaNode = sdk.node(forHandle: node.handle) else {
                continuation.resume(throwing: RenameNodeErrorEntity.generic)
                return
            }
            guard Task.isCancelled == false else {
                continuation.resume(throwing: CancellationError())
                return
            }
            sdk.renameNode(megaNode, newName: name, delegate: RequestDelegate { result in
                guard Task.isCancelled == false else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                
                switch result {
                case .success(let request):
                    guard let node = sdk.node(forHandle: request.nodeHandle) else {
                        continuation.resume(throwing: RenameNodeErrorEntity.generic)
                        return
                    }
                    continuation.resume(returning: node.toNodeEntity())
                case .failure(let error):
                    if error.type == .apiEBusinessPastDue {
                        continuation.resume(throwing: RenameNodeErrorEntity.businessExpired)
                    } else {
                        continuation.resume(throwing: RenameNodeErrorEntity.generic)
                    }
                }
            })
        }
    }
    
    func trash(node: NodeEntity) async throws -> NodeEntity {
        try await withCheckedThrowingContinuation { continuation in
            guard let node = sdk.node(forHandle: node.handle),
                  let rubbishBinNode = sdk.rubbishNode else {
                continuation.resume(throwing: MoveNodeErrorEntity.generic)
                return
            }
            guard Task.isCancelled == false else {
                continuation.resume(throwing: CancellationError())
                return
            }
            sdk.move(node, newParent: rubbishBinNode, delegate: RequestDelegate { result in
                guard Task.isCancelled == false else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                
                switch result {
                case .success(let request):
                    guard let node = sdk.node(forHandle: request.nodeHandle) else {
                        continuation.resume(throwing: MoveNodeErrorEntity.generic)
                        return
                    }
                    continuation.resume(returning: node.toNodeEntity())
                case .failure(let error):
                    if error.type == .apiEBusinessPastDue {
                        continuation.resume(throwing: MoveNodeErrorEntity.businessExpired)
                    } else {
                        continuation.resume(throwing: MoveNodeErrorEntity.generic)
                    }
                }
            })
        }
    }
    
    func untrash(node: NodeEntity) async throws -> NodeEntity {
        try await withCheckedThrowingContinuation { continuation in
            guard let node = sdk.node(forHandle: node.handle),
                  sdk.isNode(inRubbish: node) == true,
                  let restoreNode = sdk.node(forHandle: node.restoreHandle),
                  sdk.isNode(inRubbish: restoreNode) == false else {
                continuation.resume(throwing: MoveNodeErrorEntity.generic)
                return
            }
            
            guard Task.isCancelled == false else {
                continuation.resume(throwing: CancellationError())
                return
            }
            sdk.move(node, newParent: restoreNode, delegate: RequestDelegate { result in
                guard Task.isCancelled == false else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                
                switch result {
                case .success(let request):
                    guard let node = sdk.node(forHandle: request.nodeHandle) else {
                        continuation.resume(throwing: MoveNodeErrorEntity.generic)
                        return
                    }
                    continuation.resume(returning: node.toNodeEntity())
                case .failure(let error):
                    if error.type == .apiEBusinessPastDue {
                        continuation.resume(throwing: MoveNodeErrorEntity.businessExpired)
                    } else {
                        continuation.resume(throwing: MoveNodeErrorEntity.generic)
                    }
                }
            })
        }
    }
    
    func delete(node: NodeEntity) async throws {
        guard let node = sdk.node(forHandle: node.handle),
              sdk.isNode(inRubbish: node) == true else {
            throw RemoveNodeErrorEntity.generic
        }
        return try await withCheckedThrowingContinuation { continuation in
            guard Task.isCancelled == false else {
                continuation.resume(throwing: CancellationError())
                return
            }
            sdk.remove(node, delegate: RequestDelegate { result in
                guard Task.isCancelled == false else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    if error.type == .apiEMasterOnly {
                        continuation.resume(throwing: RemoveNodeErrorEntity.masterOnly)
                    } else {
                        continuation.resume(throwing: RemoveNodeErrorEntity.generic)
                    }
                }
            })
        }
    }
    
    func move(node: NodeEntity, toParent: NodeEntity) async throws -> NodeEntity {
        try await withCheckedThrowingContinuation { continuation in
            guard let node = sdk.node(forHandle: node.handle),
                  let parent = sdk.node(forHandle: toParent.handle) else {
                continuation.resume(throwing: MoveNodeErrorEntity.generic)
                return
            }
            guard Task.isCancelled == false else {
                continuation.resume(throwing: CancellationError())
                return
            }
            sdk.move(node, newParent: parent, delegate: RequestDelegate { result in
                guard Task.isCancelled == false else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                
                switch result {
                case .success(let request):
                    guard let node = sdk.node(forHandle: request.nodeHandle) else {
                        continuation.resume(throwing: MoveNodeErrorEntity.generic)
                        return
                    }
                    continuation.resume(returning: node.toNodeEntity())
                case .failure(let error):
                    if error.type == .apiEBusinessPastDue {
                        continuation.resume(throwing: MoveNodeErrorEntity.businessExpired)
                    } else {
                        continuation.resume(throwing: MoveNodeErrorEntity.generic)
                    }
                }
            })
        }
    }
    
    func removeLink(nodes: [NodeEntity]) async throws {
        try await withThrowingTaskGroup(of: Void.self) { taskGroup in
            guard taskGroup.isCancelled == false else {
                throw CancellationError()
            }
            
            nodes.forEach { node in
                taskGroup.addTask {
                    try await removeLink(for: node)
                }
            }
            
            try await taskGroup.waitForAll()
        }
    }
}
