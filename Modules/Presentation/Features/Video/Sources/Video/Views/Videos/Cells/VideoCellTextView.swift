import MEGAAssets
import MEGADomain
import MEGASwift
import SwiftUI

struct VideoCellTitleText: View {
    
    let videoConfig: VideoConfig
    let title: String
    let searchText: String?
    let labelImage: UIImage?
    let downloadedImage: UIImage?
    
    var body: some View {
        VideoCellTitleTextRepresentable(
            text: title,
            searchText: searchText,
            labelImage: labelImage,
            downloadedImage: downloadedImage,
            foregroundColor: UIColor(videoConfig.colorAssets.primaryTextColor),
            backgroundColor: UIColor(videoConfig.colorAssets.pageBackgroundColor),
            highlightedTextColor: UIColor(videoConfig.colorAssets.highlightedTextColor)
        )
    }
}

#Preview {
    VideoCellTitleText(
        videoConfig: .preview,
        title: "This a short text",
        searchText: nil,
        labelImage: MEGAAssets.UIImage.image(named: "RedSmall")!,
        downloadedImage: MEGAAssets.UIImage.image(named: "downloaded")!
    )
}

#Preview {
    VideoCellTitleText(
        videoConfig: .preview,
        title: "This is a long long long text that needs second line probabaly line probabaly",
        searchText: nil,
        labelImage: MEGAAssets.UIImage.image(named: "RedSmall")!,
        downloadedImage: MEGAAssets.UIImage.image(named: "downloaded")!
    )
}

#Preview {
    VideoCellTitleText(
        videoConfig: .preview,
        title: "This is a long long long text that needs second line probabaly line probabaly",
        searchText: nil,
        labelImage: MEGAAssets.UIImage.image(named: "RedSmall")!,
        downloadedImage: MEGAAssets.UIImage.image(named: "downloaded")!
    )
    .preferredColorScheme(.dark)
}

#Preview {
    VideoCellTitleText(
        videoConfig: .preview,
        title: "This is text with label image",
        searchText: nil,
        labelImage: MEGAAssets.UIImage.image(named: "RedSmall")!,
        downloadedImage: nil
    )
    .preferredColorScheme(.dark)
}

#Preview {
    VideoCellTitleText(
        videoConfig: .preview,
        title: "This is text with downloaded image",
        searchText: nil,
        labelImage: nil,
        downloadedImage: MEGAAssets.UIImage.image(named: "downloaded")!
    )
    .preferredColorScheme(.dark)
}

/// A UIViewRepresentable to display the title of a video cell.
/// Unfortunately, `SwiftUI.Text` does not render `NSAttachment`when using `AttributedString`. So this component is needed.
/// This view is used to display the title of a video cell.that contains specific rule :
/// - The title is displayed with a maximum of 2 lines.
/// - Always display labelImage if any after the end of the text.
private struct VideoCellTitleTextRepresentable: UIViewRepresentable {
    private var text: String
    private let searchText: String?
    private var labelImage: UIImage?
    private var downloadedImage: UIImage?
    private var foregroundColor: UIColor
    private var backgroundColor: UIColor
    private var highlightedTextColor: UIColor

    init(
        text: String,
        searchText: String?,
        labelImage: UIImage?,
        downloadedImage: UIImage?,
        foregroundColor: UIColor,
        backgroundColor: UIColor,
        highlightedTextColor: UIColor
    ) {
        self.text = text
        self.searchText = searchText
        self.labelImage = labelImage
        self.downloadedImage = downloadedImage
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.highlightedTextColor = highlightedTextColor
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView: UITextView = UITextView()
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.isSelectable = false
        updateMaximumNumberOfLines(for: textView)
        textView.textContainer.lineBreakMode = .byTruncatingMiddle
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.backgroundColor = backgroundColor
        removeContentInset(of: textView)
        monitorSizeCategoryChanged(on: textView)
        return textView
    }
    
    private func removeContentInset(of textView: UITextView) {
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = .zero
    }
    
    private func monitorSizeCategoryChanged(on textView: UITextView) {
        NotificationCenter.default.addObserver(
            forName: UIContentSizeCategory.didChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                updateMaximumNumberOfLines(for: textView)
                textView.attributedText = createAttributedTitle()
            }
        }
    }
    
    private func updateMaximumNumberOfLines(for textView: UITextView) {
        switch UIApplication.shared.preferredContentSizeCategory {
        case .extraSmall, .small, .medium, .large:
            textView.textContainer.maximumNumberOfLines = 2
        default:
            textView.textContainer.maximumNumberOfLines = 1
        }
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        textView.attributedText = createAttributedTitle()
    }
    
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        let proposedSize = proposal.replacingUnspecifiedDimensions(by: .init(
            width: CGFloat.greatestFiniteMagnitude,
            height: .greatestFiniteMagnitude))
        
        return uiView.sizeThatFits(proposedSize)
    }
    
    private func createAttributedTitle() -> NSAttributedString {
        let attributedTitle = NSMutableAttributedString(
            attributedString: text.highlightedStringWithKeyword(
                searchText,
                primaryTextColor: foregroundColor,
                highlightedTextColor: highlightedTextColor,
                normalBackgroundColor: backgroundColor,
                normalFont: .preferredFont(forTextStyle: .body),
                highlightedFont: .preferredFont(forTextStyle: .body)
            )
        )

        if let labelImage {
            let label = createImageAttachmentWithPadding(by: labelImage)
            attributedTitle.append(label)
        }
        
        if let downloadedImage {
            let label = createImageAttachmentWithPadding(by: downloadedImage)
            attributedTitle.append(label)
        }

        return attributedTitle
    }
    
    private func createImageAttachmentWithPadding(by image: UIImage, leadingPadding: Double = 4) -> NSAttributedString {
        let attachmentString = NSMutableAttributedString()
        if leadingPadding > 0 {
            let space = createSpace(leadingPadding)
            attachmentString.append(space)
        }
        let imageAttachment = createImageAttachment(by: image)
        attachmentString.append(imageAttachment)
        return attachmentString
    }
    
    private func createSpace(_ width: Double = 4) -> NSAttributedString {
        let spaceAttachment = NSTextAttachment()
        spaceAttachment.bounds = CGRect(x: 0, y: 0, width: width, height: 0)
        return NSAttributedString(attachment: spaceAttachment)
    }
    
    private func createImageAttachment(by image: UIImage) -> NSAttributedString {
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = image
        imageAttachment.bounds = CGRect(x: 0, y: 0, width: 12, height: 12)
        return NSAttributedString(attachment: imageAttachment)
    }
}
