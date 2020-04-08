import Vapor

struct DeleteIndexCommand: Command {

    struct Signature: CommandSignature {
        @Argument(name: "Index Name", help: "The name of the index you want to delete.")
        var indexName: String
    }
    
    var help: String {
        return "Deletes the specified index from Elasticsearch"
    }
    
    func run(using context: CommandContext, signature: Signature) throws {    
        let elasticClient = ElasticsearchClient(client: context.application.client, host: "localhost", port: 9200)
        try elasticClient.deleteIndex(signature.indexName).map { response in
            if response == .ok {
                print("Deleted index with name: `\(signature.indexName)`")
            } else if response == .notFound {
                print("Could not find index with name: `\(signature.indexName)`")
            } else {
                print("Delete index response: \(response)")
            }
        }.wait()
    }
}
