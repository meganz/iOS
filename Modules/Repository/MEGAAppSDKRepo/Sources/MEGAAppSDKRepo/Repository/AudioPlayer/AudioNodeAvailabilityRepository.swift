import MEGADomain
import MEGASdk
import MEGASwift

public struct AudioNodeAvailabilityRepository: AudioNodeAvailabilityRepositoryProtocol {
    public static var newRepo: AudioNodeAvailabilityRepository {
        AudioNodeAvailabilityRepository(sdk: .sharedSdk, folderSDK: .sharedFolderLinkSdk)
    }

    private let sdk: MEGASdk
    private let folderSDK: MEGASdk

    public init(sdk: MEGASdk, folderSDK: MEGASdk) {
        self.sdk = sdk
        self.folderSDK = folderSDK
    }

    public func isTakenDown(_ node: StreamingNode) async throws -> Bool {
        switch node {
        case .account(let node):
            try await isTakenDown(node, using: sdk)
        case .folderLink(let node):
            // Folder-link nodes live in their own tree, so the account SDK cannot see them.
            try await isTakenDown(node, using: folderSDK)
        case .fileLink(let node):
            try await isTakenDown(node, using: sdk)
        }
    }

    // MARK: - Private

    private func isTakenDown(_ node: any PlayableNode, using sdk: MEGASdk) async throws -> Bool {
        // A node we cannot even resolve is not a takedown — URL resolution reports
        // that case as unplayable on its own.
        guard let megaNode = resolve(node, in: sdk) else { return false }

        return try await withAsyncThrowingValue { completion in
            sdk.getDownloadUrl(megaNode, singleUrl: false, delegate: RequestDelegate { result in
                switch result {
                case .success:
                    completion(.success(false))
                case .failure(let error) where error.type == .apiEBlocked:
                    completion(.success(true))
                case .failure(let error):
                    completion(.failure(error))
                }
            })
        }
    }

    private func resolve(_ node: any PlayableNode, in sdk: MEGASdk) -> MEGANode? {
        (node as? MEGANode) ?? sdk.node(forHandle: node.handle)
    }
}
