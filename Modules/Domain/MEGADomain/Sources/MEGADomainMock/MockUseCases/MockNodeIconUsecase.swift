import Foundation
import MEGADomain
import MEGASwift

public final class MockNodeIconUsecase: NodeIconUsecaseProtocol, @unchecked Sendable {
    
    private let stubbedIconData: Data
    
    public enum Invocation: Equatable {
        case iconData
    }
    
    @Atomic public var invocations: [Invocation] = []
    
    public init(stubbedIconData: Data = Data()) {
        self.stubbedIconData = stubbedIconData
    }
    
    public func iconData(for node: NodeEntity) -> Data {
        $invocations.mutate { $0.append(.iconData) }
        return stubbedIconData
    }
}
