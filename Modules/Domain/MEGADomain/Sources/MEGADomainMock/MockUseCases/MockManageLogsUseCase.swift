import MEGADomain
import MEGASwift

public final class MockManageLogsUseCase: ManageLogsUseCaseProtocol, @unchecked Sendable {
    public enum Invocation: Equatable {
        case toggleLogs(logMetadata: LogMetadataEntity)
    }
    @Atomic public var invocations = [Invocation]()
    
    public init() {}
    
    public func toggleLogs(with logMetadata: LogMetadataEntity) {
        $invocations.mutate { $0.append(.toggleLogs(logMetadata: logMetadata)) }
    }
}
