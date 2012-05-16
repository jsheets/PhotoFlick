// 
//  ImageSource.m
//  PhotoFrame
//
//  Created by John Sheets on 8/30/09.
//  Copyright 2009 MobileMethod, LLC. All rights reserved.
//

#import "PhotoSource.h"
#import "MMQBase.h"
#import "MMQSearchFlickr.h"
#import "MMQSearchHtml.h"
#import "SettingsViewController.h"
#import "SearchRunner.h"

@implementation PhotoSource 

@dynamic builtin;
@dynamic url;
@dynamic photoTitleXpath;
@dynamic photoBaseXpath;
@dynamic title;
@dynamic photoFileXpath;
@dynamic nextPage;
@dynamic photos;


+ (NSArray*)findPhotoSourceByUrl:(NSURL*)url inContext:(NSManagedObjectContext*)context
{
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:[NSEntityDescription entityForName:@"PhotoSource" inManagedObjectContext:context]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"url = '%s'", [url path]];
    [request setPredicate:predicate];
    
    NSError *error;
    NSArray *results = [context executeFetchRequest:request error:&error];
    if (results == nil)
    {
        FFTError(@"PHOTO SOURCE ERROR: %@", error);
    }
    return results;
}

// Factory to create a search op to add to the queue.
- (MMQBase*)searchOp
{
    if ([self.url isEqualToString:@"Favorites"])
    {
        FFTInfo(@"Don't need searchOp for builtin Favorites PhotoSource.");
        return nil;
    }
    
    MMQBase *op = nil;

    NSURL *url = [NSURL URLWithString:self.url];
    if ([url.host isEqual:@"flickr.com"])
    {
        SearchRunner *search = [[[SearchRunner alloc] init] autorelease];
        MMQSearchFlickr *flickrOp = [[[MMQSearchFlickr alloc] initWithPhotoSource:self username:search.searchUsername keyword:search.searchKeyword] autorelease];
        //flickrOp.searchText = search.searchKeyword;
        
        op = flickrOp;
    }
    else
    {
        op = [[[MMQSearchHtml alloc] initWithPhotoSource:self] autorelease];
    }
    return op;
}

@end
