import XCTest
import MEGADomainMock
import MEGADomain
@testable import MEGA

class SlideShowDataSourceTests: XCTestCase {
    private var nodeEntities: [NodeEntity] {
        var nodes = [NodeEntity]()
        
        for i in 1...40 {
            nodes.append(NodeEntity(name: "\(i).png", handle: HandleEntity(i), isFile: true))
        }
        return nodes
    }
    
    private func saveImage(_ image: UIImage, name: String) throws -> URL? {
        let imageData = try XCTUnwrap(image.jpegData(compressionQuality: 1))
        let url = try XCTUnwrap(FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first)
        let imageURL = url.appendingPathComponent(name)
        try XCTUnwrap(imageData.write(to: imageURL))
        return imageURL
    }
    
    private func emptyImage(with size: CGSize) throws -> UIImage {
        UIGraphicsBeginImageContext(size)
        try XCTUnwrap(UIGraphicsGetCurrentContext()!.addRect(CGRectMake(0, 0, size.width, size.height)))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return try XCTUnwrap(image)
    }
    
    private func makeSlideShowDataSource() throws -> SlideShowDataSource {
        let thumbnailUrl = try XCTUnwrap(saveImage(try emptyImage(with: CGSize(width: 10, height: 10)), name: "1.png"))
        
        return SlideShowDataSource(
            currentPhoto: try XCTUnwrap(nodeEntities.first),
            nodeEntities: nodeEntities,
            thumbnailUseCase: MockThumbnailUseCase(
                cachedThumbnailURLs: [(.preview, thumbnailUrl)],
                loadPreviewResult: .success(try XCTUnwrap(thumbnailUrl))
            ),
            advanceNumberOfPhotosToLoad: 20,
            numberOfUnusedPhotosBuffer: 20
        )
    }
    
    func testLoadSelectedPhotoPreview_whenCurrentPhotoProvided_shouldReturnTrue() async throws {
        let sut = try makeSlideShowDataSource()
        XCTAssertTrue(sut.loadSelectedPhotoPreview())
    }
    
    func testStartInitialDownload_withoutCurrentPhoto_numberOfPhotosShouldBe20() async throws {
        let sut = try makeSlideShowDataSource()
        sut.startInitialDownload(false)
        await sut.thumbnailLoadingTask?.value
        XCTAssertTrue(sut.photos.count == 20)
    }
    
    func testSortNodes_whenInAscendingOrder_nodeEntitiesShouldBeInAscendingOrder() async throws {
        let sut = try makeSlideShowDataSource()
        sut.sortNodes(byOrder: .newest)
        XCTAssertTrue(sut.nodeEntities == sut.nodeEntities.sorted { $0.modificationTime > $1.modificationTime })
    }
    
    func testSortNodes_whenInDescendingOrder_nodeEntitiesShouldBeInDescendingOrder() async throws {
        let sut = try makeSlideShowDataSource()
        sut.sortNodes(byOrder: .oldest)
        XCTAssertTrue(sut.nodeEntities == sut.nodeEntities.sorted { $0.modificationTime < $1.modificationTime })
    }
    
    func testProcessData_secondPageDownload_photosShouldReturn40() async throws {
        let sut = try makeSlideShowDataSource()
        sut.startInitialDownload(false)
        await sut.thumbnailLoadingTask?.value
        
        sut.processData(basedOnCurrentSlideNumber: 11, andOldSlideNumber: 10)
        await sut.thumbnailLoadingTask?.value
        XCTAssertTrue(sut.photos.count == 40)
    }

    func testProcessData_reloadUnusedPhoto_firstPhotoInPhotosShouldBeNotNil() async throws {
        let sut = try makeSlideShowDataSource()

        sut.startInitialDownload(false)
        await sut.thumbnailLoadingTask?.value
        
        sut.processData(basedOnCurrentSlideNumber: 20, andOldSlideNumber: 19)
        XCTAssertNil(sut.photos[0].image)

        sut.processData(basedOnCurrentSlideNumber: 19, andOldSlideNumber: 20)
        await sut.thumbnailLoadingTask?.value
        XCTAssertNotNil(sut.photos[0].image)
    }

    func testProcessData_removeUnusedPhotos_firstPhotoInPhotosShouldBeNil() async throws {
        let sut = try makeSlideShowDataSource()

        sut.startInitialDownload(false)
        await sut.thumbnailLoadingTask?.value
        
        sut.processData(basedOnCurrentSlideNumber: 20, andOldSlideNumber: 19)
        XCTAssertNil(sut.photos[0].image)
    }
}
