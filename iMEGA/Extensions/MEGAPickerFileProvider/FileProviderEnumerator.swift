import FileProvider
import MEGAData
import MEGADomain

final class FileProviderEnumerator: NSObject, NSFileProviderEnumerator {
    
    private let identifier: NSFileProviderItemIdentifier
    
    init(identifier: NSFileProviderItemIdentifier) {
        self.identifier = identifier
        super.init()
    }

    func invalidate() {
        MEGALogDebug("[Picker] invalidate")
    }

    func enumerateItems(for observer: NSFileProviderEnumerationObserver, startingAt page: NSFileProviderPage) {
        Task {
            do {
                if MEGASdk.shared.isLoggedIn() == 0 {
                    let authUseCase = AuthUseCase(repo: AuthRepository(sdk: MEGASdk.shared), credentialRepo: CredentialRepository.newRepo)
                    
                    guard let sessionId = authUseCase.sessionId() else {
                        MEGALogError("[Picker] Can't login: no session")
                        return
                    }
                    
                    try await authUseCase.login(sessionId: sessionId)
                    
                    let nodeActionUseCase = NodeActionUseCase(repo: NodeActionRepository.newRepo)
                    
                    try await nodeActionUseCase.fetchnodes()
                }
                
                let items = try fetchItems()
                observer.didEnumerate(items)
                
                observer.finishEnumerating(upTo: nil)
            } catch {
                observer.finishEnumeratingWithError(error)
            }
        }
    }
    
    // MARK: - Private
    
    private func fetchItems() throws -> [FileProviderItem] {
        var items: [FileProviderItem] = []

        var node: MEGANode?
        if identifier == NSFileProviderItemIdentifier.rootContainer {
            node = MEGASdk.shared.rootNode
        } else {
            let base64Handle = identifier.rawValue
            node = MEGASdk.shared.node(forHandle: MEGASdk.handle(forBase64Handle: base64Handle))
        }
        
        guard let node else {
            throw NSFileProviderError(.noSuchItem)
        }
        
        if node.isFolder() {
            let childrenArray = MEGASdk.shared.children(forParent: node).toNodeArray()
            childrenArray.forEach { items.append(FileProviderItem(node: $0.toNodeEntity())) }
        } else {
            items.append(FileProviderItem(node: node.toNodeEntity()))
        }
        return items
    }
}
