import UIKit

@objc class WebCodeViewController: UIViewController {

    private var textView = UITextView(frame: .zero)
    private var fileUrl: URL!

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    @objc init(filePath: String) {
        super.init(nibName: nil, bundle: nil)
        fileUrl = URL.init(fileURLWithPath: filePath)

        do {
            let contents = try String(contentsOf: fileUrl)
            textView.text = contents
        } catch {
            do {
                let contents = try String(contentsOf: fileUrl, encoding: .isoLatin1)
                textView.text = contents
            } catch {
                textView.text = NSLocalizedString("It was not possible to obtain the content of this file, as it is not encoded in either UTF-8 or ISO/IEC 8859-1.", comment: "Error message shown when the user tries to open a file with an unsupported encoding")
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        textView.isEditable = false
        textView.isSelectable = true
        textView.dataDetectorTypes = .all

        if let customFont = UIFont(name: "menlo", size: UIFont.labelFontSize) {
            textView.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: customFont)
            textView.adjustsFontForContentSizeCategory = true
        }

        view.addSubview(textView)
        view.backgroundColor = UIColor.white

        textView.translatesAutoresizingMaskIntoConstraints = false

        let margins = view.layoutMarginsGuide
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: margins.trailingAnchor)
        ])
        
        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalToSystemSpacingBelow: guide.topAnchor, multiplier: 1.0),
            guide.bottomAnchor.constraint(equalToSystemSpacingBelow: textView.bottomAnchor, multiplier: 1.0)
        ])

        let image = UIImage.init(named: "share")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(shareButtonTapped(sender:)))
        title = fileUrl.lastPathComponent
    }

    @objc func shareButtonTapped(sender: UIBarButtonItem) {
        let fileToShare = [fileUrl]
        let activityViewController = UIActivityViewController(activityItems: fileToShare as [Any], applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = sender
        self.present(activityViewController, animated: true, completion: nil)
    }
}
