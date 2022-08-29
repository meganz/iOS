import XCTest

final class UIMenuTests: XCTestCase {
    
    func testCompareMenuWhere_BothAreNil() {
        XCTAssertTrue(UIMenu.compareMenuItem(nil, nil))
    }
    
    func testCompareMenuWhere_EitherAreNil() {
        let menuItem = UIMenu(title: "UIMenu.ItemA", image: nil, options: .displayInline, children: [])
        XCTAssertFalse(UIMenu.compareMenuItem(nil, menuItem))
        XCTAssertFalse(UIMenu.compareMenuItem(menuItem, nil))
    }
    
    func testCompareMenuWhere_BothHaveSameData() {
        let menuItemA = UIMenu(title: "UIMenu.ItemA", image: nil, options: .displayInline, children: [])
        let menuItemB = UIMenu(title: "UIMenu.ItemA", image: nil, options: .displayInline, children: [])
        XCTAssertTrue(UIMenu.compareMenuItem(menuItemA, menuItemB))
    }
    
    func testCompareMenuWith_DifferentTitle() {
        let menuItemA = UIMenu(title: "UIMenu.ItemA", image: nil, options: .displayInline, children: [])
        let menuItemB = UIMenu(title: "UIMenu.ItemB", image: nil, options: .displayInline, children: [])
        XCTAssertFalse(UIMenu.compareMenuItem(menuItemA, menuItemB))
    }
    
    func testCompareMenuWith_DifferentImage() {
        let menuItemA = UIMenu(title: "UIMenu.ItemA", image: nil, options: .displayInline, children: [])
        let menuItemB = UIMenu(title: "UIMenu.ItemB", image: UIImage(), options: .displayInline, children: [])
        XCTAssertFalse(UIMenu.compareMenuItem(menuItemA, menuItemB))
    }
    
    func testCompareMenuWith_DifferentDisplayOptions() {
        let menuItemA = UIMenu(title: "UIMenu.ItemA", image: nil, options: .displayInline, children: [])
        let menuItemB = UIMenu(title: "UIMenu.ItemB", image: UIImage(), options: .destructive, children: [])
        XCTAssertFalse(UIMenu.compareMenuItem(menuItemA, menuItemB))
    }
    
    func testCompareMenuWith_DifferentChildren() {
        let action = UIAction(title: "", attributes: .hidden, state: .on) { _ in }
        let menuItemA = UIMenu(title: "UIMenu.ItemA", image: nil, options: .displayInline, children: [])
        let menuItemB = UIMenu(title: "UIMenu.ItemA", image: nil, options: .displayInline, children: [action])
        XCTAssertFalse(UIMenu.compareMenuItem(menuItemA, menuItemB))
    }
    
    func testCompareMenuWith_SameChildren() {
        let action = UIAction(title: "", attributes: .hidden, state: .on) { _ in }
        let menuItemA = UIMenu(title: "UIMenu.ItemA", image: nil, options: .displayInline, children: [action])
        let menuItemB = UIMenu(title: "UIMenu.ItemA", image: nil, options: .displayInline, children: [action])
        XCTAssertTrue(UIMenu.compareMenuItem(menuItemA, menuItemB))
    }
}
