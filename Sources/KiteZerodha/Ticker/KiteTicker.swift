import Foundation

public struct KiteTick: Sendable {
    public let instrumentToken: Int
    public let lastPrice: Double
    public let mode: KiteTicker.Mode
    public let open: Double?
    public let high: Double?
    public let low: Double?
    public let close: Double?
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
        guard data.count >= 4 else { return [] }
        let count = Int(data.readUInt16BE(at: 0))
        var out: [KiteTick] = []; var o = 2
        for _ in 0..<count {
            if o + 2 > data.count { break }
            let len = Int(data.readUInt16BE(at: o)); o += 2
            if len >= 8, o + len <= data.count {
                let token = Int(data.readInt32BE(at: o))
                let ltp = Double(data.readInt32BE(at: o + 4)) / 100.0
                if len == 8 {
                    out.append(.init(instrumentToken: token, lastPrice: ltp, mode: .ltp, open: nil, high: nil, low: nil, close: nil))
                } else if len == 28 || len == 32 {
                    let high = Double(data.readInt32BE(at: o + 8)) / 100.0
                    let low = Double(data.readInt32BE(at: o + 12)) / 100.0
                    let open = Double(data.readInt32BE(at: o + 16)) / 100.0
                    let close = Double(data.readInt32BE(at: o + 20)) / 100.0
                    out.append(.init(instrumentToken: token, lastPrice: ltp, mode: .quote, open: open, high: high, low: low, close: close))
                } else {
                    let open = len >= 32 ? Double(data.readInt32BE(at: o + 28)) / 100.0 : nil
                    let high = len >= 36 ? Double(data.readInt32BE(at: o + 32)) / 100.0 : nil
                    let low = len >= 40 ? Double(data.readInt32BE(at: o + 36)) / 100.0 : nil
                    let close = len >= 44 ? Double(data.readInt32BE(at: o + 40)) / 100.0 : nil
                    out.append(.init(instrumentToken: token, lastPrice: ltp, mode: len >= 184 ? .full : .quote, open: open, high: high, low: low, close: close))
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
