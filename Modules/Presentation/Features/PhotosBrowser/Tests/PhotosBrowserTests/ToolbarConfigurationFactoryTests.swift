@preconcurrency import MEGAAppPresentation
import MEGATest
@testable @preconcurrency import PhotosBrowser
import Testing

struct ToolbarConfigurationFactoryTests {
    
    static let arguments: [PhotosBrowserDisplayMode: any ToolbarConfigurationStrategy.Type] = [
        PhotosBrowserDisplayMode.cloudDrive: CloudDriveToolbarConfigurationStrategy.self,
        PhotosBrowserDisplayMode.chatAttachment: ChatAttachmenToolbarConfigurationStrategy.self
    ]
    
    @Test("New Photos Browser Bottom Tool Bar Configuration Tests", arguments: arguments)
    func bottomToolBarConfig(with displayMode: PhotosBrowserDisplayMode, strategy: any ToolbarConfigurationStrategy.Type) {
        let config = ToolbarConfigurationFactory.configuration(on: displayMode)
        #expect(type(of: config) == strategy)
    }
}
