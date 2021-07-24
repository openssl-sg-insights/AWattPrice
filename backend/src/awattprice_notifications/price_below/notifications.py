"""Send price below notifications."""
import awattprice

from awattprice.defaults import Region
from awattprice.orm import Token
from box import Box
from liteconfig import Config

import awattprice_notifications

from awattprice_notifications.price_below import defaults
from awattprice_notifications.price_below.prices import DetailedPriceData


def construct_notification_headers(apns_authorization: str, prices_below: list[Box]) -> Box:
    """Construct the headers for a token when sending a price below notification."""
    latest_price_below = max(prices_below, key=lambda price_point: price_point.start_timestamp)

    headers = Box()
    headers["authorization"] = f"bearer {apns_authorization}"
    headers["apns-push-type"] = defaults.NOTIFICATION.push_type
    headers["apns-priority"] = defaults.NOTIFICATION.priority
    headers["apns-collapse-id"] = defaults.NOTIFICATION.collapse_id
    headers["apns-topic"] = awattprice.defaults.APP_BUNDLE_ID
    headers["apns-expiration"] = latest_price_below.start_timestamp.int_timestamp

    return headers


def construct_notification(token: Token, detailed_prices: DetailedPriceData, prices_below: list[Box]) -> Box:
    """Construct the notification for a token.

    :param prices_below: List of prices considered below the value. They must all are present in the detailed prices.
        This list is not allowed to be empty.
    """
    if len(prices_below) == 0:
        raise ValueError("Prices below the value must contain at least one price point.")

    len_prices_below_str = str(len(prices_below))
    below_value_str = str(token.price_below.below_value)
    lowest_price = detailed_prices.lowest_price
    lowest_price_start_str = lowest_price.start_timestamp.format("HH")
    lowest_price_marketprice_str = str(lowest_price.marketprice.ct_kwh())

    notification = Box()
    notification.aps = {}
    notification.aps["badge"] = 0
    notification.aps["sound"] = defaults.NOTIFICATION.sound
    notification.aps["content-available"] = 0
    notification.aps["alert"] = {}
    notification.aps["alert"]["title-loc-key"] = defaults.NOTIFICATION.title_loc_key
    if len(prices_below) == 1:
        notification.aps["alert"]["loc-key"] = defaults.NOTIFICATION.loc_keys.single_price
    else:
        notification.aps["alert"]["loc-key"] = defaults.NOTIFICATION.loc_keys.multiple_prices
    notification.aps["alert"]["loc-args"] = [
        len_prices_below_str,
        below_value_str,
        lowest_price_start_str,
        lowest_price_marketprice_str,
    ]


    return notification


async def send_notification():
    """Send a single notification."""



async def deliver_notifications(
    config: Config, regions_tokens: dict[Region, list[Token]], price_data: dict[Region, DetailedPriceData]
):
    """Send price below notifications for certain tokens.

    :param tokens, price_data: Each region which has applying tokens *must* also be present in the price data.
    """

    apns_authorization = await awattprice_notifications.apns.get_apns_authorization(config)

    send_tasks = []
    for region, tokens in regions_tokens.items():
        if tokens is None:
            continue

        region_prices = price_data[region]

        for token in tokens:
            prices_below = region_prices.get_prices_below_value(token.price_below.below_value, token.tax)

            min_price = min(prices_below, key=lambda point: point.marketprice.value)

            headers = construct_notification_headers(apns_authorization, prices_below)
            notification = construct_notification(token, region_prices, prices_below)

            send_tasks.append()
