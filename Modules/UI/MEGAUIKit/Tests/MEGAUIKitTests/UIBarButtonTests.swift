import MEGASwift
@testable import MEGAUIKit
import Testing
import UIKit

@MainActor
struct UIBarButtonTests {
    
    func testMatches_differentTitles_notEqual() {
        let buttonA = UIBarButtonItem(title: "buttonA", style: .plain, target: nil, action: nil)
        let buttonB = UIBarButtonItem(title: "buttonB", style: .plain, target: nil, action: nil)
        #expect((buttonA ~~ buttonB) == false)
    }
    
    func testMatches_imagesAreDifferent_notEqual() {
        let buttonA = UIBarButtonItem(image: UIImage(systemName: "person"), style: .plain, target: nil, action: nil)
        let buttonB = UIBarButtonItem(image: UIImage(systemName: "person.fill"), style: .plain, target: nil, action: nil)
        #expect((buttonA ~~ buttonB) == false)
    }
    
    func testMatches_buttonStyleIsDifferent_notEqual() {
        let buttonA = UIBarButtonItem(title: "buttonA", style: .plain, target: nil, action: nil)
        let buttonB = UIBarButtonItem(title: "buttonA", style: .done, target: nil, action: nil)
        #expect((buttonA ~~ buttonB) == false)
        
        let buttonC = UIBarButtonItem(image: UIImage(systemName: "person"), style: .plain, target: nil, action: nil)
        let buttonD = UIBarButtonItem(image: UIImage(systemName: "person"), style: .done, target: nil, action: nil)
        #expect((buttonC ~~ buttonD) == false)
    }
    
    func testMatches_buttonsAreSame_equal() {
        let buttonA = UIBarButtonItem(title: "buttonA", style: .plain, target: nil, action: nil)
        let buttonB = UIBarButtonItem(title: "buttonA", style: .plain, target: nil, action: nil)
        #expect((buttonA ~~ buttonB) == false)
        
        let buttonC = UIBarButtonItem(image: UIImage(systemName: "person"), style: .plain, target: nil, action: nil)
        let buttonD = UIBarButtonItem(image: UIImage(systemName: "person"), style: .plain, target: nil, action: nil)
        #expect((buttonC ~~ buttonD) == false)
    }
}
