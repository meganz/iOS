import Foundation
import os
import MediaImport

final class MockMediaImportRepository: MediaImportRepositoryProtocol, @unchecked Sendable {
    private var stubbedResults: [Result<URL, Error>] = []
    private var loadDelay: UInt64 = 0
    private let callIndex = OSAllocatedUnfairLock(initialState: 0)

    func stub(results: [Result<URL, Error>]) {
        stubbedResults = results
    }

    func stub(delay: UInt64) {
        loadDelay = delay
    }

    func loadAndStageItem(
        from itemProvider: NSItemProvider,
        progressHandler: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {
        let index = callIndex.withLock { state -> Int in
            let current = state
            state += 1
            return current
        }

        if loadDelay > 0 {
            try? await Task.sleep(nanoseconds: loadDelay)
        }

        progressHandler(0.5)
        progressHandler(1.0)

        guard !stubbedResults.isEmpty else {
            return URL(fileURLWithPath: "/tmp/staged-file")
        }

        let result = index < stubbedResults.count
            ? stubbedResults[index]
            : stubbedResults[stubbedResults.count - 1]

        return try result.get()
    }
}
