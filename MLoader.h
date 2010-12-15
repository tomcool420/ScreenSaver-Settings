//
//  MLoader.h
//  MextLoader
//
//  Created by Thomas Cool on 10/22/10.
//  Copyright 2010 tomcool.org. All rights reserved.
//
#import <SMFramework/SMFramework.h>
#define PreferenceLocation @"/Library/MainMenuExtensions"
#import <Foundation/Foundation.h>
@protocol SettingPreferences
+(NSString *)displayName;
-(NSString *)displayName;
+(BRMenuController *)settingsController;
@optional
-(NSString *)summary;
-(BRImage *)art;
@end



@interface ScreensaverCustomSettings : NSObject<SettingPreferences> {
    
}
+(NSString *)displayName;
-(NSString *)displayName;
+(BRMenuController *)settingsController;
@end

@interface ScreensaverCustomSettingsController : SMFMediaMenuController<SMFFolderBrowserDelegate>
{
    NSArray * _screensavers;
    NSArray * _bookmarks;
}
-(BOOL)hasActionForFile:(NSString *)path;
-(void)executeActionForFile:(NSString *)path;
-(void)executePlayPauseActionForFile:(NSString *)path;
@end
@interface ScreensaverCustomFolderDelegateController : SMFMediaMenuController
{
    NSArray  *_bookmarks;
    NSString *_folder;
}
-(id)initWithPath:(NSString *)path;
@end