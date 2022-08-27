import XCTest

final class UIMenuElementTests: XCTestCase {
    
    func testCompareUIMenuElementWith_SameData() {
        let actionA = UIAction(title: "UIAction.A.Title", image: nil, attributes: .hidden) { _ in }
        let actionB = UIAction(title: "UIAction.A.Title", image: nil, attributes: .hidden) { _ in }
        XCTAssertTrue(actionA.compare(actionB))
    }
    
    func testCompareUIMenuElementWith_DifferentTitle() {
        let actionA = UIAction(title: "UIAction.A.Title", image: nil, attributes: .hidden) { _ in }
        let actionB = UIAction(title: "UIAction.B.Title", image: nil, attributes: .hidden) { _ in }
        XCTAssertFalse(actionA.compare(actionB))
    }
    
    func testCompareUIMenuElementWith_DifferentImage() {
        let actionA = UIAction(title: "UIAction.A.Title", image: nil, attributes: .hidden) { _ in }
        let actionB = UIAction(title: "UIAction.B.Title", image: UIImage(), attributes: .hidden) { _ in }
        XCTAssertFalse(actionA.compare(actionB))
    }
    
    func testCompareUIMenuElementWith_DifferentAttribute() {
        let actionA = UIAction(title: "UIAction.A.Title", image: nil, attributes: .hidden) { _ in }
        let actionB = UIAction(title: "UIAction.B.Title", image: UIImage(), attributes: .destructive) { _ in }
        XCTAssertFalse(actionA.compare(actionB))
    }
    
    func testCompareUIMenuElementWith_SameSubtitle() throws {
        guard #available(iOS 15.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }
        let actionA = UIAction(title: "UIAction.A.Title", subtitle: "UIAction.A.Subtitle",image: nil, attributes: .hidden) { _ in }
        let actionB = UIAction(title: "UIAction.A.Title", subtitle: "UIAction.A.Subtitle",image: nil, attributes: .hidden) { _ in }
        XCTAssertTrue(actionA.compare(actionB))
    }
    
    func testCompareUIMenuElementWith_DifferentSubtitle() throws {
        guard #available(iOS 15.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }
        let actionA = UIAction(title: "UIAction.A.Title", subtitle: "UIAction.A.Subtitle",image: nil, attributes: .hidden) { _ in }
        let actionB = UIAction(title: "UIAction.A.Title", subtitle: "",image: nil, attributes: .hidden, state: .on) { _ in }
        XCTAssertFalse(actionA.compare(actionB))
    }
}
