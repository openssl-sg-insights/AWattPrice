# -*- coding: utf-8 -*-

"""Discovergy poller

Poll for data from different sources.

All functions that end with _task will be feed to the event loop.
"""
__author__ = "Frank Becker <fb@alien8.de>"
__copyright__ = "Frank Becker"
__license__ = "mit"

import asyncio

from pathlib import Path

import arrow  # type: ignore
from typing import Dict, List, Optional

from box import Box  # type: ignore
from loguru import logger as log

from . import awattar
from .config import read_config
from .defaults import CONVERT_MWH_KWH, Region, TIME_CORRECT
from .utils import start_logging, read_data, write_data


def transform_entry(entry: Box) -> Optional[Box]:
    """Return the data entry as the AWattPrice app expects it."""
    try:
        if entry.unit == "Eur/MWh":
            entry.pop("unit")
            # Divide through 1000 to not display miliseconds
            entry.start_timestamp = int(entry.start_timestamp / TIME_CORRECT)
            entry.end_timestamp = int(entry.end_timestamp / TIME_CORRECT)
            # Convert MWh to kWh
            entry.marketprice = entry.marketprice * CONVERT_MWH_KWH
    except KeyError:
        log.warning(f"Missing key in Awattar entry. Skipping: {entry}.")
    except Exception as e:
        log.warning(f"Bogus data in Awattar entry. Skipping: {entry}: {e}")
    else:
        return entry
    return None


async def awattar_read_task(*, config: Box, region: Region) -> Optional[List[Box]]:
    """Async worker to read the Awattar data. If too old, poll the
    Awattar API."""
    try:
        data = await awattar.get(config=config, region=region)
    except Exception as e:
        log.warning(f"Error in Awattar data poller: {e}")
    else:
        return data
    return None


async def await_tasks(tasks):
    """Gather the tasks."""
    return await asyncio.gather(*tasks)


async def get_data(config: Box, region: Optional[Region] = None, force: bool = False) -> Dict:
    """Request the Awattar data. Read it from file, if it is too old fetch it
    from the Awattar API endpoint.

    :param config: AWattPrice config
    :param force: Enforce fetching of data
    """
    if region is None:
        region = Region.DE
    # 1) Read the data file.
    file_path = Path(config.file_location.data_dir).expanduser() / Path(f"awattar-data-{region.name.lower()}.json")
    data = read_data(file_path=file_path)
    fetched_data = None
    need_update = True
    last_update = 0
    now = arrow.utcnow()
    if data:
        last_update = data.meta.update_ts
        # Only poll every config.poll.awattar seconds
        if now.timestamp > last_update + int(config.poll.awattar):
            last_entry = max([d.start_timestamp for d in data.prices])
            need_update = any(
                [
                    now.timestamp > last_entry,
                    # Should trigger after 14 h or if data was missing.
                    len([True for e in data.prices if e.start_timestamp > now.timestamp]) <= 12,
                ]
            )
        else:
            need_update = False
    if need_update or force:
        future = awattar_read_task(config=config, region=region)
        if future is None:
            return None
        # results = asyncio.run(await_tasks([future]))
        results = await asyncio.gather(*[future])
        if results:
            log.info("Successfully fetched fresh data from Awattar.")
            # We run one task in asyncio
            fetched_data = results.pop()
        else:
            log.info("Failed to fetch fresh data from Awattar.")
            fetched_data = None
    else:
        log.debug("No need to update Awattar data from their API.")
    # Update existing data
    must_write_data = False
    if data and fetched_data:
        max_existing_data_start_timestamp = max([d.start_timestamp for d in data.prices]) * TIME_CORRECT
        for entry in fetched_data:
            ts = entry.start_timestamp
            if ts <= max_existing_data_start_timestamp:
                continue
            entry = transform_entry(entry)
            if entry:
                must_write_data = True
                data.prices.append(entry)
        if must_write_data:
            data.meta.update_ts = arrow.utcnow().timestamp
    elif fetched_data:
        data = Box({"prices": [], "meta": {}}, box_dots=True)
        data.meta["update_ts"] = arrow.utcnow().timestamp
        for entry in fetched_data:
            entry = transform_entry(entry)
            if entry:
                must_write_data = True
                data.prices.append(entry)
    # Filter out data older than 24h and write to disk
    if must_write_data:
        log.info("Writing Awattar data to disk.")
        before_24h = now.shift(hours=-24).timestamp
        data.prices = [e for e in data.prices if e.end_timestamp > before_24h]
        write_data(data=data, file_path=file_path)
    # As the last resort return empty data.
    if not data:
        data = Box({"prices": []})
    return data


def main() -> Box:
    """Entry point for the data poller."""
    config = read_config()
    start_logging(config)
    data = get_data(config)
    return data


if __name__ == "__main__":
    main()
