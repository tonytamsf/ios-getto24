//
//  Deck.m
//  Card
//
//  Created by Tony Tam on 1/2/14.
//
//

#import "Deck.h"
#import "Debug.h"

@interface Deck()
@property (strong, nonatomic) NSMutableArray *cards; // of card
@end

@implementation Deck

// getter
- (NSMutableArray *) cards
{
    if (!_cards) {
        _cards = [[NSMutableArray alloc]init];
    }
    DLog(@"Drawing cards");
    return _cards;
}

- (void) addCard:(Card *)card atTheTop:(BOOL) atTop {
    if (atTop) {
        [self.cards insertObject:card atIndex:0];
    } else {
        [self.cards addObject:card];
    }
}

- (void) addCard:(Card *)card {
    [self addCard:card atTheTop:NO];
}

- (Card *) drawRandomCard {
    Card *randomCard = nil;
    if ([self.cards count]) {
        unsigned index = arc4random() % [self.cards count];
        randomCard = self.cards[index];
        DLog(@"drawRandomCard %@", randomCard);
        [self.cards removeObjectAtIndex:index];
    }

    return randomCard;
}

@end
