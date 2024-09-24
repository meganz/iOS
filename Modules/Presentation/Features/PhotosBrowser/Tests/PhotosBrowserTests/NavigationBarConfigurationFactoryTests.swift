@testable @preconcurrency import PhotosBrowser

@preconcurrency import MEGAPresentation
import MEGATest
import Testing

struct NavigationBarConfigurationFactoryTests {
    
    @Test("New Photos Browser Navigation Bar Configuration Tests", arguments: [
        PhotosBrowserDisplayMode.cloudDrive: CloudDriveNavigationBarConfigurationStrategy.self,
        PhotosBrowserDisplayMode.chatAttachment: ChatAttachmentNavigationBarConfigurationStrategy.self,
        PhotosBrowserDisplayMode.fileLink: CloudDriveNavigationBarConfigurationStrategy.self
    ])
    func testNavigationConfig(with displayMode: PhotosBrowserDisplayMode, strategy: NavigationBarConfigurationStrategy.Type) {
        let config = NavigationBarConfigurationFactory.configuration(on: displayMode)
        #expect(type(of: config) == strategy)
    }
}
