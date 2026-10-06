"""
Laptop Guardian — Shared Logging Configuration
"""
import logging
import os
from logging.handlers import RotatingFileHandler

LOG_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "logs")
os.makedirs(LOG_DIR, exist_ok=True)


def get_logger(name: str, log_file: str = None, level=logging.INFO) -> logging.Logger:
    """Return a named logger writing to console and an optional rotating file."""
    logger = logging.getLogger(f"laptop_guardian.{name}")
    if logger.handlers:
        return logger  # already configured

    logger.setLevel(level)
    formatter = logging.Formatter(
        "[%(asctime)s] [%(levelname)s] [%(name)s]: %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )

    # Console handler
    console = logging.StreamHandler()
    console.setFormatter(formatter)
    logger.addHandler(console)

    if log_file:
        file_path = os.path.join(LOG_DIR, log_file)
        file_handler = RotatingFileHandler(file_path, maxBytes=5_000_000, backupCount=3, encoding="utf-8")
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)

    return logger
