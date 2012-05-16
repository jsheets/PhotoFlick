//
//  MMQSearchHtml.m
//  PhotoFrame
//
//  Created by John Sheets on 12/6/09.
//  Copyright 2009 MobileMethod, LLC. All rights reserved.
//

#import "MMQSearchHtml.h"

#import "PhotoFlickAppDelegate.h"
#import "PhotoSource.h"
#import "UrlPath.h"
#import "DataManager.h"

//#define MIN_IMAGE_COUNT 200
#define MIN_IMAGE_COUNT 50
//#define MIN_IMAGE_COUNT 25
#define MAX_PAGE_COUNT 15

@implementation MMQSearchHtml

static NSString *kNoMorePagesFound = @"<END_OF_PAGES>";

@synthesize photoSource = _photoSource;
@synthesize currentPage = _currentPage;
@synthesize nextPage = _nextPage;
@synthesize pageUrl = _pageUrl;
@synthesize currentLoadingUrl = _currentLoadingUrl;
@synthesize responseData = _responseData;


- (id)initWithPhotoSource:(PhotoSource*)photoSource
{	
    if ((self = [super init]))
    {
        // Initialization.
        self.photoSource = photoSource;
    }
    
    return self;
}

- (void) dealloc
{
    [_photoSource release], _photoSource = nil;
    [_currentPage release], _currentPage = nil;
    [_nextPage release], _nextPage = nil;
    [_pageUrl release], _pageUrl = nil;
    [_currentLoadingUrl release], _currentLoadingUrl = nil;
    [_responseData release], _responseData = nil;

    [super dealloc];
}

- (NSURL*)pageUrl
{
    if (_pageUrl == nil)
    {
        // Use stored nextPage, if set; this means we paused in the middle
        // of a longer search.
        if ([self.photoSource.nextPage isEqualToString:kNoMorePagesFound])
        {
            FFTCritical(@"No more search pages found; bailing out of HTML search: %@", kNoMorePagesFound);
        }
        else
        {
            NSString *url = (self.photoSource.nextPage != nil) ?
                self.photoSource.nextPage : self.photoSource.url;
            _pageUrl = [[NSURL URLWithString:url] retain];
            FFTCritical(@"Starting new HTML download operation for base URL: %@", _pageUrl);
        }
    }
    return _pageUrl;
}

// Check image metadata to see if we should download it.  Too big?  Too small?
// (But won't know image size until we start to download it.)
- (BOOL)shouldLoadPhoto:(NSURL*)imageUrl
{
    // Check file extension.
    NSString *extension = [[[imageUrl path] pathExtension] lowercaseString];
    NSArray *validExtensions = [NSArray arrayWithObjects:@"png", @"gif", @"jpg", @"jpeg", @"tif", @"bmp", nil];
    if (![validExtensions containsObject:extension])
    {
        FFTDebug(@"Rejecting non-graphic file path: '%@'", imageUrl);
        return NO;
    }
    
    return YES;
}

#pragma mark -
#pragma mark XML Parsing Methods
#pragma mark -

- (NSURL *)mapSpecialUrls:(NSURL *)url
{
    // TODO: Detect special sites and trigger full custom keys, including
    //        mapped URL and nextPageXpath.
    NSString *configKey = [NSString stringWithFormat:@"sitemap.%@", url];
    FFTInfo(@"Looking up URL %@ in config key %@", url, configKey);

    PhotoFlickAppDelegate *appDelegate =
        (PhotoFlickAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    @try
    {
        NSString *mappedUrlString = [appDelegate.remoteConfig valueForKeyPath:configKey];
        if (mappedUrlString)
        {
            FFTInfo(@"REMOTE CONFIG: Overriding URL %@ with mappedUrl: %@", url, mappedUrlString);
            url = [NSURL URLWithString:mappedUrlString];
        }
    }
    @catch (NSException * e)
    {
        FFTError(@"Fatal error looking up sitemap: %@", e);
    }
    return url;
}


// Scan the HTML document and return an array of NSURLs for all matching images.
- (NSArray*)xmlRunXPathOnDoc:(htmlDocPtr)doc withXpath:(NSString *)targetXpath withFilter:(BOOL)filtered
{
    FFTInfo(@"Scanning HTML document for elements at '%@'", targetXpath);
    
    xmlXPathContextPtr xpathCtx;
    xmlXPathObjectPtr xpathObj;
    
    // Create xpath evaluation context.
    xpathCtx = xmlXPathNewContext(doc);
    if(xpathCtx == NULL)
    {
        FFTError(@"HTML ERROR: Unable to create XPath context from HTML doc.");
        return nil;
    }
    
    // Evaluate xpath expression.
    xmlChar *xpath = (xmlChar *)[targetXpath cStringUsingEncoding:NSUTF8StringEncoding];
    xpathObj = xmlXPathEvalExpression(xpath, xpathCtx);
    if(xpathObj == NULL)
    {
        FFTError(@"HTML ERROR: Unable to evaluate XPath: '%@'", targetXpath);
        return nil;
    }
    
    xmlNodeSetPtr nodes = xpathObj->nodesetval;
    if (!nodes)
    {
        FFTError(@"HTML ERROR: Failed to find any xpath matches for '%@'", targetXpath);
        return nil;
    }
    
    // Extract <img src=""> or <a href=""> from each XPath result node.
    NSMutableArray *urls = [NSMutableArray array];
    for (NSInteger i = 0; i < nodes->nodeNr; i++)
    {
        xmlNodePtr currentNode = nodes->nodeTab[i];
        if (currentNode->children != NULL && currentNode->children->type == XML_TEXT_NODE)
        {
            // Text content of the found element.
            NSString *imagePath = [NSString stringWithCString:(const char*)currentNode->children->content encoding:NSUTF8StringEncoding];
            NSURL *url = [NSURL URLWithString:imagePath];
            
            // If a relative URL, prepend with PhotoSource host.
            if ([url host] == nil)
            {
                if (self.photoSource)
                {
                    imagePath = [NSString stringWithFormat:@"%@%@", self.photoSource.url, imagePath];
                }
                url = [NSURL URLWithString:imagePath];
            }
            
            FFTTrace(@"Found match at path: %@", url);
            if (filtered && ![self shouldLoadPhoto:url])
            {
                FFTTrace(@"Skipping non-photo URL: %@", url);
                continue;
            }

            [urls addObject:url];
        }
    }
    
    /* Cleanup */
    xmlXPathFreeObject(xpathObj);
    xmlXPathFreeContext(xpathCtx);
    
    return urls;
}

- (NSURL*)xmlFindNextPage:(htmlDocPtr)doc
{
    FFTInfo(@"Searching HTML doc for NEXT PAGES");
    
    // translate(.,'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz')
    NSString *nextPageXpath = @"//a[starts-with(text(), 'Next') or starts-with(text(), 'next') or contains(text(), 'Older Posts') or contains(text(), 'Older Entries')]/@href";
    
    PhotoFlickAppDelegate *appDelegate =
        (PhotoFlickAppDelegate*)[[UIApplication sharedApplication] delegate];
    NSString *configXpath = [appDelegate.remoteConfig valueForKeyPath:@"html.nextPageXpath"];
    if (configXpath)
    {
        FFTInfo(@"REMOTE CONFIG: Overriding nextPageXpath: %@", configXpath);
        nextPageXpath = configXpath;
    }
    
    NSArray *nextPages = [self xmlRunXPathOnDoc:doc withXpath:nextPageXpath withFilter:NO];
    
    FFTInfo(@"Found NEXT PAGES: %@", nextPages);
    return ([nextPages count] > 0) ? [nextPages objectAtIndex:0] : nil;
}

// Load images from one or more pages at the given PhotoSource site.
// The first element is always the URL of the next page.  If the result
// array is empty, the HTML doc was bad or unloadable.
- (NSMutableArray*)xmlLoadPhotoUrls:(NSURL*)page
{
    // Load HTML document with HTML-friendly libxml2 parser.
    FFTInfo(@"Loading content from image page URL: '%@'", page);
    NSData *rawData = [NSData dataWithContentsOfURL:page];
    htmlDocPtr doc = htmlReadMemory([rawData bytes], [rawData length], "", NULL,
                                    HTML_PARSE_NOWARNING | HTML_PARSE_NOERROR);
    if (doc == NULL)
    {
        FFTError(@"HTML ERROR: Unable to parse HTML document: '%@'", page);
        return [NSArray array];
    }
    
    // Run xpath on HTML document.
    NSURL *nextPage = [self xmlFindNextPage:doc];
    self.photoSource.nextPage = [nextPage absoluteString];
    if (self.photoSource.nextPage == nil)
    {
        self.photoSource.nextPage = kNoMorePagesFound;
    }
    FFTInfo(@"Setting PhotoSource.nextPage = %@", self.photoSource.nextPage);

    NSArray *imageUrls = [self xmlRunXPathOnDoc:doc withXpath:self.photoSource.photoBaseXpath withFilter:YES];
    FFTInfo(@"Found %i images on page %@", [imageUrls count], page);
    FFTTrace(@"%@", imageUrls);
    
    // Clean up.
    xmlFreeDoc(doc);
    
    NSMutableArray *results = [NSMutableArray arrayWithArray:imageUrls];
    
    // Push nextPage to head of image array.
    id pageObj = (nextPage == nil) ? (id)[NSNull null] : (id)nextPage;
    [results insertObject:pageObj atIndex:0];
    
    return results;
}

- (NSArray*)loadAllPhotoUrls
{
    FFTInfo(@"Loading all images from HTML source...");
    NSInteger pageCount = 0;
    NSMutableArray *images = [NSMutableArray array];
    
    // Keep scanning pages until we have 100 images, but give up after MAX_PAGE_COUNT pages.
    id nextUrl = [self mapSpecialUrls:self.pageUrl];
    while ([images count] < MIN_IMAGE_COUNT && pageCount < MAX_PAGE_COUNT)
    {
        FFTInfo(@"Loading images from next page: %@", nextUrl);
        NSMutableArray *morePhotos = [self xmlLoadPhotoUrls:nextUrl];
        if ([morePhotos count] > 0)
        {
            // Pull off first object as next page URL.
            nextUrl = [morePhotos objectAtIndex:0];
            [morePhotos removeObjectAtIndex:0];
            
//            [images addObjectsFromArray:morePhotos];
            for (id url in morePhotos)
            {
                if ([images indexOfObject:url] == NSNotFound)
                {
                    FFTDebug(@"ADDING: %@", url);
                    [images addObject:url];
                }
                else
                {
                    FFTTrace(@"DUPLICATE: %@", url);
                }
            }
        }
        else
        {
            FFTInfo(@"No images found for page %@", nextUrl);
            nextUrl = [NSNull null];
        }
        
        pageCount++;
        FFTCritical(@"Total %i images after page %i", [images count], pageCount);
        
        if (nextUrl == [NSNull null])
        {
            FFTInfo(@"No images found in next page; bailing out");
            break;
        }
    }

    return images;
}


#pragma mark -
#pragma mark Service API Methods
#pragma mark -


- (void)startOperation
{
    // NSURL objects for each remote image.
    NSArray *urls = [self loadAllPhotoUrls];
    FFTCritical(@"Found %i images from HTML", [urls count]);
    FFTDebug(@"URLS: %@", urls);
    
    NSInteger nextPos = [self.dataManager nextUrlPathPosition];
    for (NSURL *url in urls)
    {
        if ([url scheme] == nil)
        {
            FFTError(@"Invalid URL: %@", url);
            continue;
        }
        
        NSString *title = [[url path] lastPathComponent];
        NSString *urlString = [url absoluteString];

        // Returns nil if UrlPath already exists.
        UrlPath *urlPath = [self.dataManager createUrlPath:urlString title:title];
        if (urlPath)
        {
            urlPath.position = [NSNumber numberWithInteger:nextPos++];
        }
        else
        {
            FFTInfo(@"Already loaded URL: %@", urlString);
        }
    }
    [self.dataManager saveContext];
    [self completeOperation];
}

@end
