import MEGADomain

public final class MockRenameRepository: RenameRepositoryProtocol {
    public static let newRepo = MockRenameRepository()
    public var renamedDeviceRequests = [(deviceId: String, name: String)]()
    
    public init() {}
    
    public func renameDevice(_ deviceId: String, newName: String) async throws {
        renamedDeviceRequests.append((deviceId: deviceId, name: newName))
    }
    
    public func renameNode(_ node: NodeEntity, newName: String) async throws {
    }
    
    public func parentNodeHasMatchingChild(_ parentNode: NodeEntity, childName: String) -> Bool {
        true
    }
}
