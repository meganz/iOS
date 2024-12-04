import MEGASwift
@testable import MEGAUIKit
import Testing
import UIKit

@MainActor
struct UIActionTests {
    
    @Test
    func testCompareUIActionWith_sameData_equal() {
        let actionA = UIAction(title: "UIAction.A.Title", image: nil, identifier: UIAction.Identifier("UIAction.A"), attributes: .hidden, state: .on) { _ in }
        let actionB = UIAction(title: "UIAction.A.Title", image: nil, identifier: UIAction.Identifier("UIAction.A"), attributes: .hidden, state: .on) { _ in }
        #expect((actionA ~~ actionB) == true)
    }
    
    @Test
    func testCompareUIActionWith_differentState_notEqual() {
        let actionA = UIAction(title: "UIAction.A.Title", image: nil, identifier: UIAction.Identifier("UIAction.A"), attributes: .hidden, state: .on) { _ in }
        let actionB = UIAction(title: "UIAction.A.Title", image: nil, identifier: UIAction.Identifier("UIAction.A"), attributes: .hidden, state: .off) { _ in }
        #expect((actionA ~~ actionB) == false)
    }
    
    @Test
    func testCompareUIActionWith_differentTitle_notEqual() {
        let actionA = UIAction(title: "UIAction.A.Title", image: nil, attributes: .hidden) { _ in }
        let actionB = UIAction(title: "UIAction.B.Title", image: nil, attributes: .hidden) { _ in }
        #expect((actionA ~~ actionB) == false)
    }
    
    @Test
    func testCompareUIActionWith_differentImage_notEqual() {
        let actionA = UIAction(title: "UIAction.A.Title", image: nil, attributes: .hidden) { _ in }
        let actionB = UIAction(title: "UIAction.B.Title", image: UIImage(), attributes: .hidden) { _ in }
        #expect((actionA ~~ actionB) == false)
    }
    
    @Test
    func testCompareUIActionWith_differentAttribute_notEqual() {
        let actionA = UIAction(title: "UIAction.A.Title", image: nil, attributes: .hidden) { _ in }
        let actionB = UIAction(title: "UIAction.B.Title", image: UIImage(), attributes: .destructive) { _ in }
        #expect((actionA ~~ actionB) == false)
    }
    
    @Test
    func testCompareUIActionWith_differentSubtitle_notEqual() throws {
        let actionA = UIAction(title: "UIAction.A.Title", subtitle: "UIAction.A.Subtitle", image: nil, attributes: .hidden) { _ in }
        let actionB = UIAction(title: "UIAction.A.Title", subtitle: "UIAction.B.Subtitle", image: nil, attributes: .hidden, state: .on) { _ in }
        #expect((actionA ~~ actionB) == false)
    }
}
