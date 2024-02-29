import Foundation
import MEGADomain

public final class MockNodeIconUsecase: NodeIconUsecaseProtocol {
    
    private let stubbedIconData: Data
    
    public init(stubbedIconData: Data) {
        self.stubbedIconData = stubbedIconData
    }
    public func iconData(for node: MEGADomain.NodeEntity) -> Data {
        stubbedIconData
    }
}
