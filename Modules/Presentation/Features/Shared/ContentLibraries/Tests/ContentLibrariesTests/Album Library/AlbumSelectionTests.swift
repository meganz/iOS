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
    
    private func userAlbums() -> [AlbumEntity] {
        [
            AlbumEntity(id: 1, name: "Album 1", coverNode: NodeEntity(handle: 1), count: 1, type: .user, modificationTime: nil),
            AlbumEntity(id: 2, name: "Album 2", coverNode: NodeEntity(handle: 2), count: 1, type: .user, modificationTime: nil),
            AlbumEntity(id: 3, name: "Album 3", coverNode: NodeEntity(handle: 3), count: 1, type: .user, modificationTime: nil)
        ]
    }
}
