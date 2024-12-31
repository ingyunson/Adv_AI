import firebase_admin
from firebase_admin import credentials, firestore
import os
from dotenv import load_dotenv
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

load_dotenv()

def initialize_firebase():
    try:
        if not firebase_admin._apps:
            firebase_service_account = os.getenv('FIREBASE_SERVICE_ACCOUNT')
            if not firebase_service_account:
                logger.error("FIREBASE_SERVICE_ACCOUNT environment variable is not set.")
                raise ValueError("FIREBASE_SERVICE_ACCOUNT environment variable is not set.")
            
            logger.info(f"Loading Firebase credentials from: {firebase_service_account}")
            cred = credentials.Certificate(firebase_service_account)
            firebase_admin.initialize_app(cred)
            logger.info("Firebase initialized successfully.")
        else:
            logger.info("Firebase app already initialized.")
        return firestore.client()
    except Exception as e:
        logger.error(f"Failed to initialize Firebase: {e}")
        raise

db = initialize_firebase()