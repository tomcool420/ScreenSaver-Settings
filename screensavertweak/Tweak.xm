/* How to Hook with Logos
Hooks are written with syntax similar to that of an Objective-C @implementation.
You don't need to #include <substrate.h>, it will be done automatically, as will
the generation of a class list and an automatic constructor.

%hook ClassName

// Hooking a class method
+ (id)sharedInstance {
	return %orig;
}

// Hooking an instance method with an argument.
- (void)messageName:(int)argument {
	%log; // Write a message about this call, including its class, name and arguments, to the system log.

	%orig; // Call through to the original function with its original arguments.
	%orig(nil); // Call through to the original function with a custom argument.

	// If you use %orig(), you MUST supply all arguments (except for self and _cmd, the automatically generated ones.)
}

// Hooking an instance method with no arguments.
- (id)noArguments {
	%log;
	id awesome = %orig;
	[awesome doSomethingElse];

	return awesome;
}

// Always make sure you clean up after yourself; Not doing so could have grave conseqeuences!
%end
*/
#import <Foundation/Foundation.h>
#import <SMFramework/SMFramework.h>
//#import "/opt/theos/include/BackRow/BackRow.h"
#include <substrate.h>
static SMFPreferences *_prefs = nil;

%group ScreensaverHooks
%hook RUISlideShowControl
//-(void)_providerUpdated:(id)updated
//{
//    %orig;
//}
-(void)_startSlideshowWithCollection:(id)collection
{
    [_prefs synchronize];
    if([[_prefs objectForKey:@"Enabled"]boolValue])
    {
        id col = [SMFPhotoMethods photoCollectionForPath:[_prefs objectForKey:@"Folder"]];
        %orig(col);
    }
    else 
        %orig;
}
%end

%end
%hook ATVSettingsFacade
-(void)setScreenSaverSlideshowTheme:(id)theme
{
    %log;
    %orig;
}
-(void)setScreenSaverSelectedPath:(id)path
{
    %log;
    %orig;
}
-(void)setScreenSaverSecondsPerSlide:(int)val	// G=0x338fae2d; S=0x338fadf1; converted property
{
    %log;
    %orig;
}
-(void)setScreenSaverShufflePhotos:(BOOL)val	// G=0x338facdd; S=0x338faca1; converted property
{
    %log;
    %orig;
}
-(void)setScreenSaverTimeout:(int)val	// G=0x338fb111; S=0x338fb055; converted property
{
    %log;
    %orig;
}
-(void)setScreenSaverTransition:(id)trans	// G=0x338fac45; S=0x338fac09; converted property
{
    %log;
    %orig;
}
-(void)setSleepTimeout:(int)timeout
{
    %log;
    %orig;
}
%end
%hook ATVScreenSaverArchiver
+ (id)_providerForCollection:(id)collection
{
    %log;
    if([[_prefs objectForKey:@"Enabled"]boolValue])
    {
        BRDataStore *store = [SMFPhotoMethods dataStoreForPath:[_prefs objectForKey:@"Folder"]];
        BRPhotoControlFactory* controlFactory = [BRPhotoControlFactory standardFactory];
        SMFPhotoCollectionProvider* provider    = [SMFPhotoCollectionProvider providerWithDataStore:store controlFactory:controlFactory];//[[ATVSettingsFacade sharedInstance] providerForScreenSaver];//[collection provider];
        return provider;
    }
    else 
        return %orig;
}
%end
%hook NSBundle

- (BOOL)load 
{
	BOOL orig = %orig;
	
	if (orig) {
        

		if ([[[self bundlePath]lastPathComponent] isEqualToString:@"Slideshow.frss"]) 
        {
//            NSBundle *b = [NSBundle bundleWithPath:@"/Library/SettingsBundles/ScreensaverSettings.bundle"];
//            if(![b isLoaded])
//                [b load];
//            _prefs = [[b principalClass] preferences];
//            NSLog(@"Initializing Prefs, %@,%@",b,_prefs);
			%init(ScreensaverHooks);
		}
	}
    
	return orig;
}

%end


static __attribute__((constructor)) void ScreensaverHooksInit() {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	%init;
	[pool drain];
}


MSInitialize{
    NSLog(@"Initialize Tweak");
    NSAutoreleasePool * p =[[NSAutoreleasePool alloc]init];
    NSBundle *b = [NSBundle bundleWithPath:@"/Library/SettingsBundles/ScreensaverSettings.bundle"];
    if(![b isLoaded])
        [b load];
    _prefs = [[b principalClass] preferences];
    NSLog(@"Initializing Prefs, %@,%@",b,_prefs);
    [p release];

}
