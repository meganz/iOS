import XCTest
@testable import MEGA

final class GetLinkSwitchOptionCellViewModelTests: XCTestCase {
    func testDispatch_onViewReady_shouldConfigureView() {
        let viewConfig = GetLinkSwitchCellViewConfiguration(title: "Test")
        let sut = GetLinkSwitchOptionCellViewModel(type: .decryptKeySeparate, configuration: viewConfig)
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .configView(viewConfig)
        ])
    }
    
    func testDispatch_onSwitchToggled_shouldUpdateSwitchValue() {
        let expectedValue = true
        let sut = GetLinkSwitchOptionCellViewModel(type: .decryptKeySeparate, configuration: GetLinkSwitchCellViewConfiguration(title: "Test"))
        test(viewModel: sut, action: .onSwitchToggled(isOn: expectedValue), expectedCommands: [
            .updateSwitch(isOn: expectedValue)
        ])
    }
}
