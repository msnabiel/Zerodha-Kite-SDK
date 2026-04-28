import Foundation

public struct KiteTick: Sendable { public let instrumentToken: Int; public let lastPrice: Double }
public enum KiteTickerMessage: Sendable { case text(String), binary([KiteTick]) }

public final class KiteTicker {
    public enum Mode: String { case ltp, quote, full }
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
        case .data(let d): return .binary(Self.parseLTPBinary(d))
        @unknown default: return .text("")
        }
    }

    public static func parseLTPBinary(_ data: Data) -> [KiteTick] {
        guard data.count >= 12 else { return [] }
        let count = Int(data.readUInt16BE(at: 0))
        var out: [KiteTick] = []; var o = 2
        for _ in 0..<count {
            if o + 10 > data.count { break }
            let len = Int(data.readUInt16BE(at: o)); o += 2
            if len >= 8, o + len <= data.count {
                out.append(.init(instrumentToken: Int(data.readInt32BE(at: o)), lastPrice: Double(data.readInt32BE(at: o + 4)) / 100.0))
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
