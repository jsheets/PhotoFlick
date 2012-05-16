//
//  HttpSearchViewController.h
//  PhotoFrame
//
//  Created by John Sheets on 3/25/10.
//  Copyright 2010 MobileMethod, LLC. All rights reserved.
//

@class FrameViewController;
@class SearchRunner;

@interface HttpSearchViewController : UITableViewController <UISearchBarDelegate>
{
    FrameViewController *_frameViewController;
    SearchRunner *_searchRunner;
    UISearchBar *_searchBar;
}

@property (nonatomic, retain) FrameViewController *frameViewController;
@property (nonatomic, retain) SearchRunner *searchRunner;
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;

- (NSArray *)photoSources:(BOOL)forceReload;

@end
