"""Handle url calls to this web app."""
from fastapi import FastAPI
from starlette.responses import RedirectResponse

from awattprice import config as conf
from awattprice.database import get_app_database
from awattprice.defaults import Region
from awattprice.prices import get_current_prices
from awattprice.tables import generate_table_classes

config = conf.get_config()
conf.configure_loguru(config)

database = get_app_database(config)
generate_table_classes(database.registry)

app = FastAPI()


@app.get("/data/{region}")
async def get_region_data(region: Region):
    """Get current price data for specified region."""
    price_data = await get_current_prices(region, config)
    return price_data


@app.get("/data/")
async def get_default_region_data():
    """Get current price data for default region.

    This will respond with an temporary redirect to the data price site of the default region.
    """
    region = Region.DE
    return RedirectResponse(url=f"/data/{region.value}")


@app.post("/apns/add_token/")
async def add_apns_token():
    """Register an apple push notification service token."""

    return "Success"
