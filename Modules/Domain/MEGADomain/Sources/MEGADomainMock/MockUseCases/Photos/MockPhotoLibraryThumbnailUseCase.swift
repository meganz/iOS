import Foundation
import MEGADomain
import MEGASwift

public final class MockPhotoLibraryThumbnailUseCase: PhotoLibraryThumbnailUseCaseProtocol, @unchecked Sendable {
    public enum Invocation: Equatable {
        case thumbnailData(identifier: String, targetSize: CGSize, compressionQuality: CGFloat)
        case startCaching(identifiers: [String], targetSize: CGSize)
        case stopCaching(identifiers: [String], targetSize: CGSize)
        case clearCache
    }
    @Atomic public var invocations: [Invocation] = []
    
    private let thumbnailDataAsyncSequence: AnyAsyncThrowingSequence<PhotoLibraryThumbnailResultEntity, any Error>?
    
    public init(thumbnailDataAsyncSequence: AnyAsyncThrowingSequence<PhotoLibraryThumbnailResultEntity, any Error>? = nil) {
        self.thumbnailDataAsyncSequence = thumbnailDataAsyncSequence
    }
    
    public func thumbnailData(for identifier: String, targetSize: CGSize, compressionQuality: CGFloat) -> AnyAsyncThrowingSequence<PhotoLibraryThumbnailResultEntity, any Error>? {
        addInvocation(.thumbnailData(identifier: identifier, targetSize: targetSize, compressionQuality: compressionQuality))
        return thumbnailDataAsyncSequence
    }
    
    public func startCaching(for identifiers: [String], targetSize: CGSize) {
        addInvocation(.startCaching(identifiers: identifiers, targetSize: targetSize))
    }
    
    public func stopCaching(for identifiers: [String], targetSize: CGSize) {
        addInvocation(.stopCaching(identifiers: identifiers, targetSize: targetSize))
    }
    
    public func clearCache() {
        addInvocation(.clearCache)
    }
    
    private func addInvocation(_ invocation: Invocation) {
        $invocations.mutate { $0.append(invocation)}
    }
}
