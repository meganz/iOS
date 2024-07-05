import MEGADomain
import MEGASwift

public final class MockRenameUseCase: RenameUseCaseProtocol, @unchecked Sendable {
    public var shouldThrowError: Atomic<Bool>
    
    public init(shouldThrowError: Bool) {
        self.shouldThrowError = .init(wrappedValue: shouldThrowError)
    }

    public func renameDevice(_ deviceId: String, newName: String) async throws {
        if shouldThrowError.wrappedValue {
            throw GenericErrorEntity()
        }
    }
    
    public func renameNode(_ node: NodeEntity, newName: String) async throws {
        if shouldThrowError.wrappedValue {
            throw GenericErrorEntity()
        }
    }
    
    public func parentNodeHasMatchingChild(_ parentNode: NodeEntity, childName: String) -> Bool {
        true
    }
}
