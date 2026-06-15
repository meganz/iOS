@preconcurrency import FileProvider
import MEGAAppSDKRepo
import MEGADomain
import MEGAPickerFileProviderDomain
import MEGARepo

final class FileProviderEnumerator: NSObject, NSFileProviderEnumerator, Sendable {
    
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
                // Single-flight login + fetchNodes so concurrent enumerations don't race on login()
                // (which would fail all-but-one with API_EACCESS).
                try await FileProviderSession.shared.ensureReady()

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
