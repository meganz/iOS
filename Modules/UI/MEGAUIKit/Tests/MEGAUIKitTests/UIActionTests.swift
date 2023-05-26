import XCTest
import MEGASwift
@testable import MEGAUIKit

final class UIActionTests: XCTestCase {
    
    func testCompareUIActionWith_sameData_equal() {
        let actionA = UIAction(title: "UIAction.A.Title", image: nil, identifier: UIAction.Identifier("UIAction.A"), attributes: .hidden, state: .on) { _ in }
        let actionB = UIAction(title: "UIAction.A.Title", image: nil, identifier: UIAction.Identifier("UIAction.A"), attributes: .hidden, state: .on) { _ in }
        XCTAssertTrue(actionA ~~ actionB)
    }
    
    func testCompareUIActionWith_differentState_notEqual() {
        let actionA = UIAction(title: "UIAction.A.Title", image: nil, identifier: UIAction.Identifier("UIAction.A"), attributes: .hidden, state: .on) { _ in }
        let actionB = UIAction(title: "UIAction.A.Title", image: nil, identifier: UIAction.Identifier("UIAction.A"), attributes: .hidden, state: .off) { _ in }
        XCTAssertFalse(actionA ~~ actionB)
    }
    
    func testCompareUIActionWith_differentTitle_notEqual() {
        let actionA = UIAction(title: "UIAction.A.Title", image: nil, attributes: .hidden) { _ in }
        let actionB = UIAction(title: "UIAction.B.Title", image: nil, attributes: .hidden) { _ in }
        XCTAssertFalse(actionA ~~ actionB)
    }
    
    func testCompareUIActionWith_differentImage_notEqual() {
        let actionA = UIAction(title: "UIAction.A.Title", image: nil, attributes: .hidden) { _ in }
        let actionB = UIAction(title: "UIAction.B.Title", image: UIImage(), attributes: .hidden) { _ in }
        XCTAssertFalse(actionA ~~ actionB)
    }
    
    func testCompareUIActionWith_differentAttribute_notEqual() {
        let actionA = UIAction(title: "UIAction.A.Title", image: nil, attributes: .hidden) { _ in }
        let actionB = UIAction(title: "UIAction.B.Title", image: UIImage(), attributes: .destructive) { _ in }
        XCTAssertFalse(actionA ~~ actionB)
    }
    
    func testCompareUIActionWith_differentSubtitle_notEqual() throws {
        guard #available(iOS 15.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }
        let actionA = UIAction(title: "UIAction.A.Title", subtitle: "UIAction.A.Subtitle", image: nil, attributes: .hidden) { _ in }
        let actionB = UIAction(title: "UIAction.A.Title", subtitle: "UIAction.B.Subtitle", image: nil, attributes: .hidden, state: .on) { _ in }
        XCTAssertFalse(actionA ~~ actionB)
    }
}
