
import XCTest
@testable import MEGA

class MEGAavatarGeneratingUseCase: XCTestCase {
    
    // MARK: - Generate Avatar Image
    
    func testUnableGenerateAvatarImage_WhenUserIsNil() {
        let useCaseUT = MEGAAavatarGeneratingUseCase(
            storeUserClient: .foundAUser,
            megaAvatarClient: .foundImage,
            megaUserClient: .foundNil
        )
        let avatarName = useCaseUT.avatarName()
        XCTAssertNil(avatarName)

        let backgroundColor = useCaseUT.avatarBackgroundColorHex()
        XCTAssertNil(backgroundColor)
    }


    func testUnableGenerateAvatarImage_WhenStoreUserIsNil() {
        let useCaseUT = MEGAAavatarGeneratingUseCase(
            storeUserClient: .foundNil,
            megaAvatarClient: .foundImage,
            megaUserClient: .foundUser
        )
        let avatarName = useCaseUT.avatarName()
        XCTAssertNil(avatarName)
    }

    func testSuccessGenerateAvatarImage_WhenSatisfied() {
        let useCaseUT = MEGAAavatarGeneratingUseCase(
            storeUserClient: .foundAUser,
            megaAvatarClient: .foundImage,
            megaUserClient: .foundUser
        )

        let avatarName = useCaseUT.avatarName()
        XCTAssertNotNil(avatarName)

        let backgroundColor = useCaseUT.avatarBackgroundColorHex()
        XCTAssertNotNil(backgroundColor)
    }
}
