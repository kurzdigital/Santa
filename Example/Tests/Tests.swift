import XCTest
import Santa
@testable import Santa_Example

class Tests: XCTestCase {

    func testSimpleGet() {
        let expt = expectation(description: "Return Products")
        ImplWebservice().load(resource: Products.all) { result, error in
            guard result != nil else {
                return
            }
            expt.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testSimpleDownload() {
        let expt = expectation(description: "Return Products as download")
        let webservice = ImplWebservice()
        let downloadDelegate = WebserviceDownloadDelegate(with: expt)
        webservice.downloadDelegate = downloadDelegate
        webservice.load(resource: Products.allAsDownload) {error in XCTFail("\(error)")}
        waitForExpectations(timeout: 2, handler: nil)
    }
}

class WebserviceDownloadDelegate: WebserviceDownloadTaskDelegate {
    let expectation: XCTestExpectation

    init(with expectation: XCTestExpectation) {
        self.expectation = expectation
    }

    func webservice(_ sender: Webservice, didFinishDownload url: String, atLocation location: URL, fileName: String) {
        debugPrint(location.absoluteURL)
        debugPrint(fileName)
        expectation.fulfill()
    }

    func webservice(_ sender: Webservice, didErrorDownload url: String, with error: Error, forFileName fileName: String?) {
        debugPrint(fileName ?? "No Filename")
        XCTFail("didFail download \(error)")
    }

}
