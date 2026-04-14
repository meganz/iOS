import Foundation
import MEGASwift

public protocol PrepareMediaImportUseCaseProtocol: Sendable {
    func prepareItems() -> AnyAsyncSequence<MediaImportProgressEntity>
}

public struct PrepareMediaImportUseCase: PrepareMediaImportUseCaseProtocol {
    nonisolated(unsafe) private let itemProviders: [NSItemProvider]
    private let repository: any MediaImportRepositoryProtocol

    public init(
        itemProviders: [NSItemProvider],
        repository: some MediaImportRepositoryProtocol
    ) {
        self.itemProviders = itemProviders
        self.repository = repository
    }

    public func prepareItems() -> AnyAsyncSequence<MediaImportProgressEntity> {
        let totalCount = itemProviders.count
        guard totalCount > 0 else {
            return EmptyAsyncSequence<MediaImportProgressEntity>()
                .eraseToAnyAsyncSequence()
        }

        let repository = repository
        let eventStream: AsyncStream<ItemEvent> = Array(0..<totalCount)
            .taskGroup { index, continuation in
                let provider = itemProviders[index]
                do {
                    let url = try await repository.loadAndStageItem(from: provider) { fraction in
                        guard !Task.isCancelled else { return }
                        continuation.yield(.progress(index: index, fraction: fraction))
                    }
                    continuation.yield(.completed(index: index, url: url))
                } catch {
                    continuation.yield(.failed(index: index, error: error))
                }
            }

        return AsyncStream<MediaImportProgressEntity> { outerContinuation in
            let task = Task {
                var fractions = Array(repeating: 0.0, count: totalCount)
                var completedCount = 0
                var failedCount = 0

                for await event in eventStream {
                    guard !Task.isCancelled else { break }
                    var latestURL: URL?
                    var latestError: (any Error)?

                    switch event {
                    case .progress(let index, let fraction):
                        fractions[index] = fraction

                    case .completed(let index, let url):
                        fractions[index] = 1.0
                        completedCount += 1
                        latestURL = url

                    case .failed(let index, let error):
                        fractions[index] = 1.0
                        failedCount += 1
                        latestError = error
                    }

                    outerContinuation.yield(MediaImportProgressEntity(
                        fractionCompleted: fractions.reduce(0.0, +) / Double(totalCount),
                        completedCount: completedCount,
                        totalCount: totalCount,
                        failedCount: failedCount,
                        latestPreparedURL: latestURL,
                        latestError: latestError
                    ))
                }

                outerContinuation.finish()
            }

            outerContinuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }.eraseToAnyAsyncSequence()
    }
}

// MARK: - Internal Types

private enum ItemEvent: Sendable {
    case progress(index: Int, fraction: Double)
    case completed(index: Int, url: URL)
    case failed(index: Int, error: any Error)
}
