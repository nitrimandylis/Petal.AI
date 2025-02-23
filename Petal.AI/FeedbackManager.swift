import Foundation
import MessageUI

class ReportManager {
    static let shared = ReportManager()
    private let recipientEmail = "nikolas.trim8@gmail.com"
    
    private init() {}
    
    func sendReport(title: String, description: String, from viewController: UIViewController) {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = viewController as? MFMailComposeViewControllerDelegate
            mail.setToRecipients([recipientEmail])
            mail.setSubject("Issue Report: \(title)")
            
            let body = """
            Issue Report
            Title: \(title)
            Description: \(description)
            Date: \(Date())
            """
            
            mail.setMessageBody(body, isHTML: false)
            viewController.present(mail, animated: true)
        } else {
            let alert = UIAlertController(
                title: "Email Not Available",
                message: "Please set up an email account on your device to send reports.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            viewController.present(alert, animated: true)
        }
    }
}