import Combine
@testable import ContentLibraries
import MEGADomain
import SwiftUI
import XCTest

final class AlbumSelectionTests: XCTestCase {
    private let sut = AlbumSelection()
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
    
    func testIsAlbumSelected() {
        let albums = userAlbums()
        sut.setSelectedAlbums(albums)
        
        for album in albums {
            XCTAssertTrue(sut.isAlbumSelected(album))
        }
        
        let anotherAlbum = AlbumEntity(id: 4, name: "Album 4", coverNode: NodeEntity(handle: 4), count: 1, type: .user, modificationTime: nil)
        
        XCTAssertFalse(sut.isAlbumSelected(anotherAlbum))
    }
    
    func testAllSelected_removeAll() {
        let albums = userAlbums()
        
        sut.setSelectedAlbums(albums)
        
        XCTAssertEqual(sut.albums.count, 3)
        
        sut.allSelected = false
        XCTAssertTrue(sut.albums.isEmpty)
    }
    
    func testSingleSelectionMode_setSelectedAlbum_singleSelection() {
        let userAlbum = AlbumEntity(id: 1, type: .user)
        let sut = AlbumSelection(mode: .single)
        
        sut.setSelectedAlbums([userAlbum])
        
        XCTAssertTrue(sut.isAlbumSelected(userAlbum))
        
        sut.setSelectedAlbums([])
        
        XCTAssertFalse(sut.isAlbumSelected(userAlbum))
    }
    
    func testToggle_singleSelection_shouldSetIsSelectedCorrectly() {
        let userAlbum = AlbumEntity(id: 1, type: .user)
        let sut = AlbumSelection(mode: .single)
        
        sut.toggle(userAlbum)
        
        XCTAssertTrue(sut.isAlbumSelected(userAlbum))
        
        sut.toggle(userAlbum)
        
        XCTAssertFalse(sut.isAlbumSelected(userAlbum))
    }
    
    func testToggle_multiSelection_shouldSetIsSelectedCorrectly() throws {
        let sut = AlbumSelection(mode: .multiple)
        let firstUserAlbum = AlbumEntity(id: 1, type: .user)
        let secondUserAlbum = AlbumEntity(id: 2, type: .user)
        for album in [firstUserAlbum, secondUserAlbum] {
            sut.toggle(album)
            XCTAssertTrue(sut.isAlbumSelected(album))
        }
        
        sut.toggle(firstUserAlbum)
        
        XCTAssertFalse(sut.isAlbumSelected(firstUserAlbum))
        XCTAssertTrue(sut.isAlbumSelected(secondUserAlbum))
    }
    
    func testIsAlbumSelectedPublisher_onAllSelectedOrItemSelected_shouldPublishCorrectResult() {
        let album = AlbumEntity(id: 1, type: .user)
        let sut = AlbumSelection()
        
        var results = [true, false, true, false, true, false]
        let exp = expectation(description: "is album selected published")
        exp.expectedFulfillmentCount = results.count
        let subscription = sut.isAlbumSelectedPublisher(album: album)
            .dropFirst()
            .sink {
                XCTAssertEqual($0, results.removeFirst())
                exp.fulfill()
            }
        
        sut.toggle(album)
        sut.toggle(album)
        sut.allSelected = true
        sut.allSelected = false
        sut.toggle(album)
        sut.allSelected = false
        
        wait(for: [exp], timeout: 1.0)
        subscription.cancel()
    }
    
    func testShouldShowDisabled_onMulitiSelection_shouldAlwaysReturnFalse() {
        let album = AlbumEntity(id: 5, type: .user)
        let sut = AlbumSelection(mode: .multiple)
        
        let exp = expectation(description: "Should always return false")
        let subscription = sut.shouldShowDisabled(for: album)
            .sink {
                XCTAssertFalse($0)
                exp.fulfill()
            }
        sut.toggle(album)
        sut.toggle(album)
        
        wait(for: [exp], timeout: 1.0)
        subscription.cancel()
    }
    
    func testShouldShowDisabled_onSingleSelection_shouldReturnFalseIfNothingIsSelectedAndTrueIfSpecificAlbumIsNotSelected() async throws {
        let album = AlbumEntity(id: 5, type: .user)
        let sut = AlbumSelection(mode: .single)
        
        var results = [false, true, false]
        let exp = expectation(description: "Should set correct disabled state")
        exp.expectedFulfillmentCount = results.count
        let subscription = sut.shouldShowDisabled(for: album)
            .sink {
                XCTAssertEqual($0, results.removeFirst())
                exp.fulfill()
            }
        
        sut.toggle(.init(id: 1, type: .user))
        try await Task.sleep(nanoseconds: 150_000_000)
        sut.toggle(album)
        
        await fulfillment(of: [exp], timeout: 1.0)
        subscription.cancel()
    }
    
    private func userAlbums() -> [AlbumEntity] {
        [
            AlbumEntity(id: 1, name: "Album 1", coverNode: NodeEntity(handle: 1), count: 1, type: .user, modificationTime: nil),
            AlbumEntity(id: 2, name: "Album 2", coverNode: NodeEntity(handle: 2), count: 1, type: .user, modificationTime: nil),
            AlbumEntity(id: 3, name: "Album 3", coverNode: NodeEntity(handle: 3), count: 1, type: .user, modificationTime: nil)
        ]
    }
}
