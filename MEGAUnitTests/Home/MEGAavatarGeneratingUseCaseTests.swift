@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

class MEGAavatarGeneratingUseCase: XCTestCase {
    
    // MARK: - Generate Avatar Image
    
    func testUnableGenerateAvatarImage_WhenUserIsNil() {
        let useCaseUT = MEGAAavatarGeneratingUseCase(
            storeUserClient: .foundAUser,
            megaAvatarClient: .foundImage,
            accountUseCase: MockAccountUseCase(currentUser: nil)
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
            accountUseCase: MockAccountUseCase()
        )
        let avatarName = useCaseUT.avatarName()
        XCTAssertNil(avatarName)
    }

    func testSuccessGenerateAvatarImage_WhenSatisfied() {
        let useCaseUT = MEGAAavatarGeneratingUseCase(
            storeUserClient: .foundAUser,
            megaAvatarClient: .foundImage,
            accountUseCase: MockAccountUseCase()
        )

        let avatarName = useCaseUT.avatarName()
        XCTAssertNotNil(avatarName)

        let backgroundColor = useCaseUT.avatarBackgroundColorHex()
        XCTAssertNotNil(backgroundColor)
    }
}
