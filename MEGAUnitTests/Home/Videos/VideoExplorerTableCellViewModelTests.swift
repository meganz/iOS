import XCTest
@testable import MEGA
import MEGADataMock

final class VideoExplorerTableCellViewModelTests: XCTestCase {
    private let videoName = "Video name for test.mp4"
    
    func testAttributedTitle_withNoLabelAndNoFavourite_titleShouldBeNameOnly() {
        let node = MockNode(handle: 1, name: videoName)
        let vm = VideoExplorerTableCellViewModel(node: node) { _, _ in }
        let attributedTitleForTest = vm.createAttributedTitle()
        let attributedTitle = NSAttributedString(string: videoName)
        XCTAssertEqual(attributedTitleForTest, attributedTitle)
    }
    
    func testAttributedTitle_withNoLabelAndFavourite_titleShouldBeNameAndFavourite() {
        let node = MockNode(handle: 1, name: videoName, isFavourite: true)
        let vm = VideoExplorerTableCellViewModel(node: node) { _, _ in }
        let attributedTitleForTest = createAttributedTitleForTest(by: vm)
        
        let attributedTitle = NSMutableAttributedString(string: videoName)
        let space = createSpace()
        let favouriteIcon = createImageAttachment(by: Asset.Images.Labels.favouriteSmall.image)
        attributedTitle.append(space)
        attributedTitle.append(favouriteIcon)
        
        XCTAssertEqual(attributedTitleForTest.string, attributedTitle.string)
        compareAttachmentImages(for: attributedTitle, with: attributedTitleForTest)
    }
    
    func testAttributedTitle_withLabelAndNoFavourite_titleShouldBeNameAndLabel() {
        let nodelabel = MEGANodeLabel(nodeLabelTypeEntity: .blue)
        guard let nodelabel = nodelabel,
              let labelName = MEGANode.string(for: nodelabel)?.appending("Small"),
              let labelImage = UIImage(named: labelName) else {
            XCTFail("Expect to create \(type(of: MEGANodeLabel.self)) instance and corresponding label image, but fail.")
            return
        }
        
        let node = MockNode(handle: 1, name: videoName, label: nodelabel)
        let vm = VideoExplorerTableCellViewModel(node: node) { _, _ in }
        let attributedTitleForTest = createAttributedTitleForTest(by: vm)
        
        let attributedTitle = NSMutableAttributedString(string: videoName)
        let space = createSpace()
        let label = createImageAttachment(by: labelImage)
        attributedTitle.append(space)
        attributedTitle.append(label)
        
        XCTAssertEqual(attributedTitleForTest.string, attributedTitle.string)
        compareAttachmentImages(for: attributedTitle, with: attributedTitleForTest)
    }
    
    func testAttributedTitle_withLabelAndFavourite_titleShouldBeNameWithLabelAndFavourite() {
        let nodelabel = MEGANodeLabel(nodeLabelTypeEntity: .blue)
        guard let nodelabel = nodelabel,
              let labelName = MEGANode.string(for: nodelabel)?.appending("Small"),
              let labelImage = UIImage(named: labelName) else {
            XCTFail("Expect to create \(type(of: MEGANodeLabel.self)) instance and corresponding label image, but fail.")
            return
        }
        
        let node = MockNode(handle: 1, name: videoName, label: nodelabel, isFavourite: true)
        let vm = VideoExplorerTableCellViewModel(node: node) { _, _ in }
        let attributedTitleForTest = createAttributedTitleForTest(by: vm)
        
        let attributedTitle = NSMutableAttributedString(string: videoName)
        let label = createImageAttachment(by: labelImage)
        let favouriteIcon = createImageAttachment(by: Asset.Images.Labels.favouriteSmall.image)
        attributedTitle.append(createSpace())
        attributedTitle.append(label)
        attributedTitle.append(createSpace())
        attributedTitle.append(favouriteIcon)
        
        XCTAssertEqual(attributedTitleForTest.string, attributedTitle.string)
        compareAttachmentImages(for: attributedTitle, with: attributedTitleForTest)
    }
    
    // MARK: - Private
    
    private func createAttributedTitleForTest(by vm: VideoExplorerTableCellViewModel) -> NSAttributedString {
        let attributedTitleForTest = vm.createAttributedTitle()
        
        guard let attributedTitleForTest = attributedTitleForTest else {
            XCTFail("The video name should not be nil")
            return NSAttributedString()
        }
        
        return attributedTitleForTest
    }
    
    private func createSpace(_ width: Double = 4) -> NSAttributedString {
        let spaceAttachment = NSTextAttachment()
        spaceAttachment.bounds = CGRect(x: 0, y: 0, width: width, height: 0)
        let space = NSAttributedString(attachment: spaceAttachment)
        return space
    }
    
    private func createImageAttachment(by image: UIImage) -> NSAttributedString {
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = image
        imageAttachment.bounds = CGRect(x: 0, y: 0, width: 12, height: 12)
        let attchmentString = NSAttributedString(attachment: imageAttachment)
        return attchmentString
    }
    
    private func compareAttachmentImages(for attributedTitle: NSAttributedString,
                                         with attributedTitleForTest: NSAttributedString) {
        attributedTitle.enumerateAttribute(.attachment,
                                           in: NSRange(location: 0, length: attributedTitle.length)) { value, range, _ in
            guard let attachment = value as? NSTextAttachment,
                  let image = attachment.image else {
                return
            }
            
            guard let attachmentForTest = attributedTitleForTest.attribute(.attachment, at: range.location, effectiveRange: nil) as? NSTextAttachment,
                  let imageForTest = attachmentForTest.image else {
                XCTFail("The video name should have attached image at this position")
                return
            }
            
            XCTAssertTrue(image.isEqual(imageForTest))
        }
    }
}
