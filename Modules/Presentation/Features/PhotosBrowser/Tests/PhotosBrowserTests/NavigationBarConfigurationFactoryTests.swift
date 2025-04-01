@preconcurrency import MEGAAppPresentation
import MEGATest
@testable @preconcurrency import PhotosBrowser
import Testing

struct NavigationBarConfigurationFactoryTests {
    
    static let arguments: [PhotosBrowserDisplayMode: NavigationBarConfigurationStrategy.Type] = [
        PhotosBrowserDisplayMode.cloudDrive: CloudDriveNavigationBarConfigurationStrategy.self,
        PhotosBrowserDisplayMode.chatAttachment: ChatAttachmentNavigationBarConfigurationStrategy.self
    ]
    
    @Test("New Photos Browser Navigation Bar Configuration Tests", arguments: arguments)
    func navigationBarConfig(with displayMode: PhotosBrowserDisplayMode, strategy: NavigationBarConfigurationStrategy.Type) {
        let config = NavigationBarConfigurationFactory.configuration(on: displayMode)
        #expect(type(of: config) == strategy)
    }
}
