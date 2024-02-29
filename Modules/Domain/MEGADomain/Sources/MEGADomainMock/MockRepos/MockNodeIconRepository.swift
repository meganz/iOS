import Foundation
import MEGADomain

public final class MockNodeIconRepository: NodeIconRepositoryProtocol {
    private let stubbedIconData: Data
    
    public init(stubbedIconData: Data) {
        self.stubbedIconData = stubbedIconData
    }
    public func iconData(for node: MEGADomain.NodeEntity) -> Data {
        stubbedIconData
    }
}
