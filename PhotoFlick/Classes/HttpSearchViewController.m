//
//  HttpSearchViewController.m
//  PhotoFrame
//
//  Created by John Sheets on 3/25/10.
//  Copyright 2010 MobileMethod, LLC. All rights reserved.
//

#import "HttpSearchViewController.h"
#import "SearchRunner.h"

@implementation HttpSearchViewController

@synthesize frameViewController = _frameViewController;
@synthesize searchRunner = _searchRunner;
@synthesize searchBar = _searchBar;

#pragma mark -
#pragma mark View lifecycle

- (void) dealloc
{
    [_frameViewController release], _frameViewController = nil;
    [_searchRunner release], _searchRunner = nil;
    [_searchBar release], _searchBar = nil;
    
    [super dealloc];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Override to allow orientations other than the default portrait orientation.
    return YES;
}

- (PhotoFlickAppDelegate*)appDelegate
{
    return (PhotoFlickAppDelegate*)[[UIApplication sharedApplication] delegate];
}

- (NSArray *)photoSources:(BOOL)forceReload
{
    NSArray *sources = [self.appDelegate.dataManager allCustomPhotoSources:forceReload];
    if (forceReload)
    {
        FFTInfo(@"Reloaded %i custom photo sources.", [sources count]);
        FFTDebug(@"%@", sources);
    }
    return sources;
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[self photoSources:NO] count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
    PhotoSource *photoSource = [[self photoSources:NO] objectAtIndex:indexPath.row];
    FFTTrace(@"CELL: %i - %@", indexPath.row, photoSource);
    cell.textLabel.text = photoSource.url;
    
    return cell;
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FFTDebug(@"HTTP SELECTED ROW: %i", indexPath.row);
    
    // Selected an old result: Immediately run search!
    PhotoSource *photoSource = [[self photoSources:NO] objectAtIndex:indexPath.row];
    EVENT_SEARCH_CUSTOM(photoSource.url);
    
    // Dismiss popover.
    [self.frameViewController.httpPopoverController dismissPopoverAnimated:YES];
    self.frameViewController.httpPopoverController = nil;
    
    [self.searchRunner searchHttp:photoSource.url];
}


#pragma mark -
#pragma mark Memory management


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload
{
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


#pragma mark -
#pragma mark UISearchBar


- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    FFTCritical(@"Running the http:// search for: %@", searchBar.text);
    
    // Hide keyboard.
//    [searchBar resignFirstResponder];
    [self.frameViewController.httpPopoverController dismissPopoverAnimated:YES];
    self.frameViewController.httpPopoverController = nil;
    
    EVENT_SEARCH_CUSTOM(searchBar.text);
    [self.searchRunner searchHttp:searchBar.text];
}

@end

