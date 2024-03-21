@testable import MEGASwiftUI
import MEGASwiftUIMock
import MEGATest
import XCTest

final class ImageLoaderTests: XCTestCase {
    var defaultImageURLString = "https://example.com/image.png"
    var defaultNonImageURLString = "https://example.com/non-image-data"
    var invalidURLString = "https://this.url.does.not.exist"
    
    private func makeSUT(
        urlSession: MockURLSession = MockURLSession(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> ImageLoader {
        let sut = ImageLoader(session: urlSession)
        
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
    
    private func defaultImageData() -> Data? {
        guard let expectedImage = UIImage(systemName: "photo"),
              let expectedImageData = expectedImage.pngData() else {
            return nil
        }
        
        return expectedImageData
    }
    
    private func defaultNotImageData() -> Data? {
        "Different data".data(using: .utf8)
    }
    
    func testLoadImage_validURL_returnsImage() async throws {
        let expectedImageData = try XCTUnwrap(defaultImageData(), "Could not load system image for test.")
        let url = try XCTUnwrap(URL(string: defaultImageURLString), "Failed to construct URL from string: \(defaultImageURLString)")
        let sut = makeSUT(urlSession: MockURLSession(mockData: expectedImageData))
        let image = await sut.loadImage(from: url)
        
        XCTAssertNotNil(image, "Expected non-nil image for valid URL.")
    }
    
    func testLoadImage_errorFromURL_returnsNil() async throws {
        let sut = makeSUT(urlSession: MockURLSession(mockError: NSError(domain: "TestError", code: 1, userInfo: nil)))
        let url = try XCTUnwrap(URL(string: defaultImageURLString), "Failed to construct URL from string: \(defaultImageURLString)")
        let image = await sut.loadImage(from: url)
        
        XCTAssertNil(image, "Expected nil image for URL when error occurs.")
    }
    
    func testLoadImage_validURL_cachesImage() async throws {
        let expectedImageData = try XCTUnwrap(defaultImageData(), "Could not load system image for test.")
        let url = try XCTUnwrap(URL(string: defaultImageURLString), "Failed to construct URL from string: \(defaultImageURLString)")
        var mockSession = MockURLSession(mockData: expectedImageData)
        let sut = makeSUT(urlSession: mockSession)
        
        _ = await sut.loadImage(from: url)
        
        mockSession.resetData()
        let cachedImage = await sut.loadImage(from: url)
        
        XCTAssertNotNil(cachedImage, "Expected to retrieve the image from cache on subsequent load.")
    }
    
    func testLoadImage_validURL_returnsNilForNonImageData() async throws {
        let nonImageData = try XCTUnwrap(defaultNotImageData(), "Could not load data for test.")
        let url = try XCTUnwrap(URL(string: defaultNonImageURLString), "Failed to construct URL from string: \(defaultNonImageURLString)")
        let sut = makeSUT(urlSession: MockURLSession(mockData: nonImageData))
        let image = await sut.loadImage(from: url)
        
        XCTAssertNil(image, "Expected nil because the URL does not point to valid image data.")
    }
    
    func testLoadImage_invalidURL_returnsNil() async throws {
        let sut = makeSUT()
        let url = try XCTUnwrap(URL(string: invalidURLString), "Failed to construct URL from string: \(invalidURLString)")
        let image = await sut.loadImage(from: url)
        
        XCTAssertNil(image, "Expected nil for an invalid URL.")
    }
    
    func testLoadImage_validURL_repeatedRequestsUseCache() async throws {
        let expectedImageData = try XCTUnwrap(defaultImageData(), "Could not load system image for test.")
        let url = try XCTUnwrap(URL(string: defaultImageURLString), "Failed to construct URL from string: \(defaultImageURLString)")
        var mockSession = MockURLSession(mockData: expectedImageData)
        let sut = makeSUT(urlSession: mockSession)
        
        let firstLoadImage = await sut.loadImage(from: url)
        
        let nonImageData = try XCTUnwrap(defaultNotImageData(), "Could not load data for test.")
        
        mockSession.updateCurrentData(nonImageData)
        let secondLoadImage = await sut.loadImage(from: url)
        
        let firstUnwrappedImage = try XCTUnwrap(firstLoadImage, "Expected first load to successfully retrieve an image.")
        let secondUnwrappedImage = try  XCTUnwrap(secondLoadImage, "Expected second load to also retrieve an image, despite the mock session's change.")
        XCTAssertEqual(firstUnwrappedImage.pngData(), secondUnwrappedImage.pngData(), "Expected both loads to return the same image, indicating the second load used the cache.")
    }
}
