import Foundation
import MEGADomain
import MEGASwift
import MEGATest

public final class MockPhotoLibraryThumbnailRepository: PhotoLibraryThumbnailRepositoryProtocol, @unchecked Sendable {
    public enum Invocation: Equatable {
        case thumbnailData(for: String, targetSize: CGSize, compressionQuality: CGFloat)
        case startCaching(for: [String], targetSize: CGSize)
        case stopCaching(for: [String], targetSize: CGSize)
        case clearCache
    }
    
    private let thumbnailResultAsyncSequence: AnyAsyncSequence<PhotoLibraryThumbnailResultEntity>?
    @Atomic public var invocations: [Invocation] = []
    
    public init(thumbnailResultAsyncSequence: AnyAsyncSequence<PhotoLibraryThumbnailResultEntity>? = nil) {
        self.thumbnailResultAsyncSequence = thumbnailResultAsyncSequence
    }
    
    public func thumbnailData(for identifier: String, targetSize: CGSize, compressionQuality: CGFloat) -> AnyAsyncSequence<PhotoLibraryThumbnailResultEntity>? {
        addInvocation(.thumbnailData(for: identifier, targetSize: targetSize, compressionQuality: compressionQuality))
        return thumbnailResultAsyncSequence
    }
    
    public func startCaching(for identifiers: [String], targetSize: CGSize) {
        addInvocation(.startCaching(for: identifiers, targetSize: targetSize))
    }
    
    public func stopCaching(for identifiers: [String], targetSize: CGSize) {
        addInvocation(.stopCaching(for: identifiers, targetSize: targetSize))
    }
    
    public func clearCache() {
        addInvocation(.clearCache)
    }
    
    private func addInvocation(_ invocation: Invocation) {
        $invocations.mutate { $0.append(invocation) }
    }
}
