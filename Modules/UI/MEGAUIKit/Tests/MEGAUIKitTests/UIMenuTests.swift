import XCTest
import MEGASwift
@testable import MEGAUIKit

final class UIMenuTests: XCTestCase {
    var action1: UIAction!
    var action2: UIAction!
    
    override func setUp() {
        super.setUp()
        action1 = UIAction(title: "Action 1", handler: {_ in})
        action2 = UIAction(title: "Action 2", handler: {_ in})
    }
    
    func testCompareMenuWhere_EitherAreNil() {
        let menuItemA: UIMenu? = UIMenu(title: "UIMenu.ItemA", image: nil, options: .displayInline, children: [])
        let menuItemB: UIMenu? = nil
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
        let menuItemA = UIMenu(title: "UIMenu.ItemA", image: nil, options: .displayInline, children: [])
        let menuItemB = UIMenu(title: "UIMenu.ItemA", image: nil, options: .displayInline, children: [action1])
        XCTAssertFalse(menuItemA ~~ menuItemB)
    }
    
    func testCompareMenuWith_SameChildren() {
        let menuItemA = UIMenu(title: "UIMenu.ItemA", image: nil, options: .displayInline, children: [action1])
        let menuItemB = UIMenu(title: "UIMenu.ItemA", image: nil, options: .displayInline, children: [action1])
        XCTAssertTrue(menuItemA ~~ menuItemB)
    }
    
    func testDoMenuActionMatch_whenMenusAreIdentical_returnsTrue() {
        let menu = UIMenu(title: "Test Menu", children: [action1, action2])
        
        XCTAssertTrue(UIMenu.match(lhs: menu, rhs: menu))
    }
    
    func testDoMenuActionMatch_whenMenusAreDifferentButHaveSameActions_returnsTrue() {
        let oldMenu = UIMenu(title: "Old Menu", children: [action1, action2])
        let updatedMenu = UIMenu(title: "Updated Menu", children: [action1, action2])
        
        XCTAssertTrue(UIMenu.match(lhs: oldMenu, rhs: updatedMenu))
    }
    
    func testDoMenuActionMatch_whenMenusHaveDifferentActions_returnsFalse() {
        let oldMenu = UIMenu(title: "Old Menu", children: [action1])
        let updatedMenu = UIMenu(title: "Updated Menu", children: [action2])
    
        XCTAssertFalse(UIMenu.match(lhs: oldMenu, rhs: updatedMenu))
    }
    
    func testDoMenuActionMatch_whenMenusHaveSameActionsInDifferentOrder_returnsFalse() {
        let oldMenu = UIMenu(title: "Test Menu", children: [action1, action2])
        let updatedMenu = UIMenu(title: "Test Menu", children: [action2, action1])
        
        XCTAssertFalse(UIMenu.match(lhs: oldMenu, rhs: updatedMenu))
    }
    
    func testDoMenuActionMatch_whenMenusHaveSameActionsAndActionStates_returnsTrue() {
        let action1_ON = UIAction(title: "Action 1", state: .on, handler: {_ in})
        let action2_OFF = UIAction(title: "Action 2", state: .off, handler: {_ in})
        
        let oldMenu = UIMenu(title: "Test Menu", children: [action1_ON, action2_OFF])
        let updatedMenu = UIMenu(title: "Test Menu", children: [action1_ON, action2_OFF])
        
        XCTAssertTrue(UIMenu.match(lhs: oldMenu, rhs: updatedMenu))
    }
    
    func testDoMenuActionMatch_whenMenusAreDifferentButHaveSameActionsAndActionStates_returnsFalse() {
        let action1_ON = UIAction(title: "Action 1", state: .on, handler: {_ in})
        let action2_OFF = UIAction(title: "Action 2", state: .off, handler: {_ in})
        
        let oldMenu = UIMenu(title: "Old Menu", children: [action1_ON, action2_OFF])
        let updatedMenu = UIMenu(title: "Updated Menu", children: [action1_ON, action2_OFF])
        
        XCTAssertTrue(UIMenu.match(lhs: oldMenu, rhs: updatedMenu))
    }
    
    func testDoMenuActionMatch_whenMenusAreDifferentAndHaveSameActionsButDifferentActionStates_returnsFalse() {
        let action1_ON = UIAction(title: "Action 1", state: .on, handler: {_ in})
        let action1_OFF = UIAction(title: "Action 1", state: .off, handler: {_ in})
        let action2_ON = UIAction(title: "Action 2", state: .on, handler: {_ in})
        let action2_OFF = UIAction(title: "Action 2", state: .off, handler: {_ in})
        
        let oldMenu = UIMenu(title: "Old Menu", children: [action1_ON, action2_OFF])
        let updatedMenu = UIMenu(title: "Updated Menu", children: [action1_OFF, action2_ON])
        
        XCTAssertFalse(UIMenu.match(lhs: oldMenu, rhs: updatedMenu))
    }
    
    func testMatch_sameActionStates_returnsFalse() {
        let action1_ON = UIAction(title: "Action 1", state: .on, handler: {_ in})
        let menu1 = UIMenu(title: "Updated Menu", options: [], children: [action1_ON])
        let menu2 = UIMenu(title: "Updated Menu", options: [], children: [action1_ON])
        
        let result = UIMenu.match(lhs: menu1, rhs: menu2)
       
        XCTAssertTrue(result)
   }
    
    func testMatch_differentActionStates_returnsFalse() {
        let action1_ON = UIAction(title: "Action 1", state: .on, handler: {_ in})
        let menu1 = UIMenu(title: "Updated Menu", options: [], children: [action1_ON])
        let action1_OFF = UIAction(title: "Action 1", state: .off, handler: {_ in})
        let menu2 = UIMenu(title: "Updated Menu", options: [], children: [action1_OFF])
        
        let result = UIMenu.match(lhs: menu1, rhs: menu2)
       
        XCTAssertFalse(result)
   }
}
