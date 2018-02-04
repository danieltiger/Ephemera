//
//  Post.m
//  ConvertPostsToCSV
//
//  Created by Arik Devens on 2/1/18.
//  Copyright © 2018 Foreign & Domestic. All rights reserved.
//

#import "Post.h"

@implementation Post

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    self.published = YES;
    self.countries = [NSMutableArray new];
    self.languages = [NSMutableArray new];
    self.years = [NSMutableArray new];
    self.decades = [NSMutableArray new];
    self.ratios = [NSMutableArray new];

    return self;
}

- (void)setContent:(NSArray *)content {
    _content = content;
    [self updateStatus];
}

- (NSArray *)csv {
    NSMutableArray *output = [NSMutableArray new];

    [output addObject:[self constructEntryForTitle:self.title rating:self.rating runningTime:self.runningTime seenBefore:self.seenBefore country:self.countries.firstObject language:self.languages.firstObject year:self.years.firstObject decade:self.decades.firstObject ratio:self.ratios.firstObject length:self.length week:self.week day:self.day]];

    for (int i = 1; i < self.countries.count; i++) {
        [output addObject:[self constructEntryForTitle:self.title country:self.countries[i]]];
    }

    for (int i = 1; i < self.languages.count; i++) {
        [output addObject:[self constructEntryForTitle:self.title language:self.languages[i]]];
    }

    for (int i = 1; i < self.years.count; i++) {
        [output addObject:[self constructEntryForTitle:self.title year:self.years[i]]];
    }

    for (int i = 1; i < self.decades.count; i++) {
        [output addObject:[self constructEntryForTitle:self.title decade:self.decades[i]]];
    }

    for (int i = 1; i < self.ratios.count; i++) {
        [output addObject:[self constructEntryForTitle:self.title ratio:self.ratios[i]]];
    }

    return output;
}

#pragma mark - Helpers

- (void)updateStatus {
    for (NSString *line in self.content) {
        if ([line hasPrefix:@"> "]) { break; }

        if ([line hasPrefix:@"date: "]) {
            self.date = [self extractDateForLine:line];
        } else if ([line hasPrefix:@"published: "]) {
            self.published = NO;
        } else if ([line hasPrefix:@"title: "]) {
            self.title = [self extractTitleForLine:line];
        } else if ([line hasPrefix:@"rating: "]) {
            self.rating = [self extractTitleForLine:line];
        } else if ([line hasPrefix:@"time: "]) {
            self.runningTime = [self extractTitleForLine:line];
        } else if ([line hasPrefix:@"seen: "]) {
            self.seenBefore = [self extractTitleForLine:line];
        } else if ([line hasPrefix:@"categories: "]) {
            [self updateCategoriesForLine:line];
        } else if ([line hasPrefix:@"length: "]) {
            self.length = [self extractTitleForLine:line];
        } else if ([line hasPrefix:@"week: "]) {
            self.week = [self extractTitleForLine:line];
        } else if ([line hasPrefix:@"day: "]) {
            self.day = [self extractTitleForLine:line];
        }
    }
}

- (NSString *)extractDateForLine:(NSString *)line {
    NSRange firstSpace = [line rangeOfString:@" "];
    NSRange firstDash = [line rangeOfString:@"-"];
    long length = firstDash.location - firstSpace.location;
    NSString *date = [line substringWithRange:NSMakeRange(firstSpace.location, length)];
    return [date stringByReplacingOccurrencesOfString:@" " withString:@""];
}

- (NSString *)extractTitleForLine:(NSString *)line {
    return [[self extractContentForLine:line] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
}

- (NSString *)extractContentForLine:(NSString *)line {
    NSRange firstSpace = [line rangeOfString:@" "];
    long length = line.length - firstSpace.location;
    return [[line substringWithRange:NSMakeRange(firstSpace.location, length)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

// categories: ["Italy", "Germany", "1928", "1.33:1", German, Italian]
- (void)updateCategoriesForLine:(NSString *)line {
    NSString *content = [self extractContentForLine:line];
    if ([content isEqualToString:@""] || content.length <= 0) { return; }

    BOOL hasFoundYear = NO;
    NSArray *categories = [content componentsSeparatedByString:@", "];
    for (NSString *category in categories) {
        if ([category containsString:@"\""] == YES) {
            hasFoundYear = YES;
        }

        NSString *strippedCategory = [category stringByTrimmingCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]];

        if (hasFoundYear == NO) {
            [self.countries addObject:strippedCategory];
        } else if ([strippedCategory containsString:@":"]) {
            [self.ratios addObject:strippedCategory];
        } else if ([strippedCategory intValue] != 0) {
            [self.years addObject:strippedCategory];
            [self.decades addObject:[NSString stringWithFormat:@"%@0", [strippedCategory substringToIndex:[strippedCategory length] - 1]]];
            self.decades = [[[NSSet setWithArray:self.decades] allObjects] mutableCopy];
        } else if (hasFoundYear) {
            [self.languages addObject:strippedCategory];
        }
    }
}

- (NSString *)constructEntryForTitle:(NSString *)title country:(NSString *)country {
    return [self constructEntryForTitle:title rating:@"" runningTime:@"" seenBefore:@"" country:country language:@"" year:@"" decade:@"" ratio:@"" length:@"" week:@"" day:@""];
}

- (NSString *)constructEntryForTitle:(NSString *)title language:(NSString *)language {
    return [self constructEntryForTitle:title rating:@"" runningTime:@"" seenBefore:@"" country:@"" language:language year:@"" decade:@"" ratio:@"" length:@"" week:@"" day:@""];
}

- (NSString *)constructEntryForTitle:(NSString *)title year:(NSString *)year {
    return [self constructEntryForTitle:title rating:@"" runningTime:@"" seenBefore:@"" country:@"" language:@"" year:year decade:@"" ratio:@"" length:@"" week:@"" day:@""];
}

- (NSString *)constructEntryForTitle:(NSString *)title decade:(NSString *)decade {
    return [self constructEntryForTitle:title rating:@"" runningTime:@"" seenBefore:@"" country:@"" language:@"" year:@"" decade:decade ratio:@"" length:@"" week:@"" day:@""];
}

- (NSString *)constructEntryForTitle:(NSString *)title ratio:(NSString *)ratio {
    return [self constructEntryForTitle:title rating:@"" runningTime:@"" seenBefore:@"" country:@"" language:@"" year:@"" decade:@"" ratio:ratio length:@"" week:@"" day:@""];
}

- (NSString *)constructEntryForTitle:(NSString *)title rating:(NSString *)rating runningTime:(NSString *)runningTime seenBefore:(NSString *)seenBefore country:(NSString *)country language:(NSString *)language year:(NSString *)year decade:(NSString *)decade ratio:(NSString *)ratio length:(NSString *)length week:(NSString *)week day:(NSString *)day {
    return [NSString stringWithFormat:@"%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@", title ?: @"", rating ?: @"", runningTime ?: @"", seenBefore ?: @"", country ?: @"", language ?: @"", year ?: @"", decade ?: @"", ratio ?: @"", length ?: @"", week ?: @"", day ?: @""];
}

@end
