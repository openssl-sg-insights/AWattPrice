"""Contains small helper functions which don't fit into a bigger category."""
import asyncio
import json

from enum import Enum
from functools import partial
from pathlib import Path
from typing import Any
from typing import Callable
from typing import Optional
from typing import Union

import httpx
import jsonschema

from aiofile import async_open
from box import Box
from box import BoxList
from fastapi import HTTPException
from loguru import logger


def async_wrap(func: Callable):
    """Wrap a synchronous running function to make it run asynchronous."""

    async def run(*args, loop=None, executor=None, **kwargs) -> Callable:
        """Run sync function async."""
        if loop is None:
            loop = asyncio.get_event_loop()
        pfunc = partial(func, *args, **kwargs)
        return await loop.run_in_executor(executor, pfunc)

    return run


async def request_url(method: str, url: str, **kwargs) -> httpx.Response:
    """Downloads data at url asynchronous.

    :param **kwargs: Keyword arguments parsed to the httpx.AsyncClient.request() method. This method
        performs the request.
    :returns: Instance of httpx.Response.
    """
    async with httpx.AsyncClient() as client:
        logger.debug(f"Sending {method} request to {url}.")
        response = await client.request(method, url, **kwargs)

    return response


async def read_json_file(file_path: Path) -> Optional[Union[Box, BoxList]]:
    """Read file asynchronous and convert content to json.

    :raises JSONDecodeError: if file content couldn't be decoded as json.
    :returns: Box (if content is dict) or BoxList (if content is list).
    """
    async with async_open(file_path, "r") as file:
        data_raw = await file.read()

    if len(data_raw) == 0:
        data_raw = None

    try:
        data_json = json.loads(data_raw)
    except json.JSONDecodeError as err:
        logger.error(f"Couldn't read json file as it is no valid json: {err}.")
        raise

    if isinstance(data_json, dict):
        data = Box(data_json)
    elif isinstance(data_json, list):
        data = BoxList(data_json)

    return data


# Functions prefixed with http_exception run tasks and throw an http exception if they fail.
def http_exc_validate_json_schema(body: Union[Box, dict, list], schema: dict):
    """Validate a body against a schema.

    :raises HTTPException: with status code 400 if the body doesn't match the schema.
    """
    try:
        jsonschema.validate(body, schema)
    except jsonschema.ValidationError as exc:
        logger.warning(f"Body doesn't match correct schema: {exc}.")
        raise HTTPException(400) from exc


def http_exc_get_attr(obj: Any, attr_name: str):
    """Get attr from enumeration.

    :raises HTTPException: with status code 400 if there is no appropriate attr on the enumeration.
    """
    try:
        attr = getattr(obj, attr_name)
    except AttributeError as exc:
        logger.warning(f"Can't get attr named '{attr_name}' from object {obj.__name__}.")
        raise HTTPException(400) from exc

    return attr
