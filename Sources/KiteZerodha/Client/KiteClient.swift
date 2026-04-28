import Foundation
import CryptoKit

public enum KiteError: Error { case missingAccessToken, invalidURL, apiError(String), decodingError }
private struct KiteEnvelope<T: Decodable>: Decodable { let status: String; let data: T?; let message: String? }
private struct KiteHistoricalEnvelope: Decodable { let status: String; let data: KiteHistoricalData?; let message: String? }
private struct KiteHistoricalData: Decodable { let candles: [[AnyCodable]] }

public final class KiteClient: @unchecked Sendable {
    public let apiKey: String
    public private(set) var accessToken: String?
    public private(set) var refreshToken: String?
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
        refreshToken = s.refreshToken
        return s
    }

    public func renewAccessToken(refreshToken: String, apiSecret: String) async throws -> KiteSession {
        let checksum = Self.sha256Hex(apiKey + refreshToken + apiSecret)
        let s: KiteSession = try await request(path: "/session/refresh_token", method: "POST", form: ["api_key": apiKey, "refresh_token": refreshToken, "checksum": checksum], requiresAuth: false)
        accessToken = s.accessToken
        self.refreshToken = s.refreshToken
        return s
    }

    public func invalidateAccessToken() async throws {
        guard let token = accessToken else { throw KiteError.missingAccessToken }
        let _: [String: String] = try await request(path: "/session/token", method: "DELETE", form: ["api_key": apiKey, "access_token": token], requiresAuth: false)
        accessToken = nil
    }

    public func invalidateRefreshToken(_ refreshToken: String) async throws {
        let _: [String: String] = try await request(path: "/session/refresh_token", method: "DELETE", form: ["api_key": apiKey, "refresh_token": refreshToken], requiresAuth: false)
        self.refreshToken = nil
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

    // Alerts (form-encoded).
    public func alerts() async throws -> [KiteAlert] { try await request(path: "/alerts", method: "GET") }
    public func alert(uuid: String) async throws -> KiteAlert { try await request(path: "/alerts/\(uuid)", method: "GET") }
    public func createAlert(_ req: KiteAlertCreateRequest) async throws -> KiteAlert { try await request(path: "/alerts", method: "POST", form: req.fields) }
    public func modifyAlert(uuid: String, _ req: KiteAlertModifyRequest) async throws -> KiteAlert { try await request(path: "/alerts/\(uuid)", method: "PUT", form: req.fields) }
    public func deleteAlert(uuid: String) async throws -> [String: String] { try await request(path: "/alerts", method: "DELETE", query: [URLQueryItem(name: "uuid", value: uuid)]) }
    public func alertHistory(uuid: String) async throws -> [KiteAlertHistoryEvent] { try await request(path: "/alerts/\(uuid)/history", method: "GET") }

    // Mutual funds.
    public func mfOrders() async throws -> [KiteMFOrder] { try await request(path: "/mf/orders", method: "GET") }
    public func mfOrder(orderID: String) async throws -> KiteMFOrder { try await request(path: "/mf/orders/\(orderID)", method: "GET") }
    public func mfSIPs() async throws -> [KiteMFSIP] { try await request(path: "/mf/sips", method: "GET") }
    public func mfHoldings() async throws -> [KiteMFHolding] { try await request(path: "/mf/holdings", method: "GET") }
    public func mfInstruments() async throws -> String { try await requestRaw(path: "/mf/instruments", method: "GET") }

    // Margin calculation and charges (JSON POST).
    public func marginsOrders(_ orders: [KiteMarginOrderRequest], mode: String? = nil) async throws -> [KiteMarginResult] {
        var q: [URLQueryItem] = []
        if let mode { q.append(.init(name: "mode", value: mode)) }
        return try await requestJSON(path: "/margins/orders", method: "POST", body: orders, query: q)
    }

    public func marginsBasket(_ orders: [KiteMarginOrderRequest], mode: String? = nil) async throws -> [KiteMarginResult] {
        var q: [URLQueryItem] = []
        if let mode { q.append(.init(name: "mode", value: mode)) }
        return try await requestJSON(path: "/margins/basket", method: "POST", body: orders, query: q)
    }

    public func chargesOrders(_ orders: [KiteChargesOrderRequest]) async throws -> [KiteMarginResult] {
        try await requestJSON(path: "/charges/orders", method: "POST", body: orders)
    }

    public func historical(instrumentToken: Int, interval: String, from: String, to: String, continuous: Int = 0, oi: Int = 0) async throws -> [KiteCandle] {
        var comps = URLComponents(url: apiRoot.appendingPathComponent("/instruments/historical/\(instrumentToken)/\(interval)"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [.init(name: "from", value: from), .init(name: "to", value: to), .init(name: "continuous", value: String(continuous)), .init(name: "oi", value: String(oi))]
        var req = URLRequest(url: comps.url!)
        req.httpMethod = "GET"
        req.setValue(KiteZerodha.apiVersion, forHTTPHeaderField: "X-Kite-Version")
        guard let token = accessToken else { throw KiteError.missingAccessToken }
        req.setValue("token \(apiKey):\(token)", forHTTPHeaderField: "Authorization")
        let (d, _) = try await session.data(for: req)
        let env = try JSONDecoder().decode(KiteHistoricalEnvelope.self, from: d)
        guard env.status == "success", let raw = env.data?.candles else { throw KiteError.apiError(env.message ?? "unknown") }
        return raw.compactMap(Self.decodeCandle)
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
            "disclosed_quantity": req.disclosedQuantity.map { String($0) } ?? "",
            "market_protection": req.marketProtection.map { String($0) } ?? "",
            "autoslice": req.autoslice.map { $0 ? "true" : "false" } ?? "",
        ].filter { !$0.value.isEmpty })
        return data.orderID
    }

    public func modifyOrder(_ req: ModifyOrderRequest) async throws -> String {
        let data: KiteOrder = try await request(path: "/orders/\(req.variety)/\(req.orderID)", method: "PUT", form: [
            "quantity": req.quantity.map { String($0) } ?? "",
            "price": req.price.map { String($0) } ?? "",
            "trigger_price": req.triggerPrice.map { String($0) } ?? "",
            "validity": req.validity ?? "",
            "disclosed_quantity": req.disclosedQuantity.map { String($0) } ?? "",
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

    private func requestJSON<T: Decodable, Body: Encodable>(path: String, method: String, body: Body, query: [URLQueryItem] = []) async throws -> T {
        var comps = URLComponents(url: apiRoot.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        comps.queryItems = query.isEmpty ? nil : query
        var req = URLRequest(url: comps.url!)
        req.httpMethod = method
        req.setValue(KiteZerodha.apiVersion, forHTTPHeaderField: "X-Kite-Version")
        guard let token = accessToken else { throw KiteError.missingAccessToken }
        req.setValue("token \(apiKey):\(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)

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

    private static func decodeCandle(_ row: [AnyCodable]) -> KiteCandle? {
        guard row.count >= 6,
              case .string(let ts) = row[0],
              let o = toDouble(row[1]), let h = toDouble(row[2]), let l = toDouble(row[3]), let c = toDouble(row[4]), let v = toInt(row[5]) else { return nil }
        let oi: Int? = row.count > 6 ? toInt(row[6]) : nil
        return .init(timestamp: ts, open: o, high: h, low: l, close: c, volume: v, oi: oi)
    }

    private static func toDouble(_ a: AnyCodable) -> Double? {
        switch a { case .double(let v): return v; case .int(let v): return Double(v); case .string(let v): return Double(v); default: return nil }
    }
    private static func toInt(_ a: AnyCodable) -> Int? {
        switch a { case .int(let v): return v; case .double(let v): return Int(v); case .string(let v): return Int(v); default: return nil }
    }

    public static func sha256Hex(_ value: String) -> String { SHA256.hash(data: Data(value.utf8)).map { String(format: "%02x", $0) }.joined() }
}
