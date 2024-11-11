@testable import ContentLibraries
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGASwift
import Testing

@Suite("MonitorAlbumsUseCaseProtocol+Additions Test")
struct MonitorAlbumsUseCaseProtocolAdditionsTest {
    
    @Suite("Calls to monitorLocalizedSystemAlbums")
    struct LocalizedSystemAlbums {
        let favouriteAlbum = AlbumEntity(id: 1, name: "", type: .favourite)
        let rawAlbum = AlbumEntity(id: 2, name: "", type: .raw)
        
        @Test("When system albums are returned ensure the localized text replaces the name")
        func monitorSystemReplacesNameWithLocalized() async throws {
            let monitorSystemAlbumsSequence = SingleItemAsyncSequence<Result<[AlbumEntity], any Error>>(item: .success([favouriteAlbum]))
                .eraseToAnyAsyncSequence()
            
            var iterator = await MockMonitorAlbumsUseCase(monitorSystemAlbumsSequence: monitorSystemAlbumsSequence)
                .monitorLocalizedSystemAlbums(excludeSensitives: false)
                .makeAsyncIterator()
            
            let localizedSystemAlbums = try await iterator.next()?.get()
            
            let updatedSystemAlbum = try #require(localizedSystemAlbums?.first)
            #expect(updatedSystemAlbum.name == Strings.Localizable.CameraUploads.Albums.Favourites.title)
        }
        
        @Test("When search text provided it should filter on localized name")
        func searchTextProvided() async throws {
            let searchText = "Ra"
            let monitorSystemAlbumsSequence = SingleItemAsyncSequence<Result<[AlbumEntity], any Error>>(item: .success([favouriteAlbum, rawAlbum]))
                .eraseToAnyAsyncSequence()
            
            var iterator = await MockMonitorAlbumsUseCase(monitorSystemAlbumsSequence: monitorSystemAlbumsSequence)
                .monitorLocalizedSystemAlbums(
                    excludeSensitives: false,
                    searchText: searchText
                )
                .makeAsyncIterator()
            
            let localizedSystemAlbums = try await iterator.next()?.get()
            #expect(localizedSystemAlbums?.count == 1)
            let updatedRawAlbum = try #require(localizedSystemAlbums?.first)
            #expect(updatedRawAlbum.name == Strings.Localizable.CameraUploads.Albums.Raw.title)
        }
    }
    
    @Suite("Calls to monitorLocalizedSystemAlbums")
    struct SortedUserAlbums {
        let userAlbum1 = AlbumEntity(id: 1, name: "1", type: .user)
        let userAlbum2 = AlbumEntity(id: 2, name: "2", type: .user)
        
        @Test("When user albums are returned ensure they are sorted correctly")
        func sortIsAppliedCorrectly() async {
            let monitorUserAlbumsSequence = SingleItemAsyncSequence(item: [userAlbum1, userAlbum2])
                .eraseToAnyAsyncSequence()
            var iterator = await MockMonitorAlbumsUseCase(monitorUserAlbumsSequence: monitorUserAlbumsSequence)
                .monitorSortedUserAlbums(
                    excludeSensitives: false,
                    by: { $0.id > $1.id })
                .makeAsyncIterator()
            
            #expect(await iterator.next() == [userAlbum2, userAlbum1])
        }
        
        @Test("When search text is provided ensure that only albums matching the search text are returned")
        func searchTextProvided() async {
            let searchText = "2"
            let monitorUserAlbumsSequence = SingleItemAsyncSequence(item: [userAlbum1, userAlbum2])
                .eraseToAnyAsyncSequence()
            var iterator = await MockMonitorAlbumsUseCase(monitorUserAlbumsSequence: monitorUserAlbumsSequence)
                .monitorSortedUserAlbums(
                    excludeSensitives: false,
                    by: { $0.id > $1.id },
                    searchText: searchText)
                .makeAsyncIterator()
            
            #expect(await iterator.next() == [userAlbum2])
        }
    }
    
    @Suite("Calls to monitorAlbums")
    struct AllAlbums {
        @Test("When monitoring all albums ensure that system albums are placed before user albums")
        func allAlbumsEnsureSystemFirst() async throws {
            let systemAlbum = AlbumEntity(id: 1, name: "Favourites", type: .favourite)
            let userAlbum = AlbumEntity(id: 2, name: "Custom", type: .user)
            let monitorSystemAlbumsSequence = SingleItemAsyncSequence<Result<[AlbumEntity], any Error>>(
                item: .success([systemAlbum])).eraseToAnyAsyncSequence()
            
            let monitorUserAlbumsSequence = SingleItemAsyncSequence(item: [userAlbum])
                .eraseToAnyAsyncSequence()
            
            var iterator = try await MockMonitorAlbumsUseCase(
                monitorSystemAlbumsSequence: monitorSystemAlbumsSequence,
                monitorUserAlbumsSequence: monitorUserAlbumsSequence)
                .monitorAlbums(excludeSensitives: false)
                .makeAsyncIterator()
            
            #expect(await iterator.next().map { $0.map(\.type) } == [AlbumEntityType.favourite, .user])
        }
    }
}
