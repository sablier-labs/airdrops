import http.client
import json

"""
This script fetches the latest token prices from the CoinGecko API and converts them 
to their "wei" equivalent for $1.

It is intended for use in fork tests, where it will be executed via Foundry's "ffi" cheatcode.
For more details, refer to the Foundry documentation: https://book.getfoundry.sh/cheatcodes/ffi
"""

# Mapping of chain-native tokens to their corresponding CoinGecko IDs
TOKEN_IDS = {
    "ethereum": "ethereum",
    "avalanche": "avalanche-2",
    "bnb": "binancecoin",
    "dai": "dai",  # for Gnosis chain
    "polygon": "matic-network",
}


def get_token_prices_in_wei():
    conn = http.client.HTTPSConnection("api.coingecko.com")
    query = f"/api/v3/simple/price?ids={','.join(TOKEN_IDS.values())}&vs_currencies=usd"

    conn.request("GET", query)
    response = conn.getresponse()

    if response.status == 200:
        prices = json.loads(response.read().decode())

        # Convert token prices to "wei" equivalent for $3
        token_prices_in_wei = {
            token: int((3 / prices[cg_id]["usd"]) *
                       1e18) if cg_id in prices else 0
            for token, cg_id in TOKEN_IDS.items()
        }

        return json.dumps(token_prices_in_wei)

    return json.dumps({"error": f"API Error {response.status}"})


if __name__ == "__main__":
    print(get_token_prices_in_wei())  # Foundry captures this JSON output
