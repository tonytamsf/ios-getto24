//
//  GetTo24ViewController.m
//  Get To 24
//
//  Created by Tony Tam on 1/4/14.
//  Copyright (c) 2014 Yama Llama. All rights reserved.
//
// TODO: local leader board
// TODO: fix the time transition
// TODO: the transition of the card label needs work
//

#import "GetTo24ViewController.h"
#import "PlayingCardDeck.h"
#import "Deck.h"
#import "Debug.h"
#import "NSArrayUtil.h"
#import "AudioUtil.h"

@interface GetTo24ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *flipsLabel;
@property (nonatomic) int flipCount;

- (void) startGame;

- (void) dealHand;

- (void) countdown;

- (void) putInDeck:(NSArray *) cards;

- (void) calculateHand:(NSArray *)cards;

- (NSDecimalNumber *) calcuateSimple:(NSArray *) cards usingOperators:(SEL *)selectors;
- (NSDecimalNumber *) calcuateGrouping:(NSArray *) cards usingOperators:(SEL *)selectors;

@property PlayingCardDeck *_cardDeck;

@property NSArray *cards;

@property NSArray *cardLabels;

@property NSTimer *timer;

@property int currentGameTime;

@property int player1ScorePoints;

@property int player2ScorePoints;

@property NSMutableArray *hand;

@property SEL plusSel, minusSel, mulSel, divSel;

@property SEL *selectors;
@property char *operatorChars;

- (void) rightAnswer;

@end

@implementation GetTo24ViewController


//
// Player got the right answer, reward with a point
// Maybe show them other potential answers
//
-(void) rightAnswer
{
    [AudioUtil playSound:@"chimes" :@"wav"];
}

//
// Player choose to skip the card
//
- (IBAction)skip:(id)sender {
    [self dealHand];
    [AudioUtil playSound:@"whoosh" :@"wav"];
}

//
// Kick off the game
//
- (void) startGame
{
    
    // The valid operators
    self.plusSel = @selector(decimalNumberByAdding:);
    self.minusSel = @selector(decimalNumberBySubtracting:);
    self.mulSel = @selector(decimalNumberByMultiplyingBy:);
    self.divSel = @selector(decimalNumberByDividingBy:);
    
    // We will need to loop through the operators/selectors
    self.selectors = malloc(sizeof(SEL) * 4);
    self.selectors[0] = self.plusSel;
    self.selectors[1] = self.minusSel;
    self.selectors[2] = self.mulSel;
    self.selectors[3] = self.divSel;

    self.operatorChars = malloc(sizeof(char) * 4);
    self.operatorChars[0] = '+';
    self.operatorChars[0] = '-';
    self.operatorChars[0] = '*';
    self.operatorChars[0] = '/';

    // Deal a new deck of cards
    if (! self._cardDeck) {
        self._cardDeck = [[PlayingCardDeck alloc] init];
    }
    
    
    self.hand = [[NSMutableArray alloc] init];
    self.gameCountdownProgress.progress = 0.0;
    
    [AudioUtil playSound:@"opening" :@"wav"];

    // Deal a fresh hand
    [self dealHand];
}

//
// The timer calls this to start a ticking sound, very annoying
//
- (void) countdown
{
    float percent = (60 - self.currentGameTime) / 60.0;

    DLog("Countdown %d %f", self.currentGameTime, percent);
    self.currentGameTime -= 1;
    if (self.currentGameTime <= 0) {
        [self timesUp];
        return;
    }

    [self.gameCountdownProgress
        setProgress:percent
            animated:YES];
}

//
// Put the 4 cards back into the deck
//
- (void) putInDeck:(NSArray *) cards
{
    for (Card *card in cards ) {
        [self._cardDeck addCard:card];
    }
}

//
// Deal 4 cards to start a game
//
- (void) dealHand
{

    // TODO what if we run out of cards, time to call a winner
    self.currentGameTime = 60;

    // clear the current hand about put back into the deck in random order?
    [self putInDeck:self.hand];
    
    // clear the hand
    [self.hand removeAllObjects];
    
    UIButton *card;
    
    // deal 4 cards
    for (int i = 0; i < [self.cards count]; i++) {
        PlayingCard *newCard = (PlayingCard *)[self._cardDeck drawRandomCard];

        [self.hand addObject:newCard];
        
        // For displaying the 2 lables for the card and color
        UILabel *left = [self.cardLabels objectAtIndex:2*i];
        UILabel *right = [self.cardLabels objectAtIndex:2*i+1];
        
        left.text =  [newCard contents];

        card = [self.cards objectAtIndex:i];
        left.TextColor = [newCard cardColor];
        right.text =  [newCard contents];
        right.TextColor = [newCard cardColor];
        
        [self showCard:card label:left label:right];
    }

    // We the answer before the user
    [self calcuateAnswer];
    
    [self.timer invalidate];
    // Start the countdown
     self.timer = [NSTimer scheduledTimerWithTimeInterval:1
                               target:self
                               selector:@selector(countdown)
                               userInfo:nil
                               repeats:YES];

    [self.gameCountdownProgress setProgress:0.00 animated:NO];
    [AudioUtil playSound:@"relaxing-short" :@"wav"];
}

//
// Animate the card flipping
// go from alpha == 0.0 (hidden) to transparency of 0.7
// The background is the image of the back of the card, once
// the animation is one, animate removing the background so it
// look like it's flipped
//
- (void) showCard:(UIButton *) card label:(UILabel *)left label:(UILabel *)right
{
    card.alpha = 0.0;
    left.alpha = 0.0;
    right.alpha = 0.0;
    [card setBackgroundImage:[UIImage imageNamed:@"red.card.background.png"] forState:UIControlStateNormal];


    [UIView beginAnimations:@"ShowHideView" context:(void*)card];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    [UIView setAnimationDuration:0.4];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(showHideDidStop:finished:context:)];
    
    // Make the animatable changes.
    card.alpha = 0.7;
    left.alpha = 0.7;
    right.alpha = 0.7;
    //[card setBackgroundImage:nil forState:UIControlStateNormal];

    // Commit the changes and perform the animation.
    [UIView commitAnimations];
}

// Called at the end of the preceding animation.
// remove the background
//
- (void)showHideDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    [UIView beginAnimations:@"ShowHideView2" context:context];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [UIView setAnimationDuration:1.0];
    [UIView setAnimationDelay:0.0];
    
    UIButton *card = (__bridge UIButton *)context;
    
    // Make the animatable changes.
    card.alpha = 0.7;

    [card setBackgroundImage:nil forState:UIControlStateNormal];
    
    DLog(@"showHideDidStop");
    [UIView commitAnimations];
}

//
// Dock points from both players
// the player has to find the answer, skip or say there is no answer
//
- (void)timesUp {
    [self.gameCountdownProgress setProgress:0.00 animated:NO];
    //[AudioUtil playSound:@"whoosh" :@"wav"];
    // Stop the previous timer
    [self.timer invalidate];
    
    [AudioUtil playSound:@"ray" :@"wav"];
    
    [self dealHand];
}

//
// Give up without saying anything, any dock points from both players
//
- (IBAction)giveUp:(id)sender {
    [self.gameCountdownProgress setProgress:0.00 animated:NO];

    [self dealHand];
    [AudioUtil playSound:@"whoosh" :@"wav"];
}

//
// Say therei no solution, plus points if computer agrees otherwise it's consider
// the same as wrong answer
//
- (IBAction)noSolution:(id)sender {
    [self.gameCountdownProgress setProgress:0.00 animated:NO];
    
    [self dealHand];
    [AudioUtil playSound:@"beep" :@"wav"];
}

//
// Player1 thinks he has it, need to validate the answer
// TODO
//
- (IBAction)player1Pressed:(id)sender {
    self.player1ScorePoints += 1;
    self.player1Score.text = [NSString stringWithFormat:@"%d",
                                                        self.player1ScorePoints];
    [self dealHand];
    [self rightAnswer];

}

//
// Player2 thinks he has it, need to validate the answer
// TODO
//
- (IBAction)player2Pressed:(id)sender {
    self.player2ScorePoints += 1;
    self.player2Score.text = [NSString stringWithFormat:@"%d",
                              self.player2ScorePoints];
    [self dealHand];
    [self rightAnswer];


}

//
// Hide the answers, show it when we are ready
//
- (void) hideAnswer
{
    self.operatorNESE.alpha = 0.0;
    self.operatorNWNE.alpha = 0.0;
    self.operatorNWSW.alpha = 0.0;
    self.operatorSWSE.alpha = 0.0;

}

//
// Beginning
// Rotate the buttons
//
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // rotate the buttons, labels
    [self.operatorNESE setTransform:CGAffineTransformMakeRotation(-M_PI / 2)];
    [self.operatorNWSW setTransform:CGAffineTransformMakeRotation(-M_PI / 2)];

    [self.buttonGiveUp setTransform:CGAffineTransformMakeRotation(-M_PI / 2)];
    [self.player1Button setTransform:CGAffineTransformMakeRotation(-M_PI)];
    [self.player1Score setTransform:CGAffineTransformMakeRotation(-M_PI)];
    [self.player1NameLabel setTransform:CGAffineTransformMakeRotation(-M_PI)];

    [self.labelNEright setTransform:CGAffineTransformMakeRotation(-M_PI)];
    [self.labelNWright setTransform:CGAffineTransformMakeRotation(-M_PI)];
    [self.labelSWright setTransform:CGAffineTransformMakeRotation(-M_PI)];
    [self.labelSEright setTransform:CGAffineTransformMakeRotation(-M_PI)];

    // 2 player game allow 2 players to press buttons at the same time
    [self.view setMultipleTouchEnabled:YES];
    
    // The list of cards and the labels on them
    self.cards = [NSArray arrayWithObjects:
                  self.cardNW,
                  self.cardSW,
                  self.cardSE,
                  self.cardNE, nil];
    
    // setup the list to labels
    self.cardLabels = [NSArray arrayWithObjects:
                       self.labelNWleft,
                       self.labelNWright,
                       self.labelSWleft,
                       self.labelSWright,
                       self.labelSEleft,
                       self.labelSEright,
                       self.labelNEleft,
                       self.labelNEright,
                       nil
                       ];
    
    // Don't show them the answers
    [self hideAnswer];
    
    // Get started
    [self startGame];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//
// Take current hand generate all permutations of the 4 cards
// 4 * 3 * 2 hands
// Apply all the possible combinations of operators
// 4 * 4 * 4 * 4 with the different possible parentisis
//
- (void) calcuateAnswer
{
    // This should give us 4 * 3 * 2 hands
    NSArray *allHands = [(NSArray *)self.hand allPermutations];
    
    DLog(@"TOTAL %d", [allHands count]);
    for (int i = 0; i < [allHands count] - 1; ++i) {
        NSArray *tryHand = allHands[i];

        DLog(@"==================================================");
        DLog(@" %d %@", i, tryHand);
        DLog(@"==================================================");
        @try {
            [self calculateHand:tryHand];
        }
        @catch (NSException *e) {
            // Just catch division by zero, ignore
            DLog("%@", e);
        }
    }
}

//
// Apply all the possible operators on the 4 cards, keeping them in the same order
//
// Solve for these combination
// ((a op b) op c) op d
// (a op b) op (c op d)
// a op (b op c) op d
// (a op b) op c op d
//
- (void) calculateHand:(NSArray *)cards
{
    Boolean found = FALSE;
    NSDecimalNumber *answer = [[NSDecimalNumber alloc] init];
    NSDecimalNumber *rightAnswer = (NSDecimalNumber *)[NSDecimalNumber numberWithInt:24];
    

    for (int j = 0; j <= 3 ; ++j) {
        for (int k = 0; k <=  3 ; ++k) {
            for (int l = 0; l <= 3 ; ++l) {
                SEL currentOperators[] = {
                    self.selectors[j],
                    self.selectors[k],
                    self.selectors[l]

                };
                
                char currentOperatorChars = {
                    self.operatorChars[j],
                    self.operatorChars[k],
                    self.operatorChars[l],
                };
                if (found) {
                    break;
                }
                answer = [self calcuateSimple:cards usingOperators:currentOperators];
                if ([answer compare:rightAnswer] == NSOrderedSame) {
                    NSLog(@"--- found 24 %d %s %d %s %d %s %d",
                          MIN(((PlayingCard *)cards[0]).rank, 10), currentOperators[0],
                          MIN(((PlayingCard *)cards[1]).rank, 10),
                          currentOperators[1],
                          MIN(((PlayingCard *)cards[2]).rank, 10),
                          currentOperators[2],
                          MIN(((PlayingCard *)cards[3]).rank, 10));
                    found = TRUE;
                    break;
                }
                answer = [self calcuateGrouping:cards usingOperators:currentOperators];
                if ([answer compare:rightAnswer] == NSOrderedSame) {
                    NSLog(@"--- found 24 (%d %s %d) %s (%d %s %d)",
                          MIN(((PlayingCard *)cards[0]).rank, 10), currentOperators[0],
                          MIN(((PlayingCard *)cards[1]).rank, 10),
                          currentOperators[1],
                          MIN(((PlayingCard *)cards[2]).rank, 10),
                          currentOperators[2],
                          MIN(((PlayingCard *)cards[3]).rank, 10));
                    found = TRUE;
                    break;
                }
                answer = [self calcuateGroupingOfTwo:cards usingOperators:currentOperators];
                if ([answer compare:rightAnswer] == NSOrderedSame) {
                    NSLog(@"--- found 24 (%d %s %d) %s %d %s %d",
                          MIN(((PlayingCard *)cards[0]).rank, 10), currentOperators[0],
                          MIN(((PlayingCard *)cards[1]).rank, 10),
                          currentOperators[1],
                          MIN(((PlayingCard *)cards[2]).rank, 10),
                          currentOperators[2],
                          MIN(((PlayingCard *)cards[3]).rank, 10));
                    found = TRUE;
                    break;
                }
                answer = [self calcuateGroupingSecond:cards usingOperators:currentOperators];
                if ([answer compare:rightAnswer] == NSOrderedSame) {
                    NSLog(@"--- found 24 %d %s (%d %s %d) %s %d)",
                          MIN(((PlayingCard *)cards[0]).rank, 10), currentOperators[0],
                          MIN(((PlayingCard *)cards[1]).rank, 10),
                          currentOperators[1],
                          MIN(((PlayingCard *)cards[2]).rank, 10),
                          currentOperators[2],
                          MIN(((PlayingCard *)cards[3]).rank, 10));
                    found = TRUE;
                    break;
                }
                    /*
                     DLog(@"--- try %d %s %d %s %d %s %d",
                     MIN(card0.rank, 10), selector0,
                     MIN(card1.rank, 10),
                     selector1,
                     MIN(card2.rank, 10),
                     selector2,
                     MIN(card3.rank, 10));
                     */
            }
            if (found) { break; };
            }
        if (found) { break; };
    }
}

// ((a op b) op c) op d
- (NSDecimalNumber *) calcuateSimple:(NSArray *) cards usingOperators:(SEL [])selectors
{
    NSDecimalNumber *subtotal = [[NSDecimalNumber alloc] init];
    SEL selector0 = selectors[0];
    SEL selector1 = selectors[1];
    SEL selector2 = selectors[2];

    PlayingCard *card0 = (PlayingCard *)cards[0];
    PlayingCard *card1 = (PlayingCard *)cards[1];
    PlayingCard *card2 = (PlayingCard *)cards[2];
    PlayingCard *card3 = (PlayingCard *)cards[3];
    
    subtotal = [[NSDecimalNumber numberWithInt:MIN(card0.rank, 10)]
                performSelector:selector0
                withObject:[NSDecimalNumber numberWithInt:MIN(card1.rank, 10)]];
    
    
    subtotal = [subtotal
                performSelector:selector1
                withObject:[NSDecimalNumber numberWithInt:MIN(card2.rank, 10)]];
    
    subtotal = [subtotal
                performSelector:selector2
                withObject:[NSDecimalNumber numberWithInt:MIN(card3.rank, 10)]];
    

    return subtotal;
}

// (a op b) op (c op d)
- (NSDecimalNumber *) calcuateGrouping:(NSArray *) cards usingOperators:(SEL [])selectors
{
    NSDecimalNumber *subtotal = [[NSDecimalNumber alloc] init];
    NSDecimalNumber *subtotal1 = [[NSDecimalNumber alloc] init];

    SEL selector0 = selectors[0];
    SEL selector1 = selectors[1];
    SEL selector2 = selectors[2];
    
    PlayingCard *card0 = (PlayingCard *)cards[0];
    PlayingCard *card1 = (PlayingCard *)cards[1];
    PlayingCard *card2 = (PlayingCard *)cards[2];
    PlayingCard *card3 = (PlayingCard *)cards[3];
    
    subtotal = [[NSDecimalNumber numberWithInt:MIN(card0.rank, 10)]
                performSelector:selector0
                withObject:[NSDecimalNumber numberWithInt:MIN(card1.rank, 10)]];
    
    
    subtotal1 = [[NSDecimalNumber numberWithInt:MIN(card2.rank, 10)]
                performSelector:selector2
                withObject:[NSDecimalNumber numberWithInt:MIN(card3.rank, 10)]];
    
    
    subtotal = [subtotal
                performSelector:selector1
                withObject:subtotal1];
    
    
    return subtotal;
}


// (a op b) op c op d
- (NSDecimalNumber *) calcuateGroupingOfTwo:(NSArray *) cards usingOperators:(SEL [])selectors
{
    NSDecimalNumber *subtotal = [[NSDecimalNumber alloc] init];
    NSDecimalNumber *subtotal1 = [[NSDecimalNumber alloc] init];
    
    SEL selector0 = selectors[0];
    SEL selector1 = selectors[1];
    SEL selector2 = selectors[2];
    
    PlayingCard *card0 = (PlayingCard *)cards[0];
    PlayingCard *card1 = (PlayingCard *)cards[1];
    PlayingCard *card2 = (PlayingCard *)cards[2];
    PlayingCard *card3 = (PlayingCard *)cards[3];
    
    subtotal = [[NSDecimalNumber numberWithInt:MIN(card0.rank, 10)]
                performSelector:selector0
                withObject:[NSDecimalNumber numberWithInt:MIN(card1.rank, 10)]];
    
    
    subtotal = [subtotal
                performSelector:selector1
                withObject:[NSDecimalNumber numberWithInt:MIN(card2.rank, 10)]];

    
    subtotal = [subtotal
                performSelector:selector2
                withObject:[NSDecimalNumber numberWithInt:MIN(card3.rank, 10)]];
    
    
    return subtotal;
}

// a op (b op c) op d
- (NSDecimalNumber *) calcuateGroupingSecond:(NSArray *) cards usingOperators:(SEL [])selectors
{
    NSDecimalNumber *subtotal = [[NSDecimalNumber alloc] init];
    NSDecimalNumber *subtotal1 = [[NSDecimalNumber alloc] init];
    
    SEL selector0 = selectors[0];
    SEL selector1 = selectors[1];
    SEL selector2 = selectors[2];
    
    PlayingCard *card0 = (PlayingCard *)cards[0];
    PlayingCard *card1 = (PlayingCard *)cards[1];
    PlayingCard *card2 = (PlayingCard *)cards[2];
    PlayingCard *card3 = (PlayingCard *)cards[3];
    
    subtotal = [[NSDecimalNumber numberWithInt:MIN(card1.rank, 10)]
                performSelector:selector1
                withObject:[NSDecimalNumber numberWithInt:MIN(card2.rank, 10)]];
    
    
    subtotal = [[NSDecimalNumber numberWithInt:MIN(card0.rank, 10)]
                performSelector:selector0
                withObject:subtotal];
    
    
    subtotal = [subtotal
                performSelector:selector2
                withObject:[NSDecimalNumber numberWithInt:MIN(card3.rank, 10)]];
    
    
    return subtotal;
}

- (void) setFlipCount:(int)flipCount
{
    _flipCount = flipCount;
    [self.flipsLabel setText:[NSString stringWithFormat:@"Flips %d", self.flipCount]];
    
}


- (IBAction)touchCardButton:(UIButton *)sender
{
    if ([sender.currentTitle length]) {
        UIImage *cardImage = [UIImage imageNamed:@"cardback"];
        [sender setBackgroundImage:cardImage
                          forState:UIControlStateNormal ];
        [sender setTitle:@""
                forState:UIControlStateNormal];
    } else {
        UIImage *cardImage = [UIImage imageNamed:@"cardfront"];
        [sender setBackgroundImage:cardImage
                          forState:UIControlStateNormal ];
        [sender setTitle:@"A ♣︎"
                forState:UIControlStateNormal];
    }
    self.flipCount++;
}
@end
