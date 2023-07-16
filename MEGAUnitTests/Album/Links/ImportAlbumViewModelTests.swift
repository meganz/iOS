import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class ImportAlbumViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    private var validFullAlbumLink: URL {
        get throws {
            try XCTUnwrap(URL(string: "https://mega.nz/collection/p3IBQCiZ#Nt8-bopPB8em4cOlKas"))
        }
    }
    
    private var requireDecryptionKeyAlbumLink: URL {
        get throws {
            try XCTUnwrap(URL(string: "https://mega.nz/collection/yro2RbQAx"))
        }
    }
    
    func testLoadPublicAlbum_onCollectionLinkOpen_publicLinkStatusShouldBeNeedsDescryptionKey() throws {
        let sut = makeImportAlbumViewModel(
            publicLink: try requireDecryptionKeyAlbumLink,
            publicAlbumUseCase: MockPublicAlbumUseCase())
        
        sut.loadPublicAlbum()
        
        XCTAssertEqual(sut.publicLinkStatus, .requireDecryptionKey)
    }
    
    func testLoadPublicAlbum_onFullAlbumLink_shouldChangeLinkStatusSetAlbumNameAndLoadPhotos() throws {
        let photos = makePhotos()
        let albumName = "New album (5)"
        let sharedAlbumEntity = makeSharedAlbumEntity(set: SetEntity(handle: 2, name: albumName))
        let albumUseCase = MockPublicAlbumUseCase(publicAlbumResult: .success(sharedAlbumEntity),
                                                  nodes: photos)
        let sut = makeImportAlbumViewModel(
            publicLink: try validFullAlbumLink,
            publicAlbumUseCase: albumUseCase)
        XCTAssertNil(sut.albumName)
        XCTAssertFalse(sut.isPhotosLoaded)
        
        let exp = expectation(description: "link status should change correctly")
        sut.$publicLinkStatus
            .dropFirst()
            .collect(2)
            .first()
            .sink {
                XCTAssertEqual($0, [.inProgress, .loaded])
                exp.fulfill()
            }.store(in: &subscriptions)
        
        sut.loadPublicAlbum()
        
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(sut.albumName, albumName)
        XCTAssertEqual(sut.photoLibraryContentViewModel.library,
                       photos.toPhotoLibrary(withSortType: .newest))
        XCTAssertTrue(sut.isPhotosLoaded)
    }
    
    func testLoadPublicAlbum_onSharedAlbumError_shouldShowCannotAccessAlbumAlert() throws {
        let sut = makeImportAlbumViewModel(
            publicLink: try validFullAlbumLink,
            publicAlbumUseCase: MockPublicAlbumUseCase(publicAlbumResult: .failure(SharedAlbumErrorEntity.couldNotBeReadOrDecrypted)))
        XCTAssertEqual(sut.publicLinkStatus, .none)
        XCTAssertFalse(sut.showCannotAccessAlbumAlert)
        
        let exp = expectation(description: "link status should switch to in progress to invalid")
        sut.$publicLinkStatus
            .dropFirst()
            .collect(2)
            .first()
            .sink {
                XCTAssertEqual($0, [.inProgress, .invalid])
                exp.fulfill()
            }.store(in: &subscriptions)
        
        sut.loadPublicAlbum()
        
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertTrue(sut.showCannotAccessAlbumAlert)
    }
    
    func testLoadWithNewDecryptionKey_validKeyEntered_shouldSetAlbumNameLoadAlbumContentsAndPreserveOrignalURL() throws {
        let link = try requireDecryptionKeyAlbumLink
        let albumName = "New album (5)"
        let sharedAlbumEntity = makeSharedAlbumEntity(set: SetEntity(handle: 5, name: albumName))
        let photos = makePhotos()
        let albumUseCase = MockPublicAlbumUseCase(publicAlbumResult: .success(sharedAlbumEntity),
                                                  nodes: photos)
        let sut = makeImportAlbumViewModel(
            publicLink: link,
            publicAlbumUseCase: albumUseCase)
        sut.publicLinkStatus = .requireDecryptionKey
        sut.publicLinkDecryptionKey = "Nt8-bopPB8em4cOlKas"
        
        let exp = expectation(description: "link status should change correctly")
        sut.$publicLinkStatus
            .dropFirst()
            .collect(2)
            .first()
            .sink {
                XCTAssertEqual($0, [.inProgress, .loaded])
                exp.fulfill()
            }.store(in: &subscriptions)
        
        sut.loadWithNewDecryptionKey()
        
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(sut.albumName, albumName)
        XCTAssertEqual(sut.photoLibraryContentViewModel.library,
                       photos.toPhotoLibrary(withSortType: .newest))
        XCTAssertEqual(sut.publicLink, link)
    }
    
    func testLoadWithNewDecryptionKey_invalidKeyEntered_shouldSetStatusToInvalid() throws {
        let sut = makeImportAlbumViewModel(
            publicLink: try requireDecryptionKeyAlbumLink, publicAlbumUseCase: MockPublicAlbumUseCase())
        sut.publicLinkStatus = .requireDecryptionKey
        sut.publicLinkDecryptionKey = "<<<<"
        
        sut.loadWithNewDecryptionKey()
        
        XCTAssertEqual(sut.publicLinkStatus, .invalid)
    }
    
    func testEnablePhotoLibraryEditMode_onEditModeChange_shouldUpdateisSelectionEnabled() throws {
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink)
        XCTAssertFalse(sut.isSelectionEnabled)
        
        sut.enablePhotoLibraryEditMode(true)
        XCTAssertTrue(sut.isSelectionEnabled)
        
        sut.enablePhotoLibraryEditMode(false)
        XCTAssertFalse(sut.isSelectionEnabled)
    }
    
    // MARK: - Private
    
    private func makeImportAlbumViewModel(publicLink: URL,
                                          publicAlbumUseCase: some PublicAlbumUseCaseProtocol = MockPublicAlbumUseCase()
    ) -> ImportAlbumViewModel {
        ImportAlbumViewModel(
            publicLink: publicLink,
            publicAlbumUseCase: publicAlbumUseCase)
    }
    
    private func makeSharedAlbumEntity(set: SetEntity = SetEntity(handle: 1),
                                       setElements: [SetElementEntity] = []) -> SharedAlbumEntity {
        SharedAlbumEntity(set: set, setElements: setElements)
    }
    
    private func makePhotos() -> [NodeEntity] {
        [NodeEntity(handle: 1, hasThumbnail: true, mediaType: .image),
         NodeEntity(handle: 4, hasThumbnail: true, mediaType: .video),
         NodeEntity(handle: 7, hasThumbnail: true, mediaType: .image)
        ]
    }
}
