import XCTest
import Combine
import MEGADomainMock
import MEGADomain
@testable import MEGA

final class AlbumListViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    func testLoadAlbums_onAlbumsLoaded_systemAlbumsTitlesAreUpdatedAndAlbumsAreSortedCorrectly() async throws {
        let favouriteAlbum = AlbumEntity(id: 1, name: "", coverNode: NodeEntity(handle: 1), count: 1, type: .favourite)
        let gifAlbum = AlbumEntity(id: 2, name: "", coverNode: NodeEntity(handle: 1), count: 1, type: .gif)
        let rawAlbum = AlbumEntity(id: 3, name: "", coverNode: NodeEntity(handle: 2), count: 1, type: .raw)
        let userAlbum1 = AlbumEntity(id: 4, name: "Album 1", coverNode: NodeEntity(handle: 3),
                                     count: 1, type: .user, modificationTime: nil)
        let userAlbum2 = AlbumEntity(id: 5, name: "Album 2", coverNode: NodeEntity(handle: 4),
                                     count: 1, type: .user, modificationTime: try "2022-12-31T22:01:04Z".date)
        let userAlbum3 = AlbumEntity(id: 6, name: "Other Album 1", coverNode: NodeEntity(handle: 5),
                                     count: 1, type: .user, modificationTime: nil)
        let userAlbum4 = AlbumEntity(id: 7, name: "Other Album 4", coverNode: NodeEntity(handle: 6),
                                     count: 1, type: .user, modificationTime: try "2023-01-16T10:01:04Z".date)
        let userAlbum5 = AlbumEntity(id: 8, name: "Album 5", coverNode: NodeEntity(handle: 7),
                                     count: 1, type: .user, modificationTime: try "2023-01-16T10:01:04Z".date)
        let useCase = MockAlbumListUseCase(albums: [favouriteAlbum, gifAlbum, rawAlbum,
                                                    userAlbum1, userAlbum2, userAlbum3, userAlbum4, userAlbum5])
        let sut = AlbumListViewModel(usecase: useCase, alertViewModel: alertViewModel())
        
        let exp = expectation(description: "albums titles are updated when retrieved")
        sut.$albums
            .dropFirst()
            .sink {
                XCTAssertEqual($0, [
                    favouriteAlbum.update(name: Strings.Localizable.CameraUploads.Albums.Favourites.title),
                    gifAlbum.update(name: Strings.Localizable.CameraUploads.Albums.Gif.title),
                    rawAlbum.update(name: Strings.Localizable.CameraUploads.Albums.Raw.title),
                    userAlbum4,
                    userAlbum5,
                    userAlbum2,
                    userAlbum1,
                    userAlbum3,
                ])
                exp.fulfill()
            }.store(in: &subscriptions)
        await sut.loadAlbums()
        await sut.albumLoadingTask?.value
        wait(for: [exp], timeout: 2.0)
    }
    
    func testLoadAlbums_onAlbumsLoadedFinsihed_shouldLoadSetToFalse() async throws {
        let sut = AlbumListViewModel(usecase: MockAlbumListUseCase(), alertViewModel: alertViewModel())
        let exp = expectation(description: "should load set after album load")
        
        sut.$shouldLoad
            .dropFirst()
            .sink {
                XCTAssertFalse($0)
                exp.fulfill()
            }.store(in: &subscriptions)
        
        await sut.loadAlbums()
        await sut.albumLoadingTask?.value
        wait(for: [exp], timeout: 2.0)
    }
    
    func testCancelLoading_stopMonitoringForNodeUpdates() async throws {
        let useCase = MockAlbumListUseCase()
        let sut = AlbumListViewModel(usecase: useCase, alertViewModel: alertViewModel())
        XCTAssertTrue(useCase.startMonitoringNodesUpdateCalled == 0)
        XCTAssertTrue(useCase.stopMonitoringNodesUpdateCalled == 0)
        await sut.loadAlbums()
        XCTAssertTrue(useCase.startMonitoringNodesUpdateCalled == 1)
        sut.cancelLoading()
        XCTAssertTrue(useCase.stopMonitoringNodesUpdateCalled == 1)
    }
    
    @MainActor
    func testCreateUserAlbum_shouldCreateUserAlbum() {
        let exp = expectation(description: "should load album at first after creating")
        let useCase = MockAlbumListUseCase()
        let sut = AlbumListViewModel(usecase: useCase, alertViewModel: alertViewModel())
        sut.createUserAlbum(with: "userAlbum")
        sut.$shouldLoad
            .dropFirst()
            .sink {
                XCTAssertFalse($0)
                exp.fulfill()
            }.store(in: &subscriptions)
        
        wait(for: [exp], timeout: 2.0)
        XCTAssertEqual(sut.albums.last?.name, "userAlbum")
        XCTAssertEqual(sut.albums.last?.type, .user)
        XCTAssertEqual(sut.albums.last?.count, 0)
    }
    
    @MainActor
    func testCreateUserAlbum_shouldCreateUserAlbumAndInsertBeforeOlderUserAlbums() throws {
        let firstAlbumName = "First Created Album"
        let secondAlbumName = "Second Created Album"
        let firstCreatedUserAlbum = AlbumEntity(id: 1, name: firstAlbumName, coverNode: nil, count: 0, type: .user, modificationTime: try "2023-01-16T10:01:04Z".date)
        let secondCreatedUserAlbum = AlbumEntity(id: 1, name: secondAlbumName, coverNode: nil, count: 0, type: .user, modificationTime: try "2023-01-16T11:01:04Z".date)
        let createdAlbums = [firstAlbumName: firstCreatedUserAlbum,
                            secondAlbumName: secondCreatedUserAlbum]
        let useCase = MockAlbumListUseCase(createdUserAlbums: createdAlbums)
        let sut = AlbumListViewModel(usecase: useCase, alertViewModel: alertViewModel())
        
        let exp = expectation(description: "albums loaded")
        exp.expectedFulfillmentCount = 2
        var result = [[AlbumEntity]]()
        sut.$albums
            .dropFirst()
            .sink {
                result.append($0)
                exp.fulfill()
            }.store(in: &subscriptions)
        sut.createUserAlbum(with: firstAlbumName)
        sut.createUserAlbum(with: secondAlbumName)
        
        wait(for: [exp], timeout: 2.0)
        XCTAssertEqual(result, [
            [firstCreatedUserAlbum],
            [secondCreatedUserAlbum, firstCreatedUserAlbum]
        ])
    }
    
    func testNewAlbumName_whenAlbumContainsNoNewAlbum() async {
        let useCase = MockAlbumListUseCase()
        let sut = AlbumListViewModel(usecase: useCase, alertViewModel: alertViewModel())
        await sut.loadAlbums()
        await sut.albumLoadingTask?.value
        XCTAssertEqual(sut.newAlbumName(), Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder)
    }
    
    func testNewAlbumName_whenAlbumContainsNewAlbum() async {
        let newAlbum = MockAlbumListUseCase.sampleUserAlbum(name: Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder)
        let useCase = MockAlbumListUseCase(albums: [newAlbum])
        let sut = AlbumListViewModel(usecase: useCase, alertViewModel: alertViewModel())
        await sut.loadAlbums()
        await sut.albumLoadingTask?.value
        XCTAssertEqual(sut.albums.count, 1)
        XCTAssertEqual(sut.newAlbumName(), Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder + " \("(1)")")
    }
    
    func testValidateAlbum_whenAlbumNameIsNil_returnsNil() {
        let sut = AlbumListViewModel(usecase: MockAlbumListUseCase(), alertViewModel: alertViewModel())
        XCTAssertNil(sut.validateAlbum(name: nil))
    }
    
    func testValidateAlbum_whenAlbumNameIsEmpty_returnsNil() {
        let sut = AlbumListViewModel(usecase: MockAlbumListUseCase(), alertViewModel: alertViewModel())
        XCTAssertNil(sut.validateAlbum(name: ""))
    }
    
    func testValidateAlbum_whenAlbumNameIsSpaces_returnsError() {
        let sut = AlbumListViewModel(usecase: MockAlbumListUseCase(), alertViewModel: alertViewModel())
        XCTAssertNotNil(sut.validateAlbum(name: "      "))
    }
    
    func testValidateAlbum_whenAlbumNameIsValidButWithWhiteSpaces_returnsNil() {
        let sut = AlbumListViewModel(usecase: MockAlbumListUseCase(), alertViewModel: alertViewModel())
        XCTAssertNil(sut.validateAlbum(name: "  userAlbum    "))
    }
    
    func testValidateAlbum_whenAlbumNameIsValid_returnsNil() {
        let sut = AlbumListViewModel(usecase: MockAlbumListUseCase(), alertViewModel: alertViewModel())
        XCTAssertNil(sut.validateAlbum(name: "userAlbum"))
    }
    
    func testValidateAlbum_whenAlbumNameContainsInvalidChars_returnsErrorMessage() {
        let sut = AlbumListViewModel(usecase: MockAlbumListUseCase(), alertViewModel: alertViewModel())
        XCTAssertNotNil(sut.validateAlbum(name: "userAlbum:/;"))
    }
    
    func testValidateAlbum_whenAlbumNameIsSameAsExistingUserAlbum_returnsErrorMessage() async {
        let newAlbum = MockAlbumListUseCase.sampleUserAlbum(name: "userAlbum")
        let useCase = MockAlbumListUseCase(albums: [newAlbum])
        let sut = AlbumListViewModel(usecase: useCase, alertViewModel: alertViewModel())
        await sut.loadAlbums()
        await sut.albumLoadingTask?.value
        XCTAssertEqual(sut.albums.count, 1)
        XCTAssertNotNil(sut.validateAlbum(name: newAlbum.name))
    }
    
    func testValidateAlbum_whenAlbumNameIsSameAsExistingSystemAlbum_returnsErrorMessage() async {
        let newSysAlbum = AlbumEntity(id: AlbumIdEntity.favourite.rawValue, name: Strings.Localizable.CameraUploads.Albums.Favourites.title, coverNode: NodeEntity(handle: AlbumIdEntity.favourite.rawValue), count: 0, type: .favourite)
        let useCase = MockAlbumListUseCase(albums: [newSysAlbum])
        let sut = AlbumListViewModel(usecase: useCase, alertViewModel: alertViewModel())
        await sut.loadAlbums()
        await sut.albumLoadingTask?.value
        XCTAssertEqual(sut.albums.count, 1)
        XCTAssertNotNil(sut.validateAlbum(name: newSysAlbum.name))
    }
    
    func testValidateAlbum_withSystemAlbumNames_returnsErrorMessage() {
        let reservedNames = [Strings.Localizable.CameraUploads.Albums.Favourites.title,
                             Strings.Localizable.CameraUploads.Albums.Gif.title,
                             Strings.Localizable.CameraUploads.Albums.Raw.title,
                             Strings.Localizable.CameraUploads.Albums.MyAlbum.title,
                             Strings.Localizable.CameraUploads.Albums.SharedAlbum.title]
        let useCase = MockAlbumListUseCase()
        let sut = AlbumListViewModel(usecase: useCase, alertViewModel: alertViewModel())
        reservedNames.forEach { name in
            XCTAssertNotNil(sut.validateAlbum(name: name))
        }
    }
    
    private func alertViewModel() -> TextFieldAlertViewModel {
        TextFieldAlertViewModel(title: Strings.Localizable.CameraUploads.Albums.Create.Alert.title,
                                                   placeholderText: Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder,
                                                   affirmativeButtonTitle: Strings.Localizable.createFolderButton,
                                                   message: nil)
    }
}

