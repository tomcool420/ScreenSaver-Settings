//
//  MLoader.m
//  MextLoader
//
//  Created by Thomas Cool on 10/22/10.
//  Copyright 2010 tomcool.org. All rights reserved.
//
#import "MLoader.h"
#import <BackRow/BackRow.h>
#import <AppleTV/ATVScreensaverManager.h>
#import <AppleTV/ATVSettingsFacade.h>

#define PREFS  [ScreensaverCustomSettings preferences]
#define BC     [_bookmarks count]
#define SC     [_screensavers count]

static NSString * const kBookmarksArray                = @"Bookmarks";
static NSString * const kCustomEnabledBool             = @"Enabled";
static NSString * const kCustomFolderString            = @"Folder";


static NSString * const kScreenSaverFolder             = @"/Applications/Lowtide.app/Screen Savers/";
static NSString * const kSlideshowScreensaver          = @"Slideshow.frss";
static NSString * const kPhotoScreensaver              = @"Photo.frss";

static NSString * const kFloatingScreensaverTheme      = @"Floating";

static NSString * _selectedScreenSaver                 = nil;
static NSString * _selectedScreenSaverBundle           = nil;

@implementation ScreensaverCustomSettings
+(NSString *)displayName    { return @"Screensaver Settings"; }
-(NSString *)displayName    { return [ScreensaverCustomSettings displayName]; }
-(NSString *)summary        { return @"Custom Screensaver Settings"; }
+(BRImage *)image
{
    return[BRImage imageWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"screensaver" ofType:@"png"]];
}
+(BRPhotoMediaAsset *)assetForPath:(NSString *)pathToPhoto
{

        BRPhotoMediaAsset * asset = [[BRPhotoMediaAsset alloc] init];
        [asset setFullURL:pathToPhoto];
        [asset setThumbURL:pathToPhoto];
        [asset setCoverArtURL:pathToPhoto];
        [asset setIsLocal:YES];
        return [asset autorelease];
}
-(BRImage *)art
{
    return [ScreensaverCustomSettings image];
}
+(BRMenuController *)settingsController
{
    
    ScreensaverCustomSettingsController *m = [[ScreensaverCustomSettingsController alloc]init];
    return [m autorelease];
}
+(SMFPreferences *)preferences {
    static SMFPreferences *_preferences = nil;
    
    if(!_preferences)
    {
        _preferences = [[SMFPreferences alloc] initWithPersistentDomainName:@"org.tomcool.Screensaver"];
        [_preferences registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:NO],kCustomEnabledBool,
                                        [NSArray arrayWithObjects:@"/var/root",nil],kBookmarksArray,
                                        @"/var/root",kCustomFolderString,
                                        nil]];
    }
        
    
    return _preferences;
}

@end

enum {
    kScreensaverEnableToggle=0,
//    kScreensaverTimeout,
    kScreensaverSelectFolder,
    kScreensaverPreview,
    kScreensaverOptions,
        
};
enum  {
    kScreensaverTimeout=100
};
@implementation ScreensaverCustomSettingsController
-(void)reload
{
    [_bookmarks release];
    _bookmarks = [[PREFS objectForKey:kBookmarksArray] retain];
    [_selectedScreenSaver release];
    _selectedScreenSaver       = [[[ATVSettingsFacade singleton]screenSaverSlideshowTheme] retain];
    [_selectedScreenSaverBundle release];
    _selectedScreenSaverBundle = [[[[ATVSettingsFacade singleton]screenSaverSelectedPath] lastPathComponent] retain];
    
    [[self list]removeDividers];
    [[self list]addDividerAtIndex:(kScreensaverOptions) withLabel:@"Bookmarks"];
    [[self list]addDividerAtIndex:(kScreensaverOptions + [_bookmarks count]) withLabel:@"Screensavers"];
    [[self list]reload];
}
-(id)previewControlForItem:(long)item
{
    if (item<kScreensaverOptions) {
        SMFBaseAsset *asset = [[SMFBaseAsset alloc] init];
        switch (item) {
            case kScreensaverEnableToggle:
                [asset setTitle:@"Custom ScreenSavers"];
                [asset setSummary:@"Enables the use of folders in /var/root to be used as screensavers"];
                break;
            case kScreensaverSelectFolder:
                [asset release];
                return [[BRMediaPreviewControlFactory factory] previewControlForAssets:[SMFPhotoMethods mediaAssetsForPath:[PREFS objectForKey:kCustomFolderString]]];
                break;
            case kScreensaverTimeout:
                [asset setTitle:@"ScreenSaver Timeout"];
                //[asset setSummary:@"T"];
            case kScreensaverPreview:
                [asset setTitle:@"Start ScreenSaver"];
                break;
            default:
                break;
        }
        //[asset setCoverArt:[[SMFThemeInfo sharedTheme]btstackIcon]];
        [asset setCoverArt:[BRImage imageWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"screensaver" ofType:@"png"]]];
        SMFMediaPreview *p = [[SMFMediaPreview alloc] init];
        [p setShowsMetadataImmediately:YES];
        [p setAsset:asset];
        [asset release];
        return [p autorelease];
    }
    else if(item<(kScreensaverOptions+BC))
    {
        return [[BRMediaPreviewControlFactory factory] previewControlForAssets:[SMFPhotoMethods mediaAssetsForPath:[_bookmarks objectAtIndex:(item-kScreensaverOptions)]]];
    }
    return [[BRMediaPreviewControlFactory factory]previewControlForAsset:[ScreensaverCustomSettings assetForPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"screensaver" ofType:@"png"]]];

    
}
- (long)itemCount							
{ 
    return (kScreensaverOptions+SC+BC);
}
- (id)itemForRow:(long)row					
{ 
    if (row<kScreensaverOptions) 
    {
        switch (row) {
            case kScreensaverEnableToggle:
            {
                SMFMenuItem *it = [SMFMenuItem menuItem];
                [it setTitle:@"Custom Screensaver"];
                [it setRightText:([[PREFS objectForKey:kCustomEnabledBool] boolValue]?@"Enabled":@"Disabled")];
                return it;
                break;
            }
            case kScreensaverPreview:
            {
                SMFMenuItem *it = [SMFMenuItem menuItem];
                [it setTitle:@"Preview Screensaver"];
                return it;
                break;
            }
            case kScreensaverTimeout:
            {
                SMFMenuItem *it = [SMFMenuItem menuItem];
                [it setTitle:@"Screensaver Timeout"];
                int time = [[ATVSettingsFacade singleton] screenSaverTimeout];
                if (time==-1) {
                    [it setRightText:@"Never"];
                }
                else
                    [it setRightText:[NSString stringWithFormat:@"%d min",time,nil]];
                return it;
            }
            case kScreensaverSelectFolder:
            {
                SMFMenuItem *it = [SMFMenuItem menuItem];
                [it setTitle:@"Select Folder"];
                [it setRightText:[[PREFS objectForKey:kCustomFolderString] lastPathComponent]];
                return it;
                break;
            }
            default:
                break;
        }
        
        
    }
    else if (row < (kScreensaverOptions+BC))
    {
        SMFMenuItem *bookmark = [SMFMenuItem menuItem];
        row = row-kScreensaverOptions;
        if ([[_bookmarks objectAtIndex:row] isEqualToString:[PREFS objectForKey:kCustomFolderString]]) {
            [bookmark setImage:[[SMFThemeInfo sharedTheme]selectedImage]];
        }
        [bookmark setTitle:[_bookmarks objectAtIndex:row]];
        return bookmark;
    }
    else if (row < (SC+kScreensaverOptions+BC))
    {
        SMFMenuItem *screensaver = [SMFMenuItem menuItem];
        row = row-kScreensaverOptions-BC;
        if ([_selectedScreenSaverBundle isEqualToString:kPhotoScreensaver] &&
            [[_screensavers objectAtIndex:row] isEqualToString:kFloatingScreensaverTheme]) {
            [screensaver setImage:[[SMFThemeInfo sharedTheme]selectedImage]];
        }
        else if([_selectedScreenSaverBundle isEqualToString:kSlideshowScreensaver])
        {
            if([[_screensavers objectAtIndex:row] isEqualToString:_selectedScreenSaver])
                [screensaver setImage:[[SMFThemeInfo sharedTheme]selectedImage]];
        }
        
        [screensaver setTitle:[_screensavers objectAtIndex:row]];
        return screensaver;
    }
    return nil;
}

- (id)titleForRow:(long)row	{ return [[self itemForRow:row] text]; }
+ (NSString *)rootMenuLabel {return @"org.tomcool.ScreensaverCustom";}

-(id)init
{
    if ((self = [super init])!=nil) {
        [self setLabel:@"org.tomcool.ScreensaverCustom"];
        _screensavers = [[NSArray arrayWithObjects:@"Random",kFloatingScreensaverTheme,@"Reflections",@"Origami",@"Snapshots",@"Ken Burns",@"Classic",nil] retain];
        _bookmarks = [[PREFS objectForKey:kBookmarksArray] retain];
        _selectedScreenSaver       = [[[ATVSettingsFacade singleton]screenSaverSlideshowTheme] retain];
        _selectedScreenSaverBundle = [[[[ATVSettingsFacade singleton]screenSaverSelectedPath] lastPathComponent] retain];
        [self setListTitle:@"Screensaver Settings"];
        [[self list]addDividerAtIndex:(kScreensaverOptions) withLabel:@"Bookmarks"];
        [[self list]addDividerAtIndex:(kScreensaverOptions + [_bookmarks count]) withLabel:@"Screensavers"];
        
    }
    return self;
}
-(void)itemSelected:(long)selected
{
    if (selected<kScreensaverOptions) 
    {
        switch (selected) {
            case kScreensaverEnableToggle:
            {
                BOOL old = [[PREFS objectForKey:kCustomEnabledBool] boolValue];
                [PREFS setObject:[NSNumber numberWithBool:!old] forKey:kCustomEnabledBool];
                [self reload];
                break;
            }
                
            case kScreensaverSelectFolder:
            {
                SMFFolderBrowser *b = [[SMFFolderBrowser alloc] initWithPath:@"/var/root"];
                [b setDelegate:self];
                [[self stack] pushController:[b autorelease]];
                break;
            }
            case kScreensaverTimeout:
            {
                SMFPasscodeController *p = [SMFPasscodeController passcodeWithTitle:@"ScreenSaver Timeout" 
                                                                    withDescription:@"Please Select Screensaver Timeout Duration in minutes (0 means never)"
                                                                          withBoxes:4 
                                                                       withDelegate:self];
                [p setInitialValue:[[ATVSettingsFacade singleton]screenSaverTimeout]];
                [[self stack]pushController:p];
                break;
            }
            case kScreensaverPreview:
            {
                [[ATVScreenSaverManager singleton] showScreenSaver];
                break;
            }
            default:
                break;
        }
    }
    else if (selected < (kScreensaverOptions+BC))
    {
        selected = selected-kScreensaverOptions;
        [PREFS setObject:[_bookmarks objectAtIndex:selected] forKey:kCustomFolderString];
    }
    else if (selected < (SC+kScreensaverOptions+BC))
    {
        selected = selected-kScreensaverOptions-BC;

        NSString *title = [_screensavers objectAtIndex:selected];
        NSString *base = kScreenSaverFolder;
        if (![[[ATVSettingsFacade singleton] versionOS] isEqualToString:@"4.1"]) 
            base = [base stringByReplacingOccurrencesOfString:@"Lowtide" withString:@"AppleTV"];
        
        if ([title isEqualToString:kFloatingScreensaverTheme]) {

            [[ATVSettingsFacade singleton] setScreenSaverSlideshowTheme:nil];
            [[ATVSettingsFacade singleton] setScreenSaverSelectedPath:[base stringByAppendingPathComponent:kPhotoScreensaver]];
        }
        else {
            [[ATVSettingsFacade singleton] setScreenSaverSlideshowTheme:title];
            [[ATVSettingsFacade singleton] setScreenSaverSelectedPath:[base stringByAppendingPathComponent:kSlideshowScreensaver]];
        }
        
    }
    [self reload];
}
-(void)dealloc
{
    [_screensavers release];
    _screensavers=nil;
    [_selectedScreenSaver release];
    _selectedScreenSaver=nil;
    [_selectedScreenSaverBundle release];
    _selectedScreenSaverBundle=nil;
    [_bookmarks release];
    _bookmarks=nil;
    [super dealloc];
}
-(void)wasExhumed
{
    [self reload];
}
#pragma mark SMFPasscodeController delegate methods
- (void) textDidChange: (id) sender
{
}

- (void) textDidEndEditing: (id) sender
{
    int val  = [[sender stringValue] intValue];
    if (val==0) 
        val=-1;
    [[ATVSettingsFacade singleton]setScreenSaverTimeout:val];
    [self reload];
    [[self stack] popController];	
}
#pragma mark SMFFolderBrowser delegate methods
-(BOOL)hasActionForFile:(NSString *)path
{
    BOOL isDir=NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]&&isDir) {
        return YES;
    }
    return NO;
    
}
-(void)executeActionForFile:(NSString *)path
{
    
    BOOL isDir=NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]&&isDir) {
        ScreensaverCustomFolderDelegateController * ctrl = [[ScreensaverCustomFolderDelegateController alloc] initWithPath:path];
        [[[BRApplicationStackManager singleton] stack] pushController:ctrl];
    }
    
}
-(void)executePlayPauseActionForFile:(NSString *)path
{
    BOOL isDir=NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]&&isDir) {
        [PREFS setObject:path forKey:kCustomFolderString];
        [[self stack]popToController:self];
    }
}
@end
enum {
    kScreensaverDelSet=0,
    kScreensaverDelAdd_Rem,
    kScreensaverDelSlideshow,
    kScreensaverDelOptions
};
@implementation ScreensaverCustomFolderDelegateController
-(id)previewControlForItem:(long)item
{
    return [[BRMediaPreviewControlFactory factory] previewControlForAsset:[[SMFPhotoMethods mediaAssetsForPath:_folder]objectAtIndex:0]];
}
-(void)reload
{
    [_bookmarks release];
    _bookmarks=[[PREFS objectForKey:kBookmarksArray] retain];
    [[self list]reload];
}
-(id)initWithPath:(NSString *)path
{
    self=[super init];
    if (self!=nil) {
        [self setListTitle:[path lastPathComponent]];
        _bookmarks=[[PREFS objectForKey:kBookmarksArray] retain];
        _folder=[path retain];
    }
    return self;
}
-(long)itemCount {return kScreensaverDelOptions;}
-(void)itemSelected:(long)selected
{
    switch (selected) {
        case kScreensaverDelSet:
        {
            BOOL isDir=NO;
            if ([[NSFileManager defaultManager] fileExistsAtPath:_folder isDirectory:&isDir]&&isDir) {
                [PREFS setObject:_folder forKey:kCustomFolderString];
                [[self stack]popToControllerWithLabel:@"org.tomcool.ScreensaverCustom"];
            }
            
            break;
        }
        case kScreensaverDelAdd_Rem:
        {
            BOOL isDir=NO;
            if ([[NSFileManager defaultManager] fileExistsAtPath:_folder isDirectory:&isDir]&&isDir) 
            {
                NSMutableArray * a = [_bookmarks mutableCopy];
                if ([_bookmarks containsObject:_folder])
                    [a removeObject:_folder];
                else
                    [a addObject:_folder];
                [PREFS setObject:a forKey:kBookmarksArray];
            } 
            break;
        }
        case kScreensaverDelSlideshow:
        {
            BRDataStore *store = [SMFPhotoMethods dataStoreForPath:_folder];
            BRPhotoControlFactory* controlFactory = [BRPhotoControlFactory standardFactory];
            SMFPhotoCollectionProvider* provider    = [SMFPhotoCollectionProvider providerWithDataStore:store controlFactory:controlFactory];
            id controller_three = [BRFullScreenPhotoController fullScreenPhotoControllerForProvider:provider/*[self provider]*/ startIndex:0];
            [[self stack] pushController:controller_three];
            [controller_three _startSlideshow];
            break;
            
        }

        default:
            break;
    }
    [self reload];
}
-(void)dealloc
{
    [_folder release];
    [_bookmarks release];
    [super dealloc];
}
-(id)titleForRow:(long)row	{ return [[self itemForRow:row] text]; }
-(id)itemForRow:(long)row
{
    SMFMenuItem *it = [SMFMenuItem menuItem];
    switch (row) {
        case 0:
        {
            
            [it setTitle:@"Set as Screensaver Folder"];
            break;
        }
        case kScreensaverDelAdd_Rem:
        {
            if ([_bookmarks containsObject:_folder])
                [it setTitle:@"Remove from Bookmarks"];
            else
                [it setTitle:@"Add to Bookmarks"];
            break;
        }
        case kScreensaverDelSlideshow:
        {
            [it setTitle:@"Present Slideshow"];
            break;
        }
        default:
            break;
    }
    return it;
}
@end