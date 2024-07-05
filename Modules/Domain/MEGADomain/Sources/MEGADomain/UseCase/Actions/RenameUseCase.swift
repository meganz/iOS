import Foundation

public protocol RenameUseCaseProtocol: Sendable {
    func renameDevice(_ deviceId: String, newName: String) async throws
}

public struct RenameUseCase<Repository: RenameRepositoryProtocol>: RenameUseCaseProtocol {
    private let repository: Repository
    
    public init(renameRepository: Repository) {
        self.repository = renameRepository
    }
    
    public func renameDevice(_ deviceId: String, newName: String) async throws {
        try await repository.renameDevice(deviceId, newName: newName)
    }
}
