import FileProvider
import MEGADomain
import MEGAPickerFileProviderDomain
import MEGASDKRepo

final class FileProviderEnumerator: NSObject, NSFileProviderEnumerator {
    
    private let identifier: NSFileProviderItemIdentifier
    private let fileProviderEnumeratorUseCase: any FileProviderEnumeratorUseCaseProtocol
    
    init(identifier: NSFileProviderItemIdentifier,
         fileProviderEnumeratorUseCase: some FileProviderEnumeratorUseCaseProtocol) {
        self.identifier = identifier
        self.fileProviderEnumeratorUseCase = fileProviderEnumeratorUseCase
        
        super.init()
    }

    func invalidate() {
        MEGALogDebug("[Picker] invalidate")
    }

    func enumerateItems(for observer: any NSFileProviderEnumerationObserver,
                        startingAt page: NSFileProviderPage) {
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
                    
                    try await nodeActionUseCase.fetchNodes()
                }
                
                let items = try await fetchItems()
                
                observer.didEnumerate(items)
                
                observer.finishEnumerating(upTo: nil)
            } catch {
                observer.finishEnumeratingWithError(error)
            }
        }
    }
    
    // MARK: - Private
    private func fetchItems() async throws -> [FileProviderItem] {
        try await fileProviderEnumeratorUseCase
            .fetchItems(for: identifier)
            .map(FileProviderItem.init(node:))
    }
}
