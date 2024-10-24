@testable import MEGA
import MEGADomain
import XCTest

final class DocScannerSaveSettingTableViewControllerTests: XCTestCase {
    
    func testNumberOfSections_rendersCorrectSectionCount() {
        let sut = makeSUT()
        
        let sectionCount = sut.numberOfSections(in: sut.tableView)
        
        XCTAssertEqual(sectionCount, 3)
    }
    
    func testNumberOfSections_rendersCorrectSectionCountWhenHasChatRoom() {
        let sut = makeSUT(chatRoom: anyChatRoom())
        
        let sectionCount = sut.numberOfSections(in: sut.tableView)
        
        XCTAssertEqual(sectionCount, 2)
    }
    
    func testTitleForHeaderInSection_rendersSectionTitle() {
        let sut = makeSUT()
        
        for section in 0..<sut.numberOfSections(in: sut.tableView) {
            let sectionTitle = sut.tableView(sut.tableView, titleForHeaderInSection: section)
            
            assertHeaderSectionTitleNullability(at: section, sectionTitle: sectionTitle)
        }
    }
    
    func testWillDisplayHeaderView_rendersSectionTitle() {
        let sut = makeSUT()
        
        for section in 0..<sut.numberOfSections(in: sut.tableView) {
            let mockHeaderView = UITableViewHeaderFooterView(frame: .zero)
            
            sut.tableView(sut.tableView, willDisplayHeaderView: mockHeaderView, forSection: section)
            
            assertHeaderSectionTitleNullability(at: section, sectionTitle: mockHeaderView.textLabel?.text)
        }
    }
    
    func testTitleForFooterInSection_rendersSectionTitle() {
        let sut = makeSUT()
        
        for section in 0..<sut.numberOfSections(in: sut.tableView) {
            let sectionTitle = sut.tableView(sut.tableView, titleForFooterInSection: section)
            
            assertFooterSectionTitleNullability(at: section, sectionTitle: sectionTitle)
        }
    }
    
    // MARK: - Helpers
    
    private func makeSUT(chatRoom: ChatRoomEntity? = nil, file: StaticString = #filePath, line: UInt = #line) -> DocScannerSaveSettingTableViewController {
        let storyboard = UIStoryboard(name: "Cloud", bundle: nil)
        let sut = storyboard.instantiateViewController(withIdentifier: "DocScannerSaveSettingTableViewController") as! DocScannerSaveSettingTableViewController
        sut.chatRoom = chatRoom
        sut.loadView()
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
    
    private func assertHeaderSectionTitleNullability(at section: Int, sectionTitle: String?, file: StaticString = #filePath, line: UInt = #line) {
        if section == 0 {
            XCTAssertNil(sectionTitle, "Expect nil title, got non nil instead at section \(section)", file: file, line: line)
        } else {
            XCTAssertNotNil(sectionTitle, "Expect non nil title, got nil instead at section \(section)", file: file, line: line)
        }
    }
    
    private func assertFooterSectionTitleNullability(at section: Int, sectionTitle: String?, file: StaticString = #filePath, line: UInt = #line) {
        if section == 0 {
            XCTAssertNotNil(sectionTitle, "Expect non nil title, got nil instead at section \(section)", file: file, line: line)
        } else {
            XCTAssertNil(sectionTitle, "Expect nil title, got non nil instead at section \(section)", file: file, line: line)
        }
    }
    
    private func anyChatRoom() -> ChatRoomEntity {
        ChatRoomEntity()
    }
}
