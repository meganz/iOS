@testable import Accounts
import SwiftUI
import Testing

@MainActor
@Suite("App loading router tests")
struct AppLoadingViewRouterTests {
    
    @Test("Test init with completion")
    func testInitWithCompletion() async {
        await confirmation { confirm in
            let router = AppLoadingViewRouter {
                confirm()
            }
            
            router.appLoadComplete?()
        }
    }
    
    @Test("Test init without completion")
    func testInitWithoutCompletion() {
        let router = AppLoadingViewRouter()
        #expect(router.appLoadComplete == nil)
    }
    
    @MainActor
    @Test("Test build")
    func testBuild() {
        let router = AppLoadingViewRouter()
        let viewController = router.build()
        
        #expect(viewController is UIHostingController<AppLoadingView>)
    }
}
