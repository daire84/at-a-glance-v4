import os
import json
import shutil
import logging
from datetime import datetime

logger = logging.getLogger(__name__)

def ensure_directory(directory_path):
    """
    Ensure a directory exists, creating it if needed
    """
    try:
        os.makedirs(directory_path, exist_ok=True)
        return True
    except Exception as e:
        logger.error(f"Error creating directory {directory_path}: {str(e)}")
        return False

def save_json_file(file_path, data):
    """
    Save data to a JSON file
    """
    try:
        # Ensure directory exists
        directory = os.path.dirname(file_path)
        ensure_directory(directory)
        
        # Write data to file
        with open(file_path, 'w') as f:
            json.dump(data, f, indent=2)
        
        return True
    except Exception as e:
        logger.error(f"Error saving JSON file {file_path}: {str(e)}")
        return False

def load_json_file(file_path, default=None):
    """
    Load data from a JSON file
    """
    try:
        if not os.path.exists(file_path):
            return default
        
        with open(file_path, 'r') as f:
            return json.load(f)
    except Exception as e:
        logger.error(f"Error loading JSON file {file_path}: {str(e)}")
        return default

def backup_project_data(data_dir, backup_dir):
    """
    Create a backup of all project data
    """
    try:
        # Ensure backup directory exists
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_path = os.path.join(backup_dir, f"backup_{timestamp}")
        ensure_directory(backup_path)
        
        # Copy all files from data directory
        shutil.copytree(data_dir, backup_path, dirs_exist_ok=True)
        
        logger.info(f"Backup created at {backup_path}")
        return backup_path
    except Exception as e:
        logger.error(f"Error creating backup: {str(e)}")
        return None

def restore_backup(backup_path, data_dir):
    """
    Restore data from a backup
    """
    try:
        if not os.path.exists(backup_path):
            logger.error(f"Backup path {backup_path} does not exist")
            return False
        
        # Copy files from backup to data directory
        shutil.copytree(backup_path, data_dir, dirs_exist_ok=True)
        
        logger.info(f"Restored backup from {backup_path}")
        return True
    except Exception as e:
        logger.error(f"Error restoring backup: {str(e)}")
        return False
