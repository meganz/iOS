import MEGAAssets
import MEGADomain
import SwiftUI
@testable import Video
import XCTest

class VideoCellPreviewEntityTests: XCTestCase {
    
    // MARK: - Equality

    func testVideoCellPreviewEntity_whenCompared_shouldEqual() {
        let sut1 = VideoCellPreviewEntity.placeholder
        let sut2 = VideoCellPreviewEntity.placeholder
        
        XCTAssertEqual(sut1, sut2, "Placeholder entities should be equal")
    }
    
    // MARK: - shouldShowCircleImage
    
    func testShouldShowCircleImage_whenNodeIsExported_returnsTrue() {
        let sut = makeSUT(isExported: true)
        
        let shouldShowCircleImage = sut.shouldShowCircleImage
        
        XCTAssertTrue(shouldShowCircleImage, "Should show circle image when video is exported")
    }
    
    func testShouldShowCircleImage_whenNodeNotIsExported_returnsFalse() {
        let sut = makeSUT(isExported: false)
        
        let shouldShowCircleImage = sut.shouldShowCircleImage
        
        XCTAssertFalse(shouldShowCircleImage, "Should not show circle image when video is not exported")
    }
    
    // MARK: - labelImage
    
    func testLabelImage_whenLabelIsNil_returnsNilImage() {
        let sut = makeSUT(label: nil)
        
        let image = sut.labelImage(source: labelAssets())
        
        XCTAssertNil(image)
    }
    
    func testLabelImage_whenLabelIsUnknown_returnsNilImage() {
        let sut = makeSUT(label: .unknown)
        
        let image = sut.labelImage(source: labelAssets())
        
        XCTAssertNil(image)
    }
    
    func testLabelImage_whenHasLabel_returnsCorrectImage() {
        let samples: [NodeLabelTypeEntity] = NodeLabelTypeEntity.allCases.filter { $0 != .unknown }
        samples.enumerated().forEach { (index, label) in
            let sut = makeSUT(label: label)
            
            let image = sut.labelImage(source: labelAssets())
            
            assertCorrectLabelImageRendered(image!, at: index)
        }
    }
    
    // MARK: - Helpers
    
    private func makeSUT(isExported: Bool = false, label: NodeLabelTypeEntity? = nil) -> VideoCellPreviewEntity {
        VideoCellPreviewEntity(
            isFavorite: false,
            imageContainer: PreviewImageContainerFactory.withColor(.black, size: CGSize(width: 1000, height: 1000)),
            duration: "",
            title: "title",
            description: nil,
            searchText: nil,
            size: "size",
            isExported: isExported,
            label: label,
            hasThumbnail: true,
            isDownloaded: true
        )
    }
    
    private func assertCorrectLabelImageRendered(_ label: UIImage, at index: Int, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(label, labelImageDictionary[index], "Unmatch color at index: \(index)", file: file, line: line)
    }
    
    private lazy var labelImageDictionary: [Int: UIImage] = [
        0: redImage(),
        1: orangeImage(),
        2: yellowImage(),
        3: greenImage(),
        4: blueImage(),
        5: purpleImage(),
        6: greyImage()
    ]
    
    private func labelAssets() -> VideoConfig.RowAssets.LabelAssets {
        VideoConfig.RowAssets.LabelAssets(
            redImage: redImage(),
            orangeImage: orangeImage(),
            yellowImage: yellowImage(),
            greenImage: greenImage(),
            blueImage: blueImage(),
            purpleImage: purpleImage(),
            greyImage: greyImage()
        )
    }
    
    private func redImage() -> UIImage { image(named: "RedSmall") }
    
    private func orangeImage() -> UIImage { image(named: "OrangeSmall") }
    
    private func yellowImage() -> UIImage { image(named: "YellowSmall") }
    
    private func greenImage() -> UIImage { image(named: "GreenSmall") }
    
    private func blueImage() -> UIImage { image(named: "BlueSmall") }
    
    private func purpleImage() -> UIImage { image(named: "PurpleSmall") }
    
    private func greyImage() -> UIImage { image(named: "GreySmall") }
    
    private func image(named: String) -> UIImage {
        guard let image = MEGAAssetsImageProvider.image(named: named) else {
            fatalError("Could not found color from asset named: \(named)")
        }
        return image
    }
}
