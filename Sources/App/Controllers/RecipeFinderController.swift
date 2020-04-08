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

final class RecipeFinderController {
    
    func createHandler(_ req: Request) throws -> EventLoopFuture<Recipe> {
        let recipe = try req.content.decode(Recipe.self)
        return try req.esClient
            .createDocument(recipe, in: "recipes")
            .map { response in
                recipe.id = response.id
                return recipe
        }
    }
    
    func getSingleHandler(_ req: Request) throws -> EventLoopFuture<Recipe> {
        guard let id: String = req.parameters.get("id") else { throw Abort(.notFound) }
        return try req.esClient
            .getDocument(id: id, from: "recipes")
            .map { (response: ESGetSingleDocumentResponse<Recipe>) in
                let recipe = response.source
                recipe.id = response.id
                return recipe
        }
    }
    
    func updateHandler(_ req: Request) throws -> EventLoopFuture<Recipe> {
        let recipe = try req.content.decode(Recipe.self)
        guard let id: String = req.parameters.get("id") else { throw Abort(.notFound) }
        return try req.esClient.updateDocument(recipe, id: id, in: "recipes").map { response in
            return recipe
        }
    }
    
    func getAllHandler(_ req: Request) throws -> EventLoopFuture<[Recipe]> {
        return try req.esClient
            .getAllDocuments(from: "recipes")
            .map { (response: ESGetMultipleDocumentsResponse<Recipe>) in
                return response.hits.hits.map { doc in
                    let recipe = doc.source
                    recipe.id = doc.id
                    return recipe
                }
        }
    }
    
    func deleteHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        guard let id: String = req.parameters.get("id") else { throw Abort(.notFound) }
        return try req.esClient.deleteDocument(id: id, from: "recipes").map { response in
            return .ok
        }
    }
    
    func searchHandler(_ req: Request) throws -> EventLoopFuture<[Recipe]> {
        guard let term = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest, reason: "`term` is mandatory")
        }
        
        let searchTerm = "(name:*\(term)*^5 OR description:*\(term)* OR ingredients:*\(term)*^2)"
        
        return try req.esClient
            .searchDocuments(from: "recipes", searchTerm: searchTerm)
            .map { (response: ESGetMultipleDocumentsResponse<Recipe>) in
                return response.hits.hits.map { doc in
                    let recipe = doc.source
                    recipe.id = doc.id
                    return recipe
                }
        }
    }
}

extension RecipeFinderController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.post(use: createHandler)
        routes.get(":id", use: getSingleHandler)
        routes.put(":id", use: updateHandler)
        routes.get(use: getAllHandler)
        routes.delete(":id", use: deleteHandler)
        routes.get("search", use: searchHandler)
    }
}
