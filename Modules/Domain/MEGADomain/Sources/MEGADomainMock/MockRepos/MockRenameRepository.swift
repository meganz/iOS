import MEGADomain
import MEGASwift

public final class MockRenameRepository: RenameRepositoryProtocol, @unchecked Sendable {
    public static let newRepo = MockRenameRepository()
    @Atomic public var renamedDeviceRequests = [(deviceId: String, name: String)]()
    
    public init() {}
    
    public func renameDevice(_ deviceId: String, newName: String) async throws {
        $renamedDeviceRequests.mutate { $0.append((deviceId: deviceId, name: newName)) }
    }
}
