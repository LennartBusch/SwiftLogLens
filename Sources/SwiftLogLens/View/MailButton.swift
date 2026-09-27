//
//  MailButton.swift
//  SwiftLogLens
//
//  Created by Lennart Busch on 27.09.26.
//

import SwiftUI

#if canImport(MessageUI)
import MessageUI

public struct LogLensMailButton: View {
    @State private var showMailComposer = false
    @State private var showMailUnavailableAlert = false
    var attachmentURL: URL?
    let subject: String
    let mailBody: String
    let recipient: String
    let buttonText: String
    
    public init(
        buttonText: String = "Send logs via email",
        attachmentURL: URL? = LogStore.logURL,
        subject: String,
        mailBody: String,
        recipient: String
    ) {
        self.buttonText = buttonText
        self.attachmentURL = attachmentURL
        self.subject = subject
        self.mailBody = mailBody
        self.recipient = recipient
    }
    
    public var body: some View {
        Button(buttonText) {
            if MFMailComposeViewController.canSendMail() {
                showMailComposer = true
            } else {
                showMailUnavailableAlert = true
            }
        }
        .sheet(isPresented: $showMailComposer) {
            MailComposerView(
                recipient: recipient,
                subject: subject,
                body: mailBody,
                attachmentURL: attachmentURL
            )
        }
        .alert("Mail not available", isPresented: $showMailUnavailableAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please configure the Mail app on this device to send logs via email.")
        }

    }
}

#endif
