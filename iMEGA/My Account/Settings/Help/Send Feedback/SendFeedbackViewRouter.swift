import ChatRepo
import LogRepo
import MEGAAppPresentation
import MEGADomain
import MEGAL10n
import MessageUI

final class SendFeedbackViewRouter: Routing {
    private weak var presenter: UIViewController?
    private var feedbackEntity: FeedbackEntity
    
    init(presenter: UIViewController, feedbackEntity: FeedbackEntity) {
        self.presenter = presenter
        self.feedbackEntity = feedbackEntity
    }
    
    func build() -> UIViewController {
        guard let presenter = presenter as? any MFMailComposeViewControllerDelegate else {
            return UIViewController()
        }

        let mailComposeVC = createMailComposeController(presenter)
        
        return mailComposeVC
    }
    
    @objc func start() {
        if MFMailComposeViewController.canSendMail() {
            presenter?.present(build(), animated: true)
        } else {
            guard let url = createEmailUrl(to: feedbackEntity.toEmail,
                                           subject: feedbackEntity.subject,
                                           body: feedbackEntity.messageBody) else { return }
            
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    private func createMailComposeController(_ presenter: some MFMailComposeViewControllerDelegate) -> MFMailComposeViewController {
        let mailComposeVC = MFMailComposeViewController()
        mailComposeVC.mailComposeDelegate = presenter
        mailComposeVC.setToRecipients([feedbackEntity.toEmail])
        mailComposeVC.setSubject(feedbackEntity.subject)
        mailComposeVC.setMessageBody(feedbackEntity.messageBody, isHTML: false)
        return mailComposeVC
    }
    
    private func createEmailUrl(to: String, subject: String, body: String) -> URL? {
        guard let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let bodyEncoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        
        return URL(string: "mailto:\(to)?subject=\(subjectEncoded)&body=\(bodyEncoded)")
    }
    
    private func createReportIssueAlertController(_ mailComposeVC: MFMailComposeViewController) -> UIViewController {
        let alertController = UIAlertController(title: Strings.Localizable.Help.ReportIssue.AttachLogFiles.title,
                                                message: Strings.Localizable.Help.ReportIssue.AttachLogFiles.message,
                                                preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: Strings.Localizable.yes, style: .default) { [weak self] _ in
            guard let `self` = self else { return }
            if let logsURL = LogFileCompressor().compressedFileURL(sourceURL: Logger.shared().logsDirectoryUrl, toNewFilename: self.feedbackEntity.logsFileName),
                let data = LogFileCompressor().compressedData(url: logsURL) {
                mailComposeVC.addAttachmentData(data, mimeType: "text/plain", fileName: self.feedbackEntity.logsFileName)
            }
            self.presenter?.present(mailComposeVC, animated: true)
        })
        
        alertController.addAction(UIAlertAction(title: Strings.Localizable.no, style: .cancel) { [weak self] _ in
            self?.presenter?.present(mailComposeVC, animated: true)
        })
        
        return alertController
    }
}
