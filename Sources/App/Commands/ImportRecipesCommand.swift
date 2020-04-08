import Vapor

struct ImportRecipesCommand: Command {
    
    struct Signature: CommandSignature {
        @Argument(name: "File Path", help: "The full path to the JSON file you want to import.")
        var filePath: String
    }
    
    var help: String {
        return "Imports the recipes found at `File Path` into Elasticsearch `recipes` index."
    }
        
    func run(using context: CommandContext, signature: Signature) throws {
        
        let fileURL = URL(fileURLWithPath: signature.filePath, isDirectory: false)
        
        guard let data = try? Data(contentsOf: fileURL) else {
            throw Abort(.badRequest, reason: "Could not read file: \(fileURL)")
        }
        
        guard let recipes = try? JSONDecoder().decode([Recipe].self, from: data) else {
            throw Abort(.badRequest, reason: "Could not parse JSON into recipes")
        }
        
        let elasticClient = ElasticsearchClient(client: context.application.client, host: "localhost", port: 9200)
        
        try recipes.map { recipe in
            return try elasticClient.createDocument(recipe, in: "recipes")
        }
        .flatten(on: context.application.eventLoopGroup.next())
        .map { _ in print("Import done") }
        .wait()
    }
}
