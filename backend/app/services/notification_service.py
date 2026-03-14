import smtplib
import requests
import json
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from flask import current_app

class NotificationService:
    """Service for sending emails and SMS"""
    
    @staticmethod
    def send_email(to_email, subject, message, html_content=None):
        """Send email using SMTP"""
        try:
            # For development, simulate email sending
            print(f"📧 SIMULATED EMAIL SENT TO: {to_email}")
            print(f"📧 SUBJECT: {subject}")
            print(f"📧 MESSAGE: {message}")
            print("=" * 50)
            
            # Return success for development
            return True, "Email sent successfully (simulated for development)"
            
            # Uncomment below for actual email sending
            # Email configuration (you can move this to environment variables)
            # smtp_server = "smtp.gmail.com"  # Change as needed
            # smtp_port = 587
            # sender_email = "your-app@gmail.com"  # Replace with your email
            # sender_password = "your-app-password"  # Replace with your app password
            # 
            # # Create message
            # msg = MIMEMultipart('alternative')
            # msg['From'] = sender_email
            # msg['To'] = to_email
            # msg['Subject'] = subject
            # 
            # # Add text content
            # text_part = MIMEText(message, 'plain')
            # msg.attach(text_part)
            # 
            # # Add HTML content if provided
            # if html_content:
            #     html_part = MIMEText(html_content, 'html')
            #     msg.attach(html_part)
            # 
            # # Send email
            # with smtplib.SMTP(smtp_server, smtp_port) as server:
            #     server.starttls()
            #     server.login(sender_email, sender_password)
            #     server.send_message(msg)
            # 
            # return True, "Email sent successfully"
            
        except Exception as e:
            print(f"Email sending error: {e}")
            return False, f"Failed to send email: {str(e)}"
    
    @staticmethod
    def send_sms(phone_number, message):
        """Send SMS using SMS gateway (implement based on your provider)"""
        try:
            # Example using Twilio (you'll need to install twilio: pip install twilio)
            # from twilio.rest import Client
            # 
            # account_sid = 'your_account_sid'
            # auth_token = 'your_auth_token'
            # client = Client(account_sid, auth_token)
            # 
            # message = client.messages.create(
            #     body=message,
            #     from_='+1234567890',  # Your Twilio phone number
            #     to=phone_number
            # )
            # 
            # return True, "SMS sent successfully"
            
            # For now, we'll simulate SMS sending (replace with actual implementation)
            print(f"SMS would be sent to {phone_number}: {message}")
            return True, "SMS sent successfully (simulated)"
            
        except Exception as e:
            print(f"SMS sending error: {e}")
            return False, f"Failed to send SMS: {str(e)}"
    
    @staticmethod
    def send_registration_otp_email(to_email, name, otp):
        """Send registration OTP via email"""
        subject = "Verify Your Account - Medical App"
        
        text_message = f"""
Dear {name},

Thank you for registering with Medical App!

Your email verification OTP is: {otp}

This OTP is valid for 10 minutes. Please enter this code to complete your account verification.

If you didn't request this, please ignore this email.

Best regards,
Medical App Team
        """
        
        html_message = f"""
        <html>
        <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
            <div style="background-color: #f8f9fa; padding: 30px; border-radius: 10px;">
                <h2 style="color: #2c3e50; text-align: center;">Welcome to Medical App!</h2>
                
                <p style="color: #34495e; font-size: 16px;">Dear {name},</p>
                
                <p style="color: #34495e; font-size: 16px;">
                    Thank you for registering with Medical App. To complete your account verification, 
                    please use the following OTP:
                </p>
                
                <div style="text-align: center; margin: 30px 0;">
                    <span style="font-size: 36px; font-weight: bold; color: #e74c3c; 
                                 background-color: #fff; padding: 15px 25px; 
                                 border-radius: 8px; border: 2px dashed #e74c3c;">
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
                    Best regards,<br>
                    Medical App Team
                </p>
            </div>
        </body>
        </html>
        """
        
        return NotificationService.send_email(to_email, subject, text_message, html_message)
    
    @staticmethod
    def send_registration_otp_sms(phone_number, name, otp):
        """Send registration OTP via SMS"""
        message = f"Dear {name}, Your Medical App verification OTP is: {otp}. Valid for 10 minutes. Do not share with anyone."
        return NotificationService.send_sms(phone_number, message)
    
    @staticmethod
    def send_account_created_notification(email, name):
        """Send account creation confirmation"""
        subject = "Account Created Successfully - Medical App"
        
        text_message = f"""
Dear {name},

Your Medical App account has been created successfully!

You can now login and start using our services.

Welcome to Medical App!

Best regards,
Medical App Team
        """
        
        html_message = f"""
        <html>
        <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
            <div style="background-color: #d4edda; padding: 30px; border-radius: 10px; border: 1px solid #c3e6cb;">
                <h2 style="color: #155724; text-align: center;">🎉 Account Created Successfully!</h2>
                
                <p style="color: #155724; font-size: 16px;">Dear {name},</p>
                
                <p style="color: #155724; font-size: 16px;">
                    Welcome to Medical App! Your account has been created successfully and you can now 
                    access all our healthcare services.
                </p>
                
                <div style="text-align: center; margin: 30px 0;">
                    <a href="#" style="background-color: #28a745; color: white; padding: 12px 30px; 
                                      text-decoration: none; border-radius: 5px; font-weight: bold;">
                        Login Now
                    </a>
                </div>
                
                <p style="color: #155724; font-size: 16px;">
                    Thank you for choosing Medical App for your healthcare needs.
                </p>
                
                <hr style="border: none; border-top: 1px solid #c3e6cb; margin: 30px 0;">
                
                <p style="color: #6c757d; font-size: 12px; text-align: center;">
                    Best regards,<br>
                    Medical App Team
                </p>
            </div>
        </body>
        </html>
        """
        
        return NotificationService.send_email(email, subject, text_message, html_message)
    
    @staticmethod
    def send_password_reset_otp_email(email, name, otp):
        """Send password reset OTP via email"""
        subject = "Password Reset OTP - Medical App"
        
        text_message = f"""
Hi {name},

You have requested to reset your password for your Medical App account.

Your OTP for password reset is: {otp}

This OTP will expire in 10 minutes.

If you did not request this password reset, please ignore this email or contact support if you have concerns.

Best regards,
Medical App Team
        """
        
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
                
                <p style="color: #333; font-size: 16px;">
                    Hi {name},
                </p>
                
                <p style="color: #333; font-size: 16px;">
                    You have requested to reset your password for your Medical App account.
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
                    Best regards,<br>
                    Medical App Team
                </p>
            </div>
        </body>
        </html>
        """
        
        return NotificationService.send_email(email, subject, text_message, html_message)
    
    @staticmethod
    def send_password_reset_otp_sms(phone, otp):
        """Send password reset OTP via SMS"""
        message = f"Your Medical App password reset OTP is: {otp}. Valid for 10 minutes. Do not share this code."
        return NotificationService.send_sms(phone, message)