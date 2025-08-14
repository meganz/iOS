@preconcurrency import MEGAAppPresentation
import MEGATest
@testable @preconcurrency import PhotosBrowser
import Testing

@MainActor
struct ToolbarConfigurationFactoryTests {
    
    static let arguments: [PhotosBrowserDisplayMode: any ToolbarConfigurationStrategy.Type] = [
        PhotosBrowserDisplayMode.cloudDrive: CloudDriveToolbarConfigurationStrategy.self,
        PhotosBrowserDisplayMode.chatAttachment: ChatAttachmenToolbarConfigurationStrategy.self
    ]
    
    @Test
    func whenCloudDriveMode_shouldUseCloudDriveToolbarConfigurationStrategy() {
        let config = ToolbarConfigurationFactory.configuration(on: .cloudDrive)
        #expect(type(of: config) == CloudDriveToolbarConfigurationStrategy.self)
    }
    
    @Test
    func whenChatAttachmentMode_shouldUseChatAttachmenToolbarConfigurationStrategy() {
        let config = ToolbarConfigurationFactory.configuration(on: .chatAttachment)
        #expect(type(of: config) == ChatAttachmenToolbarConfigurationStrategy.self)
    }
}
