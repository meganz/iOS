
import UIKit
import WebKit

@objc class HtmlViewController: UIViewController {
    
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
                let contents = try String(contentsOf: fileUrl, encoding: .isoLatin2)
                textView.text = contents
            } catch {
                textView.text = "It has not been possible to obtain the content of the file " + fileUrl.lastPathComponent + " ,it is not encoded in utf8 nor in iso latin 2."
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.isEditable = false
        textView.isSelectable = true
        textView.dataDetectorTypes = .all
        
        if #available(iOS 11.0, *) {
            if let customFont = UIFont(name: "menlo", size: UIFont.labelFontSize) {
                textView.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: customFont)
                textView.adjustsFontForContentSizeCategory = true
            }
        } else {
            textView.font = UIFont.preferredFont(forTextStyle: .body)
        }
        
        view.addSubview(textView)
        view.backgroundColor = UIColor.white
        
        textView.translatesAutoresizingMaskIntoConstraints = false
        
        let margins = view.layoutMarginsGuide
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: margins.trailingAnchor)
        ])
        
        if #available(iOS 11, *) {
            let guide = view.safeAreaLayoutGuide
            NSLayoutConstraint.activate([
                textView.topAnchor.constraint(equalToSystemSpacingBelow: guide.topAnchor, multiplier: 1.0),
                guide.bottomAnchor.constraint(equalToSystemSpacingBelow: textView.bottomAnchor, multiplier: 1.0)
            ])
            
        } else {
            let standardSpacing: CGFloat = 8.0
            NSLayoutConstraint.activate([
                textView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: standardSpacing),
                bottomLayoutGuide.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: standardSpacing)
            ])
        }
        
        let image = UIImage.init(named: "shareGray")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(shareButtonTapped(sender:)))
        title = fileUrl.lastPathComponent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    @objc func shareButtonTapped(sender: UIBarButtonItem) -> Void {
        let fileToShare = [fileUrl]
        let activityViewController = UIActivityViewController(activityItems: fileToShare as [Any], applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = sender
        self.present(activityViewController, animated: true, completion: nil)
    }
}
