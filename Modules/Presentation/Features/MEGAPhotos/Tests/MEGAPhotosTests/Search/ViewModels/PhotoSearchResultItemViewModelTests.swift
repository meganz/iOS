import Combine
import MEGAAssets
import MEGADomain
@testable import MEGAPhotos
import MEGAPresentation
import MEGAPresentationMock
import MEGASwift
import SwiftUI
import Testing

@Suite("PhotoSearchResultItemViewModel Tests")
struct PhotoSearchResultItemViewModelTests {
    
    @Suite("calls init")
    struct Constructor {
        @Test("Title should use node name")
        @MainActor
        func title() {
            let expectedTitle = "Test"
            let sut = PhotoSearchResultItemViewModelTests
                .makeSUT(photo: .init(name: expectedTitle))
            
            #expect(sut.title == expectedTitle)
        }
        
        @Test("ensure search text is set to binding")
        @MainActor
        func searchText() {
            let expected = "Search me"
            let sut = PhotoSearchResultItemViewModelTests
                .makeSUT(searchText: Published(initialValue: expected))
            
            #expect(sut.searchText == expected)
        }
        
        @Test("Initial image found for photo should set thumbnail container")
        @MainActor
        func initialImageFound() async throws {
            let thumbnailContainer = ImageContainer(image: Image(systemName: "square"), type: .thumbnail)
            let thumbnailLoader = MockThumbnailLoader(initialImage: thumbnailContainer)
            let sut = PhotoSearchResultItemViewModelTests
                .makeSUT(thumbnailLoader: thumbnailLoader)
            
            #expect(sut.thumbnailContainer.isEqual(thumbnailContainer))
        }
    }
    
    @Suite("calls loadThumbnail()")
    struct LoadThumbnail {
        @Test("When initial image is set (not placeholder) then it should not load anything")
        @MainActor
        func notPlaceholder() async {
            let thumbnailContainer = ImageContainer(image: Image(systemName: "square"), type: .thumbnail)
            let thumbnailLoader = MockThumbnailLoader(initialImage: thumbnailContainer)
            let sut = PhotoSearchResultItemViewModelTests
                .makeSUT(thumbnailLoader: thumbnailLoader)
            
            await sut.loadThumbnail()
            
            #expect(thumbnailLoader.invocations.notContains(.loadImage))
        }
        
        
        @Test("When initial image is thumbnail, then it should load image")
        @MainActor
        func initialImagePlaceholder() async {
            let loadedImage = ImageContainer(image: Image(systemName: "square"), type: .thumbnail)
            let thumbnailLoader = MockThumbnailLoader(
                initialImage: ImageContainer(image: Image(systemName:"circle.fill"), type: .placeholder),
                loadImage: SingleItemAsyncSequence<any ImageContaining>(item: loadedImage).eraseToAnyAsyncSequence())
            let sut = PhotoSearchResultItemViewModelTests
                .makeSUT(thumbnailLoader: thumbnailLoader)
            
            await sut.loadThumbnail()
            
            #expect(sut.thumbnailContainer.isEqual(loadedImage))
        }
    }
    
    @MainActor
    private static func makeSUT(
        photo: NodeEntity = .init(handle: 1),
        thumbnailLoader: some ThumbnailLoaderProtocol = MockThumbnailLoader(),
        searchText: Published<String> = Published(initialValue: "")
    ) -> PhotoSearchResultItemViewModel {
        var searchTextPublisher = searchText
        return PhotoSearchResultItemViewModel(
            photo: photo,
            thumbnailLoader: thumbnailLoader,
            searchTextPublisher: searchTextPublisher .projectedValue)
    }
}
