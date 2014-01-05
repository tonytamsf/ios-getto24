//
//  Card.h
//  Card
//
//  Created by Tony Tam on 12/20/13.
//
//

#import <Foundation/Foundation.h>

@interface Card : NSObject

// nonatomic: not thread safe
// strong: the memory will be freed when reference count == 0
// with weak the pointer will actually be nil when reference count == 0
@property (strong, nonatomic) NSString *contents;

@property (nonatomic, getter=isChosen) BOOL chosen;
@property (nonatomic, getter=isMatched) BOOL matched;

// 0 if the cards don't match
// 
- (int) match:(NSArray *) otherCards;

@end
