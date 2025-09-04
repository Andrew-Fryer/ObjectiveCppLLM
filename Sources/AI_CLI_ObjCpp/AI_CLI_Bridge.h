#ifndef AI_CLI_Bridge_h
#define AI_CLI_Bridge_h

#import <Foundation/Foundation.h>

@interface SearchMatchObjC : NSObject
@property (nonatomic, readonly) NSString *text;
@property (nonatomic, readonly) double relevanceScore;
@property (nonatomic, readonly) NSInteger startIndex;
@property (nonatomic, readonly) NSInteger endIndex;
@property (nonatomic, readonly) NSString *reasoning;

- (instancetype)initWithText:(NSString *)text 
              relevanceScore:(double)relevanceScore 
                  startIndex:(NSInteger)startIndex 
                    endIndex:(NSInteger)endIndex 
                   reasoning:(NSString *)reasoning;
@end

@interface SearchResultsObjC : NSObject
@property (nonatomic, readonly) NSArray<SearchMatchObjC *> *matches;
@property (nonatomic, readonly) NSInteger totalMatches;
@property (nonatomic, readonly) NSString *queryProcessed;

- (instancetype)initWithMatches:(NSArray<SearchMatchObjC *> *)matches 
                   totalMatches:(NSInteger)totalMatches 
                 queryProcessed:(NSString *)queryProcessed;
@end

@interface AI_CLIBridge : NSObject

+ (void)performSemanticSearchWithQuery:(NSString *)query 
                                  body:(NSString *)body 
                            completion:(void (^)(SearchResultsObjC * _Nullable results, NSError * _Nullable error))completion;

+ (NSString *)readFromStdin:(NSError **)error;
+ (NSString *)extractJSONFromText:(NSString *)text;

@end

#endif /* AI_CLI_Bridge_h */