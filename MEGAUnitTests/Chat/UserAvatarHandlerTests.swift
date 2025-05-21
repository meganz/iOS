@testable import MEGA
import MEGAAssets
import MEGADomainMock
import XCTest

class UserAvatarHandlerTests: XCTestCase {
    func testAvatar_whenAvatarPathExists_returnsImage() async throws {
        let userHandle = "testHandle"
        let userImageUseCase = MockUserImageUseCase(fetchAvatarResult: .success("/path/to/avatar.jpg"))
        let sut = makeSUT(userImageUseCase: userImageUseCase)
        
        let image = await sut.avatar(for: userHandle)
        
        XCTAssertNotNil(image)
    }
    
    func testAvatar_whenAvatarPathDoesNotExist_returnsPlaceholderImage() async {
        let userHandle = "testHandle"
        let userImageUseCase = MockUserImageUseCase()
        let sut = makeSUT(userImageUseCase: userImageUseCase)
        
        let image = await sut.avatar(for: userHandle)
        
        XCTAssertEqual(MEGAAssets.UIImage.iconContacts, image)
    }
    
    // MARK: - Private
    
    func makeSUT(userImageUseCase: MockUserImageUseCase) -> UserAvatarHandler {
        UserAvatarHandler(
            userImageUseCase: userImageUseCase,
            initials: "JD",
            avatarBackgroundColor: .blue
        )
    }
}
