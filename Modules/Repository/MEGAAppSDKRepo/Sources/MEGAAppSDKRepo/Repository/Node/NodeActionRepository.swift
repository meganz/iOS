import MEGADomain
import MEGASdk
import MEGASwift

public struct NodeActionRepository: NodeActionRepositoryProtocol {
    public static var newRepo: NodeActionRepository {
        NodeActionRepository(sdk: MEGASdk.sharedSdk)
    }

    private let sdk: MEGASdk

    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }

    public func fetchNodes() async throws {
        try await withAsyncThrowingValue { completion in
            sdk.fetchNodes(with: RequestDelegate { result in
                switch result {
                case .success:
                    completion(.success(()))
                case .failure:
                    completion(.failure(GenericErrorEntity()))
                }
            })
        }
    }

    public func createFolder(name: String, parent: NodeEntity) async throws -> NodeEntity {
        try await withAsyncThrowingValue { completion in
            guard let parentNode = sdk.node(forHandle: parent.handle) else {
                completion(.failure(CreateFolderErrorEntity.generic))
                return
            }

            sdk.createFolder(withName: name, parent: parentNode, delegate: RequestDelegate { result in
                switch result {
                case .success(let request):
                    guard let node = sdk.node(forHandle: request.nodeHandle) else {
                        completion(.failure(CreateFolderErrorEntity.generic))
                        return
                    }

                    completion(.success(node.toNodeEntity()))
                case .failure(let error):
                    if error.type == .apiEBusinessPastDue {
                        completion(.failure(CreateFolderErrorEntity.businessExpired))
                    } else {
                        completion(.failure(CreateFolderErrorEntity.generic))
                    }
                }
            })
        }
    }

    public func rename(node: NodeEntity, name: String) async throws -> NodeEntity {
        try await withAsyncThrowingValue { completion in
            guard let megaNode = sdk.node(forHandle: node.handle) else {
                completion(.failure(RenameNodeErrorEntity.generic))
                return
            }

            sdk.renameNode(megaNode, newName: name, delegate: RequestDelegate { result in
                switch result {
                case .success(let request):
                    guard let node = sdk.node(forHandle: request.nodeHandle) else {
                        completion(.failure(RenameNodeErrorEntity.generic))
                        return
                    }

                    completion(.success(node.toNodeEntity()))
                case .failure(let error):
                    if error.type == .apiEBusinessPastDue {
                        completion(.failure(RenameNodeErrorEntity.businessExpired))
                    } else {
                        completion(.failure(RenameNodeErrorEntity.generic))
                    }
                }
            })
        }
    }

    public func trash(node: NodeEntity) async throws -> NodeEntity {
        try await withAsyncThrowingValue { completion in
            guard
                let node = sdk.node(forHandle: node.handle),
                let rubbishBinNode = sdk.rubbishNode
            else {
                completion(.failure(MoveNodeErrorEntity.generic))
                return
            }

            sdk.move(node, newParent: rubbishBinNode, delegate: RequestDelegate { result in
                switch result {
                case .success(let request):
                    guard let node = sdk.node(forHandle: request.nodeHandle) else {
                        completion(.failure(MoveNodeErrorEntity.generic))
                        return
                    }
                    completion(.success(node.toNodeEntity()))
                case .failure(let error):
                    if error.type == .apiEBusinessPastDue {
                        completion(.failure(MoveNodeErrorEntity.businessExpired))
                    } else {
                        completion(.failure(MoveNodeErrorEntity.generic))
                    }
                }
            })
        }
    }

    public func untrash(node: NodeEntity) async throws -> NodeEntity {
        try await withAsyncThrowingValue { completion in
            guard
                let node = sdk.node(forHandle: node.handle),
                sdk.isNode(inRubbish: node),
                let restoreNode = sdk.node(forHandle: node.restoreHandle),
                !sdk.isNode(inRubbish: restoreNode)
            else {
                completion(.failure(MoveNodeErrorEntity.generic))
                return
            }

            sdk.move(node, newParent: restoreNode, delegate: RequestDelegate { result in
                switch result {
                case .success(let request):
                    guard let node = sdk.node(forHandle: request.nodeHandle) else {
                        completion(.failure(MoveNodeErrorEntity.generic))
                        return
                    }

                    completion(.success(node.toNodeEntity()))
                case .failure(let error):
                    if error.type == .apiEBusinessPastDue {
                        completion(.failure(MoveNodeErrorEntity.businessExpired))
                    } else {
                        completion(.failure(MoveNodeErrorEntity.generic))
                    }
                }
            })
        }
    }

    public func delete(node: NodeEntity) async throws {
        try await withAsyncThrowingValue { (completion: @escaping (Result<Void, any Error>) -> Void) in
            guard
                let node = sdk.node(forHandle: node.handle),
                sdk.isNode(inRubbish: node)
            else {
                completion(.failure(RemoveNodeErrorEntity.generic))
                return
            }

            sdk.remove(node, delegate: RequestDelegate { result in
                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    if error.type == .apiEMasterOnly {
                        completion(.failure(RemoveNodeErrorEntity.masterOnly))
                    } else {
                        completion(.failure(RemoveNodeErrorEntity.generic))
                    }
                }
            })
        }
    }

    public func move(node: NodeEntity, toParent: NodeEntity) async throws -> NodeEntity {
        try await withAsyncThrowingValue { completion in
            guard
                let node = sdk.node(forHandle: node.handle),
                let parent = sdk.node(forHandle: toParent.handle)
            else {
                completion(.failure(MoveNodeErrorEntity.generic))
                return
            }

            sdk.move(node, newParent: parent, delegate: RequestDelegate { result in
                switch result {
                case .success(let request):
                    guard let node = sdk.node(forHandle: request.nodeHandle) else {
                        completion(.failure(MoveNodeErrorEntity.generic))
                        return
                    }
                    completion(.success(node.toNodeEntity()))
                case .failure(let error):
                    if error.type == .apiEBusinessPastDue {
                        completion(.failure(MoveNodeErrorEntity.businessExpired))
                    } else {
                        completion(.failure(MoveNodeErrorEntity.generic))
                    }
                }
            })
        }
    }

    public func removeLink(nodes: [NodeEntity]) async throws {
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
    
    public func setSensitive(node: NodeEntity, sensitive: Bool) async throws -> NodeEntity {
        try await withAsyncThrowingValue { completion in
            guard
                let node = sdk.node(forHandle: node.handle)
            else {
                completion(.failure(NodeErrorEntity.nodeNotFound))
                return
            }
            
            sdk.setNodeSensitive(node, sensitive: sensitive, delegate: RequestDelegate { result in
                switch result {
                case .success(let request):
                    guard let node = sdk.node(forHandle: request.nodeHandle) else {
                        completion(.failure(NodeErrorEntity.nodeNotFound))
                        return
                    }
                    completion(.success(node.toNodeEntity()))
                case .failure(let error):
                    let message = "[iOS] [NodeActionRepository] could not setNodeSensitive (\(sensitive)) - \(error.localizedDescription)"
                    MEGASdk.log(with: .error, message: message, filename: #file, line: #line)
                    completion(.failure(GenericErrorEntity()))
                }
            })
        }
    }

    // MARK: - Private
    
    private func removeLink(for node: NodeEntity) async throws {
        try await withAsyncThrowingValue { (completion: @escaping (Result<Void, any Error>) -> Void) in
            guard let megaNode = node.toMEGANode(in: sdk) else {
                completion(.failure(RemoveLinkErrorEntity.generic))
                return
            }

            sdk.disableExport(megaNode, delegate: RequestDelegate { result in
                switch result {
                case .failure(let error):
                    switch error.type {
                    case .apiEBusinessPastDue:
                        completion(.failure(RemoveLinkErrorEntity.businessExpired))
                    case .apiENoent:
                        completion(.failure(RemoveLinkErrorEntity.notFound))
                    default:
                        completion(.failure(RemoveLinkErrorEntity.generic))
                    }
                case .success:
                    completion(.success(()))
                }
            })
        }
    }
}
