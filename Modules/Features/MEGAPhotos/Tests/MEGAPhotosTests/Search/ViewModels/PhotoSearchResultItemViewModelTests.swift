import Combine
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGAAssets
import MEGADesignToken
import MEGADomain
@testable import MEGAPhotos
import MEGASwift
import SwiftUI
import Testing

@Suite("PhotoSearchResultItemViewModel Tests")
struct PhotoSearchResultItemViewModelTests {
    
    @Suite("calls init")
    struct Constructor {
        @Test("Title should use node name and highlight search term")
        @MainActor
        func title() {
            let expectedTitle = "Test"
            let searchText = "st"
            let sut = makeSUT(photo: .init(name: expectedTitle),
                         searchText: searchText)
            
            #expect(sut.title == AttributedString(expectedTitle
                .forceLeftToRight()
                .highlightedStringWithKeyword(
                    searchText,
                    primaryTextColor: TokenColors.Text.primary,
                    highlightedTextColor: TokenColors.Notifications.notificationSuccess
                )))
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
    
    @Suite("Node attributes")
    struct NodeAttributes {
        @Test("Label image should be nil when label is unknown")
        @MainActor
        func labelImageUnknown() {
            let sut = makeSUT(photo: .init(handle: 1, label: .unknown))
            #expect(sut.labelImage == nil)
        }

        @Test("Label image should return image when label is set",
              arguments: [NodeLabelTypeEntity.red, .orange, .yellow, .green, .blue, .purple, .grey])
        @MainActor
        func labelImageSet(label: NodeLabelTypeEntity) {
            let sut = makeSUT(photo: .init(handle: 1, label: label))
            #expect(sut.labelImage != nil)
        }

        @Test("shouldShowFavourite should reflect photo isFavourite")
        @MainActor
        func shouldShowFavourite() {
            let favouriteSUT = makeSUT(photo: .init(handle: 1, isFavourite: true))
            let nonFavouriteSUT = makeSUT(photo: .init(handle: 2, isFavourite: false))
            #expect(favouriteSUT.shouldShowFavourite == true)
            #expect(nonFavouriteSUT.shouldShowFavourite == false)
        }

        @Test("shouldShowLink should reflect photo isExported")
        @MainActor
        func shouldShowLink() {
            let exportedSUT = makeSUT(photo: .init(handle: 1, isExported: true))
            let nonExportedSUT = makeSUT(photo: .init(handle: 2, isExported: false))
            #expect(exportedSUT.shouldShowLink == true)
            #expect(nonExportedSUT.shouldShowLink == false)
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
