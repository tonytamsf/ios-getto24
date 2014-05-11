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
#import "MRCircularProgressView.h"

#import "PlayingCardDeck.h"
#import "Deck.h"
#import "Debug.h"
#import "NSArrayUtil.h"
#import "AudioUtil.h"

@interface AnswerPackage : NSObject
@property NSString *stringAnswer;
@property NSString *stringFormat;
@property NSArray *operators;
@property NSArray *cards;
@property NSDecimalNumber *answer;
@end

@implementation AnswerPackage
@end

@interface CardHand : NSObject
@property PlayingCard *card;
@property UILabel *operatorLabel;
@end
    
@implementation CardHand
@end

@interface GetTo24ViewController ()


@property (weak, nonatomic) IBOutlet UILabel *flipsLabel;
@property (nonatomic) int flipCount;

- (void) startGame;

- (void) dealHand;

- (void) countdown;

- (void) putInDeck:(NSArray *) cards;

- (AnswerPackage *) calculateHand:(NSArray *)cards;

- (AnswerPackage *) calcuateSimple:(NSArray *)cards  usingOperators:(SEL *)selectors withOperatorChars:(NSArray *)currentOperatorChars;
- (AnswerPackage *) calcuateGrouping:(NSArray *)cards  usingOperators:(SEL *)selectors withOperatorChars:(NSArray *)currentOperatorChars;
- (AnswerPackage *) calcuateGroupingOfTwo:(NSArray *)cards usingOperators:(SEL *)selectors withOperatorChars:(NSArray *)currentOperatorChars;
- (AnswerPackage *) calcuateGroupingSecond:(NSArray *)cards usingOperators:(SEL *)selectors withOperatorChars:(NSArray *)currentOperatorChars;

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

@property NSArray *operatorChars;
@property NSArray *operatorLabels;
@property AnswerPackage *storeAnswerPackage;

- (void) rightAnswer;

@end

@implementation GetTo24ViewController

// pop up the text field
- (void) verifyAnswer
{
    for (int i = 0; i < 4; i++ ){
        [((UIButton *)self.cards[i]) setUserInteractionEnabled:TRUE];
        ((UIButton *)self.operatorLabels[i]).hidden = FALSE;
    }
    
    self.labelAnswer.hidden = FALSE;
    self.labelOperatorBackground.hidden = FALSE;
    self.gameCountdownProgress.hidden = TRUE;
    
    self.labelAnswer.text = @"(select cards)";

    [self.timer invalidate];

}
//
// Player got the right answer, reward with a point
// Maybe show them other potential answers
//
-(void) rightAnswer
{
    [self.timer invalidate];

    self.labelAnswer.hidden = FALSE;
    if (self.storeAnswerPackage.stringAnswer == nil) {
        self.labelAnswer.text = @"No answer";
    } else {
        self.labelAnswer.text = self.storeAnswerPackage.stringAnswer;
    }
    
    // Disable the other button
    self.player1Button.enabled = FALSE;
    self.player2Button.enabled = FALSE;
    self.skipButton.enabled = FALSE;
    self.buttonGiveUp.enabled = FALSE;
    
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

    self.operatorChars = [NSArray arrayWithObjects:
                          @"+",
                          @"-",
                          @"*",
                          @"/",
                          nil];

    self.operatorLabels = [NSArray arrayWithObjects:
                           self.buttonPlus,
                           self.buttonMinus,
                           self.buttonMultiplication,
                           self.buttonDivision,
                           nil
                           ];

    // Deal a new deck of cards
    if (! self._cardDeck) {
        self._cardDeck = [[PlayingCardDeck alloc] init];
    }
    
    
    self.hand = [[NSMutableArray alloc] init];
    [self.gameCountdownProgress setProgress:0.0 duration:1.0];
    self.gameCountdownProgress.progressArcWidth = 3.0f;
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

    if (self.currentGameTime < 40) {
        self.gameCountdownProgress.progressColor = [UIColor yellowColor];
    }
    if (self.currentGameTime < 20) {
        self.gameCountdownProgress.progressColor = [UIColor redColor];
    }
    if (self.currentGameTime < 5) {
        self.gameCountdownProgress.progressColor = [UIColor purpleColor];
    }

    [self.gameCountdownProgress setProgress:percent duration:1.0];

}

//
// Put the 4 cards back into the deck
//
- (void) putInDeck:(NSArray *) cards
{
    for (CardHand *card in cards ) {
        [self._cardDeck addCard:card.card];
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
        CardHand *singleDeal = [[CardHand alloc] init];
        
        [self.cards[i] setTag:MIN(10, newCard.rank)];
        
        singleDeal.card = newCard;
        singleDeal.operatorLabel = self.operatorLabels[i];

        [self.hand addObject:singleDeal];
        
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

    [self.gameCountdownProgress setProgress:0.0 duration:1.0];
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
    [self rightAnswer];

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
    [self verifyAnswer];
}

//
// Player2 thinks he has it, need to validate the answer
// TODO
//
- (IBAction)player2Pressed:(id)sender {
    self.player2ScorePoints += 1;
    self.player2Score.text = [NSString stringWithFormat:@"%d",
                              self.player2ScorePoints];
    [self verifyAnswer];


}

//
// Hide the answers, show it when we are ready
//
- (void) hideAnswer
{
    self.buttonMinus.hidden = TRUE;
    self.buttonPlus.hidden = TRUE;
    self.buttonMultiplication.hidden = TRUE;
    self.buttonDivision.hidden = TRUE;
    
    self.labelAnswer.hidden = TRUE;
    self.labelOperatorBackground.hidden = TRUE;
    self.gameCountdownProgress.hidden = FALSE;

}

//
// Beginning
// Rotate the buttons
//
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // rotate the buttons, labels
    [self.buttonGiveUp setTransform:CGAffineTransformMakeRotation(-M_PI / 2)];
    [self.skipButton setTransform:CGAffineTransformMakeRotation(-M_PI / 2)];

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
                  self.cardNE,
                  nil];
    
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
    //
    [self.buttonPlus setTag:10];
    [self.buttonMinus setTag:11];
    [self.buttonMultiplication setTag:12];
    [self.buttonDivision setTag:13];

    // Don't show them the answers
    [self hideAnswer];	
    [self.labelAnswer setTag:100];
    [self.labelOperatorBackground setTag:101];

    self.skipButton.contentEdgeInsets = UIEdgeInsetsZero;
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
- (AnswerPackage *) calcuateAnswer
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
            self.storeAnswerPackage = [self calculateHand:tryHand];
            if (nil != self.storeAnswerPackage) {
                return self.storeAnswerPackage;
            }
        }
        @catch (NSException *e) {
            // Just catch division by zero, ignore
            //NSLog(@"%@", e);
        }
    }
    return nil;
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
- (AnswerPackage *) calculateHand:(NSArray *)cards
{
    Boolean found = FALSE;
    NSDecimalNumber *rightAnswer = (NSDecimalNumber *)[NSDecimalNumber numberWithInt:24];
    AnswerPackage *storeAnswerPackage;

    for (int j = 0; j <= 3 ; ++j) {
        for (int k = 0; k <=  3 ; ++k) {
            for (int l = 0; l <= 3 ; ++l) {
                // TODO: Seems hard to get a NSArray of SEL
                SEL currentOperators[] = {
                    self.selectors[j],
                    self.selectors[k],
                    self.selectors[l]

                };
                
                NSArray *currentOperatorChars = [NSArray arrayWithObjects:
                                                 [self.operatorChars objectAtIndex:j],
                                                 [self.operatorChars objectAtIndex:k],
                                                 [self.operatorChars objectAtIndex:l],
                                                 nil];
                if (found) {
                    break;
                }

                storeAnswerPackage = [self calcuateSimple:cards usingOperators:currentOperators
                                                                withOperatorChars:currentOperatorChars];
                if ([storeAnswerPackage.answer compare:rightAnswer] == NSOrderedSame) {
                    NSLog(@"answer %@", storeAnswerPackage.stringAnswer);

                    found = TRUE;
                    break;
                }
                storeAnswerPackage = [self calcuateGrouping:cards usingOperators:currentOperators
                                                                  withOperatorChars:currentOperatorChars];
                if ([storeAnswerPackage.answer compare:rightAnswer] == NSOrderedSame) {
                    NSLog(@"answer %@", storeAnswerPackage.stringAnswer);

                    found = TRUE;
                    break;
                }
                storeAnswerPackage = [self calcuateGroupingOfTwo:cards usingOperators:currentOperators
                                                                       withOperatorChars:currentOperatorChars];
                if ([storeAnswerPackage.answer compare:rightAnswer] == NSOrderedSame) {
                    NSLog(@"answer %@", storeAnswerPackage.stringAnswer);

                    found = TRUE;
                    break;
                }
                storeAnswerPackage = [self calcuateGroupingSecond:cards usingOperators:currentOperators
                                                                        withOperatorChars:currentOperatorChars];
                if ([storeAnswerPackage.answer compare:rightAnswer] == NSOrderedSame) {
                    NSLog(@"answer %@", storeAnswerPackage.stringAnswer);

                    found = TRUE;
                    break;
                }
                DLog(@"--- try %d %s %d %s %d %s %d",
                     MIN(card0.rank, 10),
                     selector0,
                     MIN(card1.rank, 10),
                     selector1,
                     MIN(card2.rank, 10),
                     selector2,
                     MIN(card3.rank, 10));
            }
            if (found) { break; };
            }
        if (found) { break; };
    }
    if (found) {
        return storeAnswerPackage;
    } else {
        return nil;
    }
}

// ((a op b) op c) op d
- (AnswerPackage *) calcuateSimple:(NSArray *) cards usingOperators:(SEL [])selectors withOperatorChars:(NSArray *)currentOperatorChars
{
    NSDecimalNumber *subtotal = [[NSDecimalNumber alloc] init];
    AnswerPackage *answer = [[AnswerPackage alloc] init];

    SEL selector0 = selectors[0];
    SEL selector1 = selectors[1];
    SEL selector2 = selectors[2];

    PlayingCard *card0 = (PlayingCard *)((CardHand *)cards[0]).card;
    PlayingCard *card1 = (PlayingCard *)((CardHand *)cards[1]).card;
    PlayingCard *card2 = (PlayingCard *)((CardHand *)cards[2]).card;
    PlayingCard *card3 = (PlayingCard *)((CardHand *)cards[3]).card;
    
    subtotal = [[NSDecimalNumber numberWithInt:MIN(card0.rank, 10)]
                performSelector:selector0
                withObject:[NSDecimalNumber numberWithInt:MIN(card1.rank, 10)]];
    
    
    subtotal = [subtotal
                performSelector:selector1
                withObject:[NSDecimalNumber numberWithInt:MIN(card2.rank, 10)]];
    
    subtotal = [subtotal
                performSelector:selector2
                withObject:[NSDecimalNumber numberWithInt:MIN(card3.rank, 10)]];
    answer.answer = subtotal;
    answer.stringFormat = @"((%d %@ %d) %@ %d) %@ %d";
    answer.stringAnswer = [NSString stringWithFormat:answer.stringFormat,
                           MIN(card0.rank, 10),
                           [currentOperatorChars objectAtIndex:0],
                           MIN(card1.rank, 10),
                           [currentOperatorChars objectAtIndex:1],
                           MIN(card2.rank, 10),
                           [currentOperatorChars objectAtIndex:2],
                           MIN(card3.rank, 10)
                           ];
    answer.operators = [NSArray arrayWithArray:currentOperatorChars];
    answer.cards = [NSArray arrayWithArray:cards];

    return answer;
}

// (a op b) op (c op d)
- (AnswerPackage *) calcuateGrouping:(NSArray *) cards usingOperators:(SEL [])selectors withOperatorChars:(NSArray *)currentOperatorChars
{
    NSDecimalNumber *subtotal = [[NSDecimalNumber alloc] init];
    NSDecimalNumber *subtotal1 = [[NSDecimalNumber alloc] init];
    AnswerPackage *answer = [[AnswerPackage alloc] init];

    SEL selector0 = selectors[0];
    SEL selector1 = selectors[1];
    SEL selector2 = selectors[2];
    
    PlayingCard *card0 = (PlayingCard *)((CardHand *)cards[0]).card;
    PlayingCard *card1 = (PlayingCard *)((CardHand *)cards[1]).card;
    PlayingCard *card2 = (PlayingCard *)((CardHand *)cards[2]).card;
    PlayingCard *card3 = (PlayingCard *)((CardHand *)cards[3]).card;
    
    subtotal = [[NSDecimalNumber numberWithInt:MIN(card0.rank, 10)]
                performSelector:selector0
                withObject:[NSDecimalNumber numberWithInt:MIN(card1.rank, 10)]];
    
    
    subtotal1 = [[NSDecimalNumber numberWithInt:MIN(card2.rank, 10)]
                performSelector:selector2
                withObject:[NSDecimalNumber numberWithInt:MIN(card3.rank, 10)]];
    
    
    subtotal = [subtotal
                performSelector:selector1
                withObject:subtotal1];

    answer.answer = subtotal;
    answer.stringFormat = @"(%d %@ %d) %@ (%d %@ %d)";
    answer.stringAnswer = [NSString stringWithFormat:answer.stringFormat,
                           MIN(card0.rank, 10),
                           [currentOperatorChars objectAtIndex:0],
                           MIN(card1.rank, 10),
                           [currentOperatorChars objectAtIndex:1],
                           MIN(card2.rank, 10),
                           [currentOperatorChars objectAtIndex:2],
                           MIN(card3.rank, 10)
                           ];
    
    answer.operators = [NSArray arrayWithArray:currentOperatorChars];
    answer.cards = [NSArray arrayWithArray:cards];

    return answer;
}


// (a op b) op c op d
- (AnswerPackage *)calcuateGroupingOfTwo:(NSArray *) cards usingOperators:(SEL [])selectors withOperatorChars:(NSArray *)currentOperatorChars
{
    NSDecimalNumber *subtotal = [[NSDecimalNumber alloc] init];
    AnswerPackage *answer = [[AnswerPackage alloc] init];

    SEL selector0 = selectors[0];
    SEL selector1 = selectors[1];
    SEL selector2 = selectors[2];
    
    PlayingCard *card0 = (PlayingCard *)((CardHand *)cards[0]).card;
    PlayingCard *card1 = (PlayingCard *)((CardHand *)cards[1]).card;
    PlayingCard *card2 = (PlayingCard *)((CardHand *)cards[2]).card;
    PlayingCard *card3 = (PlayingCard *)((CardHand *)cards[3]).card;
    
    subtotal = [[NSDecimalNumber numberWithInt:MIN(card0.rank, 10)]
                performSelector:selector0
                withObject:[NSDecimalNumber numberWithInt:MIN(card1.rank, 10)]];
    
    
    subtotal = [subtotal
                performSelector:selector1
                withObject:[NSDecimalNumber numberWithInt:MIN(card2.rank, 10)]];

    
    subtotal = [subtotal
                performSelector:selector2
                withObject:[NSDecimalNumber numberWithInt:MIN(card3.rank, 10)]];
    
    answer.answer = subtotal;
    answer.stringFormat = @"(%d %@ %d) %@ %d %@ %d";
    answer.stringAnswer = [NSString stringWithFormat:answer.stringFormat,
                           MIN(card0.rank, 10),
                           [currentOperatorChars objectAtIndex:0],
                           MIN(card1.rank, 10),
                           [currentOperatorChars objectAtIndex:1],
                           MIN(card2.rank, 10),
                           [currentOperatorChars objectAtIndex:2],
                           MIN(card3.rank, 10)
                           ];
    
    answer.operators = [NSArray arrayWithArray:currentOperatorChars];
    answer.cards = [NSArray arrayWithArray:cards];
    
    return answer;
}

// a op (b op c) op d
- (AnswerPackage *) calcuateGroupingSecond:(NSArray *) cards usingOperators:(SEL [])selectors withOperatorChars:(NSArray *)currentOperatorChars
{
    NSDecimalNumber *subtotal = [[NSDecimalNumber alloc] init];
    AnswerPackage *answer = [[AnswerPackage alloc] init];
    
    SEL selector0 = selectors[0];
    SEL selector1 = selectors[1];
    SEL selector2 = selectors[2];
    
    PlayingCard *card0 = (PlayingCard *)((CardHand *)cards[0]).card;
    PlayingCard *card1 = (PlayingCard *)((CardHand *)cards[1]).card;
    PlayingCard *card2 = (PlayingCard *)((CardHand *)cards[2]).card;
    PlayingCard *card3 = (PlayingCard *)((CardHand *)cards[3]).card;
    
    subtotal = [[NSDecimalNumber numberWithInt:MIN(card1.rank, 10)]
                performSelector:selector1
                withObject:[NSDecimalNumber numberWithInt:MIN(card2.rank, 10)]];
    
    
    subtotal = [[NSDecimalNumber numberWithInt:MIN(card0.rank, 10)]
                performSelector:selector0
                withObject:subtotal];
    
    
    subtotal = [subtotal
                performSelector:selector2
                withObject:[NSDecimalNumber numberWithInt:MIN(card3.rank, 10)]];
    answer.answer = subtotal;
    answer.stringFormat = @"%d %@ (%d %@ %d) %@ %d";
    answer.stringAnswer = [NSString stringWithFormat:answer.stringFormat,
                           MIN(card0.rank, 10),
                           [currentOperatorChars objectAtIndex:0],
                           MIN(card1.rank, 10),
                           [currentOperatorChars objectAtIndex:1],
                           MIN(card2.rank, 10),
                           [currentOperatorChars objectAtIndex:2],
                           MIN(card3.rank, 10)
                           ];
    
    answer.operators = [NSArray arrayWithArray:currentOperatorChars];
    answer.cards = [NSArray arrayWithArray:cards];
    
    return answer;
}

- (void) setFlipCount:(int)flipCount
{
    _flipCount = flipCount;
    [self.flipsLabel setText:[NSString stringWithFormat:@"Flips %d", self.flipCount]];
    
}


- (IBAction)buttonAnswerDismiss:(id)sender {
    
    ((UIButton *)sender).hidden = TRUE;
    self.labelOperatorBackground.hidden = TRUE;

    self.player1Button.enabled = TRUE;
    self.player2Button.enabled = TRUE;
    self.skipButton.enabled = TRUE;
    self.buttonGiveUp.enabled = TRUE;
    
    // Hide
    for (int i = 0; i < 4; i++ ){
        [((UIButton *)self.cards[i]) setUserInteractionEnabled:FALSE];
        [((UIButton *)self.cards[i]) setTitle:@""
                forState:UIControlStateNormal];
        ((UIButton *)self.operatorLabels[i]).hidden = TRUE;

    }

    [self dealHand];
}

//
// Handle UILabel touch events
// http://stackoverflow.com/questions/18459322/how-to-get-uilabel-tags-in-iphone
//
-(void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event;
{
    UITouch *touch = [touches anyObject];
    
    if(touch.view.tag >= 100 && touch.view.tag < 110)
        [self buttonAnswerDismiss:self.labelAnswer];
}

- (IBAction)operatorTouched:(id)sender {
    
}

- (IBAction)touchCardButton:(UIButton *)sender
{
    if ([self.labelAnswer.text compare:@"(select cards)"] == NSOrderedSame) {
        self.labelAnswer.text = @"";
    }
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
        [sender setTitle:[NSString stringWithFormat:@"%d", sender.tag]
                forState:UIControlStateNormal];
        
        self.labelAnswer.text = [NSString stringWithFormat:@"%@ %d", self.labelAnswer.text, sender.tag];
    }
    
    NSLog(@"%@", sender);
}
@end
