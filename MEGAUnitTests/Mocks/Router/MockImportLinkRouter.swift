@testable import MEGA

final class MockImportLinkRouter: ImportLinkRouting {
    private(set) var startCalled = 0
    private(set) var showNodeBrowserCalled = 0
    private(set) var showOnboardingCalled = 0
    
    nonisolated init () {}
    
    func start() {
        startCalled += 1
    }
    
    func showNodeBrowser() {
        showNodeBrowserCalled += 1
    }
    
    func showOnboarding() {
        showOnboardingCalled += 1
    }
}
