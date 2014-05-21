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
    [self disableOperators:true];
    
    for (int i = 0; i < 4; i++ ){
        [((UIButton *)self.cards[i]) setUserInteractionEnabled:show];
        ((UIButton *)self.operatorLabels2[i]).hidden = !show;
        
        if (show == FALSE) {
            [((UIButton *)self.cards[i]) setTitle:@""
                                         forState:UIControlStateNormal];
        }
    }
    
    self.labelAnswer.hidden = !show;
    self.labelAnswer2.hidden = !show;
    
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
    
    self.operatorChars = [NSArray arrayWithObjects:
                          @"+",
                          @"-",
                          @"*",
                          @"/",
                          nil];
    
    
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
    self.labelTime.text = [NSString stringWithFormat:@"%d", self.currentGameTime];
    
    DLog("Countdown %d %f", self.currentGameTime, percent);
    self.currentGameTime -= 1;
    if (self.currentGameTime <= 0) {
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
    self.currentGameTime = 300;
    
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
    if ([self calcuateAnswer] == nil) {
        NSLog(@"Re-deal hand with no answer");
        [self dealHand];
    }
    
    [self.timer invalidate];
    
        // Start the countdown
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1
                                                  target:self
                                                selector:@selector(countdown)
                                                userInfo:nil
                                                 repeats:YES];
    
    
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
    [card setBackgroundImage:[UIImage imageNamed:@"red.card.background.png"]
                    forState:UIControlStateNormal];
    
    
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
    card.alpha = 1.0;
    
    [card setBackgroundImage:nil
                    forState:UIControlStateNormal];
    
    DLog(@"showHideDidStop");
    [UIView commitAnimations];
}

    //
    // Dock points from both players
    // the player has to find the answer, skip or say there is no answer
    //
- (void)timesUp {
        //[AudioUtil playSound:@"whoosh" :@"wav"];
        // Stop the previous timer
    [self.timer invalidate];
    
    [AudioUtil playSound:@"ray" :@"wav"];
    
        // [self dealHand];
}

    //
    // Give up without saying anything, any dock points from both players
    //
- (IBAction)giveUp:(id)sender {
    [self dealHand];
    
    [AudioUtil playSound:@"whoosh" :@"wav"];
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
    
    
    self.labelAnswer.hidden = TRUE;
    
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
    [self.labelTime setTransform:CGAffineTransformMakeRotation(-M_PI / 2)];
    [self.labelTimeStatic setTransform:CGAffineTransformMakeRotation(-M_PI / 2)];
    
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
    [self.buttonPlus2 setTag:10];
    [self.buttonMinus2 setTag:11];
    [self.buttonMultiplication2 setTag:12];
    [self.buttonDivision2 setTag:13];
    
        // Don't show them the answers
    [self hideAnswer];
    [self.labelAnswer setTag:100];
    [self.labelAnswer2 setTag:101];
    
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
                
                storeAnswerPackage = [self calcuateSimple:cards
                                           usingOperators:currentOperators
                                        withOperatorChars:currentOperatorChars];
                if ([storeAnswerPackage.answer compare:rightAnswer] == NSOrderedSame) {
                    NSLog(@"answer %@", storeAnswerPackage.stringAnswer);
                    
                    found = TRUE;
                    break;
                }
                storeAnswerPackage = [self calcuateGrouping:cards
                                             usingOperators:currentOperators
                                          withOperatorChars:currentOperatorChars];
                if ([storeAnswerPackage.answer compare:rightAnswer] == NSOrderedSame) {
                    NSLog(@"answer %@", storeAnswerPackage.stringAnswer);
                    
                    found = TRUE;
                    break;
                }
                storeAnswerPackage = [self calcuateGroupingOfTwo:cards
                                                  usingOperators:currentOperators
                                               withOperatorChars:currentOperatorChars];
                if ([storeAnswerPackage.answer compare:rightAnswer] == NSOrderedSame) {
                    NSLog(@"answer %@", storeAnswerPackage.stringAnswer);
                    
                    found = TRUE;
                    break;
                }
                storeAnswerPackage = [self calcuateGroupingSecond:cards
                                                   usingOperators:currentOperators
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
    if (self.answerPlayer < 0 || self.answerPlayer > 1) {
            // something really wrong, reset everything
        [self startGame];
        return;
    }
    
    UILabel *labelAnswer = [self.labelAnswers objectAtIndex:self.answerPlayer];
    
    if ([labelAnswer.text compare:@"(select cards)"] == NSOrderedSame) {
        labelAnswer.text = @"";
    }
    
    UIImage *cardImage = [UIImage imageNamed:@"cardfront"];
    [sender setBackgroundImage:cardImage
                      forState:UIControlStateNormal ];
    [sender setTitle:[NSString stringWithFormat:@"%d", sender.tag]
            forState:UIControlStateNormal];
    
    [sender setUserInteractionEnabled:FALSE];
    
    [self.answerArray addObject:[NSString stringWithFormat:@"%d", sender.tag]];
    
    labelAnswer.text = [NSString stringWithFormat:@"%@ %d", (NSString *)labelAnswer.text, sender.tag];
    
    
    [self disableCards:TRUE];
    [self disableOperators:FALSE];
    
}

- (IBAction)disableCards:(BOOL) bDisabled
{
    UIColor *color = [UIColor grayColor];
    if (!bDisabled) {
        color = [UIColor blackColor];
    }
    
    for (int i = 0; i < 4; i++ ) {
        [((UIButton *)self.cards[i]) setUserInteractionEnabled:!bDisabled];
        
        [((UIButton *)self.cards[i])
         setTitleColor:color
         forState:UIControlStateNormal];
    }
}

- (IBAction)disableOperators:(BOOL) bDisabled
{
    for (int i = 0; i < 4; i++ ) {
            //  [((UIButton *)self.cards[i]) setUserInteractionEnabled:!bDisabled];
            //((UIButton *)self.operatorLabels2[i]).hidden = bDisabled;
        [((UIButton *)self.operatorLabels2[i]) setUserInteractionEnabled:! bDisabled];
        
        [((UIButton *)self.operatorLabels2[i])
         setTitleColor:(bDisabled) ? [UIColor grayColor] : [UIColor blackColor]
         forState:UIControlStateNormal];
    }
}

@end
