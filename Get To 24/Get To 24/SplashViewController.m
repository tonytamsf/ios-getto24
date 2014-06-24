//
//  SplashViewController.m
//  Get To 24
//
//  Created by Tony Tam on 5/27/14.
//  Copyright (c) 2014 Yama Llama. All rights reserved.
//

#import "SplashViewController.h"
#import "Debug.h"
#import <AVFoundation/AVFoundation.h>
#import "PBJVideoPlayerController.h"
#import "GetTo24ViewController.h"

@interface SplashViewController () < PBJVideoPlayerControllerDelegate >
@end

@implementation SplashViewController

- (BOOL) canPlayTransition
{
    NSArray *versionCompatibility = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];
    
    /// Don't play intro vieo for iOS 6.0
    if ( 7 <= [[versionCompatibility objectAtIndex:0] intValue] ||
        (6 <= [[versionCompatibility objectAtIndex:0] intValue] &&
         1 <= [[versionCompatibility objectAtIndex:1] intValue])) {
            return TRUE;
        }
    return false;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    DLog(@"SplashViewController.h");
    
    NSArray *versionCompatibility = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];
    DLog(@"version %d", [[versionCompatibility objectAtIndex:0] intValue]);
    
    if ( ! [self canPlayTransition] ) { /// iOS5 is installed
        [self transtionToPlayView];
    } else {
        
        
        PBJVideoPlayerController *_videoPlayerController = [[PBJVideoPlayerController alloc] init];
        _videoPlayerController.delegate = self;
        _videoPlayerController.view.frame = self.view.bounds;
        
        NSString *path  = [[NSBundle mainBundle] pathForResource:@"24-video" ofType :@"mov"];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            
            NSURL *pathURL = [NSURL fileURLWithPath:path];
            
            _videoPlayerController.videoPath = [pathURL absoluteString];
        }
        // present
        [self addChildViewController:_videoPlayerController];
        [self.view addSubview:_videoPlayerController.view];
        [_videoPlayerController didMoveToParentViewController:self];
        [_videoPlayerController playFromBeginning];
        [_videoPlayerController setPlaybackLoops:FALSE];
        [_videoPlayerController.view setUserInteractionEnabled:FALSE];
        
        self._videoPlayerController = _videoPlayerController;
        
    }
}

- (void)videoPlayerPlaybackStateDidChange:(PBJVideoPlayerController *)videoPlayer
{
}

- (void)videoPlayerReady:(PBJVideoPlayerController *)videoPlayer
{
    //DLog(@"Max duration of the video: %f", videoPlayer.maxDuration);
}


- (void)videoPlayerPlaybackWillStartFromBeginning:(PBJVideoPlayerController *)videoPlayer
{

}

- (void) transtionToPlayView
{
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
    
    GetTo24ViewController *playView = [storyBoard instantiateViewControllerWithIdentifier:@"playView"];
    [self addChildViewController: playView];
    [self.view addSubview:playView.view];
    self._videoPlayerController.view.hidden = TRUE;
}

- (void)videoPlayerPlaybackDidEnd:(PBJVideoPlayerController *)videoPlayer
{
    NSArray *versionCompatibility = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];

    /// Don't play intro vieo for iOS 6.0
    if ( [self canPlayTransition] ) { /// iOS5 is installed
        [self transtionToPlayView];
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
