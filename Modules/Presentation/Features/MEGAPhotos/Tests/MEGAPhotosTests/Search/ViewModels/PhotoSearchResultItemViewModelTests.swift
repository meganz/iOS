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
                .makeSUT(searchText: expected)
            
            #expect(sut.searchText == expected)
        }
        
        @Test("Initial image found for photo should set thumbnail container")
        @MainActor
        func initialImageFound() async throws {
            let sut = PhotoSearchResultItemViewModelTests.makeSUT()
            
            #expect(sut.thumbnailContainer.type == .placeholder)
        }
    }
    
    @Suite("calls loadThumbnail()")
    struct LoadThumbnail {
        @Test("When initial image is thumbnail, then it should load image")
        @MainActor
        func initialImagePlaceholder() async {
            let loadedImage = ImageContainer(image: Image(systemName: "square"), type: .thumbnail)
            let thumbnailLoader = MockThumbnailLoader(
                loadImage: SingleItemAsyncSequence<any ImageContaining>(item: loadedImage).eraseToAnyAsyncSequence())
            let sut = PhotoSearchResultItemViewModelTests
                .makeSUT(thumbnailLoader: thumbnailLoader)
            
            await sut.loadThumbnail()
            
            #expect(sut.thumbnailContainer.isEqual(loadedImage))
        }
    }
    
    @Suite("calls moreButtonPressed")
    struct MoreButtonPressed {
        @Test("When more button pressed it should call router to handle")
        @MainActor
        func initialImagePlaceholder() async {
            let photo = NodeEntity(handle: 6)
            let router = MockPhotoSearchResultRouter()
            let sut = PhotoSearchResultItemViewModelTests
                .makeSUT(photo: photo,
                         photoSearchResultRouter: router)
            
            sut.moreButtonPressed(UIButton())
            
            #expect(router.moreActionOnNodeHandle == photo.handle)
        }
    }
    
    @MainActor
    private static func makeSUT(
        photo: NodeEntity = .init(handle: 1),
        searchText: String = "",
        thumbnailLoader: some ThumbnailLoaderProtocol = MockThumbnailLoader(),
        photoSearchResultRouter: some PhotoSearchResultRouterProtocol = MockPhotoSearchResultRouter()
    ) -> PhotoSearchResultItemViewModel {
        PhotoSearchResultItemViewModel(
            photo: photo,
            searchText: searchText,
            thumbnailLoader: thumbnailLoader,
            photoSearchResultRouter: photoSearchResultRouter)
    }
}
