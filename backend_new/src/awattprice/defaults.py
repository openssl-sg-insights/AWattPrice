"""Contains default values and models."""
from enum import Enum


class Region(str, Enum):
    """Identify a region (country)."""

    DE = "DE"
    AT = "AT"


DEFAULT_CONFIG = """\
[general]
debug = off

[awattar.de]
url = https://api.awattar.de/v1/marketdata/

[awattar.at]
url = https://api.awattar.at/v1/marketdata/

[paths]
log_dir = ~/awattprice/logs/
data_dir = ~/awattprice/data/
"""

# Describes how a notification task payload should be structured like.
NOTIFICATION_TASK_SCHEMA = {
    "properties": {
        "token": {"type": "string"},
        "tasks": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "type": {
                        "type": "string",
                    },
                    "payload": {
                        "type": "object",
                    },
                },
                "required": ["type", "payload"],
            },
            "minItems": 1,
        },
    },
    "required": ["token", "tasks"],
}


# Factor to convert seconds into microseconds.
TO_MICROSECONDS = 1000

# Timeout in seconds when requesting from aWATTar.
AWATTAR_TIMEOUT = 10.0
# The aWATTar API refresh interval. After polling the API wait x seconds before requesting again.
AWATTAR_REFRESH_INTERVAL = 60
# Attempt to update aWATTar prices if its past this hour of the day.
# The backend autmatically switches between summer and winter times.
# So for example 13 o'clock will always stay 13 o'clock independent of summer or winter time.
AWATTAR_UPDATE_HOUR = 13

# File name for the AWattPrice backend database ending.
DATABASE_FILE_NAME = "database.sqlite3"  # End with '.sqlite3'

# File name for file storing aWATTar price data.
# The string will be formatted with the lowercase region identifier.
PRICE_DATA_FILE_NAME = "awattar-data-{}.json"
# Name of the subdir in which to store cached price data.
# This subdir is relative to the data dir specified in the config file.
PRICE_DATA_SUBDIR_NAME = "price_data"
# File name of lock file which will be acquired when aWATTar price data needs to be updated.
# The string will be formatted with the lowercase region identifier.
PRICE_DATA_REFRESH_LOCK = "awattar-data-{}-update.lck"
# Timeout in seconds to wait when needing the refresh price data lock to be unlocked.
PRICE_DATA_REFRESH_LOCK_TIMEOUT = AWATTAR_TIMEOUT + 2.0
