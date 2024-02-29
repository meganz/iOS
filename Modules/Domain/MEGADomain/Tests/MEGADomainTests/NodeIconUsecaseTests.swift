import Foundation
import MEGADomain
import MEGADomainMock
import XCTest

final class NodeIconUsecaseTests: XCTestCase {
    func testIconData_returnEmptyData() {
        let repo = MockNodeIconRepository(stubbedIconData: Data())
        let sut = NodeIconUseCase(nodeIconRepo: repo)
        XCTAssertEqual(sut.iconData(for: NodeEntity(handle: HandleEntity())).count, 0)
    }
    
    func testIconData_returnsSystemImageData() {
        let playImageData = UIImage(systemName: "play")!.pngData()!
        let repo = MockNodeIconRepository(stubbedIconData: playImageData)
        let sut = NodeIconUseCase(nodeIconRepo: repo)
        XCTAssertEqual(sut.iconData(for: NodeEntity(handle: HandleEntity())), playImageData)
    }
}
