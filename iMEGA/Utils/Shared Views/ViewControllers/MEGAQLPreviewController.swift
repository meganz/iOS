import MEGADesignToken
import MEGASwift
import QuickLook
import UIKit

final class MEGAQLPreviewController: QLPreviewController, QLPreviewControllerDelegate, QLPreviewControllerDataSource {

    private var files: [String] = []

    @objc init(arrayOfFiles files: [String]) {
        super.init(nibName: nil, bundle: nil)
        self.files = files
        self.delegate = self
        self.dataSource = self
    }
    
    @objc init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.backgroundColor = TokenColors.Background.page
    }

    // MARK: - QLPreviewControllerDataSource

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        files.count
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> any QLPreviewItem {
        URL(fileURLWithPath: files[safe: index] ?? "") as (any QLPreviewItem)
    }

    // MARK: - QLPreviewControllerDelegate

    func previewController(_ controller: QLPreviewController, shouldOpen url: URL, for item: any QLPreviewItem) -> Bool {
        DispatchQueue.main.async {
            MEGALinkManager.linkURL = url
            MEGALinkManager.processLinkURL(url)
        }
        return false
    }
}
