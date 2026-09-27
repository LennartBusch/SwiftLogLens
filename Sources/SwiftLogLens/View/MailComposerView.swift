//
//  MailComposerView.swift
//  SwiftLogLens
//
//  Created by Lennart Busch on 27.09.26.
//

import SwiftUI
#if canImport(MessageUI)
import MessageUI


struct MailComposerView: UIViewControllerRepresentable {
    let recipient: String
    let subject: String
    let body: String
    let attachmentURL: URL?

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            Task { @MainActor in
                controller.dismiss(animated: true)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        controller.setToRecipients([recipient])
        controller.setSubject(subject)
        controller.setMessageBody(body, isHTML: false)

        if let attachmentURL, let data = try? Data(contentsOf: attachmentURL) {
            controller.addAttachmentData(
                data,
                mimeType: "text/plain",
                fileName: attachmentURL.lastPathComponent
            )
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
    }
}

#endif
