//
//  Card.m
//  Card
//
//  Created by Tony Tam on 12/20/13.
//
//

#import "Card.h"

@interface Card()

@end

@implementation Card

- (int) match:(NSArray *) otherCards
{
    int score = 0;
    
    for (Card *card in otherCards) {
        
        if ([card.contents isEqualToString:self.contents]) {
            score = 1;
        }
    }
    
    return score;
}
/*
@property from *.h created this
@synthesize contents = _contents;

- (NSString *) contennts
{
    return _contents;
}

- (void) setContents:(NSString *) contents
{
    _contents = contents;
}
*/
@end
