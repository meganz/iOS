@testable import Accounts
import MEGADomainMock
import MEGAPresentation
import SwiftUI
import XCTest

final class OnboardingUpgradeAccountRouterTests: XCTestCase {

    func testBuild_variantA_shouldBeOnboardingWithViewProPlansView() {
        let sut = makeSUT(abTestVariant: .variantA)
        
        let viewController = sut.build()
        
        XCTAssertNotNil(viewController)
        XCTAssert(viewController is UIHostingController<OnboardingWithViewProPlansView>)
    }
    
    func testBuild_variantB_shouldBeOnboardingWithViewProPlansView() {
        let sut = makeSUT(abTestVariant: .variantB)
        
        let viewController = sut.build()
        
        XCTAssertNotNil(viewController)
        XCTAssert(viewController is UIHostingController<OnboardingWithProPlanListView>)
    }
    
    func testBuild_baseline_shouldReturnNil() {
        let sut = makeSUT(abTestVariant: .baseline)
        
        XCTAssertNil(sut.build())
    }

    func makeSUT(
        abTestVariant: ABTestVariant,
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
            onboardingABvariant: abTestVariant,
            accountsConfig: AccountsConfig(onboardingViewAssets: accountsConfig),
            viewProPlanAction: {}
        )
        
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}
