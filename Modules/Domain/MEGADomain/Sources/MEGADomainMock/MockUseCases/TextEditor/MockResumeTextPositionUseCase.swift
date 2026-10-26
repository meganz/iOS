import Foundation
import MEGADomain

public final class MockResumeTextPositionUseCase: ResumeTextPositionUseCaseProtocol, @unchecked Sendable {
    public var savedOffsets: [String: Int]
    public var savedLines: [String: Int]
    public var saveReadingOffsetCallCount = 0
    public var readingOffsetCallCount = 0
    public var deleteReadingOffsetCallCount = 0
    public var saveReadingLineCallCount = 0
    public var deleteReadingLineCallCount = 0

    public init(savedOffsets: [String: Int] = [:], savedLines: [String: Int] = [:]) {
        self.savedOffsets = savedOffsets
        self.savedLines = savedLines
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

    public func saveReadingLine(_ line: Int, for node: NodeEntity) {
        guard let fingerprint = node.fingerprint else { return }
        saveReadingLineCallCount += 1
        savedLines[fingerprint] = line
    }

    public func readingLine(for node: NodeEntity) -> Int? {
        guard let fingerprint = node.fingerprint else { return nil }
        return savedLines[fingerprint]
    }

    public func deleteReadingLine(for node: NodeEntity) {
        guard let fingerprint = node.fingerprint else { return }
        deleteReadingLineCallCount += 1
        savedLines.removeValue(forKey: fingerprint)
    }
}
