//
//  main.m
//  ConvertPostsToCSV
//
//  Created by Arik Devens on 1/31/18.
//  Copyright © 2018 Foreign & Domestic. All rights reserved.
//

@import Foundation;
#include "Generator.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        [[Generator new] outputCSV];
    }
    return 0;
}
