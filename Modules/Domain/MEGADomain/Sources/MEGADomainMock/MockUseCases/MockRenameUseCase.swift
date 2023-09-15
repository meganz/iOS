import MEGADomain

public final class MockRenameUseCase: RenameUseCaseProtocol {
    public var shouldThrowError: Bool
    
    public init(shouldThrowError: Bool) {
        self.shouldThrowError = shouldThrowError
    }

    public func renameDevice(_ deviceId: String, newName: String) async throws {
        if shouldThrowError {
            throw GenericErrorEntity()
        }
    }
}
