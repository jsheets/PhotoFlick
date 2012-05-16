//
//  MMQSearchFlickr.m
//  PhotoFrame
//
//  Created by John Sheets on 12/6/09.
//  Copyright 2009 MobileMethod, LLC. All rights reserved.
//

#import "MMQSearchFlickr.h"
#import "FlickrAPIKey.h"
#import "DataManager.h"
#import "Photo.h"
#import "PhotoSource.h"

@implementation MMQSearchFlickr

// Flickr session constants.
static NSString *kQFlickrSearchPhotosKeyName = @"FlickrSearchPhotosKeyName";
static NSString *kQFlickrLookupUserKeyName = @"FlickrLookupUserKeyName";
static NSString *kQPageSize = @"200";
//const NSString *kQPageSize = @"25";

@synthesize context = _context;
@synthesize request = _request;
@synthesize photoSource = _photoSource;
@synthesize username = _username;
@synthesize keyword = _keyword;
@synthesize searchText = _searchText;
@synthesize searchWords = _searchWords;

- (id)initWithPhotoSource:(PhotoSource*)photoSource
                 username:(NSString*)username
                 keyword:(NSString*)keyword;
{	
    if (self = [super init])
    {
        // Initialization.
        self.photoSource = photoSource;
        self.username = username;
        self.keyword = keyword;
        FFTInfo(@"Creating Flickr op with user '%@' and keyword '%@'", username, keyword);
        _context = [[OFFlickrAPIContext alloc]
                    initWithAPIKey:OBJECTIVE_FLICKR_API_KEY
                    sharedSecret:OBJECTIVE_FLICKR_API_SHARED_SECRET];
        _request = [[OFFlickrAPIRequest alloc] initWithAPIContext:_context];
        [_request setDelegate:self];
    }
    
    return self;
}

- (void)dealloc
{
    FFTTrace(@"Deallocating Flickr op");
    if ([_request isRunning])
    {
        FFTTrace(@"Shutting down running Flickr request");
        [_request cancel];
    }
    [_context release], _context = nil;
    [_request release], _request = nil;
    [_photoSource release], _photoSource = nil;
    [_username release], _username = nil;
    [_keyword release], _keyword = nil;
    [_searchText release], _searchText = nil;
    [_searchWords release], _searchWords = nil;

    [super dealloc];
}


#pragma mark Private Service Implementation

- (void)flickrGetAny
{
    FFTInfo(@"Running flickr.photos.getRecent");
    _request.sessionInfo = kQFlickrSearchPhotosKeyName;
    
    NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:kQPageSize, @"per_page", nil];
    [_request callAPIMethodWithGET:@"flickr.photos.getRecent" arguments:args];
}

- (void)flickrLookupUser
{
    FFTInfo(@"Running flickr.people.findByUsername (username=%@; tags=%@)", self.username, self.keyword);
    _request.sessionInfo = kQFlickrLookupUserKeyName;
    
    // FIXME: Include keywords in search.
    NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:kQPageSize, @"per_page",
                          self.username, @"username", nil];
    [_request callAPIMethodWithGET:@"flickr.people.findByUsername" arguments:args];
}

- (void)flickrSearch:(NSString*)userId
{
    FFTInfo(@"Running flickr.photos.search with user_id: %@", userId);
    _request.sessionInfo = kQFlickrSearchPhotosKeyName;
    
    NSMutableDictionary *args = [NSMutableDictionary dictionaryWithObjectsAndKeys:kQPageSize, @"per_page", nil];
    if ([userId length] > 0)
    {
        [args setValue:userId forKey:@"user_id"];
    }
    if ([self.keyword length] > 0)
    {
        [args setValue:self.keyword forKey:@"tags"];
    }
    FFTInfo(@"Searching Flickr with params %@", args);
    [_request callAPIMethodWithGET:@"flickr.photos.search" arguments:args];
    
    self.username = nil;
    self.keyword = nil;
}

// Google-like searching on flickr.
- (void)flickrSearchText:(NSString *)searchText
{
    // Break the free-form search string into words.  Look up each one to
    // see if it's a username.  If we find a user name, use that.  Otherwise
    // treat all words as keywords.
    NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@" ,"];
    self.searchWords = [searchText componentsSeparatedByCharactersInSet:charSet];
    FFTInfo(@"FLICKR SEARCH WORDS: %@", self.searchWords);
    
}



#pragma mark Operation Main

- (void)startOperation
{
    // If any search args, use:
    //   flickr.photos.search
    //
    // If no search args, do global search with:
    //   flickr.photos.getRecent
    //
    // Other useful detail methods (maybe already covered?):
    //   flickr.photos.getInfo
    //   flickr.photos.getSizes
    
    FFTInfo(@"Running Flickr search with searchText='%@' username=%@, keyword=%@",
           self.searchText, self.username, self.keyword);
    if ([self.searchText length] > 0)
    {
        NSString *trimmed = [self.searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        [self flickrSearchText:trimmed];
    }
    else if ([self.username length] == 0 && [self.keyword length] == 0)
    {
        // Username and keyword fields are both empty.
        [self flickrGetAny];
    }
    else if ([self.username length] == 0)
    {
        // Have something in keyword field; username is blank.
        [self flickrSearch:@""];
    }
    else
    {
        // Have something in username field; might also have keyword.
        [self flickrLookupUser];
    }
}


#pragma mark Flickr Protocol

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest
 didCompleteWithResponse:(NSDictionary *)inResponseDictionary
{
    FFTDebug(@"Completed request: %@", inRequest.sessionInfo);
    FFTTrace(@"Completed request: %@", inResponseDictionary);
    FFTInfo(@"Completed request");
    
    if (inRequest.sessionInfo == kQFlickrLookupUserKeyName)
    {
        // Looked up user id.
        NSString *userId = [inResponseDictionary valueForKeyPath:@"user.id"];
        [self flickrSearch:userId];
    }
    else
    {
        // Parse out photo URLs from ObjectiveFlickr dict.
        NSInteger nextPos = [self.dataManager nextUrlPathPosition];

        NSArray *flickrPhotos = [inResponseDictionary valueForKeyPath:@"photos.photo"];

        for (NSDictionary *flickrPhoto in flickrPhotos)
        {
            FFTTrace(@"Photo metadata: %@", flickrPhoto);
            NSURL *photoUrl = [_context photoSourceURLFromDictionary:flickrPhoto size:OFFlickrMediumSize];
            
            NSString *title = [flickrPhoto valueForKey:@"title"];
            NSString *urlString = [photoUrl absoluteString];

            UrlPath *urlPath = [self.dataManager createUrlPath:urlString title:title];
            if (urlPath)
            {
                FFTTrace(@"Flickr adding UrlPath: %@", urlPath);
                urlPath.position = [NSNumber numberWithInteger:nextPos++];
            }
            else
            {
                FFTCritical(@"Already loaded URL: %@", urlString);
            }
        }
        [self.dataManager saveContext];
        
        [self completeOperation];
    }
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest
        didFailWithError:(NSError *)inError
{
    FFTError(@"FLICKR ERROR: failed request %@", inError);
    [self completeOperation];
}

@end
