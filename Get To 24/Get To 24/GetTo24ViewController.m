
//
//  GetTo24ViewController.m
//  Get To 24
//
//  Created by Tony Tam on 1/4/14.
//  Copyright (c) 2014 Yama Llama. All rights reserved.
//
// TODO: local leader board
// TODO: swipe away the answer use has to change it
// TODO: wrong answer
//2014-05-25 22:30:45.419 Math 24[1298:60b] answer ((8 + 7) - 1) + 10
// 2014-05-25 22:31:11.298 Math 24[1298:60b] answer ((10 * 8) * 7) + 1
// 2014-05-25 22:31:11.298 Math 24[1298:60b] Player got it right: ((10 * 8) * 7) + 1

#import "GetTo24ViewController.h"

#import "PlayingCardDeckNoFace.h"
#import "PlayingCardDeckMedium24.h"
#import "PlayingCardDeckEasy24.h"
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
- (AnswerPackage *) calcuateSimple:(NSArray *)cards
                    usingOperators:(SEL *)selectors
                 withOperatorChars:(NSArray *)currentOperatorChars;

- (AnswerPackage *) calcuateGrouping:(NSArray *)cards
                      usingOperators:(SEL *)selectors
                   withOperatorChars:(NSArray *)currentOperatorChars;

- (AnswerPackage *) calcuateGroupingOfTwo:(NSArray *)cards
                           usingOperators:(SEL *)selectors
                        withOperatorChars:(NSArray *)currentOperatorChars;

- (AnswerPackage *) calcuateGroupingSecond:(NSArray *)cards
                            usingOperators:(SEL *)selectors
                         withOperatorChars:(NSArray *)currentOperatorChars;


@property PlayingCardDeckNoFace *_hardDeck;
@property PlayingCardDeckEasy24 *_easyDeck;
@property PlayingCardDeckMedium24 *_mediumDeck;

@property PlayingCardDeck *currentDeck;

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
@property NSArray *operatorLabels2;
@property NSArray *labelAnswers;

@property NSMutableArray *answerArray;
@property NSMutableArray *answerCardArray;
@property SEL *answerOperators;
@property int numAnswerOperators;
@property NSMutableArray *operatorStrings;

@property AnswerPackage *storeAnswerPackage;



- (void) rightAnswer:(int) playerNumber;

@property int answerPlayer;
@end

@implementation GetTo24ViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
//
// pop up the answer area for the player to verify
//
- (void) verifyAnswer
{
    [self showAnswerControllers:TRUE];
    [self.timer invalidate];
}

//
// Show or hide the controllers use for answers
//
- (void) showAnswerControllers:(Boolean)show
{
    [self disableOperators:true];
    
    // the cards and the operators
    for (int i = 0; i < 4; i++ ){
        [((UIButton *)self.cards[i]) setUserInteractionEnabled:show];
        ((UIButton *)self.cards[i]).alpha = show ? 1 : 0.2;

        ((UIButton *)self.operatorLabels2[i]).alpha = show ? 1 : .2;
        
        if (show == FALSE) {
            [((UIButton *)self.cards[i]) setTitle:@""
                                         forState:UIControlStateNormal];
        }
    }
    
    self.segmentLevels.hidden = show;
    
    // Show the area where the answers are shown
    self.labelAnswer.hidden = !show;
    self.labelAnswer2.hidden = !show;
    
    self.player1Button.hidden = show;
    self.player2Button.hidden = show;

    self.labelTime.hidden = show;
    self.labelTime1.hidden = show;
    self.labelTimeStatic.hidden = show;
    self.labelTimeStatic1.hidden = show;
    self.player2NameLabel.hidden = show;
    self.player1NameLabel.hidden = show;
    self.player1Score.hidden = show;
    self.player2Score.hidden = show;
    self.labelBackground1.hidden = show;
    self.labelBackground2.hidden = show;

    [self.imageViewCenter setUserInteractionEnabled:!show];
    
    if (show) {
        if (self.answerPlayer == 0) {
            self.labelAnswer.text = @"(select cards)";
            self.labelAnswer2.text = @"";
        } else {
            self.labelAnswer.text = @"";
            self.labelAnswer2.text = @"(select cards)";
        }
    }
    
    if (show == TRUE) {
        [self disableOperators:TRUE];
        [self disableCards:FALSE];
    }
}
//
// Player got the right answer, reward with a point
// Maybe show them other potential answers
//
-(void) rightAnswer:(int) playerNumber
{
    if (playerNumber == 0) {
        
        self.player1ScorePoints += 1;
        self.player1Score.text = [NSString stringWithFormat:@"%d",
                                  self.player1ScorePoints];
    } else {
        
        self.player2ScorePoints += 1;
        self.player2Score.text = [NSString stringWithFormat:@"%d",
                                  self.player2ScorePoints];
    }

    [AudioUtil playSound:@"chimes" :@"wav"];
}

//
// Player got the right answer, reward with a point
// Maybe show them other potential answers
//
-(void) wrongAnswer:(int) playerNumber
{
    if (playerNumber == 0) {
        
        self.player1ScorePoints -= 1;
        self.player1Score.text = [NSString stringWithFormat:@"%d",
                                  self.player1ScorePoints];
    } else {
        
        self.player2ScorePoints -= 1;
        self.player2Score.text = [NSString stringWithFormat:@"%d",
                                  self.player2ScorePoints];
    }
    
    [AudioUtil playSound:@"chimes" :@"wav"];
}

- (void) clearAnswer
{
    DLog(@"answer cards %@", self.answerCardArray);

    if ([self.answerCardArray count] == 4) {
        [self dealHand];
        return;
    }
    
    self.labelAnswer.text = @"";
    self.labelAnswer2.text = @"";
    
    // the cards and the operatdors
    for (int i = 0; i < 4; i++ ){
        [((UIButton *)self.cards[i]) setUserInteractionEnabled:TRUE];
        ((UIButton *)self.cards[i]).alpha =  0.8;

        [((UIButton *)self.cards[i]) setTitle:@""
                                     forState:UIControlStateNormal];
    }
    
    [self.answerArray removeAllObjects];
    [self.answerCardArray removeAllObjects];
    [self.operatorStrings removeAllObjects];
    self.numAnswerOperators = 0;
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
    self.currentGameTime = 600;
    // Update both timers
    self.labelTime.text = [NSString stringWithFormat:@"%d", self.currentGameTime];
    self.labelTime1.text = [NSString stringWithFormat:@"%d", self.currentGameTime];

    // Scores
    self.player1ScorePoints = 0;
    
    self.player1Score.text = [NSString stringWithFormat:@"%d",
                              self.player1ScorePoints];
    
    self.player2ScorePoints = 0;
    self.player2Score.text = [NSString stringWithFormat:@"%d",
                              self.player1ScorePoints];
    
    // The valid operators
    self.plusSel  = @selector(decimalNumberByAdding:);
    self.minusSel = @selector(decimalNumberBySubtracting:);
    self.mulSel   = @selector(decimalNumberByMultiplyingBy:);
    self.divSel   = @selector(decimalNumberByDividingBy:);
    
    // We will need to loop through the operators/selectors
    self.selectors = malloc(sizeof(SEL) * 4);
    self.selectors[0] = self.plusSel;
    self.selectors[1] = self.minusSel;
    self.selectors[2] = self.mulSel;
    self.selectors[3] = self.divSel;
    
    self.answerOperators = malloc(sizeof(SEL) * 3);
    self.operatorStrings = [[NSMutableArray alloc] init];
    self.answerCardArray = [[NSMutableArray alloc] init];
    self.answerArray = [[NSMutableArray alloc] init];

    // just because it's hard to map SEL, we have the string representations
    self.operatorChars = [NSArray arrayWithObjects:
                          @"+",
                          @"-",
                          @"×",
                          @"÷",
                          nil];
    
    
    // Keep track of the UIButtons where the operators are
    self.operatorLabels2 = [NSArray arrayWithObjects:
                            self.buttonPlus2,
                            self.buttonMinus2,
                            self.buttonMultiplication2,
                            self.buttonDivision2,
                            nil
                            ];
    
    // Deal a new deck of cards
    
    if (! self._hardDeck) {
        self._hardDeck = [[PlayingCardDeckNoFace alloc] init];
    }
    
    if (! self._easyDeck) {
        self._easyDeck = [[PlayingCardDeckEasy24 alloc] init];
    }
    
    if (! self._mediumDeck) {
        self._mediumDeck = [[PlayingCardDeckMedium24 alloc] init];
    }
    self.currentDeck = self._easyDeck;
    
    // Keep track of the labels used to display the status/answers to both players
    self.labelAnswers = [[NSArray alloc] initWithObjects:self.labelAnswer, self.labelAnswer2, nil];
    
    
    // Start off with no answer controllers
    [self showAnswerControllers:FALSE];
    self.labelMiddleInfo.hidden = TRUE;
    
    // Deal a fresh hand
    self.hand = [[NSMutableArray alloc] init];
    [self dealHand];
    
    

    [AudioUtil playSound:@"opening" :@"wav"];
}

//
// The timer calls this to start a ticking sound, very annoying
//
- (void) countdown
{
    self.currentGameTime -= 1;
    if (self.currentGameTime <= 0) {
        self.currentGameTime = 0;
    }
    DLog("Countdown %d %f", self.currentGameTime, percent);

    // Update both timers
    self.labelTime.text = [NSString stringWithFormat:@"%d", self.currentGameTime];
    self.labelTime1.text = [NSString stringWithFormat:@"%d", self.currentGameTime];

    if (self.currentGameTime <= 0) {
        [self.timer invalidate];
        [self timesUp];
        return;
    }
}

//
// Put the 4 cards back into the deck
//
- (void) putInDeck:(NSArray *) cards
{
    for (CardHand *card in cards ) {
        [self.currentDeck addCard:card.card];
    }
}

//
// Deal 4 cards to start a game
//
- (void) dealHand
{
    self.answerPlayer = -1;
    
    [self showAnswerControllers:FALSE];

    // TODO what if we run out of cards, time to call a winner
    //self.currentGameTime = 300;
    
    // clear the current hand about put back into the deck in random order?
    [self putInDeck:self.hand];
    [self.hand removeAllObjects];
    
    self.labelMiddleInfo.hidden = TRUE;
    // clear the hand
    [self.answerArray removeAllObjects];
    [self.answerCardArray removeAllObjects];
    [self.operatorStrings removeAllObjects];
    self.numAnswerOperators = 0;
    
    UIButton *card;
    
    // deal 4 cards
    for (int i = 0; i < [self.cards count]; i++) {
        PlayingCard *newCard = (PlayingCard *)[self.currentDeck drawRandomCard];

        CardHand *singleDeal = [[CardHand alloc] init];
        
        // tag it for later to get the value back
        [self.cards[i] setTag:i];
        
        singleDeal.card = newCard;
        
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
        [card setBackgroundImage:[UIImage imageNamed:[NSString stringWithFormat:@"num-%d.png",  (int) newCard.rank]]
                        forState:UIControlStateNormal];
        DLog(@"deal %d", newCard.rank);
    }
    

    // We the answer before the user
    if ([self calcuateAnswer] == nil) {
        DLog(@"Re-deal hand with no answer");
        [self dealHand];
        return;
    }
    if (![self.timer isValid]) {
        // Start the countdown
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1
                                                      target:self
                                                    selector:@selector(countdown)
                                                    userInfo:nil
                                                     repeats:YES];
        //[AudioUtil playSound:@"relaxing-short" :@"wav"];
    }
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
    //[card setBackgroundImage:[UIImage imageNamed:@"num-1.png"]
    //                forState:UIControlStateNormal];
    
    
    [UIView beginAnimations:@"ShowHideView" context:(void*)card];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    [UIView setAnimationDuration:0.4];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(showHideDidStop:finished:context:)];
    
    // Make the animatable changes.
    card.alpha = 0.8;
    left.alpha = 0.8;
    right.alpha = 0.8;
    //[card setBackgroundImage:nil forState:UIControlStateNormal];
    
    // Commit the changes and perform the animation.
    [UIView commitAnimations];
    
    
}

// Called at the end of the preceding animation.
// remove the background
//
- (void)showHideDidStop:(NSString *)animationID
               finished:(NSNumber *)finished
                context:(void *)context
{
    [UIView beginAnimations:@"ShowHideView2" context:context];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [UIView setAnimationDuration:1.0];
    [UIView setAnimationDelay:0.0];
    
    UIButton *card = (__bridge UIButton *)context;
    
    // Make the animatable changes.
    card.alpha = 0.8;
    
    //[card setBackgroundImage:[UIImage imageNamed:@"num-1.png"]
    //                forState:UIControlStateNormal];
    
    /*
     [card setBackgroundImage:nil
     forState:UIControlStateNormal];
     */
    DLog(@"showHideDidStop");
    [UIView commitAnimations];
}

// TODO: declare winner!
// Dock points from both players
// the player has to find the answer, skip or say there is no answer
//
- (void)timesUp {
    [AudioUtil playSound:@"whoosh" :@"wav"];
    // Stop the previous timer
    
    // [AudioUtil playSound:@"ray" :@"wav"];
    
    [self.timer invalidate];
    self.labelMiddleInfo.hidden = FALSE;
    self.labelMiddleInfo.text = @"Game Over";
    
    [self showAnswerControllers:FALSE];
    self.player1Button.hidden = TRUE;
    self.player2Button.hidden = TRUE;
    DLog(@"timesup");
}

//
// Give up without saying anything, any dock points from both players
//
- (IBAction)giveUp:(id)sender {
    [self dealHand];
    self.currentGameTime = self.currentGameTime - 10;
    
    [AudioUtil playSound:@"whoosh" :@"wav"];
}



//
// Player1 thinks he has it, need to validate the answer
//
- (IBAction)player1Pressed:(id)sender {
    
    self.answerPlayer = 0;

    [self verifyAnswer];
}

//
// Player2 thinks he has it, need to validate the answer
//
- (IBAction)player2Pressed:(id)sender {
    self.answerPlayer = 1;

    [self verifyAnswer];
}

//
// Hide the answers, show it when we are ready
//
- (void) hideAnswer
{
    self.labelAnswer.hidden = TRUE;
    self.labelAnswer2.hidden = TRUE;
    
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
    [self.labelTime1 setTransform:CGAffineTransformMakeRotation(-M_PI)];
    [self.labelTimeStatic1 setTransform:CGAffineTransformMakeRotation(-M_PI)];
    
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
    
    // tag the buttons so we can map it to self.operators
    [self.buttonPlus2 setTag:0];
    [self.buttonMinus2 setTag:1];
    [self.buttonMultiplication2 setTag:2];
    [self.buttonDivision2 setTag:3];
    
    // Don't show them the answers
    [self hideAnswer];
    [self.labelAnswer setTag:100];
    [self.labelAnswer2 setTag:101];
    
    [self.labelMiddleInfo setTag:200];
    
    [self.segmentLevels setTag:300];
    
    // Swipe
    self.swipeGesture.direction = UISwipeGestureRecognizerDirectionRight | UISwipeGestureRecognizerDirectionLeft;
    self.swipeGesture1.direction = UISwipeGestureRecognizerDirectionRight | UISwipeGestureRecognizerDirectionLeft;
    self.swipeGestureGiveUp.direction = UISwipeGestureRecognizerDirectionRight | UISwipeGestureRecognizerDirectionLeft;
    

    // Get started
    [self startGame];
    
}

// nada to clear
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
            //DLog(@"%@", e);
        }
    }
    return nil;
}



// TODO, refactor this into calculateHand
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
                
                storeAnswerPackage = [self calcuateSimple:cards
                                           usingOperators:currentOperators
                                        withOperatorChars:currentOperatorChars];
                if ([storeAnswerPackage.answer compare:rightAnswer] == NSOrderedSame) {
                    DLog(@"answer %@", storeAnswerPackage.stringAnswer);
                    
                    found = TRUE;
                    break;
                }
                storeAnswerPackage = [self calcuateGrouping:cards
                                             usingOperators:currentOperators
                                          withOperatorChars:currentOperatorChars];
                if ([storeAnswerPackage.answer compare:rightAnswer] == NSOrderedSame) {
                    DLog(@"answer %@", storeAnswerPackage.stringAnswer);
                    
                    found = TRUE;
                    break;
                }
                storeAnswerPackage = [self calcuateGroupingOfTwo:cards
                                                  usingOperators:currentOperators
                                               withOperatorChars:currentOperatorChars];
                if ([storeAnswerPackage.answer compare:rightAnswer] == NSOrderedSame) {
                    DLog(@"answer %@", storeAnswerPackage.stringAnswer);
                    
                    found = TRUE;
                    break;
                }
                storeAnswerPackage = [self calcuateGroupingSecond:cards
                                                   usingOperators:currentOperators
                                                withOperatorChars:currentOperatorChars];
                if ([storeAnswerPackage.answer compare:rightAnswer] == NSOrderedSame) {
                    DLog(@"answer %@", storeAnswerPackage.stringAnswer);
                    
                    found = TRUE;
                    break;
                }
                DLog(@"--- try %d %s %d %s %d %s %d",
                     card0.rank,
                     selector0,
                     card1.rank,
                     selector1,
                     card2.rank,
                     selector2,
                     card3.rank);
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

// Using the cards in the given sequence and operators in the sequence
// calculate whether there is an answer.  This can be used
// to verify the human players answer
//
// RETURN the answerPackage or nil if 24 is not found
//
- (AnswerPackage *) calculateHand:(NSArray *)cards
                   usingOperators:(SEL [])selectors
                withOperatorChars:(NSArray *)currentOperatorChars
{
    AnswerPackage *storeAnswerPackage;
    NSDecimalNumber *rightAnswer = (NSDecimalNumber *)[NSDecimalNumber numberWithInt:24];
    

    
    BOOL found = false;

    
    storeAnswerPackage = [self calcuateSimple:cards
                               usingOperators:selectors
                            withOperatorChars:currentOperatorChars];

    if ([storeAnswerPackage.answer compare:rightAnswer] == NSOrderedSame) {
        DLog(@"answer %@", storeAnswerPackage.stringAnswer);
        
        found = TRUE;
        return storeAnswerPackage;
    }
    
    storeAnswerPackage = [self calcuateGrouping:cards
                                 usingOperators:selectors
                              withOperatorChars:currentOperatorChars];
    if ([storeAnswerPackage.answer compare:rightAnswer] == NSOrderedSame) {
        DLog(@"answer %@", storeAnswerPackage.stringAnswer);
        
        found = TRUE;
        return storeAnswerPackage;
    }
    storeAnswerPackage = [self calcuateGroupingOfTwo:cards
                                      usingOperators:selectors
                                   withOperatorChars:currentOperatorChars];
    if ([storeAnswerPackage.answer compare:rightAnswer] == NSOrderedSame) {
        DLog(@"answer %@", storeAnswerPackage.stringAnswer);
        
        found = TRUE;
        return storeAnswerPackage;
    }
    storeAnswerPackage = [self calcuateGroupingSecond:cards
                                       usingOperators:selectors
                                    withOperatorChars:currentOperatorChars];
    if ([storeAnswerPackage.answer compare:rightAnswer] == NSOrderedSame) {
        DLog(@"answer %@", storeAnswerPackage.stringAnswer);
        
        found = TRUE;
        return storeAnswerPackage;
    }
    
    return nil;
}

// ((a op b) op c) op d
- (AnswerPackage *) calcuateSimple:(NSArray *) cards
                    usingOperators:(SEL [])selectors
                 withOperatorChars:(NSArray *)currentOperatorChars
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
    
    @try {
        
        subtotal = [[NSDecimalNumber numberWithInt:card0.rank]
                    performSelector:selector0
                    withObject:[NSDecimalNumber numberWithInt:card1.rank]];
        
        
        subtotal = [subtotal
                    performSelector:selector1
                    withObject:[NSDecimalNumber numberWithInt:card2.rank]];
        
        subtotal = [subtotal
                    performSelector:selector2
                    withObject:[NSDecimalNumber numberWithInt:card3.rank]];
    }
    @catch (NSException *e) {
        answer.answer = [NSDecimalNumber numberWithInt:-1];
        
        answer.stringAnswer = @"Divide by zero";
        return answer;
    }

    answer.answer = subtotal;
    answer.stringFormat = @"((%d %@ %d) %@ %d) %@ %d";
    answer.stringAnswer = [NSString stringWithFormat:answer.stringFormat,
                           card0.rank,
                           [currentOperatorChars objectAtIndex:0],
                           card1.rank,
                           [currentOperatorChars objectAtIndex:1],
                           card2.rank,
                           [currentOperatorChars objectAtIndex:2],
                           card3.rank
                           ];
    answer.operators = [NSArray arrayWithArray:currentOperatorChars];
    answer.cards = [NSArray arrayWithArray:cards];
    
    return answer;
}

// (a op b) op (c op d)
- (AnswerPackage *) calcuateGrouping:(NSArray *) cards
                      usingOperators:(SEL [])selectors
                   withOperatorChars:(NSArray *)currentOperatorChars
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
    
    @try {
        
        subtotal = [[NSDecimalNumber numberWithInt:card0.rank]
                    performSelector:selector0
                    withObject:[NSDecimalNumber numberWithInt:card1.rank]];
        
        
        subtotal1 = [[NSDecimalNumber numberWithInt:card2.rank]
                     performSelector:selector2
                     withObject:[NSDecimalNumber numberWithInt:card3.rank]];
        
        
        subtotal = [subtotal
                    performSelector:selector1
                    withObject:subtotal1];
        
    }
    @catch (NSException *e) {
        answer.answer = [NSDecimalNumber numberWithInt:-1];
        
        answer.stringAnswer = @"Divide by zero";
        return answer;
        
    }
    answer.answer = subtotal;
    answer.stringFormat = @"(%d %@ %d) %@ (%d %@ %d)";
    answer.stringAnswer = [NSString stringWithFormat:answer.stringFormat,
                           card0.rank,
                           [currentOperatorChars objectAtIndex:0],
                           card1.rank,
                           [currentOperatorChars objectAtIndex:1],
                           card2.rank,
                           [currentOperatorChars objectAtIndex:2],
                           card3.rank
                           ];
    
    answer.operators = [NSArray arrayWithArray:currentOperatorChars];
    answer.cards = [NSArray arrayWithArray:cards];
    
    return answer;
}


// (a op b) op c op d
- (AnswerPackage *)calcuateGroupingOfTwo:(NSArray *) cards
                          usingOperators:(SEL [])selectors
                       withOperatorChars:(NSArray *)currentOperatorChars
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
    @try {
        
        subtotal = [[NSDecimalNumber numberWithInt:card0.rank]
                    performSelector:selector0
                    withObject:[NSDecimalNumber numberWithInt:card1.rank]];
        
        
        subtotal = [subtotal
                    performSelector:selector1
                    withObject:[NSDecimalNumber numberWithInt:card2.rank]];
        
        
        subtotal = [subtotal
                    performSelector:selector2
                    withObject:[NSDecimalNumber numberWithInt:card3.rank]];
        
    }
    @catch (NSException *e) {
        answer.answer = [NSDecimalNumber numberWithInt:-1];
        
        answer.stringAnswer = @"Divide by zero";
        return answer;
        
    }
    answer.answer = subtotal;
    answer.stringFormat = @"(%d %@ %d) %@ %d %@ %d";
    answer.stringAnswer = [NSString stringWithFormat:answer.stringFormat,
                           card0.rank,
                           [currentOperatorChars objectAtIndex:0],
                           card1.rank,
                           [currentOperatorChars objectAtIndex:1],
                           card2.rank,
                           [currentOperatorChars objectAtIndex:2],
                           card3.rank
                           ];
    
    answer.operators = [NSArray arrayWithArray:currentOperatorChars];
    answer.cards = [NSArray arrayWithArray:cards];
    
    return answer;
}

// a op (b op c) op d
- (AnswerPackage *) calcuateGroupingSecond:(NSArray *) cards
                            usingOperators:(SEL [])selectors
                         withOperatorChars:(NSArray *)currentOperatorChars
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
    
    @try {
        
        subtotal = [[NSDecimalNumber numberWithInt:card1.rank]
                    performSelector:selector1
                    withObject:[NSDecimalNumber numberWithInt:card2.rank]];
        
        
        subtotal = [[NSDecimalNumber numberWithInt:card0.rank]
                    performSelector:selector0
                    withObject:subtotal];
        
        
        subtotal = [subtotal
                    performSelector:selector2
                    withObject:[NSDecimalNumber numberWithInt:card3.rank]];

    }
    @catch (NSException *e) {
        answer.answer = [NSDecimalNumber numberWithInt:-1];

        answer.stringAnswer = @"Divide by zero";
        return answer;

    }
    answer.answer = subtotal;
    answer.stringFormat = @"%d %@ (%d %@ %d) %@ %d";
    answer.stringAnswer = [NSString stringWithFormat:answer.stringFormat,
                           card0.rank,
                           [currentOperatorChars objectAtIndex:0],
                           card1.rank,
                           [currentOperatorChars objectAtIndex:1],
                           card2.rank,
                           [currentOperatorChars objectAtIndex:2],
                           card3.rank
                           ];
    
    answer.operators = [NSArray arrayWithArray:currentOperatorChars];
    answer.cards = [NSArray arrayWithArray:cards];
    
    return answer;
}


// TODO nothing to do right now
// Handle UILabel touch events
// http://stackoverflow.com/questions/18459322/how-to-get-uilabel-tags-in-iphone
//
-(void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event;
{
    UITouch *touch = [touches anyObject];
    DLog(@"touch %@", touch);
    if (touch.view.tag >=  100 && touch.view.tag <= 110) {
        //[self showAnswerControllers:FALSE];
        //[self rightAnswer:1];
        //[self hideAnswer];
        //[self dealHand];
    }
    
    if (touch.view.tag == 200) {
        if (self.currentGameTime <= 0) {
            [self startGame];
        } else {
            [self dealHand];
        }
    }
    

}
- (IBAction)segmentLevelsTouched:(id)sender {
    self.segmentLevels.alpha = 0.5;
    DLog(@"Level %ld", (long)self.segmentLevels.selectedSegmentIndex);
    [self putInDeck:self.hand];
    [self.hand removeAllObjects];

    if (self.segmentLevels.selectedSegmentIndex == 0) {
        self.currentDeck = self._easyDeck;
        [self dealHand];
    }
    if (self.segmentLevels.selectedSegmentIndex == 1) {
        self.currentDeck = self._mediumDeck;
        [self dealHand];

    }
    if (self.segmentLevels.selectedSegmentIndex == 2) {
        self.currentDeck = self._hardDeck;
        [self dealHand];

    }
}

// An operator is touched, enable the cards, disable the operators
//
- (IBAction)operatorTouched:(id)sender
{
    UIButton *operator = (UIButton *) sender;

    // This keeps track of the current state of the answers
    // TODO this can be a struct?
    //
    [self.answerArray addObject:[NSString stringWithFormat:@"%@", self.operatorChars[operator.tag]]];
    self.answerOperators[self.numAnswerOperators++ ] = self.selectors[operator.tag];
    [self.operatorStrings addObject:self.operatorChars[operator.tag]];
    
    // Show the players where we are
    //
    for (int i = 0; i < 2; i++) {
        UILabel *labelAnswer = [self.labelAnswers objectAtIndex:i];
        
        if ([labelAnswer.text compare:@"(select cards)"] == NSOrderedSame) {
            labelAnswer.text = @"";
        }
        
        labelAnswer.text = [NSString stringWithFormat:@"%@ %@",
                            labelAnswer.text,
                            self.operatorChars[operator.tag]];
        
    }
    
    // Enable cards, disable operators
    [self disableOperators:TRUE];
    [self disableCards:FALSE];
}

//
// A playing card is pressed, the user is building up an answer
// show the user how the answer is being built by the user.
// enable the operator buttons, but disable the card buttons
//
- (IBAction)touchCardButton:(UIButton *)sender
{
    NSDecimalNumber *rightAnswer = (NSDecimalNumber *)[NSDecimalNumber numberWithInt:24];

    if (self.answerPlayer < 0 || self.answerPlayer > 1) {
        // something really wrong, reset everything
        DLog(@"should be fatal error here, only 2 players are supported");
        [self startGame];
        return;
    }
    
    CardHand * cardHand = [self.hand objectAtIndex:sender.tag];
    
    [sender setUserInteractionEnabled:FALSE];
    sender.alpha = 0.2;

    [self.answerArray addObject:sender];
    [self.answerCardArray addObject:cardHand];

    // Keep the players informed about what has been selected, both players need to know
    for (int i = 0; i < 2; i++) {
        UILabel *labelAnswer = [self.labelAnswers objectAtIndex:i];
        if ([labelAnswer.text compare:@"(select cards)"] == NSOrderedSame) {
            labelAnswer.text = @"";
        }
        labelAnswer.text = [NSString stringWithFormat:@"%@ %d",
                                  (NSString *)labelAnswer.text,
                                  (int)cardHand.card.rank];
    }
    
    // TODO: add or remove points
    // We have 4 cards and 3 operators, we are done
    if ([self.answerArray count] == 7) {
        NSString * finalText = [[NSString alloc] init];
        
        AnswerPackage *answer = [self calculateHand:self.answerCardArray
                                  usingOperators:self.answerOperators
                               withOperatorChars:self.operatorStrings];
        if (answer != nil && [answer.answer compare:rightAnswer] == NSOrderedSame) {
            
            // Internationalize these strings
            DLog(@"Player got it right: %@", answer.stringAnswer);
            finalText = [NSString stringWithFormat:@"Yay, You Got 24!!\n %@", answer.stringAnswer];
            [self rightAnswer:self.answerPlayer];
        } else {
            finalText = [NSString stringWithFormat:@"Sorry, Get To 24 with: \n%@", self.storeAnswerPackage.stringAnswer];
            [self wrongAnswer:self.answerPlayer];
        }
        
        if (self.answerPlayer == 0) {
            [self.labelMiddleInfo setTransform:CGAffineTransformMakeRotation(-M_PI)];
        } else {
            [self.labelMiddleInfo setTransform:CGAffineTransformMakeRotation(0)];
        }
        self.labelMiddleInfo.text = finalText;
        self.labelMiddleInfo.hidden = FALSE;
        return;
    }
    
    // Disable cards, enable operators
    [self disableCards:TRUE];
    [self disableOperators:FALSE];
}

// We are selecting operators, so deselect the cards, but let the user know
// via the alpha level which cards were already selected
//
- (IBAction)disableCards:(BOOL) bDisabled
{

    for (int i = 0; i < 4; i++ ) {
        UIButton *card = (UIButton *)self.cards[i];
        
        // Never enable a card once it's been selected
        if (bDisabled == FALSE && [self.answerArray containsObject:card]) {
            DLog(@"not enabling %@", card);
            continue;
        }
        
        [card setUserInteractionEnabled:!bDisabled];
        
        // If the card has already been selected, dime it even more
        if (bDisabled == TRUE && [self.answerArray containsObject:card]) {
            card.alpha = bDisabled ? 0.2 : 1;

        } else {
            card.alpha = bDisabled ? 0.5 : 1;
        }
    }
}

// We are selectings cards, so disable the operators
- (IBAction)disableOperators:(BOOL) bDisabled
{
    for (int i = 0; i < 4; i++ ) {
        [((UIButton *)self.operatorLabels2[i]) setUserInteractionEnabled:! bDisabled];
        ((UIButton *)self.operatorLabels2[i]).alpha =  bDisabled ? 0.2 : 1;
    }
}

// Swipe away and try answer again
- (IBAction)swipeAway:(UISwipeGestureRecognizer *)sender {
    DLog(@"swipe");
    [self clearAnswer];
}

// Swipe away and try answer again
- (IBAction)swipeAway1:(UISwipeGestureRecognizer *)sender {
    DLog(@"swipe1");
    [self clearAnswer];
}

// Skp the current hand, you loose a few precious seconds
- (IBAction)swipeAwayGiveUp:(id)sender {
    DLog(@"swipeAwayGiveUp");

    [self giveUp:sender];
}


@end
