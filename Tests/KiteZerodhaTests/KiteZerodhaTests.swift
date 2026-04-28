import Testing
import Foundation
@testable import KiteZerodha

@Test func loginURLIncludesExpectedParameters() async throws {
    let client = KiteClient(apiKey: "abc123")
    let url = client.loginURL(redirectParams: "state=xyz")
    let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
    let items = components.queryItems ?? []

    #expect(items.contains(URLQueryItem(name: "v", value: "3")))
    #expect(items.contains(URLQueryItem(name: "api_key", value: "abc123")))
    #expect(items.contains(URLQueryItem(name: "redirect_params", value: "state=xyz")))
}

@Test func checksumMatchesKnownSHA256() async throws {
    let input = "api_keyrequest_tokenapi_secret"
    let checksum = KiteClient.sha256Hex(input)
    #expect(checksum == "ff6a6d3d60c9d974df906ba6f787ac38300cfa68b41801b486ea1007e52e8942")
}
