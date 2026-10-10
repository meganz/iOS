import FileProvider
import MEGAPickerFileProviderDomain

public struct FileProviderWorkingSetSignalRepository: FileProviderWorkingSetSignalRepositoryProtocol {
    public static var newRepo: FileProviderWorkingSetSignalRepository {
        FileProviderWorkingSetSignalRepository()
    }

    public func signalWorkingSet() async throws {
        guard let manager = NSFileProviderManager(for: .mega) else {
            throw NSFileProviderError(.providerNotFound)
        }
        try await manager.signalEnumerator(for: .workingSet)
    }
}
