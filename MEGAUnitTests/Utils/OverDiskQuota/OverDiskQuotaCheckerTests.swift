@testable import MEGA
import MEGADomain
import MEGADomainMock
import Testing

struct OverDiskQuotaCheckerTests {
    @Test("ensure over disk quota is shown when paywalled",
          arguments: [true, false]
    )
    @MainActor
    func overDiskQuotaShown(isPaywalled: Bool) async throws {
        let appDelegateRouter = MockAppDelegateRouter()
        let accountStorageUseCase = MockAccountStorageUseCase(isPaywalled: isPaywalled)
        let sut = OverDiskQuotaCheckerTests
            .makeSUT(
                accountStorageUseCase: accountStorageUseCase,
                appDelegateRouter: appDelegateRouter
            )
        
        #expect(sut.showOverDiskQuotaIfNeeded() == isPaywalled)
        #expect(appDelegateRouter.showOverDiskQuotaCalled == (isPaywalled ? 1 : 0))
    }
    
    @MainActor
    private static func makeSUT(
        accountStorageUseCase: some AccountStorageUseCaseProtocol = MockAccountStorageUseCase(),
        appDelegateRouter: some AppDelegateRouting = MockAppDelegateRouter()
    ) -> OverDiskQuotaChecker {
        .init(
            accountStorageUseCase: accountStorageUseCase,
            appDelegateRouter: appDelegateRouter)
    }
}
