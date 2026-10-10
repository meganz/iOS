import FileProvider
import Foundation
import MEGAPickerFileProviderDomain

final class MockFileProviderSnapshotRepository: FileProviderSnapshotRepositoryProtocol, @unchecked Sendable {
    static var newRepo: MockFileProviderSnapshotRepository { MockFileProviderSnapshotRepository() }

    private let lock = NSLock()
    private let error: NSFileProviderError?
    private var _snapshots: [NSFileProviderItemIdentifier: FileProviderSnapshotEntity]

    var snapshots: [NSFileProviderItemIdentifier: FileProviderSnapshotEntity] {
        synchronized { _snapshots }
    }

    /// - Parameter error: What every call throws, when set.
    init(snapshots: [NSFileProviderItemIdentifier: FileProviderSnapshotEntity] = [:], error: NSFileProviderError? = nil) {
        _snapshots = snapshots
        self.error = error
    }

    func snapshot(of containerIdentifier: NSFileProviderItemIdentifier) throws -> FileProviderSnapshotEntity? {
        try throwError()
        return synchronized { _snapshots[containerIdentifier] }
    }

    func updateSnapshot(
        of containerIdentifier: NSFileProviderItemIdentifier,
        _ update: @Sendable (inout FileProviderSnapshotEntity?) -> Void
    ) throws {
        try throwError()
        synchronized { update(&_snapshots[containerIdentifier]) }
    }

    func removeSnapshot(of containerIdentifier: NSFileProviderItemIdentifier) throws {
        try throwError()
        synchronized { _snapshots[containerIdentifier] = nil }
    }

    func containerIdentifiers() throws -> [NSFileProviderItemIdentifier] {
        try throwError()
        return synchronized { Array(_snapshots.keys) }
    }

    private func throwError() throws {
        if let error {
            throw error
        }
    }

    private func synchronized<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }
}
