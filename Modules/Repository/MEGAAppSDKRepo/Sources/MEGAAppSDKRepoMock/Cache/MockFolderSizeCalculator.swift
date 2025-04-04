import Foundation
import MEGAAppSDKRepo

public struct MockFolderSizeCalculator: FolderSizeCalculatingProtocol {
    private let folderSize: UInt64
    private let groupSharedDirectorySize: UInt64
    
    public init(
        folderSize: UInt64 = 0,
        groupSharedDirectorySize: UInt64 = 0
    ) {
        self.folderSize = folderSize
        self.groupSharedDirectorySize = groupSharedDirectorySize
    }
    
    public func folderSize(at url: URL) -> UInt64 {
        folderSize
    }
    
    public func groupSharedDirectorySize(groupIdentifier: String) -> UInt64 {
        groupSharedDirectorySize
    }
}
