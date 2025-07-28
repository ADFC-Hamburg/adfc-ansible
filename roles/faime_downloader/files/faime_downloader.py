#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
FAI Downloader

A tool to send POST requests to fai-project.org with YAML configuration.
Supports file uploads and automatic MIME type detection.
"""

import argparse
import logging
import mimetypes
import re
import time
import urllib.parse
from pathlib import Path
from typing import Dict, Any, Tuple, Optional

import requests
import yaml

FAI_URL = "https://fai-project.org/cgi/faime.cgi"

# Configure logger
logger = logging.getLogger(__name__)


def load_yaml_config(path: str) -> Dict[str, Any]:
    """
    Load configuration from a YAML file.

    Args:
        path: Path to the YAML configuration file

    Returns:
        Dictionary containing the parsed YAML configuration

    Raises:
        FileNotFoundError: If the config file doesn't exist
        yaml.YAMLError: If the YAML file is malformed
    """
    try:
        with open(path, "r", encoding="utf-8") as f:
            return yaml.safe_load(f)
    except FileNotFoundError:
        raise FileNotFoundError(f"Configuration file not found: {path}")
    except yaml.YAMLError as e:
        raise yaml.YAMLError(f"Error parsing YAML file {path}: {e}")


def load_file_content(file_path: str) -> bytes:
    """
    Load file content as bytes.

    Args:
        file_path: Path to the file to load

    Returns:
        File content as bytes, empty bytes if file doesn't exist or path is empty
    """
    if not file_path:
        return b""

    path_obj = Path(file_path)
    return path_obj.read_bytes() if path_obj.exists() else b""


def extract_redirect_url(response_text: str) -> Optional[str]:
    """
    Extract redirect URL from FAI response text.

    Args:
        response_text: HTML response text from FAI server

    Returns:
        Extracted URL if found, None otherwise
    """
    match = re.search(r'url=(https?://[^"]+)', response_text, re.IGNORECASE)
    return match.group(1) if match else None


def extract_job_info(response_text: str) -> Optional[Dict[str, str]]:
    """
    Extract job ID, status page URL and image URL from FAI response.

    Args:
        response_text: HTML response text from FAI server

    Returns:
        Dictionary with job_id, status_url, and image_url if found, None otherwise
    """
    info = {}

    # Extract job ID from title
    job_match = re.search(
        r'<title>Your job id ([A-Z0-9]+)</title>', response_text)
    if job_match:
        info['job_id'] = job_match.group(1)

    # Extract status page URL
    status_match = re.search(r'statuspage:\s*(https?://[^\s]+)', response_text)
    if status_match:
        info['status_url'] = status_match.group(1)

    # Extract image URL
    image_match = re.search(r'imageurl:\s*(https?://[^\s]+)', response_text)
    if image_match:
        info['image_url'] = image_match.group(1)

    return info if info else None


def prepare_files_data(files_config: Dict[str, Dict[str, str]]) -> Dict[str, Tuple[str, bytes, str]]:
    """
    Prepare file data for multipart upload.

    Args:
        files_config: Dictionary containing file configuration

    Returns:
        Dictionary with file data formatted for requests library

    Raises:
        ValueError: If both 'path' and 'content' are specified for a file
    """
    files = {}

    for fieldname, fileinfo in files_config.items():
        path = fileinfo.get("path", "")
        content = fileinfo.get("content", "")
        filename = fileinfo.get("filename", "")
        mime_type = fileinfo.get("mime_type")

        # Validate that only path OR content is specified, not both
        if path and content:
            raise ValueError(
                f"File '{fieldname}': Cannot specify both 'path' and 'content'. Use only one.")

        if not path and not content:
            logger.warning(
                f"File '{fieldname}': Neither 'path' nor 'content' specified. Skipping.")
            continue

        # Handle content vs path
        if content:
            # Content is provided directly
            file_content = content.encode(
                'utf-8') if isinstance(content, str) else content
            if not filename:
                # Default filename if not specified
                filename = f"{fieldname}.txt"
        else:
            # Path is provided
            file_content = load_file_content(path)
            if not filename:
                filename = Path(path).name if path else ""

        # Auto-detect MIME type if not specified
        if not mime_type:
            mime_type, _ = mimetypes.guess_type(filename)
        if not mime_type:
            mime_type = "application/octet-stream"

        files[fieldname] = (filename, file_content, mime_type)

    return files


def check_status_page(status_url: str) -> bool:
    """
    Check if the FAI image is ready by looking for completion message.

    Args:
        status_url: URL of the status page to check

    Returns:
        True if image is ready, False otherwise
    """
    try:
        response = requests.get(status_url, timeout=10)
        logger.debug("Status page content: %s",
                     response.text[:500])  # Log first 500 chars
        if response.status_code == 200:
            return "Your customized FAI.me image is ready" in response.text
    except requests.RequestException as e:
        logger.error("Error checking status: %s", e)
    return False


def download_image(image_url: str, output_dir: str = ".") -> Optional[str]:
    """
    Download the FAI image from the given URL.

    Args:
        image_url: URL of the image to download
        output_dir: Directory to save the image

    Returns:
        Path to downloaded file if successful, None otherwise
    """
    try:
        # Extract filename from URL
        parsed_url = urllib.parse.urlparse(image_url)
        filename = Path(parsed_url.path).name
        if not filename:
            filename = "faime-image.iso"

        output_path = Path(output_dir) / filename

        logger.info("Downloading image to %s...", output_path)
        response = requests.get(image_url, stream=True, timeout=30)
        response.raise_for_status()

        with open(output_path, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)

        logger.info("Download completed: %s", output_path)
        return str(output_path)

    except requests.RequestException as e:
        logger.error("Error downloading image: %s", e)
    except IOError as e:
        logger.error("Error writing file: %s", e)

    return None


def wait_for_image_completion(job_info: Dict[str, str], check_interval: int = 5, timeout_minutes: int = 30) -> bool:
    """
    Wait for the FAI image to be ready by polling the status page.

    Args:
        job_info: Dictionary containing job information
        check_interval: Seconds between status checks
        timeout_minutes: Maximum time to wait in minutes

    Returns:
        True if image is ready, False if timeout or error
    """
    status_url = job_info.get('status_url')
    job_id = job_info.get('job_id', 'unknown')

    if not status_url:
        logger.error("No status URL found")
        return False

    timeout_seconds = timeout_minutes * 60
    start_time = time.time()

    logger.info("Checking status for job %s every %s seconds (timeout: %s minutes)...",
                job_id, check_interval, timeout_minutes)
    logger.info("Status URL: %s", status_url)

    while True:
        elapsed_time = time.time() - start_time

        if elapsed_time > timeout_seconds:
            logger.error(
                "Timeout reached (%s minutes). Image build may still be in progress.", timeout_minutes)
            return False

        remaining_time = timeout_seconds - elapsed_time
        logger.info("Checking status... (%d seconds remaining)",
                    remaining_time)

        if check_status_page(status_url):
            logger.info("✓ Image is ready!")
            return True
        else:
            logger.info("⏳ Still building...")
            time.sleep(check_interval)


def save_config_yaml(config_data: Dict[str, Any], job_info: Dict[str, str], output_dir: str = ".") -> Optional[str]:
    """
    Save the configuration data as a YAML file alongside the downloaded image.

    Args:
        config_data: Original configuration data used for the request
        job_info: Job information containing job_id
        output_dir: Directory to save the YAML file

    Returns:
        Path to saved YAML file if successful, None otherwise
    """
    try:
        job_id = job_info.get('job_id', 'unknown')
        yaml_filename = f"faime-{job_id}.faime.yml"
        yaml_path = Path(output_dir) / yaml_filename

        # Create a copy of config data and add job information
        config_to_save = config_data.copy()

        logger.info("Saving configuration to %s...", yaml_path)
        with open(yaml_path, 'w', encoding='utf-8') as f:
            yaml.dump(config_to_save, f, default_flow_style=False,
                      allow_unicode=True)

        logger.info("Configuration saved: %s", yaml_path)
        return str(yaml_path)

    except Exception as e:
        logger.error("Error saving configuration YAML: %s", e)

    return None


def main() -> None:
    """
    Main function to handle command line arguments and execute FAI request.
    """
    parser = argparse.ArgumentParser(
        description="Send POST request to fai-project.org with YAML configuration"
    )
    parser.add_argument(
        "--config", "-c",
        default="/etc/fai/config.faime.yml",
        help="Path to YAML configuration file"
    )
    parser.add_argument(
        "--log-level",
        choices=['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL'],
        default='INFO',
        help="Set the logging level (default: INFO)"
    )
    parser.add_argument(
        "--log-file",
        help="Write logs to file instead of console"
    )
    parser.add_argument(
        "--log-format",
        default='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        help="Custom log format string"
    )
    parser.add_argument(
        "--timeout", "-t",
        type=int,
        default=30,
        help="Timeout in minutes for image completion (default: 30)"
    )
    args = parser.parse_args()

    # Configure logging
    log_level = getattr(logging, args.log_level.upper())

    logging_config = {
        'level': log_level,
        'format': args.log_format,
        'datefmt': '%Y-%m-%d %H:%M:%S'
    }

    if args.log_file:
        logging_config['filename'] = args.log_file
        logging_config['filemode'] = 'a'  # Append mode

    logging.basicConfig(**logging_config)

    try:
        # Load configuration
        config = load_yaml_config(args.config)
        config['sbm'] = "2"  # Required parameter for FAI
        original_config = config.copy()  # Keep original for saving later

        # Extract file configuration and prepare form data
        files_config = config.pop("files", {})
        form_data = config  # All other keys are regular form data

        # Prepare files for upload
        files = prepare_files_data(files_config)

        # Send HTTP POST request
        logger.info("Sending request to %s...", FAI_URL)
        response = requests.post(
            FAI_URL, data=form_data, files=files, timeout=30)

        logger.info("Status Code: %s", response.status_code)

        if response.status_code == 200:
            # Extract job information from response
            job_info = extract_job_info(response.text)
            if job_info:
                logger.info("Job ID: %s", job_info.get('job_id', 'unknown'))
                logger.info("Status URL: %s", job_info.get(
                    'status_url', 'unknown'))
                logger.info("Image URL: %s", job_info.get(
                    'image_url', 'unknown'))

                # Wait for image completion
                if wait_for_image_completion(job_info, timeout_minutes=args.timeout):
                    # Download thels - image
                    image_url = job_info.get('image_url')
                    if image_url:
                        downloaded_path = download_image(image_url)
                        if downloaded_path:
                            # Save configuration YAML in same directory as image
                            output_dir = str(Path(downloaded_path).parent)
                            save_config_yaml(
                                original_config, job_info, output_dir)
                    else:
                        logger.error("No image URL found")
                else:
                    logger.error("Failed to wait for image completion")
            else:
                logger.error("No job information found in response.")
                # First 500 chars
                logger.debug("Response Text: %s", response.text[:500])
        else:
            logger.error("Request failed with status %s", response.status_code)
            logger.debug("Response Text: %s", response.text[:500])

    except Exception as e:
        logger.error("Error: %s", e)
        return 1

    return 0


if __name__ == "__main__":
    exit(main())
