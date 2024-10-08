@testable import MEGA
import MEGADomain
import MEGADomainMock
import Testing

@Suite("NodeTagsCellViewModel Tests")
struct NodeTagsCellViewModelTests {
    @Test("Check if the user is a pro user", arguments: [true, false])
    func isProUser(hasValidProOrUnexpiredBusinessAccount: Bool) {
        let sut = makeSUT(
            hasValidProOrUnexpiredBusinessAccount: hasValidProOrUnexpiredBusinessAccount
        )
        #expect(sut.isProUser == hasValidProOrUnexpiredBusinessAccount)
    }

    private func makeSUT(
        hasValidProOrUnexpiredBusinessAccount: Bool = false
    ) -> NodeTagsCellViewModel {
        let accountUseCase = MockAccountUseCase(
            hasValidProOrUnexpiredBusinessAccount: hasValidProOrUnexpiredBusinessAccount
        )
        return NodeTagsCellViewModel(accountUseCase: accountUseCase)
    }
}
