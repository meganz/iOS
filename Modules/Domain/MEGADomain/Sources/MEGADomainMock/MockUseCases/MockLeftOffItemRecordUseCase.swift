import Foundation
import MEGADomain

public final class MockLeftOffItemRecordUseCase: LeftOffItemRecordUseCaseProtocol, @unchecked Sendable {
    public private(set) var record_Calls = [(handle: HandleEntity, name: String)]()
    public private(set) var remove_Calls = [HandleEntity]()
    /// Called after each recorded call, so a test can wait for work started in a detached task.
    public var onCall: (@Sendable () -> Void)?

    public init() {}

    public func record(handle: HandleEntity, name: String) async {
        record_Calls.append((handle, name))
        onCall?()
    }

    public func remove(handle: HandleEntity) async {
        remove_Calls.append(handle)
        onCall?()
    }
}
