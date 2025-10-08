import Foundation
import MEGADomain
import MEGADomainMock
import MEGASwift
import Testing
import UIKit

struct PhotoLibraryThumbnailUseCaseTests {
    
    @Test
    func thumbnailData() async throws {
        let compressionQuality: CGFloat = 0.8
        let targetSize = CGSize(width: 1, height: 1)
        let imageData = try #require(UIImage(systemName: "folder")?.jpegData(
            compressionQuality: compressionQuality))
        let expected = PhotoLibraryThumbnailResultEntity(data: imageData, isDegraded: false)
        let imageDataAsyncSequence = SingleItemAsyncSequence(item: expected)
        let photoLibraryThumbnailRepository = MockPhotoLibraryThumbnailRepository(
            thumbnailResultAsyncSequence: imageDataAsyncSequence.eraseToAnyAsyncSequence()
        )
        let identifier = UUID().uuidString
        let sut = Self.makeSUT(
            photoLibraryThumbnailRepository: photoLibraryThumbnailRepository)
        
        var iterator = sut.thumbnailData(
            for: identifier, targetSize: targetSize, compressionQuality: compressionQuality)?.makeAsyncIterator()
        
        #expect(await iterator?.next() == expected)
        #expect(photoLibraryThumbnailRepository.invocations == [.thumbnailData(
            for: identifier, targetSize: targetSize, compressionQuality: compressionQuality)])
    }
    
    private static func makeSUT(
        photoLibraryThumbnailRepository: some PhotoLibraryThumbnailRepositoryProtocol = MockPhotoLibraryThumbnailRepository()
    ) -> PhotoLibraryThumbnailUseCase {
        .init(photoLibraryThumbnailRepository: photoLibraryThumbnailRepository)
    }
}
