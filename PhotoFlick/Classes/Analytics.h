/*
 *  Analytics.h
 *  PhotoFlick
 *
 *  Created by John Sheets on 10/6/10.
 *  Copyright 2010 MobileMethod, LLC. All rights reserved.
 *
 */

#if defined(USE_PINCH_MEDIA)
#define API_KEY (@"replacewithpinchmediakey")
#endif

#if defined(USE_FLURRY)
#if defined(PRODUCTION_ANALYTICS)
#define API_KEY (@"replacewithflurrykey")
#else
#define API_KEY (@"replacewithflurrykey")
#endif
#endif

#if defined(USE_LOCALYTICS)
#define API_KEY (@"replacewithlocalyticskey")
#endif

// 
// Analytics events
// 
//  - Play Slideshow (Search)
//  - About
//  - Settings
//  - Favorites

#define EVENT_ABOUT EVENT_ANALYTICS_START(@"About")
#define EVENT_SETTINGS(displayTime) EVENT_ANALYTICS_START_CUSTOM(@"Settings", \
[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:displayTime] forKey:@"displayTime"])
#define EVENT_FAVORITES_SEND EVENT_ANALYTICS_START(@"Email Favorites")
#define EVENT_FAVORITES_CLEAR EVENT_ANALYTICS_START(@"Clear Favorites")

#define EVENT_SEARCH_FLICKR      EVENT_ANALYTICS_START_CUSTOM(@"Search", \
[NSDictionary dictionaryWithObject:@"Flickr" forKey:@"serviceName"])
#define EVENT_SEARCH_FFFFOUND    EVENT_ANALYTICS_START_CUSTOM(@"Search", \
[NSDictionary dictionaryWithObject:@"Ffffound" forKey:@"serviceName"])
#define EVENT_SEARCH_CUSTOM(url) EVENT_ANALYTICS_START_CUSTOM(@"Search", \
[NSDictionary dictionaryWithObject:url forKey:@"url"])

#define EVENT_SLIDE_TO(scrolledTo) EVENT_ANALYTICS_START_CUSTOM(@"Slideshow", \
([NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:scrolledTo] forKey:@"slideIndex"]))

