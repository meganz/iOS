import MEGADomain
import MEGASwift

public final class MockCameraUploadAssetRepository: CameraUploadAssetRepositoryProtocol, @unchecked Sendable {
    public enum Invocation: Sendable, Equatable {
        case uploads(startingFrom: QueuedCameraUploadCursorEntity?, isForward: Bool, limit: Int?, statuses: [CameraAssetUploadStatusEntity], mediaTypes: [PhotoAssetMediaTypeEntity])
        case fileDetails(identifiers: Set<String>)
    }
    private let uploadsResult: Result<[CameraAssetUploadEntity], any Error>
    private let fileDetailsResult: Result<Set<CameraUploadFileDetailsEntity>, any Error>
    @Atomic public var invocations: [Invocation] = []
    
    public init(
        uploadsResult: Result<[CameraAssetUploadEntity], any Error> = .failure(GenericErrorEntity()),
        fileDetailsResult: Result<Set<CameraUploadFileDetailsEntity>, any Error> = .failure(GenericErrorEntity())
    ) {
        self.uploadsResult = uploadsResult
        self.fileDetailsResult = fileDetailsResult
    }
    
    public func uploads(
        startingFrom cursor: QueuedCameraUploadCursorEntity?,
        isForward: Bool,
        limit: Int?,
        statuses: [CameraAssetUploadStatusEntity],
        mediaTypes: [PhotoAssetMediaTypeEntity]
    ) async throws -> [CameraAssetUploadEntity] {
        addInvocation(.uploads(startingFrom: cursor, isForward: isForward, limit: limit, statuses: statuses, mediaTypes: mediaTypes))
        return try uploadsResult.get()
    }
    
    public func fileDetails(forLocalIdentifiers identifiers: Set<String>) async throws -> Set<CameraUploadFileDetailsEntity> {
        addInvocation(.fileDetails(identifiers: identifiers))
        return try fileDetailsResult.get()
    }
    
    private func addInvocation(_ invocation: Invocation) {
        $invocations.mutate { $0.append(invocation) }
    }
}
