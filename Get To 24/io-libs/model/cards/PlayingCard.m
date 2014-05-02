//
//  PlayingCard.m
//  Card
//
//  Created by Tony Tam on 1/2/14.
//  Copyright (c) 2014 com.wordpress.tonytam. All rights reserved.
//

#import "PlayingCard.h"
#import "Debug.h"

@implementation PlayingCard

@synthesize suit = _suit; // because we provide settings and getters
@synthesize contents = _contents;

- (NSString *) contents
{
    NSArray *rankStrings = [PlayingCard rankStrings];
    
    DLog(@"getting contents %@ %@", rankStrings[self.rank], self.suit);
    return [rankStrings[self.rank] stringByAppendingString:self.suit];

                              
}

+ (NSArray *) validSuits
{
    // TODO
    return @[@"♠︎",
             @"♣︎",
             @"♥︎",
             @"♦︎"];
}

+ (NSUInteger) maxRank {
    return [[self rankStrings] count] - 1;
}

- (void) setRank:(NSUInteger) rank
{
    if (rank <= [PlayingCard maxRank]) {
        _rank = rank;
    }
}

+ (NSArray *) rankStrings
{
    return @[@"?",
             @"A",
             @"2",
             @"3",
             @"4",
             @"5",
             @"6",
             @"7",
             @"8",
             @"9",
             @"10",
             @"J",
             @"Q",
             @"K"];
}
- (void) setSuit:(NSString *) suit
{
    if([[PlayingCard validSuits] containsObject:suit]) {
        _suit = suit;
    }
}

- (NSString *) description
{
    return [self contents];
}

- (NSString *) suit
{
    return _suit ? _suit : @"?";
}

- (UIColor *) cardColor
{
    if ([self.suit isEqualToString:@"♠︎"] ||
        [self.suit isEqualToString:@"♣︎"]
        ) {
        return [UIColor blackColor];
    }
    return [UIColor redColor];
}

@end
