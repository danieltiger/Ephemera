//
//  Generator.m
//  ConvertPostsToCSV
//
//  Created by Arik Devens on 1/31/18.
//  Copyright © 2018 Foreign & Domestic. All rights reserved.
//

#import "Generator.h"
#import "Post.h"

@implementation Generator

- (void)outputCSV {
    NSError *error;
    NSArray *posts = [self posts:&error];
    if (error) abort();

    NSMutableArray *output = [NSMutableArray new];
    [output addObject:@"title,rating,running time,seen before?,country,language,year,decade,aspect ratio,entry length,week,day"];

    for (Post *post in posts) {
        [output addObjectsFromArray:post.csv];
    }

    printf("%s\n", [[output componentsJoinedByString:@"\n"] UTF8String]);
}


#pragma mark - Helpers

- (NSArray *)posts:(NSError **)error {
    NSString *sourceDirectory = @"/Users/arik/Development/danieltiger.github.io/source/_posts";
    NSString *year = [NSString stringWithFormat:@"%ld", (long)[NSCalendar.currentCalendar component:NSCalendarUnitYear fromDate:[NSDate date]]];


    NSArray *filenames = [NSFileManager.defaultManager contentsOfDirectoryAtPath:sourceDirectory error:error];

    NSMutableArray *posts = [NSMutableArray new];
    for (NSString *filename in filenames) {
        Post *post = [Post new];

        NSString *filePath = [NSString stringWithFormat:@"/%@/%@", sourceDirectory, filename];
        post.content = [[NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:error] componentsSeparatedByString:@"\n"];

        if ([post.date isEqualToString:year] && post.published) {
            [posts addObject:post];
        }
    }
    return posts;
}

@end
