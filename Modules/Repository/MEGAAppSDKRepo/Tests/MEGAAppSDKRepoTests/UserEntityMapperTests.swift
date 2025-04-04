import MEGAAppSDKRepoMock
import MEGADomain
import MEGASdk
import XCTest

final class UserEntityMapperTests: XCTestCase {
    
    func testVisibilityMapper() {
        let sut: [MEGAUserVisibility] = [
            .unknown,
            .hidden,
            .visible,
            .inactive,
            .blocked
        ]
        
        for visibility in sut {
            let entity = visibility.toVisibilityEntity()
            switch visibility {
            case .unknown:
                XCTAssertEqual(entity, .unknown)
            case .hidden:
                XCTAssertEqual(entity, .hidden)
            case .visible:
                XCTAssertEqual(entity, .visible)
            case .inactive:
                XCTAssertEqual(entity, .inactive)
            case .blocked:
                XCTAssertEqual(entity, .blocked)
            @unknown default:
                XCTFail("Please map the new \(type(of: MEGAUserVisibility.self)) to \(type(of: UserEntity.self)).\(type(of: UserEntity.VisibilityEntity.self))")
            }
        }
    }
    
    func testUserEntityMapper_externalChange() {
        let user = MockUser(handle: 0, visibility: .unknown, email: "test@mega.nz", changes: .unshareableKey, isOwnChange: 0, addedDate: Date())
        
        let entity = user.toUserEntity()
        XCTAssertEqual(entity.changeSource, .externalChange)
        XCTAssertEqual(entity.changes, .unshareableKey)
        XCTAssertEqual(entity.visibility, .unknown)
    }
    
    func testUserEntityMapper_explicitRequest() {
        let user = MockUser(handle: 0, visibility: .blocked, email: "test@mega.nz", changes: .pubKeyEd255, isOwnChange: 1, addedDate: Date())
        
        let entity = user.toUserEntity()
        XCTAssertEqual(entity.changeSource, .explicitRequest)
        XCTAssertEqual(entity.changes, .publicKeyForSigning)
        XCTAssertEqual(entity.visibility, .blocked)
    }
    
    func testUserEntityMapper_implicitRequest() {
        let user = MockUser(handle: 0, visibility: .visible, email: "test@mega.nz", changes: .cameraUploadsFolder, isOwnChange: -10, addedDate: Date())
        
        let entity = user.toUserEntity()
        XCTAssertEqual(entity.changeSource, .implicitRequest)
        XCTAssertEqual(entity.changes, .cameraUploadsFolder)
        XCTAssertEqual(entity.visibility, .visible)
    }
}
