//
//  DataManager.h
//  PhotoFrame
//
//  Created by John Sheets on 9/27/09.
//  Copyright 2009 MobileMethod, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PhotoSource.h"
#import "Photo.h"
#import "UrlPath.h"

@interface DataManager : NSObject
{
    // Can add sources directly, but not through imageSources property.
    NSMutableArray *_photoSources;

    NSManagedObjectModel *_managedObjectModel;
    NSManagedObjectContext *_managedObjectContext;	    
    NSPersistentStoreCoordinator *_persistentStoreCoordinator;
}

@property (nonatomic, retain, readonly) NSArray *photoSources;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

// Core Data methods
- (BOOL)saveContext;
- (NSManagedObjectContext *) newManagedObjectContext;

// Photo Source methods
- (PhotoSource*)createPhotoSourceWithTitle:(NSString *)title andUrl:(NSString *)url;
- (NSArray *)initializePhotoSources;
- (PhotoSource *)loadPhotoSourceByPath:(NSString *)path;
- (void)deletePhotoSourceForPath:(NSString *)path;
- (NSArray *)allCustomPhotoSources:(BOOL)forceReload;

- (PhotoSource *)flickrPhotoSource;
- (PhotoSource *)ffffoundPhotoSource;
- (PhotoSource *)favoritesPhotoSource;

// UrlPath methods
- (BOOL)hasAvailableUrlPaths;
- (UrlPath *)createUrlPath:(NSString *)remoteUrl title:(NSString *)title;
- (NSInteger)nextUrlPathPosition;
- (UrlPath *)popNextUrlPath;
- (void)deleteAllUrlPaths;
- (void)debugUrlPaths;

// Photo methods
- (Photo *)createPhotoNamed:(NSString *)title fromUrl:(NSString *)urlPath forPhotoSource:(PhotoSource*)imageSource;
- (Photo *)fetchPhotoForUrlPath:(NSString *)remoteUrl;
- (NSInteger)nextPhotoPosition;
- (NSArray*)slideshowPhotos:(NSInteger)startIndex count:(NSInteger)photoCount;
- (NSArray*)slideshowPhotos:(NSInteger)startIndex toEndIndex:(NSInteger)endIndex;
- (NSUInteger)slideshowPhotoCount;
- (Photo*)photoAtPosition:(NSInteger)photoPosition;
- (void)mirrorFavorite:(Photo *)photo;

- (Photo*)nextPhotoToDownload;
- (NSArray *)allPhotos;
- (NSArray*)favoritePhotos;
- (NSArray*)nonFavoritePhotos;
- (NSArray *)photosToDownload:(NSInteger)batchSize;

- (void)deleteAllPhotos:(BOOL)keepFavorites;
- (void)unfavoriteAll;

- (void)debugPhotos;
- (void)debugFavorites;
- (void)logError:(NSError*)error;

@end
