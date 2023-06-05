import XCTest
@testable import MEGA
import MEGADataMock

final class VideoExplorerTableCellViewModelTests: XCTestCase {
    let videoName = "Video name for test.mp4"
    
    func testAttributedTitle_withNoLabelsAndNoFavourite_titleShouldBeNameOnly() {
        let node = MockNode(handle: 1, name: videoName)
        let vm = VideoExplorerTableCellViewModel(node: node) { _, _ in }
        let attributedTitleForTest = vm.createAttributedTitle()
        let attributedTitle = NSAttributedString(string: videoName)
        XCTAssertEqual(attributedTitleForTest, attributedTitle)
        
    }
    
    func testAttributedTitle_withNoLabelsAndFavourite_titleShouldBeNameAndFavourite() {
        let node = MockNode(handle: 1, name: videoName, isFavourite: true)
        let vm = VideoExplorerTableCellViewModel(node: node) { _, _ in }
        let attributedTitleForTest = vm.createAttributedTitle()
        
        guard let attributedTitleForTest = attributedTitleForTest else {
            XCTFail()
            return
        }
        
        let attributedTitle = NSMutableAttributedString(string: videoName)
        attributedTitle.append(createSpace())
        attributedTitle.append(createFavouriteIcon())
        
        XCTAssertEqual(attributedTitleForTest.string, attributedTitle.string)
        compareAttachmentImages(for: attributedTitle, with: attributedTitleForTest)
    }
    
    // MARK: - Private
    
    private func createSpace(_ width: Double = 4) -> NSAttributedString {
        let spaceAttachment = NSTextAttachment()
        spaceAttachment.bounds = CGRect(x:0, y: 0, width: width, height: 0)
        let space = NSAttributedString(attachment: spaceAttachment)
        return space
    }
    
    private func createFavouriteIcon() -> NSAttributedString {
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = Asset.Images.Labels.favouriteSmall.image
        imageAttachment.bounds = CGRect(x: 0, y: 0, width: 12, height: 12)
        let favouriteIcon = NSAttributedString(attachment: imageAttachment)
        return favouriteIcon
    }
    
    private func compareAttachmentImages(for attributedTitle: NSAttributedString,
                                         with attributedTitleForTest: NSAttributedString) {
        attributedTitle.enumerateAttribute(.attachment,
                                           in: NSRange(location: 0, length: attributedTitle.length)) { value, range, _ in
            if let attachment = value as? NSTextAttachment,
               let attachmentForTest = attributedTitleForTest.attribute(.attachment, at: range.location, effectiveRange: nil) as? NSTextAttachment,
               let image = attachment.image,
               let imageForTest = attachmentForTest.image {
                XCTAssertTrue(image.isEqual(imageForTest))
            }
        }
    }
}
