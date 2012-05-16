//
//  DataManager.m
//  PhotoFrame
//
//  Created by John Sheets on 9/27/09.
//  Copyright 2009 MobileMethod, LLC. All rights reserved.
//

#import "DataManager.h"
#import "PhotoFlickAppDelegate.h"
#import "UrlPath.h"

@implementation DataManager

@synthesize photoSources = _photoSources;

- (void)dealloc
{
    [_photoSources release], _photoSources = nil;
    [_managedObjectModel release], _managedObjectModel = nil;
    [_managedObjectContext release], _managedObjectContext = nil;
    [_persistentStoreCoordinator release], _persistentStoreCoordinator = nil;
    
    [super dealloc];
}


- (void)logError:(NSError*)error
{
    FFTError(@"============================================================");
    FFTError(@"CORE DATA ERROR: %@\n\n", [error localizedDescription]);
    NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
    if(detailedErrors != nil && [detailedErrors count] > 0)
    {
        for(NSError* detailedError in detailedErrors)
        {
            FFTError(@"  DetailedError: %@", [detailedError userInfo]);
        }
    }
    else
    {
        FFTError(@"  %@", [error userInfo]);
    }
    FFTError(@"============================================================");
}


#pragma mark -
#pragma mark Core Data Management
#pragma mark -

- (NSString *)applicationDirectory
{
    PhotoFlickAppDelegate *delegate = (PhotoFlickAppDelegate*)[[UIApplication sharedApplication] delegate];
    NSString *appDir = [delegate applicationDocumentsDirectory];
    FFTDebug(@"APP DIR: %@", appDir);
    return appDir;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created by merging all of the
 models found in the application bundle.
 */
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil)
    {
        return _managedObjectModel;
    }
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Slideshow" ofType:@"momd"];
    NSURL *momURL = [NSURL fileURLWithPath:path];
    FFTInfo(@"CORE DATA: Initializing NSManagedObjectModel from %@", momURL);
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];
    
    return _managedObjectModel;
}


/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the
 application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil)
    {
        return _persistentStoreCoordinator;
    }
	
    FFTDebug(@"CORE DATA: Initializing NSPersistentStoreCoordinator");
    NSURL *storeUrl = [NSURL fileURLWithPath: [[self applicationDirectory] stringByAppendingPathComponent: @"SlideShow.sqlite"]];
	
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                            [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];

	NSError *error;
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error])
    {
        // Could copy over a template database, but for now, just bail with error.
        FFTError(@"CORE DATA ERROR: Unable to add persistent store for database: %@", storeUrl);
    }    
	
    return _persistentStoreCoordinator;
}

// Create a new (non-cached) Core Data context.
- (NSManagedObjectContext *) newManagedObjectContext
{
    NSManagedObjectContext *context = nil;

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
    {
        FFTDebug(@"CORE DATA: Initializing NSManagedObjectContext");
        context = [[NSManagedObjectContext alloc] init];
        [context setPersistentStoreCoordinator: coordinator];
    }

    return context;
}

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound
 to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *) managedObjectContext
{
    if (_managedObjectContext != nil)
    {
        return _managedObjectContext;
    }

	_managedObjectContext = [self newManagedObjectContext];
    return _managedObjectContext;
}

- (BOOL)saveContext
{
    BOOL succeeded = YES;
    NSError *error;
    if ([self.managedObjectContext hasChanges] && ![self.managedObjectContext save:&error])
    {
		// Handle the error...
        succeeded = NO;
        [self logError:error];
    }
    
    return succeeded;
}

- (NSArray *)findAllOf:(NSString *)entityName
{
    NSFetchRequest *fetch = [[[NSFetchRequest alloc] init] autorelease];
    [fetch setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:self.managedObjectContext]];
    return [self.managedObjectContext executeFetchRequest:fetch error:nil];
}


#pragma mark -
#pragma mark Core Data PhotoSource Helper Methods
#pragma mark -

- (PhotoSource*)createPhotoSourceWithTitle:(NSString *)title andUrl:(NSString *)url
{
    PhotoSource* photoSource = [NSEntityDescription insertNewObjectForEntityForName:@"PhotoSource" inManagedObjectContext:self.managedObjectContext];

    photoSource.title = title;
    photoSource.url = url;

    FFTInfo(@"Created PhotoSource: %@", photoSource);
    return photoSource;
}


// Empty database; populate with Flickr and Ffffound.
// FIXME: Should always attempt this, to ensure they always exist.
- (NSArray *)initializePhotoSources
{
    // FIXME: Should these be loaded from a plist?
    
    FFTDebug(@"Initializing STORE with two new entities");
    PhotoSource *flickr = [self createPhotoSourceWithTitle:@"Flickr" andUrl:@"http://flickr.com"];
    flickr.builtin = [NSNumber numberWithBool:YES];
    
    PhotoSource *ffffound = [self createPhotoSourceWithTitle:@"Ffffound" andUrl:@"http://ffffound.com"];
    ffffound.builtin = [NSNumber numberWithBool:YES];
    ffffound.photoBaseXpath = @"//img/@src | //a/@href";
    ffffound.photoFileXpath = @"";
    ffffound.photoTitleXpath = @"";
    
    PhotoSource *favorites = [self createPhotoSourceWithTitle:@"Favorites" andUrl:@"Favorites"];
    favorites.builtin = [NSNumber numberWithBool:YES];
    
    NSError *error;
    if (![self.managedObjectContext save:&error])
    {
        FFTError(@"Unable to save built-in data source %@", error);
    }
    
    return [NSArray arrayWithObjects:flickr, ffffound, nil];
}

- (PhotoSource*)findPhotoSourceByPath:(NSString *)path
{
    FFTDebug(@"Finding PhotoSource by path: %@", path);
    PhotoSource *source = nil;
    
    for (PhotoSource *src in self.photoSources)
    {
        if ([src.url isEqual:path])
        {
            source = src;
            break;
        }
    }
    return source;
}

- (PhotoSource *)flickrPhotoSource
{
    return [self findPhotoSourceByPath:@"http://flickr.com"];
}

- (PhotoSource *)ffffoundPhotoSource
{
    return [self findPhotoSourceByPath:@"http://ffffound.com"];
}

- (PhotoSource *)favoritesPhotoSource
{
    return [self findPhotoSourceByPath:@"Favorites"];
}


- (NSArray*)photoSources
{
    if (_photoSources == nil)
    {
        _photoSources = [[NSMutableArray alloc] init];
        
        // Look up all photo sources.
        FFTDebug(@"Looking up all photo sources");
        NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
        [request setEntity:[NSEntityDescription entityForName:@"PhotoSource" inManagedObjectContext:self.managedObjectContext]];

        // Sort by title.
        NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES] autorelease];
        NSArray *sortDescriptors = [[[NSArray alloc] initWithObjects:sortDescriptor, nil] autorelease];
        [request setSortDescriptors:sortDescriptors];
        
        NSArray *sources;
        NSError *error;
        sources = [self.managedObjectContext executeFetchRequest:request error:&error];
        if (sources && [sources count])
        {
            FFTInfo(@"Found %i photo sources", [sources count]);
        }
        else
        {
            //if (error) FFTError(@"IMAGE SOURCE ERROR %@", error);
            FFTInfo(@"No photo sources found; loading default set...");
            sources = [self initializePhotoSources];
        }
        if (sources) [_photoSources addObjectsFromArray:sources];
    }
    
    return _photoSources;
}

- (PhotoSource*)loadPhotoSourceByPath:(NSString *)path
{
    PhotoSource *source = [self findPhotoSourceByPath:path];
    if (!source)
    {
        // None found.  Allocate a new one.
        FFTInfo(@"No PhotoSource exists for this URL; creating new PhotoSource for URL %@", path);
        source = [self createPhotoSourceWithTitle:path andUrl:path];
        source.builtin = [NSNumber numberWithBool:YES];
        source.photoBaseXpath = @"//img/@src | //a/@href";
        source.photoFileXpath = @"";
        source.photoTitleXpath = @"";
        
        // Add to local source array.
        [_photoSources addObject:source];
        
        [self saveContext];
    }
    
    return source;
}

- (void)deletePhotoSourceForPath:(NSString *)path
{
    PhotoSource *source = [self findPhotoSourceByPath:path];
    if (source)
    {
        [self.managedObjectContext deleteObject:source];
        [self saveContext];
    }
}

- (NSArray *)allCustomPhotoSources:(BOOL)forceReload
{
    if (forceReload)
    {
        // Force reload, since we'll be adding these dynamically.
        _photoSources = nil;
    }

    NSArray *allPhotoSources = self.photoSources;
    NSMutableArray *customSources = [NSMutableArray array];
    
    for (PhotoSource* photoSource in allPhotoSources)
    {
        if ([photoSource.title hasPrefix:@"http"])
        {
            [customSources addObject:photoSource];
        }
    }
    
    return customSources;
}


#pragma mark -
#pragma mark Core Data UrlPath Helper Methods

- (BOOL)urlPathExists:(NSString *)remoteUrl
{
    BOOL exists = NO;

    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:[NSEntityDescription entityForName:@"UrlPath" inManagedObjectContext:self.managedObjectContext]];
    request.predicate = [NSPredicate predicateWithFormat:@"remoteUrl = %@", remoteUrl];
    request.fetchLimit = 1;
    
    NSError *error = nil;
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (error)
    {
        FFTError(@"Database Error finding UrlPath: %@", error);
    }
    else if ([results count] > 0)
    {
        exists = YES;
    }

    return exists;
}

- (UrlPath *)createUrlPath:(NSString *)remoteUrl title:(NSString *)title
{
    UrlPath *urlPath = nil;
    if (![self urlPathExists:remoteUrl])
    {
        urlPath = [NSEntityDescription insertNewObjectForEntityForName:@"UrlPath"
                                                inManagedObjectContext:self.managedObjectContext];
        urlPath.remoteUrl = remoteUrl;
        urlPath.title = title;
    }

    return urlPath;
}

- (NSInteger)nextUrlPathPosition
{
    NSInteger position = 0;
    
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setResultType:NSDictionaryResultType];
    
    [request setEntity:[NSEntityDescription entityForName:@"UrlPath" inManagedObjectContext:self.managedObjectContext]];
    
    NSExpression *keyPath = [NSExpression expressionForKeyPath:@"position"];
    NSExpression *max = [NSExpression expressionForFunction:@"max:" arguments:[NSArray arrayWithObject:keyPath]];
    
    // The name is the key that will be used in the dictionary for the return value.
    NSExpressionDescription *expressionDescription = [[[NSExpressionDescription alloc] init] autorelease];
    [expressionDescription setName:@"maxPosition"];
    [expressionDescription setExpression:max];
    [expressionDescription setExpressionResultType:NSInteger32AttributeType];
    [request setPropertiesToFetch:[NSArray arrayWithObject:expressionDescription]];
    
    NSError *error;
	NSArray *objects = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (objects && [objects count] > 0)
    {
        NSNumber *maxPosition = [[objects objectAtIndex:0] valueForKey:@"maxPosition"];
        position = [maxPosition integerValue] + 1;
    }
    return position;
}

// Grab the UrlPath with the lowest position, then remove it from the database.
- (UrlPath *)popNextUrlPath
{
    UrlPath *urlPath = nil;

    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:[NSEntityDescription entityForName:@"UrlPath" inManagedObjectContext:self.managedObjectContext]];
    request.fetchLimit = 1;
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isDownloaded = NO"];
    request.predicate = predicate;

    // Sort by title.
    NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"position" ascending:YES] autorelease];
    NSArray *sortDescriptors = [[[NSArray alloc] initWithObjects:sortDescriptor, nil] autorelease];
    [request setSortDescriptors:sortDescriptors];
    
    NSError *error = nil;
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (error)
    {
        FFTError(@"Database Error finding next UrlPath: %@", error);
    }
    else if ([results count] > 0)
    {
        urlPath = [[[results objectAtIndex:0] retain] autorelease];
//        urlPath = [[results objectAtIndex:0] retain];
        FFTDebug(@"Next UrlPath: %@", urlPath.remoteUrl);
        urlPath.isDownloaded = [NSNumber numberWithBool:YES];
        [self saveContext];
    }
    else
    {
        FFTInfo(@"No UrlPath found");
    }

    return urlPath;
}

- (BOOL)hasAvailableUrlPaths
{
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:[NSEntityDescription entityForName:@"UrlPath" inManagedObjectContext:self.managedObjectContext]];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isDownloaded = NO"];
    request.predicate = predicate;

    NSError *error = nil;
    NSUInteger count = [self.managedObjectContext countForFetchRequest:request error:&error];

    return (count > 0);
}

- (void)deleteAllUrlPaths
{
    NSArray *urlPaths = [self findAllOf:@"UrlPath"];
    for (UrlPath *urlPath in urlPaths)
    {
        if (![urlPath isDeleted])
        {
            [self.managedObjectContext deleteObject:urlPath];
        }
    }
}

- (void)debugUrlPaths
{
#ifdef MM_DEBUG
    FFTDebug(@"=============================================================");
    FFTDebug(@"Dumping all UrlPaths.");
    
    NSArray *urlPaths = [self findAllOf:@"UrlPath"];
    FFTDebug(@"Found %i urls", [urlPaths count]);
    for (UrlPath *urlPath in urlPaths)
    {
        FFTDebug(@"URL PATH %@ (%@): %@", urlPath.position,
                   [urlPath.isDownloaded boolValue] ? @"true" : @"false",
                   urlPath.remoteUrl);
    }
    FFTDebug(@"=============================================================");
#endif
}


#pragma mark -
#pragma mark Core Data Photo Helper Methods
#pragma mark -


- (NSFetchRequest *)photoFetchRequest:(NSPredicate*)predicate
                                 sort:(NSString*)sortColumn
                               offset:(NSUInteger)fetchOffset
                                limit:(NSUInteger)fetchLimit
                        prefetchPaths:(NSArray*)keyPaths
{
	// Create the fetch request for the entity.
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    request.predicate = predicate;
    [request setReturnsObjectsAsFaults:NO];
    
    [request setEntity:[NSEntityDescription entityForName:@"Photo" inManagedObjectContext:self.managedObjectContext]];
    
	// Sort by position.
    if (sortColumn)
    {
        NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:sortColumn ascending:YES] autorelease];
        NSArray *sortDescriptors = [[[NSArray alloc] initWithObjects:sortDescriptor, nil] autorelease];
        [request setSortDescriptors:sortDescriptors];
    }

    if (fetchOffset > 0)
    {
        [request setFetchOffset:fetchOffset];
    }
    if (fetchLimit > 0)
    {
        [request setFetchLimit:fetchLimit];
    }

    if (keyPaths)
    {
        [request setRelationshipKeyPathsForPrefetching:keyPaths];
    }

    return request;
}

// PRIVATE
- (NSArray *)fetchPhotosWithPredicate:(NSPredicate*)predicate prefetchPaths:(NSArray*)keyPaths offset:(NSUInteger)fetchOffset limit:(NSUInteger)fetchLimit
{
    NSFetchRequest *request = [self photoFetchRequest:predicate sort:@"position" offset:fetchOffset limit:fetchLimit prefetchPaths:keyPaths];

    NSError *error;
	NSArray *photos = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (photos)
    {
        FFTDebug(@"Retrieved %i photos", [photos count]);
    }
    return photos;
}

- (NSArray *)fetchPhotosWithPredicate:(NSPredicate*)predicate
{
    return [self fetchPhotosWithPredicate:predicate prefetchPaths:nil offset:0 limit:0];
}

- (Photo *)fetchPhotoForUrlPath:(NSString *)remoteUrl
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"remoteUrl = %@", remoteUrl];
    NSArray *keyPaths = [NSArray arrayWithObject:@"imageBytes"];
    NSArray *photos = [self fetchPhotosWithPredicate:predicate prefetchPaths:keyPaths offset:0 limit:0];
    return [photos count] == 0 ? nil : [photos objectAtIndex:0];
}

// FIXME: Pass in PhotoSource?
- (Photo *)createPhotoNamed:(NSString*)title fromUrl:(NSString *)urlPath forPhotoSource:(PhotoSource*)photoSource
{
    Photo *existingPhoto = [self fetchPhotoForUrlPath:urlPath];
    if (existingPhoto && [existingPhoto.photoSource isEqual:photoSource])
    {
        return nil;
    }
    
	// Create a new instance of the entity managed by the fetched results controller.
	Photo *photo = [NSEntityDescription insertNewObjectForEntityForName:@"Photo"
                                                 inManagedObjectContext:self.managedObjectContext];
	
	// Configure the new managed object.
    photo.timestamp = [NSDate date];
    photo.title = title;
    photo.remoteUrl = urlPath;
    photo.photoSource = photoSource;
    photo.position = [NSNumber numberWithInteger:0];
    
    return photo;
}

- (Photo*)nextPhotoToDownload
{
    NSArray *photosToDownload = [self fetchPhotosWithPredicate:nil];
    FFTInfo(@"Downloadable photos found: %i", [photosToDownload count]);
    return [photosToDownload count] > 0 ? [photosToDownload objectAtIndex:0] : nil;
}

- (NSInteger)nextPhotoPosition
{
    static NSInteger nextIndex = 0;
    return nextIndex++;
}

- (NSInteger)highestPhotoPosition
{
    NSInteger position = 0;

    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isFavorite = NO"];
    request.predicate = predicate;
    [request setResultType:NSDictionaryResultType];
    
    [request setEntity:[NSEntityDescription entityForName:@"Photo" inManagedObjectContext:self.managedObjectContext]];
    
    NSExpression *keyPath = [NSExpression expressionForKeyPath:@"position"];
    NSExpression *max = [NSExpression expressionForFunction:@"max:" arguments:[NSArray arrayWithObject:keyPath]];
    
    // The name is the key that will be used in the dictionary for the return value.
    NSExpressionDescription *expressionDescription = [[[NSExpressionDescription alloc] init] autorelease];
    [expressionDescription setName:@"maxPosition"];
    [expressionDescription setExpression:max];
    [expressionDescription setExpressionResultType:NSInteger32AttributeType];
    [request setPropertiesToFetch:[NSArray arrayWithObject:expressionDescription]];

    NSError *error;
	NSArray *objects = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (objects && [objects count] > 0)
    {
        NSNumber *maxPosition = [[objects objectAtIndex:0] valueForKey:@"maxPosition"];
        position = [maxPosition integerValue] + 1;
    }
    return position;
}

- (void)mirrorFavorite:(Photo *)photo
{
    FFTDebug(@"Updating favorite mirror (%@) for Photo: %@", photo.isFavorite, photo);
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"remoteUrl = %@", photo.remoteUrl];
    NSArray *photos = [self fetchPhotosWithPredicate:predicate];
    FFTDebug(@"Found %@ Photos: %@", photo.remoteUrl, photos);

    FFTDebug(@"BEFORE MIRROR");
    [self debugFavorites];
    
    // FIXME: Filter Favorites in predicate, e.g. @"photoSource.title = 'Favorites'"
    PhotoSource *favSource = [self favoritesPhotoSource];
    Photo *mirror = nil;
    for (Photo *potentialMirror in photos)
    {
        if (favSource && [potentialMirror.photoSource isEqual:favSource])
        {
            mirror = potentialMirror;
        }
    }
    
    if ([photo.isFavorite boolValue] && mirror == nil)
    {
        // Create mirror if not already there.
        mirror = [self createPhotoNamed:photo.title fromUrl:photo.remoteUrl forPhotoSource:favSource];
        mirror.isFavorite = [NSNumber numberWithBool:NO]; // Err..?!?  Keep it outa the gene pool!
        mirror.ownerName = photo.ownerName;
        mirror.imageBytes = photo.imageBytes;
    }
    else if (![photo.isFavorite boolValue] && mirror != nil)
    {
        // Delete mirror if it exists.
        [self.managedObjectContext deleteObject:mirror];
    }
    [self saveContext];
    FFTDebug(@"AFTER MIRROR");
    [self debugFavorites];
}

- (NSArray *)allPhotos
{
    return [self fetchPhotosWithPredicate:nil];
}

// Loose favorites.
- (NSArray*)favoritePhotos
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isFavorite == YES"];
    return [self fetchPhotosWithPredicate:predicate];
}

// Mirrored favorites.
- (NSArray*)mirroredFavoritePhotos
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"photoSource.title == 'Favorites'"];
    return [self fetchPhotosWithPredicate:predicate];
}

// Want to leave both loose and mirrored favorites.
- (NSArray*)nonFavoritePhotos
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isFavorite = NO"];
//    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isFavorite = NO && photoSource.title != 'Favorites'"];
    return [self fetchPhotosWithPredicate:predicate];
}

- (NSArray*)slideshowPhotos:(NSInteger)startIndex count:(NSInteger)photoCount
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isFavorite = NO"];
    return [self fetchPhotosWithPredicate:predicate prefetchPaths:nil offset:startIndex limit:photoCount];
}

- (NSArray*)slideshowPhotos:(NSInteger)startIndex toEndIndex:(NSInteger)endIndex
{
    return [self slideshowPhotos:startIndex count:(endIndex - startIndex + 1)];
}

- (Photo*)photoAtPosition:(NSInteger)photoPosition
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isFavorite = NO and position = %i", photoPosition];
    NSArray *photos = [self fetchPhotosWithPredicate:predicate];
    return [photos count] > 0 ? [photos objectAtIndex:0] : nil;
}

- (NSUInteger)slideshowPhotoCount
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isFavorite = NO"];
    NSFetchRequest *request = [self photoFetchRequest:predicate sort:@"position" offset:0 limit:0 prefetchPaths:nil];
    return [self.managedObjectContext countForFetchRequest:request error:NULL];
}


// DELETE ME (one at a time).
- (NSArray *)photosToDownload:(NSInteger)batchSize
{
    FFTInfo(@"Have %i photos already in the queue", [[self allPhotos] count]);
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isDownloaded = NO"];
    NSArray *photosToDownload = [self fetchPhotosWithPredicate:predicate];
    NSInteger photoCount = [photosToDownload count];
    if (photoCount > batchSize)
    {
        photoCount = batchSize;
    }
    FFTInfo(@"DOWNLOADING %i more IMAGES", photoCount);
    return photoCount > 0 ? [photosToDownload subarrayWithRange:NSMakeRange(0, photoCount)] : [NSArray array];
}

- (void)deleteAllPhotos:(BOOL)keepFavorites
{
    [self debugPhotos];

    NSArray *photos = keepFavorites ? [self nonFavoritePhotos] : [self allPhotos];

    FFTInfo(@"Deleting %i photos with flag (%i)", [photos count], keepFavorites);
    for (Photo *photo in photos)
    {
        if (![photo isDeleted])
        {
            FFTTrace(@"DELETING PHOTO %@", photo.title);
            [self.managedObjectContext deleteObject:photo];
        }
    }
    
    [self saveContext];
    [self debugPhotos];
    _photoSources = nil;
}

- (void)unfavoriteAll
{
    NSArray *favorites = [self favoritePhotos];
    FFTInfo(@"Unfavoriting %i photos", [favorites count]);
    for (Photo *photo in favorites)
    {
        photo.isFavorite = [NSNumber numberWithBool:NO];
    }
    [self saveContext];
}


- (void)debugPhotos
{
#ifdef MM_DEBUG
    FFTDebug(@"=============================================================");
    FFTDebug(@"Dumping all photos.");
    
    NSArray *photos = [self allPhotos];
    if (photos && [photos count])
    {
        FFTDebug(@"Found %i photos", [photos count]);
        for (Photo *photo in photos)
        {
            FFTDebug(@"PHOTO %@ [fav=%@]: %@ (PhotoSource = %@)", photo.position, photo.isFavorite, photo.title, photo.photoSource.title);
        }
    }
    FFTDebug(@"=============================================================");
#endif
}

- (void)debugFavorites
{
#ifdef MM_DEBUG
    NSArray *photos = [self favoritePhotos];
    PhotoSource *favSource = [self favoritesPhotoSource];

    FFTDebug(@"=============================================================");
    FFTDebug(@"Dumping %i 'loose' Favorites and %i mirrored Favorites.",
            [photos count], [favSource.photos count]);
    
    if (photos && [photos count])
    {
        for (Photo *photo in photos)
        {
            FFTDebug(@"LOOSE PHOTO %@ [fav=%@]: %@", photo.position, photo.isFavorite, photo.title);
        }
    }
    FFTDebug(@"-------------------------------------------------------------");
    if (favSource && [favSource.photos count])
    {
        for (Photo *photo in favSource.photos)
        {
            FFTDebug(@"MIRROR PHOTO %@ [fav=%@]: %@", photo.position, photo.isFavorite, photo.title);
        }
    }
    FFTDebug(@"-------------------------------------------------------------");
    FFTDebug(@"favoritePhotos: %@", [self favoritePhotos]);
    FFTDebug(@"-------------------------------------------------------------");
    FFTDebug(@"mirroredFavoritePhotos: %@", [self mirroredFavoritePhotos]);
    FFTDebug(@"=============================================================");
#endif
}


@end
