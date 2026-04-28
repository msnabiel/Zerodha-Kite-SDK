# KiteZerodha Swift SDK

Lightweight, modular Swift SDK for Zerodha Kite Connect (REST + WebSocket).
Includes login/session generation, typed order models, order/GTT APIs, and basic binary tick parsing.

## Install

Add this package dependency in your `Package.swift`.

## Structure

- `Sources/KiteZerodha/Client` REST/auth client (`KiteClient`)
- `Sources/KiteZerodha/Models` request/response models
- `Sources/KiteZerodha/Ticker` websocket client (`KiteTicker`)
- `Sources/KiteZerodha/Utils` shared helpers

## Quick Start

```swift
import KiteZerodha

let client = KiteClient(apiKey: "your_api_key")
let loginURL = client.loginURL()
// Redirect user to loginURL and capture request_token from callback
let session = try await client.generateSession(requestToken: "request_token", apiSecret: "api_secret")
print(session.accessToken)
```

## Place Order

```swift
let orderID = try await client.placeOrder(
    .init(
        exchange: "NSE",
        tradingsymbol: "INFY",
        transactionType: "BUY",
        quantity: 1,
        product: "CNC",
        orderType: "MARKET"
    )
)
print(orderID)
```

## WebSocket Ticker

```swift
let ticker = KiteTicker(apiKey: "your_api_key", accessToken: "access_token")
ticker.connect()
try await ticker.subscribe(tokens: [256265])
let message = try await ticker.receive()
print(message)
```

## Notes

- Uses Kite Connect v3 headers and auth format.
- Binary parser currently decodes LTP-style packets (`instrument_token`, `last_price`).
- Extend models/decoders if you need full quote/depth packets.

## Official References

- Main docs: https://kite.trade/docs/connect/v3/
- Orders: https://kite.trade/docs/connect/v3/orders/
- GTT: https://kite.trade/docs/connect/v3/gtt/
- Alerts: https://kite.trade/docs/connect/v3/alerts/
- Mutual funds: https://kite.trade/docs/connect/v3/mutual-funds/
- Margin calculation: https://kite.trade/docs/connect/v3/margins/
- Postbacks/WebHooks: https://kite.trade/docs/connect/v3/postbacks/
- WebSocket: https://kite.trade/docs/connect/v3/websocket/
- User/session: https://kite.trade/docs/connect/v3/user/
