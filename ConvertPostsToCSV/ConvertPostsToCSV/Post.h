//
//  Post.h
//  ConvertPostsToCSV
//
//  Created by Arik Devens on 2/1/18.
//  Copyright © 2018 Foreign & Domestic. All rights reserved.
//

@import Foundation;

@interface Post : NSObject

@property (nonatomic) BOOL published;
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *date;
@property (nonatomic) NSString *rating;
@property (nonatomic) NSString *runningTime;
@property (nonatomic) NSString *seenBefore;
@property (nonatomic) NSMutableArray *countries;
@property (nonatomic) NSMutableArray *languages;
@property (nonatomic) NSMutableArray *years;
@property (nonatomic) NSMutableArray *decades;
@property (nonatomic) NSMutableArray *ratios;
@property (nonatomic) NSString *length;
@property (nonatomic) NSString *week;
@property (nonatomic) NSString *day;

@property (nonatomic) NSArray *content;

- (NSArray *)csv;

@end
