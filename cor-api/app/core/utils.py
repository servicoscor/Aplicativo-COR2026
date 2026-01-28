"""Utility functions and helpers."""

import uuid
from datetime import datetime, timezone
from typing import Any, Dict, Optional, Tuple


def generate_request_id() -> str:
    """Generate a unique request ID."""
    return str(uuid.uuid4())


def utc_now() -> datetime:
    """Get current UTC timestamp."""
    return datetime.now(timezone.utc)


def timestamp_to_iso(dt: Optional[datetime]) -> Optional[str]:
    """Convert datetime to ISO format string."""
    if dt is None:
        return None
    return dt.isoformat()


def iso_to_timestamp(iso_string: Optional[str]) -> Optional[datetime]:
    """Convert ISO format string to datetime."""
    if iso_string is None:
        return None
    return datetime.fromisoformat(iso_string.replace("Z", "+00:00"))


def calculate_age_seconds(timestamp: Optional[datetime]) -> Optional[int]:
    """Calculate age in seconds from timestamp to now."""
    if timestamp is None:
        return None
    now = utc_now()
    delta = now - timestamp
    return int(delta.total_seconds())


def parse_bbox(bbox_string: Optional[str]) -> Optional[Tuple[float, float, float, float]]:
    """
    Parse bounding box string to tuple of coordinates.

    Args:
        bbox_string: Comma-separated string "min_lon,min_lat,max_lon,max_lat"

    Returns:
        Tuple of (min_lon, min_lat, max_lon, max_lat) or None
    """
    if not bbox_string:
        return None

    try:
        parts = [float(x.strip()) for x in bbox_string.split(",")]
        if len(parts) != 4:
            return None
        return (parts[0], parts[1], parts[2], parts[3])
    except (ValueError, AttributeError):
        return None


def sanitize_dict(data: Dict[str, Any], max_depth: int = 10) -> Dict[str, Any]:
    """
    Sanitize dictionary for safe JSON serialization.

    Handles datetime objects, removes None values, and limits depth.
    """
    if max_depth <= 0:
        return {}

    result = {}
    for key, value in data.items():
        if value is None:
            continue
        elif isinstance(value, datetime):
            result[key] = timestamp_to_iso(value)
        elif isinstance(value, dict):
            result[key] = sanitize_dict(value, max_depth - 1)
        elif isinstance(value, list):
            result[key] = [
                sanitize_dict(item, max_depth - 1) if isinstance(item, dict) else item
                for item in value
            ]
        else:
            result[key] = value

    return result


def clamp(value: float, min_val: float, max_val: float) -> float:
    """Clamp a value between min and max."""
    return max(min_val, min(max_val, value))


def format_coordinates(lat: float, lon: float, precision: int = 6) -> str:
    """Format coordinates as string."""
    return f"{lat:.{precision}f},{lon:.{precision}f}"


# Rio de Janeiro bounding box (approximate)
RIO_BBOX = (-43.8, -23.1, -43.1, -22.7)  # (min_lon, min_lat, max_lon, max_lat)


def is_within_rio_bbox(lat: float, lon: float) -> bool:
    """Check if coordinates are within Rio de Janeiro bounding box."""
    min_lon, min_lat, max_lon, max_lat = RIO_BBOX
    return min_lat <= lat <= max_lat and min_lon <= lon <= max_lon
