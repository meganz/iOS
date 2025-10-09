import Foundation
import MEGADomain
import MEGADomainMock
import MEGASwift
import Testing
import UIKit

struct PhotoLibraryThumbnailUseCaseTests {
    private let assetIdentifier = UUID().uuidString
    private let thumbnailTargetSize = CGSize(width: 1, height: 1)
    
    @Test
    func thumbnailData() async throws {
        let compressionQuality: CGFloat = 0.8
        let targetSize = CGSize(width: 1, height: 1)
        let imageData = try #require(UIImage(systemName: "folder")?.jpegData(
            compressionQuality: compressionQuality))
        let expected = PhotoLibraryThumbnailResultEntity(data: imageData, isDegraded: false)
        let imageDataAsyncSequence = SingleItemAsyncSequence(item: expected)
        let photoLibraryThumbnailRepository = MockPhotoLibraryThumbnailRepository(
            thumbnailResultAsyncSequence: imageDataAsyncSequence.eraseToAnyAsyncThrowingSequence()
        )
        let sut = Self.makeSUT(
            photoLibraryThumbnailRepository: photoLibraryThumbnailRepository)
        
        var iterator = sut.thumbnailData(
            for: assetIdentifier, targetSize: targetSize, compressionQuality: compressionQuality)?.makeAsyncIterator()
        
        #expect(try await iterator?.next() == expected)
        #expect(photoLibraryThumbnailRepository.invocations == [.thumbnailData(
            for: assetIdentifier, targetSize: targetSize, compressionQuality: compressionQuality)])
    }
    
    @Test
    func startCache() {
        let photoLibraryThumbnailRepository = MockPhotoLibraryThumbnailRepository()
       
        let sut = Self.makeSUT(
            photoLibraryThumbnailRepository: photoLibraryThumbnailRepository)
        
        sut.startCaching(for: [assetIdentifier], targetSize: thumbnailTargetSize)
        
        #expect(photoLibraryThumbnailRepository.invocations == [.startCaching(for: [assetIdentifier], targetSize: thumbnailTargetSize)])
    }
    
    @Test
    func stopCaching() {
        let photoLibraryThumbnailRepository = MockPhotoLibraryThumbnailRepository()
       
        let sut = Self.makeSUT(
            photoLibraryThumbnailRepository: photoLibraryThumbnailRepository)
        
        sut.stopCaching(for: [assetIdentifier], targetSize: thumbnailTargetSize)
        
        #expect(photoLibraryThumbnailRepository.invocations == [.stopCaching(for: [assetIdentifier], targetSize: thumbnailTargetSize)])
    }
    
    @Test
    func clearCache() {
        let photoLibraryThumbnailRepository = MockPhotoLibraryThumbnailRepository()
       
        let sut = Self.makeSUT(
            photoLibraryThumbnailRepository: photoLibraryThumbnailRepository)
        
        sut.clearCache()
        
        #expect(photoLibraryThumbnailRepository.invocations == [.clearCache])
    }
    
    private static func makeSUT(
        photoLibraryThumbnailRepository: some PhotoLibraryThumbnailRepositoryProtocol = MockPhotoLibraryThumbnailRepository()
    ) -> PhotoLibraryThumbnailUseCase {
        .init(photoLibraryThumbnailRepository: photoLibraryThumbnailRepository)
    }
}
