import XCTest
import MEGASwift
@testable import MEGAUIKit

final class UIMenuTests: XCTestCase {
    
    func testCompareMenuWhere_EitherAreNil() {
        let menuItemA:UIMenu? = UIMenu(title: "UIMenu.ItemA", image: nil, options: .displayInline, children: [])
        let menuItemB:UIMenu? = nil
        XCTAssertFalse(menuItemA ~~ menuItemB)
        XCTAssertFalse(menuItemB ~~ menuItemA)
    }
    
    func testCompareMenuWhere_BothHaveSameData() {
        let menuItemA = UIMenu(title: "UIMenu.ItemA", image: nil, options: .displayInline, children: [])
        let menuItemB = UIMenu(title: "UIMenu.ItemA", image: nil, options: .displayInline, children: [])
        XCTAssertTrue(menuItemA ~~ menuItemB)
    }
    
    func testCompareMenuWith_DifferentTitle() {
        let menuItemA = UIMenu(title: "UIMenu.ItemA", image: nil, options: .displayInline, children: [])
        let menuItemB = UIMenu(title: "UIMenu.ItemB", image: nil, options: .displayInline, children: [])
        XCTAssertFalse(menuItemA ~~ menuItemB)
    }
    
    func testCompareMenuWith_DifferentImage() {
        let menuItemA = UIMenu(title: "UIMenu.ItemA", image: nil, options: .displayInline, children: [])
        let menuItemB = UIMenu(title: "UIMenu.ItemB", image: UIImage(), options: .displayInline, children: [])
        XCTAssertFalse(menuItemA ~~ menuItemB)
    }
    
    func testCompareMenuWith_DifferentDisplayOptions() {
        let menuItemA = UIMenu(title: "UIMenu.ItemA", image: nil, options: .displayInline, children: [])
        let menuItemB = UIMenu(title: "UIMenu.ItemB", image: UIImage(), options: .destructive, children: [])
        XCTAssertFalse(menuItemA ~~ menuItemB)
    }
    
    func testCompareMenuWith_DifferentChildren() {
        let action = UIAction(title: "", attributes: .hidden, state: .on) { _ in }
        let menuItemA = UIMenu(title: "UIMenu.ItemA", image: nil, options: .displayInline, children: [])
        let menuItemB = UIMenu(title: "UIMenu.ItemA", image: nil, options: .displayInline, children: [action])
        XCTAssertFalse(menuItemA ~~ menuItemB)
    }
    
    func testCompareMenuWith_SameChildren() {
        let action = UIAction(title: "", attributes: .hidden, state: .on) { _ in }
        let menuItemA = UIMenu(title: "UIMenu.ItemA", image: nil, options: .displayInline, children: [action])
        let menuItemB = UIMenu(title: "UIMenu.ItemA", image: nil, options: .displayInline, children: [action])
        XCTAssertTrue(menuItemA ~~ menuItemB)
    }
}
