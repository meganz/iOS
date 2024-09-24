@testable @preconcurrency import PhotosBrowser

@preconcurrency import MEGAPresentation
import MEGATest
import Testing

struct ToolbarConfigurationFactoryTests {
    
    @Test("New Photos Browser Bottom Tool Bar Configuration Tests", arguments: [
        PhotosBrowserDisplayMode.cloudDrive: CloudDriveToolbarConfigurationStrategy.self,
        PhotosBrowserDisplayMode.chatAttachment: ChatAttachmenToolbarConfigurationStrategy.self,
        PhotosBrowserDisplayMode.fileLink: CloudDriveToolbarConfigurationStrategy.self
    ])
    func testNavigationConfig(with displayMode: PhotosBrowserDisplayMode, strategy: ToolbarConfigurationStrategy.Type) {
        let config = ToolbarConfigurationFactory.configuration(on: displayMode)
        #expect(type(of: config) == strategy)
    }
}
