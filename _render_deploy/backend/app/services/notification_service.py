"""
Notification service.

Sends emails via Gmail SMTP when `SMTP_HOST`/`SMTP_USERNAME`/`SMTP_PASSWORD`
are configured, otherwise falls back to a no-op "simulated send" that just
logs the payload (handy for local development).

SMS helpers remain in place for programmatic callers but the product UI
has been switched to email-only OTP. They no-op in production unless a
Twilio integration is wired up.
"""

from __future__ import annotations

import os
import smtplib
import logging
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.utils import formataddr

logger = logging.getLogger(__name__)

APP_NAME = "Seevak Care"


def _smtp_config():
    """Return (host, port, user, password, from_name) or None if unset."""
    host = os.environ.get("SMTP_HOST", "").strip()
    user = os.environ.get("SMTP_USERNAME", "").strip()
    pwd = (os.environ.get("SMTP_PASSWORD") or "").replace(" ", "")
    if not (host and user and pwd):
        return None
    port = int(os.environ.get("SMTP_PORT", "587"))
    from_name = os.environ.get("SMTP_FROM_NAME", APP_NAME)
    return host, port, user, pwd, from_name


class NotificationService:
    """Service for sending emails and SMS."""

    # ------------------------------------------------------------------
    # Low-level delivery
    # ------------------------------------------------------------------
    @staticmethod
    def send_email(to_email, subject, message, html_content=None):
        cfg = _smtp_config()
        if cfg is None:
            logger.info("SIMULATED EMAIL to=%s subject=%s", to_email, subject)
            logger.info("BODY: %s", message[:500])
            return True, "Email sent (simulated - SMTP env vars not set)"

        host, port, user, pwd, from_name = cfg

        msg = MIMEMultipart("alternative")
        msg["From"] = formataddr((from_name, user))
        msg["To"] = to_email
        msg["Subject"] = subject
        msg.attach(MIMEText(message, "plain", "utf-8"))
        if html_content:
            msg.attach(MIMEText(html_content, "html", "utf-8"))

        try:
            with smtplib.SMTP(host, port, timeout=20) as server:
                server.ehlo()
                server.starttls()
                server.ehlo()
                server.login(user, pwd)
                server.sendmail(user, [to_email], msg.as_string())
            logger.info("Email delivered via %s to %s (subject=%s)", host, to_email, subject)
            return True, "Email sent successfully"
        except Exception as exc:
            logger.exception("SMTP send failed for %s: %s", to_email, exc)
            return False, f"Failed to send email: {exc}"

    @staticmethod
    def send_sms(phone_number, message):
        """No-op unless a Twilio integration is wired up.

        We keep this for forward-compatibility but the product UI now only
        offers email-based OTP, so this should rarely be called.
        """
        logger.info("SIMULATED SMS to=%s body=%s", phone_number, message[:160])
        return True, "SMS sent (simulated - provider not configured)"

    # ------------------------------------------------------------------
    # Registration OTP
    # ------------------------------------------------------------------
    @staticmethod
    def send_registration_otp_email(to_email, name, otp):
        subject = f"Verify Your Account - {APP_NAME}"
        text_message = (
            f"Dear {name},\n\n"
            f"Thank you for registering with {APP_NAME}.\n\n"
            f"Your email verification OTP is: {otp}\n\n"
            "This OTP is valid for 10 minutes. Please enter this code to complete your account verification.\n\n"
            "If you didn't request this, please ignore this email.\n\n"
            f"Best regards,\n{APP_NAME} Team\n"
        )

        html_message = f"""
        <html>
        <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
            <div style="background-color: #f8f9fa; padding: 30px; border-radius: 10px;">
                <h2 style="color: #2c3e50; text-align: center;">Welcome to {APP_NAME}!</h2>
                <p style="color: #34495e; font-size: 16px;">Dear {name},</p>
                <p style="color: #34495e; font-size: 16px;">
                    Thank you for registering with {APP_NAME}. To complete your account verification,
                    please use the following OTP:
                </p>
                <div style="text-align: center; margin: 30px 0;">
                    <span style="font-size: 36px; font-weight: bold; color: #e74c3c;
                                 background-color: #fff; padding: 15px 25px;
                                 border-radius: 8px; border: 2px dashed #e74c3c; letter-spacing: 8px;">
                        {otp}
                    </span>
                </div>
                <p style="color: #7f8c8d; font-size: 14px; text-align: center;">
                    This OTP is valid for 10 minutes only.
                </p>
                <p style="color: #34495e; font-size: 16px;">
                    If you didn't request this verification, please ignore this email.
                </p>
                <hr style="border: none; border-top: 1px solid #ecf0f1; margin: 30px 0;">
                <p style="color: #7f8c8d; font-size: 12px; text-align: center;">
                    Best regards,<br>{APP_NAME} Team
                </p>
            </div>
        </body>
        </html>
        """
        return NotificationService.send_email(to_email, subject, text_message, html_message)

    @staticmethod
    def send_registration_otp_sms(phone_number, name, otp):
        """Kept for backward-compat. UI no longer triggers this path."""
        message = (
            f"Dear {name}, Your {APP_NAME} verification OTP is: {otp}. "
            "Valid for 10 minutes. Do not share with anyone."
        )
        return NotificationService.send_sms(phone_number, message)

    # ------------------------------------------------------------------
    # Account created confirmation
    # ------------------------------------------------------------------
    @staticmethod
    def send_account_created_notification(email, name):
        subject = f"Account Created Successfully - {APP_NAME}"
        text_message = (
            f"Dear {name},\n\n"
            f"Your {APP_NAME} account has been created successfully!\n\n"
            "You can now log in and start using our services.\n\n"
            f"Welcome to {APP_NAME}!\n\n"
            f"Best regards,\n{APP_NAME} Team\n"
        )
        html_message = f"""
        <html>
        <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
            <div style="background-color: #d4edda; padding: 30px; border-radius: 10px; border: 1px solid #c3e6cb;">
                <h2 style="color: #155724; text-align: center;">Account Created Successfully</h2>
                <p style="color: #155724; font-size: 16px;">Dear {name},</p>
                <p style="color: #155724; font-size: 16px;">
                    Welcome to {APP_NAME}! Your account has been created successfully and you can now
                    access all our healthcare services.
                </p>
                <p style="color: #155724; font-size: 16px;">
                    Thank you for choosing {APP_NAME} for your healthcare needs.
                </p>
                <hr style="border: none; border-top: 1px solid #c3e6cb; margin: 30px 0;">
                <p style="color: #6c757d; font-size: 12px; text-align: center;">
                    Best regards,<br>{APP_NAME} Team
                </p>
            </div>
        </body>
        </html>
        """
        return NotificationService.send_email(email, subject, text_message, html_message)

    # ------------------------------------------------------------------
    # Password reset OTP
    # ------------------------------------------------------------------
    @staticmethod
    def send_password_reset_otp_email(email, name, otp):
        subject = f"Password Reset OTP - {APP_NAME}"
        text_message = (
            f"Hi {name},\n\n"
            f"You have requested to reset your password for your {APP_NAME} account.\n\n"
            f"Your OTP for password reset is: {otp}\n\n"
            "This OTP will expire in 10 minutes.\n\n"
            "If you did not request this password reset, please ignore this email or contact support "
            "if you have concerns.\n\n"
            f"Best regards,\n{APP_NAME} Team\n"
        )
        html_message = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body {{ font-family: Arial, sans-serif; line-height: 1.6; }}
                .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                .otp-box {{ background-color: #fff3cd; border: 2px solid #ffc107;
                           border-radius: 8px; padding: 20px; margin: 20px 0; text-align: center; }}
                .otp-code {{ font-size: 32px; font-weight: bold; color: #856404;
                            letter-spacing: 5px; margin: 10px 0; }}
                .warning {{ background-color: #fff3cd; border-left: 4px solid #ffc107;
                           padding: 15px; margin: 20px 0; }}
            </style>
        </head>
        <body>
            <div class="container">
                <h2 style="color: #856404;">Password Reset Request</h2>
                <p style="color: #333; font-size: 16px;">Hi {name},</p>
                <p style="color: #333; font-size: 16px;">
                    You have requested to reset your password for your {APP_NAME} account.
                </p>
                <div class="otp-box">
                    <p style="color: #856404; font-size: 18px; margin: 0;">Your OTP Code:</p>
                    <p class="otp-code">{otp}</p>
                    <p style="color: #856404; font-size: 14px; margin: 0;">
                        This OTP will expire in 10 minutes
                    </p>
                </div>
                <div class="warning">
                    <p style="color: #856404; margin: 0;">
                        <strong>Security Notice:</strong> If you did not request this password reset,
                        please ignore this email or contact support immediately if you have concerns.
                    </p>
                </div>
                <hr style="border: none; border-top: 1px solid #ffc107; margin: 30px 0;">
                <p style="color: #6c757d; font-size: 12px; text-align: center;">
                    Best regards,<br>{APP_NAME} Team
                </p>
            </div>
        </body>
        </html>
        """
        return NotificationService.send_email(email, subject, text_message, html_message)

    @staticmethod
    def send_password_reset_otp_sms(phone, otp):
        """Kept for backward-compat. UI no longer triggers this path."""
        message = (
            f"Your {APP_NAME} password reset OTP is: {otp}. "
            "Valid for 10 minutes. Do not share this code."
        )
        return NotificationService.send_sms(phone, message)
