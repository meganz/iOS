import XCTest
@testable import MEGA
import MEGADomain
import MEGADomainMock

final class NameCollisionViewModelTests: XCTestCase {
    let parentHandle: HandleEntity = 1000
    let copyMoveHandles: [HandleEntity] = [1, 2, 3]
    lazy var nameCollisions = [
        NameCollisionEntity(parentHandle: parentHandle, name: "Node1", isFile: Bool.random()),
        NameCollisionEntity(parentHandle: parentHandle, name: "Node2", isFile: Bool.random()),
        NameCollisionEntity(parentHandle: parentHandle, name: "Node3", isFile: Bool.random()),
    ]
    
    
    func testAcion_cancel() {
        let router = MockNameCollisionRouter()
        let viewModel = NameCollisionViewModel(router: router, thumbnailUseCase: MockThumbnailUseCase(), nameCollisionUseCase: MockNameCollisionUseCase(), fileVersionsUseCase: MockFileVersionsUseCase(), transfers: nil, nodes: nil, collisions: [], collisionType: .upload)
        
        viewModel.cancelResolveNameCollisions()
        XCTAssert(router.dismiss_calledTimes == 1)
    }
    
    func testAction_copyWithoutNameCollisionsSuccess() {
        let router = MockNameCollisionRouter()
        let nameCollisionUseCase = MockNameCollisionUseCase(nameCollisions: nameCollisions, copiedNodes: copyMoveHandles)
        
        let viewModel = NameCollisionViewModel(router: router, thumbnailUseCase: MockThumbnailUseCase(), nameCollisionUseCase: nameCollisionUseCase, fileVersionsUseCase: MockFileVersionsUseCase(), transfers: nil, nodes: nil, collisions: nameCollisions, collisionType: .copy)
        viewModel.checkNameCollisions()
        if XCTWaiter.wait(for: [expectation(description: "Wait for response")], timeout: 0.5) == .timedOut{
            XCTAssert(router.showCopyOrMoveSuccess_calledTimes == 1)
        } else {
            XCTFail()
        }
    }
    
    func testAction_copyWithoutNameCollisionsFail() {
        let router = MockNameCollisionRouter()
        let nameCollisionUseCase = MockNameCollisionUseCase(nameCollisions: nameCollisions)
        
        let viewModel = NameCollisionViewModel(router: router, thumbnailUseCase: MockThumbnailUseCase(), nameCollisionUseCase: nameCollisionUseCase, fileVersionsUseCase: MockFileVersionsUseCase(), transfers: nil, nodes: nil, collisions: nameCollisions, collisionType: .copy)
        viewModel.checkNameCollisions()
        if XCTWaiter.wait(for: [expectation(description: "Wait for response")], timeout: 0.5) == .timedOut{
            XCTAssert(router.showCopyOrMoveError_calledTimes == 1)
        } else {
            XCTFail()
        }
    }
    
    func testAction_copyWithNameCollisions() {
        let router = MockNameCollisionRouter()
        let collisions = nameCollisions
        collisions.forEach { collision in
            collision.collisionNodeHandle = HandleEntity.random(in: 100...1000)
        }
        let nameCollisionUseCase = MockNameCollisionUseCase(nameCollisions: collisions)
        
        let viewModel = NameCollisionViewModel(router: router, thumbnailUseCase: MockThumbnailUseCase(), nameCollisionUseCase: nameCollisionUseCase, fileVersionsUseCase: MockFileVersionsUseCase(), transfers: nil, nodes: nil, collisions: nameCollisions, collisionType: .copy)
        viewModel.checkNameCollisions()
        if XCTWaiter.wait(for: [expectation(description: "Wait for response")], timeout: 0.5) == .timedOut{
            XCTAssert(router.showNameCollisionsView_calledTimes == 1)
        } else {
            XCTFail()
        }
    }
    
    func testAction_moveWithoutNameCollisionsSuccess() {
        let router = MockNameCollisionRouter()
        let nameCollisionUseCase = MockNameCollisionUseCase(nameCollisions: nameCollisions, movedNodes: copyMoveHandles)
        
        let viewModel = NameCollisionViewModel(router: router, thumbnailUseCase: MockThumbnailUseCase(), nameCollisionUseCase: nameCollisionUseCase, fileVersionsUseCase: MockFileVersionsUseCase(), transfers: nil, nodes: nil, collisions: nameCollisions, collisionType: .move)
        viewModel.checkNameCollisions()
        if XCTWaiter.wait(for: [expectation(description: "Wait for response")], timeout: 0.5) == .timedOut{
            XCTAssert(router.showCopyOrMoveSuccess_calledTimes == 1)
        } else {
            XCTFail()
        }
    }
    
    func testAction_moveWithoutNameCollisionsFail() {
        let router = MockNameCollisionRouter()
        let nameCollisionUseCase = MockNameCollisionUseCase(nameCollisions: nameCollisions)
        
        let viewModel = NameCollisionViewModel(router: router, thumbnailUseCase: MockThumbnailUseCase(), nameCollisionUseCase: nameCollisionUseCase, fileVersionsUseCase: MockFileVersionsUseCase(), transfers: nil, nodes: nil, collisions: nameCollisions, collisionType: .move)
        viewModel.checkNameCollisions()
        if XCTWaiter.wait(for: [expectation(description: "Wait for response")], timeout: 0.5) == .timedOut{
            XCTAssert(router.showCopyOrMoveError_calledTimes == 1)
        } else {
            XCTFail()
        }
    }
    
    func testAction_uploadWithoutNameCollisionsSuccess() {
        let router = MockNameCollisionRouter()
        let nameCollisionUseCase = MockNameCollisionUseCase(nameCollisions: nameCollisions, copiedNodes: copyMoveHandles)
        
        let viewModel = NameCollisionViewModel(router: router, thumbnailUseCase: MockThumbnailUseCase(), nameCollisionUseCase: nameCollisionUseCase, fileVersionsUseCase: MockFileVersionsUseCase(), transfers: nil, nodes: nil, collisions: nameCollisions, collisionType: .upload)
        viewModel.checkNameCollisions()
        if XCTWaiter.wait(for: [expectation(description: "Wait for response")], timeout: 0.5) == .timedOut{
            XCTAssert(router.resolvedUploadCollisions_calledTimes == 1)
        } else {
            XCTFail()
        }
    }
}

final class MockNameCollisionRouter: NameCollisionViewRouting {
    var showNameCollisionsView_calledTimes = 0
    var resolvedUploadCollisions_calledTimes = 0
    var dismiss_calledTimes = 0
    var showCopyOrMoveSuccess_calledTimes = 0
    var showCopyOrMoveError_calledTimes = 0
    
    func showNameCollisionsView() {
        showNameCollisionsView_calledTimes += 1
    }
    
    func resolvedUploadCollisions(_ transfers: [CancellableTransfer]) {
        resolvedUploadCollisions_calledTimes += 1
    }
    
    func dismiss() {
        dismiss_calledTimes += 1
    }
    
    func showCopyOrMoveSuccess() {
        print("NameCollisionViewModelTests show succes")
        showCopyOrMoveSuccess_calledTimes += 1
    }
    
    func showCopyOrMoveError() {
        showCopyOrMoveError_calledTimes += 1
    }
}
