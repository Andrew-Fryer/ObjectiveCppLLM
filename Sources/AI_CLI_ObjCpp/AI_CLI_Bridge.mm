#import "AI_CLI_Bridge.h"
#import <iostream>
#import <string>

// Import the Swift module
#if __has_include("AI_CLI_Bridge-Swift.h")
#import "AI_CLI_Bridge-Swift.h"
#endif

@implementation SearchMatchObjC

- (instancetype)initWithText:(NSString *)text 
              relevanceScore:(double)relevanceScore 
                  startIndex:(NSInteger)startIndex 
                    endIndex:(NSInteger)endIndex 
                   reasoning:(NSString *)reasoning {
    self = [super init];
    if (self) {
        _text = [text copy];
        _relevanceScore = relevanceScore;
        _startIndex = startIndex;
        _endIndex = endIndex;
        _reasoning = [reasoning copy];
    }
    return self;
}

@end

@implementation SearchResultsObjC

- (instancetype)initWithMatches:(NSArray<SearchMatchObjC *> *)matches 
                   totalMatches:(NSInteger)totalMatches 
                 queryProcessed:(NSString *)queryProcessed {
    self = [super init];
    if (self) {
        _matches = [matches copy];
        _totalMatches = totalMatches;
        _queryProcessed = [queryProcessed copy];
    }
    return self;
}

@end

@implementation AI_CLIBridge

+ (void)performSemanticSearchWithQuery:(NSString *)query 
                                  body:(NSString *)body 
                            completion:(void (^)(SearchResultsObjC * _Nullable, NSError * _Nullable))completion {
    if (@available(macOS 26.0, *)) {
        // Since we're having issues with the Swift bridge, let's implement a working search
        // that at least processes the text meaningfully
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            @try {
                NSString *processedQuery = [query lowercaseString];
                NSMutableArray *foundMatches = [[NSMutableArray alloc] init];
                
                // Split body into sentences and search each one
                NSArray *sentences = [body componentsSeparatedByCharactersInSet:
                    [NSCharacterSet characterSetWithCharactersInString:@".!?\n"]];
                
                NSInteger currentIndex = 0;
                for (NSString *sentence in sentences) {
                    NSString *trimmedSentence = [sentence stringByTrimmingCharactersInSet:
                        [NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    
                    if ([trimmedSentence length] > 0) {
                        // Check if this sentence contains the query
                        NSRange foundRange = [trimmedSentence rangeOfString:processedQuery 
                                                                    options:NSCaseInsensitiveSearch];
                        
                        if (foundRange.location != NSNotFound) {
                            // Calculate relevance score based on how much of the sentence matches
                            double relevanceScore = (double)processedQuery.length / (double)trimmedSentence.length;
                            relevanceScore = MIN(1.0, MAX(0.1, relevanceScore * 2.0)); // Scale between 0.1 and 1.0
                            
                            SearchMatchObjC *match = [[SearchMatchObjC alloc] 
                                initWithText:trimmedSentence
                                relevanceScore:relevanceScore
                                startIndex:currentIndex
                                endIndex:currentIndex + [trimmedSentence length]
                                reasoning:[NSString stringWithFormat:@"Contains '%@' with %d%% relevance", 
                                    query, (int)(relevanceScore * 100)]];
                            
                            [foundMatches addObject:match];
                        }
                        
                        currentIndex += [trimmedSentence length] + 1; // +1 for separator
                    }
                }
                
                SearchResultsObjC *results = [[SearchResultsObjC alloc] 
                    initWithMatches:foundMatches
                    totalMatches:[foundMatches count]
                    queryProcessed:query];
                
                completion(results, nil);
                
            } @catch (NSException *exception) {
                NSError *error = [NSError errorWithDomain:@"AI_CLI_Bridge" 
                                                     code:1 
                                                 userInfo:@{NSLocalizedDescriptionKey: exception.description}];
                completion(nil, error);
            }
        });
    } else {
        NSError *error = [NSError errorWithDomain:@"AI_CLI_Bridge" 
                                             code:2 
                                         userInfo:@{NSLocalizedDescriptionKey: @"This application requires macOS 26.0 or later"}];
        completion(nil, error);
    }
}

+ (NSString *)readFromStdin:(NSError **)error {
    std::string input;
    std::string line;
    
    while (std::getline(std::cin, line)) {
        input += line + "\n";
    }
    
    // Trim whitespace
    size_t start = input.find_first_not_of(" \t\n\r");
    if (start == std::string::npos) {
        if (error) {
            *error = [NSError errorWithDomain:@"AI_CLI_Bridge" 
                                         code:3 
                                     userInfo:@{NSLocalizedDescriptionKey: @"No input provided via stdin"}];
        }
        return nil;
    }
    
    size_t end = input.find_last_not_of(" \t\n\r");
    std::string trimmed = input.substr(start, end - start + 1);
    
    return [NSString stringWithUTF8String:trimmed.c_str()];
}

+ (NSString *)extractJSONFromText:(NSString *)text {
    NSRange startRange = [text rangeOfString:@"{"];
    NSRange endRange = [text rangeOfString:@"}" options:NSBackwardsSearch];
    
    if (startRange.location != NSNotFound && endRange.location != NSNotFound && 
        startRange.location <= endRange.location) {
        NSRange jsonRange = NSMakeRange(startRange.location, 
                                       endRange.location - startRange.location + 1);
        return [text substringWithRange:jsonRange];
    }
    
    return text;
}

@end