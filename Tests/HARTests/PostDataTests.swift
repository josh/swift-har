import HAR
import XCTest

final class PostDataTests: XCTestCase {
    let formDataText = """
    ------WebKitFormBoundary
    Content-Disposition: form-data; name="name"
    Steve Jobs
    ------WebKitFormBoundary
    Content-Disposition: form-data; name="upload"; filename="upload.pdf"
    Content-Type: application/pdf
    ------WebKitFormBoundaryJ8ZeKCKRN4jiAZ8G--
    """

    func testEquatable() {
        XCTAssertEqual(
            HAR.PostData(
                mimeType: "application/x-www-form-urlencoded; charset=UTF-8",
                params: [HAR.Param(name: "foo", value: "1")], text: "foo=1"
            ),
            HAR.PostData(
                mimeType: "application/x-www-form-urlencoded; charset=UTF-8",
                params: [HAR.Param(name: "foo", value: "1")], text: "foo=1"
            )
        )
        XCTAssertNotEqual(
            HAR.PostData(
                mimeType: "application/x-www-form-urlencoded; charset=UTF-8",
                params: [HAR.Param(name: "foo", value: "1")], text: "foo=1"
            ),
            HAR.PostData(
                mimeType: "application/x-www-form-urlencoded; charset=UTF-8",
                params: [HAR.Param(name: "bar", value: "2")], text: "bar=2"
            )
        )

        XCTAssertEqual(
            HAR.PostData(
                mimeType: "multipart/form-data; boundary=----WebKitFormBoundary", params: [],
                text: formDataText
            ),
            HAR.PostData(
                mimeType: "multipart/form-data; boundary=----WebKitFormBoundary", params: [],
                text: formDataText
            )
        )
    }

    func testHashable() {
        let set = Set([
            HAR.PostData(
                mimeType: "application/x-www-form-urlencoded; charset=UTF-8",
                params: [HAR.Param(name: "foo", value: "1")], text: "foo=1"
            ),
            HAR.PostData(
                mimeType: "application/x-www-form-urlencoded; charset=UTF-8",
                params: [HAR.Param(name: "foo", value: "1")], text: "foo=1"
            ),
            HAR.PostData(
                mimeType: "application/x-www-form-urlencoded; charset=UTF-8",
                params: [HAR.Param(name: "bar", value: "2")], text: "bar=2"
            ),
        ])
        XCTAssertEqual(set.count, 2)
    }

    func testDecodable() throws {
        let json = """
            {
                "mimeType": "application/x-www-form-urlencoded; charset=UTF-8",
                "text": "foo=1",
                "params": [ { "name": "foo", "value": "1" } ]
            }
        """

        let postData = try JSONDecoder().decode(HAR.PostData.self, from: Data(json.utf8))
        XCTAssertEqual(
            postData,
            HAR.PostData(
                mimeType: "application/x-www-form-urlencoded; charset=UTF-8",
                params: [HAR.Param(name: "foo", value: "1")],
                text: "foo=1"
            )
        )
    }

    func testEncodable() throws {
        let data = try JSONEncoder().encode(
            HAR.PostData(
                mimeType: "application/x-www-form-urlencoded; charset=UTF-8",
                params: [HAR.Param(name: "foo", value: "1")],
                text: "foo=1"
            ))
        let json = String(decoding: data, as: UTF8.self)

        XCTAssert(json.contains(#""text":"foo=1""#))
    }

    func initParsingParams() {
        let urlEncodedPostData = HAR.PostData(
            parsingText: "foo=1", mimeType: "application/x-www-form-urlencoded; charset=UTF-8"
        )
        let multipartPostData = HAR.PostData(
            parsingText: formDataText, mimeType: "multipart/form-data; boundary=----WebKitFormBoundary"
        )

        XCTAssertEqual(
            urlEncodedPostData,
            HAR.PostData(
                mimeType: "application/x-www-form-urlencoded; charset=UTF-8",
                params: [HAR.Param(name: "foo", value: "1")], text: "foo=1"
            )
        )

        XCTAssertEqual(
            multipartPostData,
            HAR.PostData(
                mimeType: "multipart/form-data; boundary=----WebKitFormBoundary", params: [],
                text: formDataText
            )
        )
    }
}
