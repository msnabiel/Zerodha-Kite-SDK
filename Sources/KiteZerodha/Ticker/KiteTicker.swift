import Foundation

public struct KiteMarketDepthEntry: Sendable {
    public let quantity: Int
    public let price: Double
    public let orders: Int
}

public struct KiteTick: Sendable {
    public let instrumentToken: Int
    public let lastPrice: Double
    public let mode: KiteTicker.Mode
    public let open: Double?
    public let high: Double?
    public let low: Double?
    public let close: Double?
    public let lastTradedQuantity: Int?
    public let averageTradedPrice: Double?
    public let volumeTradedForTheDay: Int?
    public let totalBuyQuantity: Int?
    public let totalSellQuantity: Int?
    public let lastTradedTimestamp: Int?
    public let openInterest: Int?
    public let openInterestDayHigh: Int?
    public let openInterestDayLow: Int?
    public let exchangeTimestamp: Int?
    public let change: Double?
    public let depthBuy: [KiteMarketDepthEntry]?
    public let depthSell: [KiteMarketDepthEntry]?
}
public enum KiteTickerMessage: Sendable { case text(String), binary([KiteTick]) }

public final class KiteTicker {
    public enum Mode: String, Sendable { case ltp, quote, full }
    private let socket: URLSessionWebSocketTask

    public init(apiKey: String, accessToken: String, session: URLSession = .shared, wsRoot: URL = URL(string: "wss://ws.kite.trade")!) {
        var c = URLComponents(url: wsRoot, resolvingAgainstBaseURL: false)!
        c.queryItems = [.init(name: "api_key", value: apiKey), .init(name: "access_token", value: accessToken)]
        socket = session.webSocketTask(with: c.url!)
    }

    public func connect() { socket.resume() }
    public func disconnect() { socket.cancel(with: .normalClosure, reason: nil) }
    public func subscribe(tokens: [Int]) async throws { try await send(["a": "subscribe", "v": tokens]) }
    public func unsubscribe(tokens: [Int]) async throws { try await send(["a": "unsubscribe", "v": tokens]) }
    public func setMode(_ mode: Mode, tokens: [Int]) async throws { try await send(["a": "mode", "v": [mode.rawValue, tokens]]) }

    public func receive() async throws -> KiteTickerMessage {
        switch try await socket.receive() {
        case .string(let s): return .text(s)
        case .data(let d): return .binary(Self.parseBinary(d))
        @unknown default: return .text("")
        }
    }

    public static func parseBinary(_ data: Data) -> [KiteTick] {
        // Heartbeat is a single byte. Safely ignore.
        if data.count == 1 { return [] }
        guard data.count >= 4 else { return [] }
        let count = Int(data.readUInt16BE(at: 0))
        var out: [KiteTick] = []; var o = 2
        for _ in 0..<count {
            if o + 2 > data.count { break }
            let len = Int(data.readUInt16BE(at: o)); o += 2
            if len >= 8, o + len <= data.count {
                if len == 28 || len == 32 {
                    // Index packet structure (quote: 28, full: 32)
                    let token = Int(data.readInt32BE(at: o))
                    let ltp = Double(data.readInt32BE(at: o + 4)) / 100.0
                    let high = Double(data.readInt32BE(at: o + 8)) / 100.0
                    let low = Double(data.readInt32BE(at: o + 12)) / 100.0
                    let open = Double(data.readInt32BE(at: o + 16)) / 100.0
                    let close = Double(data.readInt32BE(at: o + 20)) / 100.0
                    let change = Double(data.readInt32BE(at: o + 24)) / 100.0
                    let exchangeTs = len == 32 ? Int(data.readInt32BE(at: o + 28)) : nil
                    out.append(.init(
                        instrumentToken: token,
                        lastPrice: ltp,
                        mode: len == 32 ? .full : .quote,
                        open: open, high: high, low: low, close: close,
                        lastTradedQuantity: nil, averageTradedPrice: nil, volumeTradedForTheDay: nil,
                        totalBuyQuantity: nil, totalSellQuantity: nil,
                        lastTradedTimestamp: nil,
                        openInterest: nil, openInterestDayHigh: nil, openInterestDayLow: nil,
                        exchangeTimestamp: exchangeTs,
                        change: change,
                        depthBuy: nil, depthSell: nil
                    ))
                } else {
                    // Regular instrument packets (ltp: 8, quote: 44, full: 184)
                    let token = Int(data.readInt32BE(at: o))
                    let ltp = Double(data.readInt32BE(at: o + 4)) / 100.0
                    if len == 8 {
                        out.append(.init(
                            instrumentToken: token, lastPrice: ltp, mode: .ltp,
                            open: nil, high: nil, low: nil, close: nil,
                            lastTradedQuantity: nil, averageTradedPrice: nil, volumeTradedForTheDay: nil,
                            totalBuyQuantity: nil, totalSellQuantity: nil,
                            lastTradedTimestamp: nil,
                            openInterest: nil, openInterestDayHigh: nil, openInterestDayLow: nil,
                            exchangeTimestamp: nil,
                            change: nil,
                            depthBuy: nil, depthSell: nil
                        ))
                    } else {
                        let lastQty = Int(data.readInt32BE(at: o + 8))
                        let avg = Double(data.readInt32BE(at: o + 12)) / 100.0
                        let vol = Int(data.readInt32BE(at: o + 16))
                        let buyQty = Int(data.readInt32BE(at: o + 20))
                        let sellQty = Int(data.readInt32BE(at: o + 24))
                        let open = Double(data.readInt32BE(at: o + 28)) / 100.0
                        let high = Double(data.readInt32BE(at: o + 32)) / 100.0
                        let low = Double(data.readInt32BE(at: o + 36)) / 100.0
                        let close = Double(data.readInt32BE(at: o + 40)) / 100.0
                        if len == 44 {
                            out.append(.init(
                                instrumentToken: token, lastPrice: ltp, mode: .quote,
                                open: open, high: high, low: low, close: close,
                                lastTradedQuantity: lastQty, averageTradedPrice: avg, volumeTradedForTheDay: vol,
                                totalBuyQuantity: buyQty, totalSellQuantity: sellQty,
                                lastTradedTimestamp: nil,
                                openInterest: nil, openInterestDayHigh: nil, openInterestDayLow: nil,
                                exchangeTimestamp: nil,
                                change: nil,
                                depthBuy: nil, depthSell: nil
                            ))
                        } else if len == 184 {
                            let lastTs = Int(data.readInt32BE(at: o + 44))
                            let oi = Int(data.readInt32BE(at: o + 48))
                            let oiHigh = Int(data.readInt32BE(at: o + 52))
                            let oiLow = Int(data.readInt32BE(at: o + 56))
                            let exchangeTs = Int(data.readInt32BE(at: o + 60))
                            // Market depth: 10 entries, 12 bytes each, starting at offset 64
                            var buys: [KiteMarketDepthEntry] = []
                            var sells: [KiteMarketDepthEntry] = []
                            buys.reserveCapacity(5)
                            sells.reserveCapacity(5)
                            var depthOffset = o + 64
                            for idx in 0..<10 {
                                let qty = Int(data.readInt32BE(at: depthOffset))
                                let price = Double(data.readInt32BE(at: depthOffset + 4)) / 100.0
                                let orders = Int(data.readInt16BE(at: depthOffset + 8))
                                // last 2 bytes padding at depthOffset+10
                                let entry = KiteMarketDepthEntry(quantity: qty, price: price, orders: orders)
                                if idx < 5 { buys.append(entry) } else { sells.append(entry) }
                                depthOffset += 12
                            }
                            out.append(.init(
                                instrumentToken: token, lastPrice: ltp, mode: .full,
                                open: open, high: high, low: low, close: close,
                                lastTradedQuantity: lastQty, averageTradedPrice: avg, volumeTradedForTheDay: vol,
                                totalBuyQuantity: buyQty, totalSellQuantity: sellQty,
                                lastTradedTimestamp: lastTs,
                                openInterest: oi, openInterestDayHigh: oiHigh, openInterestDayLow: oiLow,
                                exchangeTimestamp: exchangeTs,
                                change: nil,
                                depthBuy: buys, depthSell: sells
                            ))
                        } else {
                            // Unknown packet length; skip.
                        }
                    }
                }
            }
            o += len
        }
        return out
    }

    private func send(_ payload: [String: Any]) async throws {
        let text = String(data: try JSONSerialization.data(withJSONObject: payload), encoding: .utf8) ?? ""
        try await socket.send(.string(text))
    }
}
