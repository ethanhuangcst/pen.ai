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
    func sendPasswordResetEmail(to email: String, resetToken: String) async -> Bool {
        print("[EmailService] Sending password reset email to: \(email)")
        
        // Construct reset URL
        let resetURL = "https://pen.ai/reset-password?token=\(resetToken)"
        
        // Email content - plain text version
        let subject = "Reset your Pen AI password"
        let body = """
Password Reset Request

Hello,

You requested a password reset for your Pen AI account. Please click the link below to reset your password:

\(resetURL)

If you didn't request this, you can safely ignore this email.

Best regards,
The Pen AI Team
"""



        
        return await sendEmail(to: email, subject: subject, body: body, isHTML: false)
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