import HAR
import XCTest

final class HARTests: XCTestCase {
    func testCodable() throws {
        for (name, data) in fixtureData {
            do {
                let har = try HAR(data: data)
                _ = try har.encoded()
            } catch {
                XCTAssertNil(error, "\(name) failed encoding.")
                throw error
            }
        }
    }

    func testDecodable() throws {
        let har = try HAR(data: XCTUnwrap(fixtureData["Safari example.com.har"]))

        XCTAssertEqual(har.log.version, "1.2")
        XCTAssertEqual(har.log.creator.name, "WebKit Web Inspector")
        XCTAssertEqual(har.log.pages?.first?.title, "http://example.com/")
        XCTAssertEqual(har.log.entries.first?.request.url.absoluteString, "http://example.com/")
        XCTAssertEqual(har.log.entries.first?.response.statusText, "OK")
    }

    func testScrubbingHeaders() throws {
        let har = try HAR(data: XCTUnwrap(fixtureData["Safari jsbin.com.har"]))
        let scrubbed = har.scrubbing([
            .redactHeaderMatching(
                pattern: try NSRegularExpression(pattern: #"Cookie"#), placeholder: "redacted"
            ),
        ])

        XCTAssertEqual(
            scrubbed.log.entries.first?.request.headers.value(forName: "Cookie"),
            "redacted"
        )
        XCTAssertEqual(
            scrubbed.log.entries.first?.request.cookies.first,
            HAR.Cookie(name: "last", value: "redacted")
        )
    }

    func testStrippingTimings() throws {
        let har = try HAR(data: XCTUnwrap(fixtureData["Safari jsbin.com.har"]))
        let scrubbed = har.scrubbing([.stripTimmings])

        XCTAssertEqual(scrubbed.log.pages?.first?.pageTimings.onContentLoad, -1)
        XCTAssertEqual(scrubbed.log.pages?.first?.pageTimings.onLoad, -1)

        XCTAssertEqual(scrubbed.log.entries.first?.time, -1)
        XCTAssertEqual(scrubbed.log.entries.first?.timings, HAR.Timing())
    }
}
