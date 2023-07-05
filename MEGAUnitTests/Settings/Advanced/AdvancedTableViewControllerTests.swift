@testable import MEGA
import MEGATest
import XCTest

final class AdvancedTableViewControllerTests: XCTestCase {
    
    func testNumberOfSections_rendersCorrectSectionCount() {
        let sut = makeSUT()
        
        let sectionCount = sut.numberOfSections(in: sut.tableView)
        
        XCTAssertEqual(sectionCount, 3)
    }
    
    func testTitleForHeaderInSection_rendersNonNilSectionTitle() {
        let sut = makeSUT()
        
        for section in 0..<sut.numberOfSections(in: sut.tableView) {
            let sectionTitle = sut.tableView(sut.tableView, titleForHeaderInSection: section)
            
            XCTAssertNotNil(sectionTitle, "Expect non nil title, got nil instead at section \(section)")
        }
    }
    
    func testWillDisplayHeaderView_rendersNonNilSectionTitle() {
        let sut = makeSUT()
        
        for section in 0..<sut.numberOfSections(in: sut.tableView) {
            let mockHeaderView = UITableViewHeaderFooterView(frame: .zero)
            
            sut.tableView(sut.tableView, willDisplayHeaderView: mockHeaderView, forSection: section)
            
            XCTAssertNotNil(mockHeaderView.textLabel?.text, "Expect non nil title, got nil instead at section \(section)")
        }
    }
    
    func testTitleForFooterInSection_rendersNonNilSectionTitle() {
        let sut = makeSUT()
        
        for section in 0..<sut.numberOfSections(in: sut.tableView) {
            let sectionTitle = sut.tableView(sut.tableView, titleForFooterInSection: section)
            
            XCTAssertNotNil(sectionTitle, "Expect non nil title, got nil instead at section \(section)")
        }
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> AdvancedTableViewController {
        let storyboard = UIStoryboard(name: "Settings", bundle: nil)
        let sut = storyboard.instantiateViewController(withIdentifier: "AdvancedTableViewControllerID") as! AdvancedTableViewController
        sut.loadView()
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }

}
