//
//  Deck.h
//  Card
//
//  Created by Tony Tam on 1/2/14.
//
//

#import <Foundation/Foundation.h>
#import "Card.h"

@interface Deck : NSObject

- (void) addCard:(Card *)card atTheTop:(BOOL) atTop;

- (void) addCard:(Card *) card;

- (Card *) drawRandomCard;

@end
