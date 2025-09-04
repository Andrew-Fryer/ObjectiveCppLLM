import Foundation
import AI_CLI_Core

@available(macOS 26.0, *)
@main
struct AI_CLI {
    static func main() async {
        let arguments = CommandLine.arguments
        
        guard arguments.count >= 2 else {
            print("Usage: AI_CLI \"<query>\"")
            print("Example: echo \"This document discusses artificial intelligence and machine learning concepts.\" | AI_CLI \"mentions of AI\"")
            return
        }
        
        let query = arguments[1]
        
        // Read body from stdin
        let body: String
        do {
            body = try AI_CLI_Core.readFromStdin()
        } catch {
            let errorResponse = ["error": "Failed to read from stdin: \(error.localizedDescription)"]
            if let jsonData = try? JSONSerialization.data(withJSONObject: errorResponse),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                print(jsonString)
            }
            return
        }
        
        do {
            let searchResults = try await AI_CLI_Core.performSemanticSearch(query: query, body: body)
            let jsonData = try JSONEncoder().encode(searchResults)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print(jsonString)
            }
        } catch {
            let errorResponse = ["error": error.localizedDescription]
            if let jsonData = try? JSONSerialization.data(withJSONObject: errorResponse),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                print(jsonString)
            } else {
                print("{\"error\": \"Failed to process request\"}")
            }
        }
    }
}
