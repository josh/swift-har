@testable import HAR
import XCTest

final class HARTests: XCTestCase {
    func testLoadFixtures() {
        XCTAssertGreaterThan(fixtures.count, 1)
    }

    enum NormalizeJSON: Error {
        case unavailable
        case decodingError
    }

    func normalizeJSONObject(_ value: Any) -> Any {
        switch value {
        case let dict as [String: Any?]:
            return dict
                .compactMapValues { $0 }
                .mapValues { normalizeJSONObject($0) }
                .filter { !$0.key.starts(with: "_") }
        case let array as [Any]:
            return array.map { normalizeJSONObject($0) }
        case let n as Double:
            if n == n.rounded() {
                return n
            } else {
                // work around lossy Doubles when decoding JSON
                return String(format: "%.3f (rounded)", n)
            }
        default:
            return value
        }
    }

    func normalizeJSON(data: Data) throws -> String {
        guard #available(macOS 10.13, *) else {
            throw NormalizeJSON.unavailable
        }

        let jsonObject = normalizeJSONObject(try JSONSerialization.jsonObject(with: data))
        let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.sortedKeys, .prettyPrinted])

        guard let jsonString = String(bytes: jsonData, encoding: .utf8) else {
            throw NormalizeJSON.decodingError
        }

        return jsonString
    }

    func testCodable() throws {
        let decoder = JSONDecoder()

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        for (name, data) in fixtures {
            do {
                let har = try decoder.decode(HAR.self, from: data)
                let data2 = try encoder.encode(har)

                XCTAssertEqual(try normalizeJSON(data: data), try normalizeJSON(data: data2), "\(name) did not serialize to same JSON.")
            } catch {
                XCTAssertNil(error, "\(name) failed encoding.")
                throw error
            }
        }
    }

    func testDecodable() throws {
        let data = fixture(name: "Safari example.com.har")

        let decoder = JSONDecoder()
        let har = try decoder.decode(HAR.self, from: data)

        XCTAssertEqual(har.log.version, "1.2")
        XCTAssertEqual(har.log.creator.name, "WebKit Web Inspector")
        XCTAssertEqual(har.log.pages?.first?.title, "http://example.com/")
        XCTAssertEqual(har.log.entries.first?.request.url, "http://example.com/")
        XCTAssertEqual(har.log.entries.first?.response.statusText, "OK")
    }

    func testURLRequest() throws {
        let url = URL(string: "http://example.com")!
        var request = URLRequest(url: url)
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_2) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.4 Safari/605.1.15", forHTTPHeaderField: "User-Agent")

        let harRequest = HAR.Request(request)
        XCTAssertEqual(harRequest.method, "GET")
        XCTAssertEqual(harRequest.url, "http://example.com")
        XCTAssertEqual(harRequest.httpVersion, "HTTP/1.1")
        XCTAssertEqual(harRequest.cookies, [])
        XCTAssert(harRequest.headers.contains(HAR.Header(name: "Accept", value: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8")))
        XCTAssert(harRequest.headers.contains(HAR.Header(name: "User-Agent", value: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_2) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.4 Safari/605.1.15")))
        XCTAssertEqual(harRequest.queryString, [])
        XCTAssertEqual(harRequest.postData, nil)
        XCTAssertEqual(harRequest.headersSize, -1) // TODO:
        XCTAssertEqual(harRequest.bodySize, -1) // TODO:
    }

    var fixtureURL: URL {
        var url = URL(fileURLWithPath: #file)
        url.appendPathComponent("../../Fixtures")
        url.standardize()
        return url
    }

    var fixtures: [String: Data] {
        var fixtures: [String: Data] = [:]
        for name in try! FileManager.default.contentsOfDirectory(atPath: fixtureURL.path) {
            fixtures[name] = fixture(name: name)
        }
        return fixtures
    }

    func fixture(name: String) -> Data {
        try! Data(contentsOf: fixtureURL.appendingPathComponent(name))
    }

    static var allTests = [
        ("testLoadFixtures", testLoadFixtures),
        ("testCodable", testCodable),
        ("testDecodable", testDecodable),
        ("testURLRequest", testURLRequest),
    ]
}
