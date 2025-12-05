import Foundation
import MEGAAppPresentation
import MEGASwift

public final class MockPhotoLibraryThumbnailProvider: PhotoLibraryThumbnailProviderProtocol, @unchecked Sendable {
    public enum Invocation: Equatable {
        case thumbnail(for: String, targetSize: CGSize)
        case startCaching(for: [String], targetSize: CGSize)
        case stopCaching(for: [String], targetSize: CGSize)
        case clearCache
    }
    
    private let thumbnailResultAsyncSequence: AnyAsyncThrowingSequence<PhotoLibraryThumbnailResult, any Error>?
    @Atomic public var invocations: [Invocation] = []
    
    public init(thumbnailResultAsyncSequence: AnyAsyncThrowingSequence<PhotoLibraryThumbnailResult, any Error>? = nil) {
        self.thumbnailResultAsyncSequence = thumbnailResultAsyncSequence
    }
    
    public func thumbnail(for identifier: String, targetSize: CGSize) -> AnyAsyncThrowingSequence<PhotoLibraryThumbnailResult, any Error>? {
        addInvocation(.thumbnail(for: identifier, targetSize: targetSize))
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

