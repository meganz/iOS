import MEGASwift
@testable import MEGAUIKit
import Testing
import UIKit

@MainActor
struct UIMenuTests {
    let action1 = UIAction(title: "Action 1", handler: {_ in})
    let action2 = UIAction(title: "Action 2", handler: {_ in})
    
    @Test
    func testCompareMenuWhere_EitherAreNil() {
        let menuItemA: UIMenu? = UIMenu(title: "UIMenu.ItemA", image: nil, options: .displayInline, children: [])
        let menuItemB: UIMenu? = nil
        #expect((menuItemA ~~ menuItemB) == false)
        #expect((menuItemB ~~ menuItemA) == false)
    }
    
    @Test
    func testCompareMenuWhere_BothHaveSameData() {
        let menuItemA = UIMenu(title: "UIMenu.ItemA", image: nil, options: .displayInline, children: [])
        let menuItemB = UIMenu(title: "UIMenu.ItemA", image: nil, options: .displayInline, children: [])
        #expect((menuItemA ~~ menuItemB) == true)
    }
    
    @Test
    func testCompareMenuWith_DifferentTitle() {
        let menuItemA = UIMenu(title: "UIMenu.ItemA", image: nil, options: .displayInline, children: [])
        let menuItemB = UIMenu(title: "UIMenu.ItemB", image: nil, options: .displayInline, children: [])
        #expect((menuItemA ~~ menuItemB) == false)
    }
    
    @Test
    func testCompareMenuWith_DifferentImage() {
        let menuItemA = UIMenu(title: "UIMenu.ItemA", image: nil, options: .displayInline, children: [])
        let menuItemB = UIMenu(title: "UIMenu.ItemB", image: UIImage(), options: .displayInline, children: [])
        #expect((menuItemA ~~ menuItemB) == false)
    }
    
    @Test
    func testCompareMenuWith_DifferentDisplayOptions() {
        let menuItemA = UIMenu(title: "UIMenu.ItemA", image: nil, options: .displayInline, children: [])
        let menuItemB = UIMenu(title: "UIMenu.ItemB", image: UIImage(), options: .destructive, children: [])
        #expect((menuItemA ~~ menuItemB) == false)
    }
    
    @Test
    func testCompareMenuWith_DifferentChildren() {
        let menuItemA = UIMenu(title: "UIMenu.ItemA", image: nil, options: .displayInline, children: [])
        let menuItemB = UIMenu(title: "UIMenu.ItemA", image: nil, options: .displayInline, children: [action1])
        #expect((menuItemA ~~ menuItemB) == false)
    }
    
    @Test
    func testCompareMenuWith_SameChildren() {
        let menuItemA = UIMenu(title: "UIMenu.ItemA", image: nil, options: .displayInline, children: [action1])
        let menuItemB = UIMenu(title: "UIMenu.ItemA", image: nil, options: .displayInline, children: [action1])
        #expect((menuItemA ~~ menuItemB) == true)
    }
    
    @Test
    func testDoMenuActionMatch_whenMenusAreIdentical_returnsTrue() {
        let menu = UIMenu(title: "Test Menu", children: [action1, action2])
        
        #expect(UIMenu.match(lhs: menu, rhs: menu) == true)
    }
    
    @Test
    func testDoMenuActionMatch_whenMenusAreDifferentButHaveSameActions_returnsTrue() {
        let oldMenu = UIMenu(title: "Old Menu", children: [action1, action2])
        let updatedMenu = UIMenu(title: "Updated Menu", children: [action1, action2])
        
        #expect(UIMenu.match(lhs: oldMenu, rhs: updatedMenu) == true)
    }
    
    @Test
    func testDoMenuActionMatch_whenMenusHaveDifferentActions_returnsFalse() {
        let oldMenu = UIMenu(title: "Old Menu", children: [action1])
        let updatedMenu = UIMenu(title: "Updated Menu", children: [action2])
    
        #expect(UIMenu.match(lhs: oldMenu, rhs: updatedMenu) == false)
    }
    
    @Test
    func testDoMenuActionMatch_whenMenusHaveSameActionsInDifferentOrder_returnsFalse() {
        let oldMenu = UIMenu(title: "Test Menu", children: [action1, action2])
        let updatedMenu = UIMenu(title: "Test Menu", children: [action2, action1])
        
        #expect(UIMenu.match(lhs: oldMenu, rhs: updatedMenu) == false)
    }
    
    @Test
    func testDoMenuActionMatch_whenMenusHaveSameActionsAndActionStates_returnsTrue() {
        let action1_ON = UIAction(title: "Action 1", state: .on, handler: {_ in})
        let action2_OFF = UIAction(title: "Action 2", state: .off, handler: {_ in})
        
        let oldMenu = UIMenu(title: "Test Menu", children: [action1_ON, action2_OFF])
        let updatedMenu = UIMenu(title: "Test Menu", children: [action1_ON, action2_OFF])
        
        #expect(UIMenu.match(lhs: oldMenu, rhs: updatedMenu) == true)
    }
    
    @Test
    func testDoMenuActionMatch_whenMenusAreDifferentButHaveSameActionsAndActionStates_returnsFalse() {
        let action1_ON = UIAction(title: "Action 1", state: .on, handler: {_ in})
        let action2_OFF = UIAction(title: "Action 2", state: .off, handler: {_ in})
        
        let oldMenu = UIMenu(title: "Old Menu", children: [action1_ON, action2_OFF])
        let updatedMenu = UIMenu(title: "Updated Menu", children: [action1_ON, action2_OFF])
        
        #expect(UIMenu.match(lhs: oldMenu, rhs: updatedMenu) == true)
    }
    
    @Test
    func testDoMenuActionMatch_whenMenusAreDifferentAndHaveSameActionsButDifferentActionStates_returnsFalse() {
        let action1_ON = UIAction(title: "Action 1", state: .on, handler: {_ in})
        let action1_OFF = UIAction(title: "Action 1", state: .off, handler: {_ in})
        let action2_ON = UIAction(title: "Action 2", state: .on, handler: {_ in})
        let action2_OFF = UIAction(title: "Action 2", state: .off, handler: {_ in})
        
        let oldMenu = UIMenu(title: "Old Menu", children: [action1_ON, action2_OFF])
        let updatedMenu = UIMenu(title: "Updated Menu", children: [action1_OFF, action2_ON])
        
        #expect(UIMenu.match(lhs: oldMenu, rhs: updatedMenu) == false)
    }
    
    @Test
    func testMatch_sameActionStates_returnsFalse() {
        let action1_ON = UIAction(title: "Action 1", state: .on, handler: {_ in})
        let menu1 = UIMenu(title: "Updated Menu", options: [], children: [action1_ON])
        let menu2 = UIMenu(title: "Updated Menu", options: [], children: [action1_ON])
        
        let result = UIMenu.match(lhs: menu1, rhs: menu2)
       
        #expect(result == true)
   }
    
    @Test
    func testMatch_differentActionStates_returnsFalse() {
        let action1_ON = UIAction(title: "Action 1", state: .on, handler: {_ in})
        let menu1 = UIMenu(title: "Updated Menu", options: [], children: [action1_ON])
        let action1_OFF = UIAction(title: "Action 1", state: .off, handler: {_ in})
        let menu2 = UIMenu(title: "Updated Menu", options: [], children: [action1_OFF])
        
        let result = UIMenu.match(lhs: menu1, rhs: menu2)
       
        #expect(result == false)
   }
}
