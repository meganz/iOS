import Combine
@testable import ContentLibraries
import MEGADomain
import SwiftUI
import XCTest

class PhotoSelectionTests: XCTestCase {
    private let sut = PhotoSelection()
    private var subscriptions = Set<AnyCancellable>()

    override func tearDownWithError() throws {
        subscriptions = []
    }

    func testEditMode_status() {
        let exp = expectation(description: "Should change statuses")
        let statuses: [EditMode] = [.active, .inactive, .transient]
        
        sut.$editMode
            .dropFirst()
            .collect(3)
            .first()
            .sink {
                XCTAssertEqual($0, statuses)
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.editMode = .active
        sut.editMode = .inactive
        sut.editMode = .transient
        wait(for: [exp], timeout: 1.0)
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
    
    func testIsSelectionLimitReachedPublisher_onNoLimitSet_shouldReturnNil() {
        XCTAssertNil(sut.isSelectionLimitReachedPublisher)
    }
    
    func testIsSelectionLimitReacheched_onLimitReached_publisherShouldEmitTrue() throws {
        let limit = 3
        let selection = PhotoSelection(selectLimit: limit)
        let exp = expectation(description: "Should change based on selection limit")
        
        try XCTUnwrap(selection.isSelectionLimitReachedPublisher)
            .collect(3)
            .sink {
                XCTAssertEqual($0, [false, true, false])
                exp.fulfill()
            }.store(in: &subscriptions)
        
        selection.setSelectedPhotos([NodeEntity(handle: 1)])
        let maxPhotos = (1...limit).map { NodeEntity(handle: HandleEntity($0)) }
        selection.setSelectedPhotos(maxPhotos)
        selection.setSelectedPhotos([])
        
        wait(for: [exp], timeout: 1.0)
    }
}
