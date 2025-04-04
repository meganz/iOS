import MEGAAppSDKRepo
import MEGASdk
import XCTest

final class BackUpStateEntityMappingTests: XCTestCase {
    
    func testBackUpStateEntity_OnUpdateState_shouldReturnCorrectMapping() {
        let sut: [BackUpState] = [.invalid, .notInitialized, .active, .failed, .temporaryDisabled, .disabled, .pauseUp, .pauseDown, .pauseFull, .deleted, .unknown]
        
        for type in sut {
            switch type {
            case .invalid: XCTAssertEqual(type.toBackUpStateEntity(), .invalid)
            case .notInitialized: XCTAssertEqual(type.toBackUpStateEntity(), .notInitialized)
            case .active: XCTAssertEqual(type.toBackUpStateEntity(), .active)
            case .failed: XCTAssertEqual(type.toBackUpStateEntity(), .failed)
            case .temporaryDisabled: XCTAssertEqual(type.toBackUpStateEntity(), .temporaryDisabled)
            case .disabled: XCTAssertEqual(type.toBackUpStateEntity(), .disabled)
            case .pauseUp: XCTAssertEqual(type.toBackUpStateEntity(), .pauseUp)
            case .pauseDown: XCTAssertEqual(type.toBackUpStateEntity(), .pauseDown)
            case .pauseFull: XCTAssertEqual(type.toBackUpStateEntity(), .pauseFull)
            case .deleted: XCTAssertEqual(type.toBackUpStateEntity(), .deleted)
            case .unknown: XCTAssertEqual(type.toBackUpStateEntity(), .unknown)
            default: break
            }
        }
    }
}
