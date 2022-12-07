import XCTest
@testable import MEGA
import SwiftUI
import Combine
import MEGADomain

class PhotoSelectionTests: XCTestCase {
    private let sut = PhotoSelection()
    private var subscriptions = Set<AnyCancellable>()

    override func tearDownWithError() throws {
        subscriptions = []
    }

    func testEditMode_status() {
        let statuses: [EditMode] = [.active, .inactive, .transient]
        
        sut.$editMode
            .dropFirst()
            .collect(3)
            .first()
            .sink {
                XCTAssertEqual($0, statuses)
            }
            .store(in: &subscriptions)
        
        sut.editMode = .active
        sut.editMode = .inactive
        sut.editMode = .transient
    }
    
    func testEditMode_deselectAll() throws {
        sut.allSelected = true
        sut.editMode = .inactive
        XCTAssertEqual(sut.allSelected, false)
    }
    
    func testIsPhotoSelected() {
        let nodes = [NodeEntity(handle: 1),
                     NodeEntity(handle: 2),
                     NodeEntity(handle: 3)]
        sut.setSelectedPhotos(nodes)
        
        for node in nodes {
            XCTAssertTrue(sut.isPhotoSelected(node))
        }
        
        XCTAssertFalse(sut.isPhotoSelected(NodeEntity(handle: 4)))
    }
    
    func testAllSelected_removeAll() {
        let nodes = [NodeEntity(handle: 11),
                     NodeEntity(handle: 21),
                     NodeEntity(handle: 31)]
        sut.setSelectedPhotos(nodes)
        
        XCTAssertEqual(sut.photos.count, 3)
        
        sut.allSelected = false
        XCTAssertTrue(sut.photos.isEmpty)
    }
}
