import Foundation

public struct PhotoLibraryThumbnailResultEntity: Sendable, Equatable {
    public let data: Data
    public let isDegraded: Bool
    
    public init(data: Data, isDegraded: Bool) {
        self.data = data
        self.isDegraded = isDegraded
    }
}
