@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class NameCollisionViewModelTests: XCTestCase {
    let parentHandle: HandleEntity = 1000
    let copyMoveHandles: [HandleEntity] = [1, 2, 3]
    lazy var nameCollisions = [
        NameCollisionEntity(parentHandle: parentHandle, name: "Node1", isFile: Bool.random()),
        NameCollisionEntity(parentHandle: parentHandle, name: "Node2", isFile: Bool.random()),
        NameCollisionEntity(parentHandle: parentHandle, name: "Node3", isFile: Bool.random())
    ]
    
    @MainActor
    func testAcion_cancel() {
        let router = MockNameCollisionRouter()
        let viewModel = NameCollisionViewModel(router: router, thumbnailUseCase: MockThumbnailUseCase(), nameCollisionUseCase: MockNameCollisionUseCase(), fileVersionsUseCase: MockFileVersionsUseCase(), accountUseCase: MockAccountUseCase(), transfers: nil, nodes: nil, collisions: [], collisionType: .upload)

        viewModel.cancelResolveNameCollisions()
        XCTAssert(router.dismiss_calledTimes == 1)
    }
    
    @MainActor
    func testAction_copyWithoutNameCollisionsSuccess() {
        let router = MockNameCollisionRouter()
        let nameCollisionUseCase = MockNameCollisionUseCase(nameCollisions: nameCollisions, copiedNodes: copyMoveHandles)
        
        let viewModel = NameCollisionViewModel(router: router, thumbnailUseCase: MockThumbnailUseCase(), nameCollisionUseCase: nameCollisionUseCase, fileVersionsUseCase: MockFileVersionsUseCase(), accountUseCase: MockAccountUseCase(), transfers: nil, nodes: nil, collisions: nameCollisions, collisionType: .copy)
        viewModel.checkNameCollisions()
        if XCTWaiter.wait(for: [expectation(description: "Wait for response")], timeout: 0.5) == .timedOut {
            XCTAssert(router.showCopyOrMoveSuccess_calledTimes == 1)
        } else {
            XCTFail("Expected to time out!")
        }
    }
    
    @MainActor
    func testAction_copyWithoutNameCollisionsFail() {
        let router = MockNameCollisionRouter()
        let nameCollisionUseCase = MockNameCollisionUseCase(nameCollisions: nameCollisions)
        
        let viewModel = NameCollisionViewModel(router: router, thumbnailUseCase: MockThumbnailUseCase(), nameCollisionUseCase: nameCollisionUseCase, fileVersionsUseCase: MockFileVersionsUseCase(), accountUseCase: MockAccountUseCase(), transfers: nil, nodes: nil, collisions: nameCollisions, collisionType: .copy)
        viewModel.checkNameCollisions()
        if XCTWaiter.wait(for: [expectation(description: "Wait for response")], timeout: 0.5) == .timedOut {
            XCTAssert(router.showCopyOrMoveError_calledTimes == 1)
        } else {
            XCTFail("Expected to time out!")
        }
    }
    
    @MainActor
    func testAction_copyWithNameCollisions() {
        let router = MockNameCollisionRouter()
        var resolvedCollisions = [NameCollisionEntity]()
        for var collision in nameCollisions {
            collision.collisionNodeHandle = HandleEntity.random(in: 100...1000)
            resolvedCollisions.append(collision)
        }
        let nameCollisionUseCase = MockNameCollisionUseCase(nameCollisions: resolvedCollisions)
        
        let viewModel = NameCollisionViewModel(router: router, thumbnailUseCase: MockThumbnailUseCase(), nameCollisionUseCase: nameCollisionUseCase, fileVersionsUseCase: MockFileVersionsUseCase(), accountUseCase: MockAccountUseCase(), transfers: nil, nodes: nil, collisions: nameCollisions, collisionType: .copy)
        viewModel.checkNameCollisions()
        if XCTWaiter.wait(for: [expectation(description: "Wait for response")], timeout: 0.5) == .timedOut {
            XCTAssert(router.showNameCollisionsView_calledTimes == 1)
        } else {
            XCTFail("Expected to time out!")
        }
    }
    
    @MainActor
    func testAction_moveWithoutNameCollisionsSuccess() {
        let router = MockNameCollisionRouter()
        let nameCollisionUseCase = MockNameCollisionUseCase(nameCollisions: nameCollisions, movedNodes: copyMoveHandles)
        
        let viewModel = NameCollisionViewModel(router: router, thumbnailUseCase: MockThumbnailUseCase(), nameCollisionUseCase: nameCollisionUseCase, fileVersionsUseCase: MockFileVersionsUseCase(), accountUseCase: MockAccountUseCase(), transfers: nil, nodes: nil, collisions: nameCollisions, collisionType: .move)
        viewModel.checkNameCollisions()
        if XCTWaiter.wait(for: [expectation(description: "Wait for response")], timeout: 0.5) == .timedOut {
            XCTAssert(router.showCopyOrMoveSuccess_calledTimes == 1)
        } else {
            XCTFail("Expected to time out!")
        }
    }
    
    @MainActor
    func testAction_moveWithoutNameCollisionsFail() {
        let router = MockNameCollisionRouter()
        let nameCollisionUseCase = MockNameCollisionUseCase(nameCollisions: nameCollisions)
        
        let viewModel = NameCollisionViewModel(router: router, thumbnailUseCase: MockThumbnailUseCase(), nameCollisionUseCase: nameCollisionUseCase, fileVersionsUseCase: MockFileVersionsUseCase(), accountUseCase: MockAccountUseCase(), transfers: nil, nodes: nil, collisions: nameCollisions, collisionType: .move)
        viewModel.checkNameCollisions()
        if XCTWaiter.wait(for: [expectation(description: "Wait for response")], timeout: 0.5) == .timedOut {
            XCTAssert(router.showCopyOrMoveError_calledTimes == 1)
        } else {
            XCTFail("Expected to time out!")
        }
    }
    
    @MainActor
    func testAction_uploadWithoutNameCollisionsSuccess() {
        let router = MockNameCollisionRouter()
        let nameCollisionUseCase = MockNameCollisionUseCase(nameCollisions: nameCollisions, copiedNodes: copyMoveHandles)
        
        let viewModel = NameCollisionViewModel(router: router, thumbnailUseCase: MockThumbnailUseCase(), nameCollisionUseCase: nameCollisionUseCase, fileVersionsUseCase: MockFileVersionsUseCase(), accountUseCase: MockAccountUseCase(), transfers: nil, nodes: nil, collisions: nameCollisions, collisionType: .upload)
        viewModel.checkNameCollisions()
        if XCTWaiter.wait(for: [expectation(description: "Wait for response")], timeout: 0.5) == .timedOut {
            XCTAssert(router.resolvedUploadCollisions_calledTimes == 1)
        } else {
            XCTFail("Expected to time out!")
        }
    }
}

final class MockNameCollisionRouter: NameCollisionViewRouting {
    
    var showNameCollisionsView_calledTimes = 0
    var resolvedUploadCollisions_calledTimes = 0
    var dismiss_calledTimes = 0
    var showCopyOrMoveSuccess_calledTimes = 0
    var showCopyOrMoveError_calledTimes = 0
    var showProgressIndicator_calledTimes = 0

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
        showCopyOrMoveSuccess_calledTimes += 1
    }
    
    func showProgressIndicator() {
        showProgressIndicator_calledTimes += 1
    }
    
    func showCopyOrMove(error: (any Error)?) async {
        showCopyOrMoveError_calledTimes += 1
    }
}
