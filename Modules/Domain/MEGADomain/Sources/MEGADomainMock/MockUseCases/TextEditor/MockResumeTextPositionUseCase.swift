import Foundation
import MEGADomain

public final class MockResumeTextPositionUseCase: ResumeTextPositionUseCaseProtocol, @unchecked Sendable {
    public var savedOffsets: [String: Int]
    public var saveReadingOffsetCallCount = 0
    public var readingOffsetCallCount = 0
    public var deleteReadingOffsetCallCount = 0

    public init(savedOffsets: [String: Int] = [:]) {
        self.savedOffsets = savedOffsets
    }

    public func saveReadingOffset(_ offset: Int, for node: NodeEntity) {
        guard let fingerprint = node.fingerprint else { return }
        saveReadingOffsetCallCount += 1
        savedOffsets[fingerprint] = offset
    }

    public func readingOffset(for node: NodeEntity) -> Int? {
        guard let fingerprint = node.fingerprint else { return nil }
        readingOffsetCallCount += 1
        return savedOffsets[fingerprint]
    }

    public func deleteReadingOffset(for node: NodeEntity) {
        guard let fingerprint = node.fingerprint else { return }
        deleteReadingOffsetCallCount += 1
        savedOffsets.removeValue(forKey: fingerprint)
    }
}
