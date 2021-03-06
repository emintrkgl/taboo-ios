//
//  WordStore.m
//  Tababooboo
//
//  Created by Jackson Owens on 12/24/13.
//  Copyright (c) 2013 Tababooboo. All rights reserved.
//

#import "WordStore.h"
#import "Word.h"

@implementation WordStore


- (id) init {
    if (!(self = [super init])) {
        return nil;
    }
    
    self->words = [[NSMutableArray alloc] init];
    
    return self;
}

- (void) loadFromFile:(NSString *)filename {
    NSLog(@"Loading words from %@\n", filename);
    
    // Parse words.json as json
    NSString *jsonString = [[NSString alloc] initWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:NULL];
    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *e = nil;
    NSArray *wordsFromFile = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error: &e];
    
    if (!wordsFromFile) {
        NSLog(@"Error parsing words.json on word store initialization");
        return;
    }
    
    // Add all the parsed words to the store
    for (NSDictionary *item in wordsFromFile) {
        [self->words addObject: [[Word alloc] initFromDictionary: item]];
    }
    
    NSLog(@"WordStore count is %d\n", [self->words count]);
}

- (int) count {
    return [self->words count];
}

- (Word *) get:(int)index {
    return self->words[index];
}

@end
