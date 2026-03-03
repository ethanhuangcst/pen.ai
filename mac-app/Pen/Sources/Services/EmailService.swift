import Foundation
import SwiftSMTP

class EmailService {
    // MARK: - Singleton
    static let shared = EmailService()
    private init() {}
    
    // MARK: - Properties
    private let config = EmailConfig.shared
    private var smtpServer: String { return config.smtpServer }
    private var smtpPort: Int { return config.smtpPort }
    private var smtpUsername: String { return config.smtpUsername }
    private var smtpPassword: String { return config.smtpPassword }
    private var fromEmail: String { return config.fromEmail }
    private var fromName: String { return config.fromName }
    
    // MARK: - Public Methods
    
    /// Sends a password reset email
    func sendPasswordResetEmail(to email: String, temporaryPassword: String) async -> Bool {
        print("[EmailService] Sending password reset email to: \(email)")
        
        // Email content - plain text version with i18n support
        let subject = LocalizationService.shared.localizedString(for: "password_reset_email_subject")
        let greeting = LocalizationService.shared.localizedString(for: "password_reset_email_greeting")
        let body = LocalizationService.shared.localizedString(for: "password_reset_email_body")
        let temporaryPasswordLine = String(format: LocalizationService.shared.localizedString(for: "password_reset_email_temporary_password"), temporaryPassword)
        let instruction = LocalizationService.shared.localizedString(for: "password_reset_email_instruction")
        let footer = LocalizationService.shared.localizedString(for: "password_reset_email_footer")
        let signature = LocalizationService.shared.localizedString(for: "password_reset_email_signature")
        
        let emailBody = """
Password Reset Request

\(greeting)

\(body)

\(temporaryPasswordLine)

\(instruction)

\(footer)

\(signature)
"""

        return await sendEmail(to: email, subject: subject, body: emailBody, isHTML: false)
    }
    
    /// Sends a generic email
    private func sendEmail(to recipient: String, subject: String, body: String, isHTML: Bool) async -> Bool {
        do {
            // Create SMTP instance
            let smtp = SMTP(
                hostname: smtpServer,
                email: smtpUsername,
                password: smtpPassword,
                port: Int32(smtpPort)
            )
            
            // Create mail message
            let mail = Mail(
                from: Mail.User(name: fromName, email: fromEmail),
                to: [Mail.User(name: "", email: recipient)],
                subject: subject,
                text: body
            )
            
            // Send email
            try smtp.send(mail)
            
            print("[EmailService] Email sent successfully to: \(recipient)")
            
            return true
        } catch {
            print("[EmailService] Failed to send email: \(error)")
            return false
        }
    }
}