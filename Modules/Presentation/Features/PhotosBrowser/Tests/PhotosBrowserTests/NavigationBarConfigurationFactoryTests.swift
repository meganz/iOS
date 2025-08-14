@preconcurrency import MEGAAppPresentation
import MEGATest
@testable @preconcurrency import PhotosBrowser
import Testing

@MainActor
struct NavigationBarConfigurationFactoryTests {
    
    static let arguments: [PhotosBrowserDisplayMode: any NavigationBarConfigurationStrategy.Type] = [
        PhotosBrowserDisplayMode.cloudDrive: CloudDriveNavigationBarConfigurationStrategy.self,
        PhotosBrowserDisplayMode.chatAttachment: ChatAttachmentNavigationBarConfigurationStrategy.self
    ]
    
    @Test
    func whenCloudDriveMode_shouldUseCloudDriveNavigationBarConfigurationStrategy() {
        let config = NavigationBarConfigurationFactory.configuration(on: .cloudDrive)
        #expect(type(of: config) == CloudDriveNavigationBarConfigurationStrategy.self)
    }
    
    @Test
    func whenChatAttachmentMode_shouldUseChatAttachmentNavigationBarConfigurationStrategy() {
        let config = NavigationBarConfigurationFactory.configuration(on: .chatAttachment)
        #expect(type(of: config) == ChatAttachmentNavigationBarConfigurationStrategy.self)
    }
}
