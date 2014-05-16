//
//  GetTo24ViewController.m
//  Get To 24
//
//  Created by Tony Tam on 1/4/14.
//  Copyright (c) 2014 Yama Llama. All rights reserved.
//
// TODO: local leader board
//

#import "GetTo24ViewController.h"
#import "MRCircularProgressView.h"

#import "PlayingCardDeck.h"
#import "Deck.h"
#import "Debug.h"
#import "NSArrayUtil.h"
#import "AudioUtil.h"

// When the computer figures out the answer

@interface AnswerPackage : NSObject
// A human readable string
@property NSString *stringAnswer;

// The strFormat for the answer

@property NSString *stringFormat;

// the list of operators used
@property NSArray *operators;

// The list of cards for the answer, order is important
@property NSArray *cards;

// The final answer
@property NSDecimalNumber *answer;
@end

@implementation AnswerPackage
// intentionally empty
@end

// A card is dealt, but the actually UI card needs to be kept tracked
@interface CardHand : NSObject
@property PlayingCard *card;
@property UILabel *operatorLabel;
@end

@implementation CardHand
// intentially empty
@end

@interface GetTo24ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *flipsLabel;
@property (nonatomic) int flipCount;

// call this once when we are ready to start
- (void) startGame;

// deal a new hand, will handle all the UI updates
- (void) dealHand;

// call every second to countdown to the end of the timer
- (void) countdown;

// put the list o cards back into the deck to be reused
//should be call before and atfter good answers
- (void) putInDeck:(NSArray *) cards;

// Given 4 cards, calculate all possible answers, stop
// and return the answer if at least one is found
// does not currently return ll possible answers
// return nil if no answer is found
- (AnswerPackage *) calculateHand:(NSArray *)cards;

// take a list of 4 cards, without reording them, apply
// the found operators and return the answer by applying the
// operators in the order and precendence.  Don't care
// yet about the right answer
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
@property NSArray *operatorLabels2;
@property NSArray *labelAnswers;

@property NSMutableArray *answerArray;

@property AnswerPackage *storeAnswerPackage;

- (void) rightAnswer;

@property int answerPlayer;
@end

@implementation GetTo24ViewController

// pop up the text field
- (void) verifyAnswer
{
    [self showAnswerControllers:TRUE];

    self.labelAnswer.text = @"(select cards)";
    self.labelAnswer2.text = @"(select cards)";

    [self.timer invalidate];

}

- (void) showAnswerControllers:(Boolean)show
{
    
    for (int i = 0; i < 4; i++ ){
        [((UIButton *)self.cards[i]) setUserInteractionEnabled:show];
        ((UIButton *)self.operatorLabels[i]).hidden = !show;
        ((UIButton *)self.operatorLabels2[i]).hidden = !show;

        if (show == FALSE) {
            [((UIButton *)self.cards[i]) setTitle:@""
                                         forState:UIControlStateNormal];
        }
    }

    self.labelAnswer.hidden = !show;
    self.labelAnswer2.hidden = !show;

    self.labelOperatorBackground.hidden = !show;
    self.labelOperatorBackground2.hidden = !show;

    self.gameCountdownProgress.hidden = show;
    self.deleteButton.hidden = !show;
    self.deleteButton2.hidden = !show;

    self.player2NoSolutionButton.hidden = show;
    self.player1NoSolutionButton.hidden = show;

    self.player1Button.hidden = show;
    self.player2Button.hidden = show;

    // Disable the other button
    self.player1Button.enabled = !show;
    self.player2Button.enabled = !show;
    
}
//
// Player got the right answer, reward with a point
// Maybe show them other potential answers
//
-(void) rightAnswer:(int) playerNumber
{
    [self.timer invalidate];
    UILabel *label = (playerNumber == 1) ?
                     self.labelAnswer :
                     self.labelAnswer2;
    
    label.hidden = FALSE;
    self.labelAnswer2.hidden = FALSE;
    self.labelAnswer.hidden = FALSE;
    
    if (self.storeAnswerPackage.stringAnswer == nil) {
        self.labelAnswer.text = @"No answer";
        self.labelAnswer2.text = @"No answer";

    } else {
        self.labelAnswer2.text = self.storeAnswerPackage.stringAnswer;
        self.labelAnswer.text = self.storeAnswerPackage.stringAnswer;
    }
    
    self.player1Button.hidden = true;
    self.player2Button.hidden = true;
    self.player1NoSolutionButton.hidden = true;
    self.player2NoSolutionButton.hidden = true;


    //[self showAnswerControllers:FALSE];
    //[self dealHand];
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
    
    self.operatorLabels2 = [NSArray arrayWithObjects:
                           self.buttonPlus2,
                           self.buttonMinus2,
                           self.buttonMultiplication2,
                           self.buttonDivision2,
                           nil
                           ];

    // Deal a new deck of cards
    if (! self._cardDeck) {
        self._cardDeck = [[PlayingCardDeck alloc] init];
    }
    
    self.labelAnswers = [[NSArray alloc] initWithObjects:self.labelAnswer, self.labelAnswer2, nil];
    
    
    self.hand = [[NSMutableArray alloc] init];
    [self.gameCountdownProgress setProgress:0.0 duration:1.0f];
    self.gameCountdownProgress.progressColor = [UIColor greenColor];
    [AudioUtil playSound:@"opening" :@"wav"];
    
    
    [self showAnswerControllers:FALSE];
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

    [self.gameCountdownProgress setProgress:percent duration:1.0f];

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
    self.answerPlayer = -1;
    
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
        
        // tag it for later to get the value back
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

    self.gameCountdownProgress.progressColor = [UIColor greenColor];

    [self.gameCountdownProgress setProgress:0.0 duration:1.0f];
    self.gameCountdownProgress.hidden = FALSE;
    //[AudioUtil playSound:@"relaxing-short" :@"wav"];
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
    card.alpha = 1.0;
    left.alpha = 1.0;
    right.alpha = 1.0;
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
    card.alpha = 1.0;

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
// Say there i no solution, plus points if computer agrees otherwise it's consider
// the same as wrong answer
//
- (IBAction)noSolution1:(id)sender {
    [self.gameCountdownProgress setProgress:0.00 animated:NO];
    [self rightAnswer:1];

    [AudioUtil playSound:@"beep" :@"wav"];
}

//
// Say there no solution, plus points if computer agrees otherwise it's consider
// the same as wrong answer
//
- (IBAction)noSolution2:(id)sender {
    [self.gameCountdownProgress setProgress:0.00 animated:NO];
    [self rightAnswer:2];
    
    [AudioUtil playSound:@"beep" :@"wav"];
}

//
// Player1 thinks he has it, need to validate the answer
// TODO
//
- (IBAction)player1Pressed:(id)sender {
    
    self.answerPlayer = 0;
    
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
    self.answerPlayer = 1;

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

    [self.player1Button setTransform:CGAffineTransformMakeRotation(-M_PI)];
    [self.player1Score setTransform:CGAffineTransformMakeRotation(-M_PI)];
    [self.player1NameLabel setTransform:CGAffineTransformMakeRotation(-M_PI)];

    [self.labelNEright setTransform:CGAffineTransformMakeRotation(-M_PI)];
    [self.labelNWright setTransform:CGAffineTransformMakeRotation(-M_PI)];
    [self.labelSWright setTransform:CGAffineTransformMakeRotation(-M_PI)];
    [self.labelSEright setTransform:CGAffineTransformMakeRotation(-M_PI)];
    [self.labelAnswer setTransform:CGAffineTransformMakeRotation(-M_PI)];
    [self.deleteButton setTransform:CGAffineTransformMakeRotation(-M_PI)];

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
    [self.labelAnswer2 setTag:101];

    [self.labelOperatorBackground setTag:102];
    [self.labelOperatorBackground2 setTag:103];

    self.deleteButton.hidden = true;
    
    self.gameCountdownProgress.progressArcWidth = 3.0;

    self.answerArray = [[NSMutableArray alloc] init];
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


- (IBAction)buttonAnswerDismiss:(id)sender
{

    [self showAnswerControllers:FALSE];
    [self dealHand];
}

//
// Handle UILabel touch events
// http://stackoverflow.com/questions/18459322/how-to-get-uilabel-tags-in-iphone
//
-(void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event;
{
    UITouch *touch = [touches anyObject];
    if (touch.view.tag >=  100 && touch.view.tag <= 110) {
        [self showAnswerControllers:FALSE];
        [self dealHand];
    }
}

- (IBAction)operatorTouched:(id)sender
{
    UIButton *operator = (UIButton *) sender;
    UILabel *labelAnswer = [self.labelAnswers objectAtIndex:self.answerPlayer];
    

    if ([labelAnswer.text compare:@"(select cards)"] == NSOrderedSame) {
        labelAnswer.text = @"";
    }
    [self.answerArray addObject:[NSString stringWithFormat:@"%@", operator.currentTitle]];

    labelAnswer.text =
        [NSString stringWithFormat:@"%@ %@",
                                   labelAnswer.text,
                                   operator.currentTitle];
}

- (IBAction)touchCardButton:(UIButton *)sender
{
    if (self.answerPlayer < 0 || self.answerPlayer > 1) {
        // something really wrong, reset everything
        [self startGame];
        return;
    }
    
    UILabel *labelAnswer = [self.labelAnswers objectAtIndex:self.answerPlayer];
    
    if ([self.labelAnswer.text compare:@"(select cards)"] == NSOrderedSame) {
        labelAnswer.text = @"";
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
        [sender setUserInteractionEnabled:FALSE];
        
        [self.answerArray addObject:[NSString stringWithFormat:@"%d", sender.tag]];
        
        labelAnswer.text = [NSString stringWithFormat:@"% %d", labelAnswer.text, sender.tag];
    }
    
}
@end
