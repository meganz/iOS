import Foundation
import MEGADomain
import MEGASdk
import MEGASDKRepo

public final class MockOfflineStoreBridge: OfflineStoreBridgeProtocol {
    
    private let isDownloadedForNodes: [HandleEntity: Bool]
    
    public init(isDownloadedForNodes: [HandleEntity: Bool] = [:]) {
        self.isDownloadedForNodes = isDownloadedForNodes
    }
    
    public func isDownloaded(node: MEGANode) -> Bool {
        isDownloadedForNodes[node.handle] ?? false
    }
}
