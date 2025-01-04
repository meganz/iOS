@testable import MEGA
import MEGAPresentation
import Testing

@MainActor
struct SettingCellViewModelTests {
    let sut: SettingCellViewModel = SettingCellViewModel(image: nil, title: "", isDestructive: Bool.random(), displayValue: "", router: nil)
    
    @Test
    func testUpdateDisplayValue() {
        #expect(sut.displayValue == "")
        #expect(sut.invokeCommand == nil)
        var value: Bool?
        sut.invokeCommand = { cmd in
            if cmd == .reloadData {
                value = true
            }
        }
        sut.updateDisplayValue("some updated display value")
        #expect(sut.displayValue == "some updated display value")
        #expect(value != nil)
    }

    @Test
    func testUpdateRouter() {
        #expect(sut.router == nil)
        sut.updateRouter(router: MockRouter())
        #expect(sut.router != nil)
    }
    
    private struct MockRouter: Routing {}
}
