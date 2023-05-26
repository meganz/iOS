import XCTest
import MEGADomain
import MEGADomainMock


final class UserAttributeUseCaseTest: XCTestCase {
    func testUserAttribute_UpdateUserName() async throws {
        let repo = MockUserAttributeRepository()
        let sut = UserAttributeUseCase(repo: repo)
        
        try await sut.updateUserAttribute(.firstName, value: "First Name")
        try await sut.updateUserAttribute(.lastName, value: "Last Name")
        
        XCTAssertEqual(repo.userAttributes[.firstName], "First Name")
        XCTAssertEqual(repo.userAttributes[.lastName], "Last Name")
    }
}
