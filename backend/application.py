"""
Main application entry point for Azure App Service
Simple WSGI application factory
"""

from wsgi import application

if __name__ == "__main__":
    application.run()
