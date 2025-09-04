#import <Foundation/Foundation.h>
#import <iostream>
#import <string>
#import "AI_CLI_Bridge.h"

void printError(const std::string& errorMessage) {
    NSDictionary *errorDict = @{@"error": [NSString stringWithUTF8String:errorMessage.c_str()]};
    NSError *jsonError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:errorDict 
                                                       options:0 
                                                         error:&jsonError];
    if (jsonData && !jsonError) {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        std::cout << [jsonString UTF8String] << std::endl;
    } else {
        std::cout << "{\"error\": \"Failed to process request\"}" << std::endl;
    }
}

void printSearchResults(SearchResultsObjC *results) {
    NSMutableArray *matchesArray = [[NSMutableArray alloc] init];
    
    for (SearchMatchObjC *match in results.matches) {
        NSDictionary *matchDict = @{
            @"text": match.text,
            @"relevanceScore": @(match.relevanceScore),
            @"startIndex": @(match.startIndex),
            @"endIndex": @(match.endIndex),
            @"reasoning": match.reasoning
        };
        [matchesArray addObject:matchDict];
    }
    
    NSDictionary *resultsDict = @{
        @"matches": matchesArray,
        @"totalMatches": @(results.totalMatches),
        @"queryProcessed": results.queryProcessed
    };
    
    NSError *jsonError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:resultsDict 
                                                       options:0 
                                                         error:&jsonError];
    if (jsonData && !jsonError) {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        std::cout << [jsonString UTF8String] << std::endl;
    } else {
        printError("Failed to serialize search results");
    }
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc < 2) {
            std::cout << "Usage: AI_CLI_ObjCpp \"<query>\"" << std::endl;
            std::cout << "Example: echo \"This document discusses artificial intelligence and machine learning concepts.\" | AI_CLI_ObjCpp \"mentions of AI\"" << std::endl;
            return 1;
        }
        
        NSString *query = [NSString stringWithUTF8String:argv[1]];
        
        // Read body from stdin
        NSError *stdinError = nil;
        NSString *body = [AI_CLIBridge readFromStdin:&stdinError];
        if (stdinError || !body) {
            std::string errorMsg = "Failed to read from stdin";
            if (stdinError) {
                errorMsg += ": " + std::string([[stdinError localizedDescription] UTF8String]);
            }
            printError(errorMsg);
            return 1;
        }
        printError("got stdin");
        
        // Use semaphore to wait for async completion
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        __block BOOL success = NO;
        
        [AI_CLIBridge performSemanticSearch:query 
                                                body:body 
                                          completion:^(SearchResultsObjC * _Nullable results, NSError * _Nullable error) {
            if (error) {
                printError([[error localizedDescription] UTF8String]);
            } else if (results) {
                printSearchResults(results);
                success = YES;
            } else {
                printError("Unknown error occurred");
            }
            printError("dispatching signal");
            dispatch_semaphore_signal(semaphore);
        }];
        
        // Wait for completion
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        return success ? 0 : 1;
    }
}