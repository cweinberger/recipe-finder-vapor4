/// Copyright (c) 2020 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Vapor

// MARK: Client
public final class ElasticsearchClient {
    
    private let client: Client
    private let scheme: String
    private let host: String
    private let port: Int
    private let username: String?
    private let password: String?
    
    public init(client: Client, scheme: String = "http", host: String, port: Int = 9200, username: String? = nil, password: String? = nil) {
        self.client = client
        self.scheme = scheme
        self.host = host
        self.port = port
        self.username = username
        self.password = password
    }
    
    private func sendRequest<D: Decodable>(_ request: ClientRequest) throws -> EventLoopFuture<D> {
        print("\nRequest:\n\n\(request)\n")
        return try sendRequest(request).flatMapThrowing { clientResponse in
            print("\nResponse:\n\n\(clientResponse)\n")
            switch clientResponse.status.code {
            case 200...299: return try clientResponse.content.decode(D.self, using: JSONDecoder())
            default: throw Abort(HTTPResponseStatus(statusCode: Int(clientResponse.status.code)))
            }
        }
    }
    
    private func sendRequest(_ request: ClientRequest) throws -> EventLoopFuture<ClientResponse> {
        client.send(request)
    }
}

//// MARK: - Helper
extension ElasticsearchClient {
    
    private func fullURL(path: String, queryItems: [URLQueryItem] = []) -> URI {
        var urlComponents = URLComponents()
        urlComponents.scheme = scheme
        urlComponents.host = host
        urlComponents.port = port
        urlComponents.path = path
        urlComponents.queryItems = queryItems
        guard let url = urlComponents.url else {
            fatalError("malformed url: \(urlComponents)")
        }
        return URI(string: url.absoluteString)
    }
}

// MARK: Requests
extension ElasticsearchClient {
    
    public func createDocument<Document: Encodable>(_ document: Document, in indexName: String) throws -> EventLoopFuture<ESCreateDocumentResponse> {
        let url = fullURL(path: "/\(indexName)/_doc")
        var request = try ClientRequest(method: .POST, url: url, body: document)
        request.headers.contentType = .json
        return try sendRequest(request)
    }
    
    public func getDocument<Document: Decodable>(id: String, from indexName: String) throws -> EventLoopFuture<ESGetSingleDocumentResponse<Document>> {
        let url = fullURL(path: "/\(indexName)/_doc/\(id)")
        let request = ClientRequest(method: .GET, url: url)
        return try sendRequest(request)
    }
    
    public func getAllDocuments<Document: Decodable>(from indexName: String) throws -> EventLoopFuture<ESGetMultipleDocumentsResponse<Document>> {
        let url = fullURL(path: "/\(indexName)/_search")
        let request = ClientRequest(method: .GET, url: url)
        return try sendRequest(request)
    }
    
    public func searchDocuments<Document: Decodable>(from indexName: String, searchTerm: String) throws -> EventLoopFuture<ESGetMultipleDocumentsResponse<Document>> {
        let url = fullURL(
            path: "/\(indexName)/_search",
            queryItems: [URLQueryItem(name: "q", value: searchTerm)]
        )
        let request = ClientRequest(method: .GET, url: url)
        return try sendRequest(request)
    }
    
    public func updateDocument<Document: Encodable>(_ document: Document, id: String, in indexName: String) throws -> EventLoopFuture<ESUpdateDocumentResponse> {
        let url = fullURL(path: "/\(indexName)/_doc/\(id)")
        var request = try ClientRequest(method: .PUT, url: url, body: document)
        request.headers.contentType = .json
        return try sendRequest(request)
    }
    
    public func deleteDocument(id: String, from indexName: String) throws -> EventLoopFuture<ESDeleteDocumentResponse> {
        let url = fullURL(path: "/\(indexName)/_doc/\(id)")
        let request = ClientRequest(method: .DELETE, url: url)
        return try sendRequest(request)
    }
    
    public func deleteIndex(_ indexName: String) throws -> EventLoopFuture<HTTPStatus> {
        let url = fullURL(path: "/\(indexName)")
        let request = ClientRequest(method: .DELETE, url: url)
        return try sendRequest(request).map { response in
            return response.status
        }
    }
}
