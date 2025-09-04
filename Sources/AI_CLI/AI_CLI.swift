import Foundation
import FoundationModels

struct SearchMatch: Codable {
    let text: String
    let relevanceScore: Double
    let startIndex: Int
    let endIndex: Int
    let reasoning: String
}

struct SearchResults: Codable {
    let matches: [SearchMatch]
    let totalMatches: Int
    let queryProcessed: String
}

@available(macOS 26.0, *)
@main
struct AI_CLI {
    static func main() async {
        let arguments = CommandLine.arguments
        
        guard arguments.count >= 3 else {
            print("Usage: AI_CLI \"<query>\" \"<body_text>\"")
            print("Example: AI_CLI \"mentions of AI\" \"This document discusses artificial intelligence and machine learning concepts.\"")
            return
        }
        
        let query = arguments[1]
        let body = arguments[2]
        
        do {
            let searchResults = try await performSemanticSearch(query: query, body: body)
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
    
    @available(macOS 26.0, *)
    static func performSemanticSearch(query: String, body: String) async throws -> SearchResults {
        let instructions = """
You are a semantic search assistant. Your task is to analyze a given body of text and find all relevant matches for a user query. 

For each match found, provide:
1. The exact text snippet that matches (should be a meaningful excerpt, not just a single word)
2. A relevance score from 0.0 to 1.0 (1.0 being perfect match)
3. The approximate start and end character indices in the original text
4. A brief reasoning for why this text matches the query

You MUST return your response as ONLY a JSON object with this exact structure, with no additional text before or after:
{
  "matches": [
    {
      "text": "actual text snippet that matches",
      "relevanceScore": 0.85,
      "startIndex": 120,
      "endIndex": 180,
      "reasoning": "brief explanation of why this matches"
    }
  ],
  "totalMatches": 1,
  "queryProcessed": "processed version of the original query"
}

Be thorough but precise. Include semantic matches, not just exact word matches. If no matches are found, return an empty matches array. Return ONLY the JSON, no other text.
"""
        
        let session = LanguageModelSession(instructions: instructions)
        
        let prompt = """
Query: "\(query)"

Body text to search:
\(body)

Analyze this text and find all semantic matches for the query. Return ONLY the JSON response as specified in the instructions.
"""
        
        let response = try await session.respond(to: prompt)
        let responseString = response.content
        let cleanResponse = responseString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try to extract JSON from the response if it's wrapped in other text
        let jsonResponse = extractJSON(from: cleanResponse)
        
        guard let jsonData = jsonResponse.data(using: .utf8) else {
            throw NSError(domain: "AI_CLI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert response to data. Raw response: \(cleanResponse)"])
        }
        
        do {
            let searchResults = try JSONDecoder().decode(SearchResults.self, from: jsonData)
            return searchResults
        } catch {
            throw NSError(domain: "AI_CLI", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to parse JSON response: \(error.localizedDescription). Raw response: \(cleanResponse)"])
        }
    }
    
    static func extractJSON(from text: String) -> String {
        // Look for JSON object boundaries
        if let startIndex = text.firstIndex(of: "{"),
           let endIndex = text.lastIndex(of: "}") {
            return String(text[startIndex...endIndex])
        }
        return text
    }
}
