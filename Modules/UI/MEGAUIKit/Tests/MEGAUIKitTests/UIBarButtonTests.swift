import MEGASwift
@testable import MEGAUIKit
import XCTest

final class UIBarButtonTests: XCTestCase {
    
    func testMatches_differentTitles_notEqual() {
        let buttonA = UIBarButtonItem(title: "buttonA", style: .plain, target: nil, action: nil)
        let buttonB = UIBarButtonItem(title: "buttonB", style: .plain, target: nil, action: nil)
        XCTAssertFalse(buttonA ~~ buttonB)
    }
    
    func testMatches_imagesAreDifferent_notEqual() {
        let buttonA = UIBarButtonItem(image: UIImage(systemName: "person"), style: .plain, target: nil, action: nil)
        let buttonB = UIBarButtonItem(image: UIImage(systemName: "person.fill"), style: .plain, target: nil, action: nil)
        XCTAssertFalse(buttonA ~~ buttonB)
    }
    
    func testMatches_buttonStyleIsDifferent_notEqual() {
        let buttonA = UIBarButtonItem(title: "buttonA", style: .plain, target: nil, action: nil)
        let buttonB = UIBarButtonItem(title: "buttonA", style: .done, target: nil, action: nil)
        XCTAssertFalse(buttonA ~~ buttonB)
        
        let buttonC = UIBarButtonItem(image: UIImage(systemName: "person"), style: .plain, target: nil, action: nil)
        let buttonD = UIBarButtonItem(image: UIImage(systemName: "person"), style: .done, target: nil, action: nil)
        XCTAssertFalse(buttonC ~~ buttonD)
    }
    
    func testMatches_buttonsAreSame_equal() {
        let buttonA = UIBarButtonItem(title: "buttonA", style: .plain, target: nil, action: nil)
        let buttonB = UIBarButtonItem(title: "buttonA", style: .plain, target: nil, action: nil)
        XCTAssertTrue(buttonA ~~ buttonB)
        
        let buttonC = UIBarButtonItem(image: UIImage(systemName: "person"), style: .plain, target: nil, action: nil)
        let buttonD = UIBarButtonItem(image: UIImage(systemName: "person"), style: .plain, target: nil, action: nil)
        XCTAssertTrue(buttonC ~~ buttonD)
    }
}
