import Foundation
import AI_CLI_Core

// Objective-C compatible data structures
@objc public class SearchMatchObjC: NSObject {
    @objc public let text: String
    @objc public let relevanceScore: Double
    @objc public let startIndex: Int
    @objc public let endIndex: Int
    @objc public let reasoning: String
    
    public init(text: String, relevanceScore: Double, startIndex: Int, endIndex: Int, reasoning: String) {
        self.text = text
        self.relevanceScore = relevanceScore
        self.startIndex = startIndex
        self.endIndex = endIndex
        self.reasoning = reasoning
    }
}

@objc public class SearchResultsObjC: NSObject {
    @objc public let matches: [SearchMatchObjC]
    @objc public let totalMatches: Int
    @objc public let queryProcessed: String
    
    public init(matches: [SearchMatchObjC], totalMatches: Int, queryProcessed: String) {
        self.matches = matches
        self.totalMatches = totalMatches
        self.queryProcessed = queryProcessed
    }
}

@available(macOS 26.0, *)
@objc public class SwiftBridge: NSObject {
    
    @objc public static func performSemanticSearch(query: String, body: String, completion: @escaping @Sendable (SearchResultsObjC?, NSError?) -> Void) {
        Task {
            do {
                // Call the actual Swift AI_CLI_Core functionality
                let searchResults = try await AI_CLI_Core.performSemanticSearch(query: query, body: body)
                
                // Convert to Objective-C compatible objects
                let objcMatches = searchResults.matches.map { match in
                    SearchMatchObjC(
                        text: match.text,
                        relevanceScore: match.relevanceScore,
                        startIndex: match.startIndex,
                        endIndex: match.endIndex,
                        reasoning: match.reasoning
                    )
                }
                
                let objcResults = SearchResultsObjC(
                    matches: objcMatches,
                    totalMatches: searchResults.totalMatches,
                    queryProcessed: searchResults.queryProcessed
                )
                
                completion(objcResults, nil)
            } catch {
                completion(nil, error as NSError)
            }
        }
    }
}