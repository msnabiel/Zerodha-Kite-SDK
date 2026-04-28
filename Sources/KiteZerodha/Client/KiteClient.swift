import Foundation
import CryptoKit

public enum KiteError: Error { case missingAccessToken, invalidURL, apiError(String), decodingError }
private struct KiteEnvelope<T: Decodable>: Decodable { let status: String; let data: T?; let message: String? }

public final class KiteClient: @unchecked Sendable {
    public let apiKey: String
    public private(set) var accessToken: String?
    private let session: URLSession
    private let apiRoot = KiteZerodha.apiRoot
    private let loginRoot = KiteZerodha.loginRoot

    public init(apiKey: String, accessToken: String? = nil, session: URLSession = .shared) {
        self.apiKey = apiKey; self.accessToken = accessToken; self.session = session
    }

    public func loginURL(redirectParams: String? = nil) -> URL {
        var c = URLComponents(url: loginRoot, resolvingAgainstBaseURL: false)!
        c.queryItems = [.init(name: "v", value: KiteZerodha.apiVersion), .init(name: "api_key", value: apiKey), .init(name: "redirect_params", value: redirectParams)]
        return c.url!
    }

    public func setAccessToken(_ token: String) { accessToken = token }

    public func generateSession(requestToken: String, apiSecret: String) async throws -> KiteSession {
        let checksum = Self.sha256Hex(apiKey + requestToken + apiSecret)
        let s: KiteSession = try await request(path: "/session/token", method: "POST", form: ["api_key": apiKey, "request_token": requestToken, "checksum": checksum], requiresAuth: false)
        accessToken = s.accessToken
        return s
    }

    public func orders() async throws -> [KiteOrder] { try await request(path: "/orders", method: "GET") }
    public func orderHistory(orderID: String) async throws -> [KiteOrder] { try await request(path: "/orders/\(orderID)", method: "GET") }
    public func trades() async throws -> [KiteTrade] { try await request(path: "/trades", method: "GET") }
    public func orderTrades(orderID: String) async throws -> [KiteTrade] { try await request(path: "/orders/\(orderID)/trades", method: "GET") }
    public func positions() async throws -> [String: [KitePosition]] { try await request(path: "/portfolio/positions", method: "GET") }
    public func holdings() async throws -> [KiteHolding] { try await request(path: "/portfolio/holdings", method: "GET") }
    public func profile() async throws -> [String: String] { try await request(path: "/user/profile", method: "GET") }
    public func margins() async throws -> [String: [String: Double]] { try await request(path: "/user/margins", method: "GET") }
    public func instruments(exchange: String? = nil) async throws -> String { try await requestRaw(path: exchange.map { "/instruments/\($0)" } ?? "/instruments", method: "GET") }
    public func ltp(i: [String]) async throws -> [String: KiteLTPQuote] { try await request(path: "/quote/ltp", method: "GET", query: i.map { URLQueryItem(name: "i", value: $0) }) }
    public func quote(i: [String]) async throws -> [String: KiteFullQuote] { try await request(path: "/quote", method: "GET", query: i.map { URLQueryItem(name: "i", value: $0) }) }
    public func ohlc(i: [String]) async throws -> [String: KiteOHLCQuote] { try await request(path: "/quote/ohlc", method: "GET", query: i.map { URLQueryItem(name: "i", value: $0) }) }
    public func historical(instrumentToken: Int, interval: String, from: String, to: String, continuous: Int = 0, oi: Int = 0) async throws -> [String: [[AnyCodable]]] {
        try await request(path: "/instruments/historical/\(instrumentToken)/\(interval)", method: "GET", query: [
            .init(name: "from", value: from),
            .init(name: "to", value: to),
            .init(name: "continuous", value: String(continuous)),
            .init(name: "oi", value: String(oi)),
        ])
    }

    public func placeOrder(_ req: PlaceOrderRequest) async throws -> String {
        let data: KiteOrder = try await request(path: "/orders/\(req.variety)", method: "POST", form: [
            "exchange": req.exchange,
            "tradingsymbol": req.tradingsymbol,
            "transaction_type": req.transactionType,
            "quantity": String(req.quantity),
            "product": req.product,
            "order_type": req.orderType,
            "price": req.price.map { String($0) } ?? "",
            "trigger_price": req.triggerPrice.map { String($0) } ?? "",
            "validity": req.validity ?? "",
            "tag": req.tag ?? "",
        ].filter { !$0.value.isEmpty })
        return data.orderID
    }

    public func modifyOrder(_ req: ModifyOrderRequest) async throws -> String {
        let data: KiteOrder = try await request(path: "/orders/\(req.variety)/\(req.orderID)", method: "PUT", form: [
            "quantity": req.quantity.map { String($0) } ?? "",
            "price": req.price.map { String($0) } ?? "",
            "trigger_price": req.triggerPrice.map { String($0) } ?? "",
            "validity": req.validity ?? "",
        ].filter { !$0.value.isEmpty })
        return data.orderID
    }

    public func cancelOrder(variety: String = "regular", orderID: String) async throws -> String {
        let data: KiteOrder = try await request(path: "/orders/\(variety)/\(orderID)", method: "DELETE")
        return data.orderID
    }

    public func placeGTT(type: String, conditionJSON: String, ordersJSON: String) async throws -> KiteGTTResponse {
        try await request(path: "/gtt/triggers", method: "POST", form: ["type": type, "condition": conditionJSON, "orders": ordersJSON])
    }
    public func gtts() async throws -> [KiteGTTTrigger] { try await request(path: "/gtt/triggers", method: "GET") }
    public func gtt(id: Int) async throws -> KiteGTTTrigger { try await request(path: "/gtt/triggers/\(id)", method: "GET") }
    public func modifyGTT(id: Int, type: String, conditionJSON: String, ordersJSON: String) async throws -> KiteGTTResponse {
        try await request(path: "/gtt/triggers/\(id)", method: "PUT", form: ["type": type, "condition": conditionJSON, "orders": ordersJSON])
    }
    public func deleteGTT(id: Int) async throws -> KiteGTTResponse { try await request(path: "/gtt/triggers/\(id)", method: "DELETE") }

    private func request<T: Decodable>(path: String, method: String, form: [String: String]? = nil, requiresAuth: Bool = true, query: [URLQueryItem] = []) async throws -> T {
        var comps = URLComponents(url: apiRoot.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        comps.queryItems = query.isEmpty ? nil : query
        var req = URLRequest(url: comps.url!)
        req.httpMethod = method
        req.setValue(KiteZerodha.apiVersion, forHTTPHeaderField: "X-Kite-Version")
        if requiresAuth {
            guard let token = accessToken else { throw KiteError.missingAccessToken }
            req.setValue("token \(apiKey):\(token)", forHTTPHeaderField: "Authorization")
        }
        if let form {
            req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            req.httpBody = form.map { "\($0.key.urlQueryEscaped)=\($0.value.urlQueryEscaped)" }.joined(separator: "&").data(using: .utf8)
        }
        let (d, _) = try await session.data(for: req)
        let env = try JSONDecoder().decode(KiteEnvelope<T>.self, from: d)
        guard env.status == "success", let data = env.data else { throw KiteError.apiError(env.message ?? "unknown") }
        return data
    }

    private func requestRaw(path: String, method: String, query: [URLQueryItem] = [], requiresAuth: Bool = true) async throws -> String {
        var comps = URLComponents(url: apiRoot.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        comps.queryItems = query.isEmpty ? nil : query
        var req = URLRequest(url: comps.url!)
        req.httpMethod = method
        req.setValue(KiteZerodha.apiVersion, forHTTPHeaderField: "X-Kite-Version")
        if requiresAuth {
            guard let token = accessToken else { throw KiteError.missingAccessToken }
            req.setValue("token \(apiKey):\(token)", forHTTPHeaderField: "Authorization")
        }
        let (d, _) = try await session.data(for: req)
        guard let text = String(data: d, encoding: .utf8) else { throw KiteError.decodingError }
        return text
    }

    public static func sha256Hex(_ value: String) -> String {
        SHA256.hash(data: Data(value.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
