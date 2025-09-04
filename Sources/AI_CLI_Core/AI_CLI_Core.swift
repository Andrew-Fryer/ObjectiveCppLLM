import Foundation
import FoundationModels

public struct SearchMatch: Codable {
    public let text: String
    public let relevanceScore: Double
    public let startIndex: Int
    public let endIndex: Int
    public let reasoning: String
    
    public init(text: String, relevanceScore: Double, startIndex: Int, endIndex: Int, reasoning: String) {
        self.text = text
        self.relevanceScore = relevanceScore
        self.startIndex = startIndex
        self.endIndex = endIndex
        self.reasoning = reasoning
    }
}

public struct SearchResults: Codable {
    public let matches: [SearchMatch]
    public let totalMatches: Int
    public let queryProcessed: String
    
    public init(matches: [SearchMatch], totalMatches: Int, queryProcessed: String) {
        self.matches = matches
        self.totalMatches = totalMatches
        self.queryProcessed = queryProcessed
    }
}

@available(macOS 26.0, *)
public struct AI_CLI_Core {
    
    public static func performSemanticSearch(query: String, body: String) async throws -> SearchResults {
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
    
    public static func readFromStdin() throws -> String {
        var input = ""
        while let line = readLine() {
            input += line + "\n"
        }
        
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NSError(domain: "AI_CLI", code: 3, userInfo: [NSLocalizedDescriptionKey: "No input provided via stdin"])
        }
        
        return input.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public static func extractJSON(from text: String) -> String {
        // Look for JSON object boundaries
        if let startIndex = text.firstIndex(of: "{"),
           let endIndex = text.lastIndex(of: "}") {
            return String(text[startIndex...endIndex])
        }
        return text
    }
}