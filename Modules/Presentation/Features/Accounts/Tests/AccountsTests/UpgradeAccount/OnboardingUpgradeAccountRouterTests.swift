@testable import Accounts
import MEGADomainMock
import MEGAPresentation
import SwiftUI
import XCTest

final class OnboardingUpgradeAccountRouterTests: XCTestCase {

    @MainActor
    func testBuild_variantA_shouldBeOnboardingWithViewProPlansView() {
        let sut = makeSUT(onboardingVariant: .variantA)
        
        let viewController = sut.build()
        
        XCTAssertNotNil(viewController)
        XCTAssert(viewController is UIHostingController<OnboardingWithViewProPlansView>)
    }
    
    @MainActor
    func testBuild_variantB_shouldBeOnboardingWithViewProPlansView() {
        let sut = makeSUT(onboardingVariant: .variantB)
        
        let viewController = sut.build()
        
        XCTAssertNotNil(viewController)
        XCTAssert(viewController is UIHostingController<OnboardingWithProPlanListView>)
    }
    
    @MainActor
    func testBuild_baseline_shouldReturnNil() {
        let sut = makeSUT(onboardingVariant: .baseline)
        
        XCTAssertNil(sut.build())
    }

    @MainActor
    func makeSUT(
        onboardingVariant: ABTestVariant,
        isAdsEnabled: Bool = false,
        baseStorage: Int = 20,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> OnboardingUpgradeAccountRouter {
        
        let accountsConfig = AccountsConfig.OnboardingViewAssets(
            primaryTextColor: .white,
            primaryGrayTextColor: .white,
            secondaryTextColor: .white,
            subMessageBackgroundColor: .white,
            headerForegroundSelectedColor: .white,
            headerForegroundUnSelectedColor: .white,
            headerBackgroundColor: .white,
            headerStrokeColor: .white,
            backgroundColor: .white,
            currentPlanTagColor: .white,
            recommendedPlanTagColor: .white
        )
        let sut = OnboardingUpgradeAccountRouter(
            purchaseUseCase: MockAccountPlanPurchaseUseCase(),
            accountUseCase: MockAccountUseCase(),
            onboardingABvariant: onboardingVariant,
            accountsConfig: AccountsConfig(onboardingViewAssets: accountsConfig),
            isAdsEnabled: isAdsEnabled, 
            baseStorage: baseStorage, 
            viewProPlanAction: {}
        )
        
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}
