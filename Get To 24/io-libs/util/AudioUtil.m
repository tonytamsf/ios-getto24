#import "AudioUtil.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioServices.h>

@implementation AudioUtil

+(void)playSound:(NSString *)fName :(NSString *)ext
{
    NSString *path  = [[NSBundle mainBundle] pathForResource : fName ofType :ext];
    SystemSoundID audioEffect;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSLog(@"playing %@", fName);
        
        NSURL *pathURL = [NSURL fileURLWithPath:path];
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)pathURL, &audioEffect);
        AudioServicesPlaySystemSound(audioEffect);
    }
    
    else{
        NSLog(@"Error, file not found: %@",path);
    }
    
    
}

@end
