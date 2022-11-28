import Foundation

public struct AlbumElementsResultEntity {
    public let success: UInt
    public let failure: UInt
    
    public init(success: UInt, failure: UInt) {
        self.success = success
        self.failure = failure
    }
}
