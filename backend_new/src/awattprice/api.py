"""Handle url calls to this web app."""
from fastapi import FastAPI
from starlette.responses import RedirectResponse

from awattprice import config as conf
from awattprice.defaults import Region
from awattprice.prices import get_current_prices

config = conf.get_config()
conf.configure_loguru(config)

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
    return RedirectResponse(url=f"/data/{region.name}")


@app.post("/apns/add_token/")
async def add_apns_token():
    """Register an apple push notification service token."""
    return "Hello"


@app.post("/data/apns/send_token/")
def add_apns_token_old():
    """Old url to add the apns token to the database.

    This sends a redirect response to make the client call the new url for this task.
    This url is still supported for backwards compatibility reasons.
    """
    return RedirectResponse(url="/apns/add_token/")
