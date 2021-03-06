/**
 * Copyright (C) 2009 bdferris <bdferris@onebusaway.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *         http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "OBAStopV2.h"
#import "OBABookmarkV2.h"
#import "OBAStopAccessEventV2.h"
#import "OBAStopPreferencesV2.h"
#import "OBAServiceAlertsModel.h"
#import "OBARegionV2.h"

NS_ASSUME_NONNULL_BEGIN

@class OBAModelDAOUserPreferencesImpl;

@interface OBAModelDAO : NSObject
@property(nonatomic,strong,readonly) NSArray<OBABookmarkV2*> *bookmarksForCurrentRegion;
@property(weak, nonatomic,readonly) NSArray * bookmarks;
@property(weak, nonatomic,readonly) NSArray * bookmarkGroups;
@property(weak, nonatomic,readonly) NSArray<OBAStopAccessEventV2*> * mostRecentStops;
@property(nonatomic,weak) CLLocation * mostRecentLocation;
@property(nonatomic,readonly) OBARegionV2 * region;
@property(weak, nonatomic,readonly) NSArray * mostRecentCustomApiUrls;

- (OBABookmarkV2*)createTransientBookmark:(OBAStopV2*)stop;
- (OBABookmarkV2*)bookmarkForStop:(OBAStopV2*)stop;
- (void) addNewBookmark:(OBABookmarkV2*)bookmark;
- (void) saveExistingBookmark:(OBABookmarkV2*)bookmark;
- (void) moveBookmark:(NSInteger)startIndex to:(NSInteger)endIndex;
- (void) removeBookmark:(OBABookmarkV2*) bookmark;

- (void) addOrSaveBookmarkGroup:(OBABookmarkGroup *)bookmarkGroup;
- (void) removeBookmarkGroup:(OBABookmarkGroup*)bookmarkGroup;
- (void) moveBookmark:(OBABookmarkV2*)bookmark toGroup:(OBABookmarkGroup*)group;
- (void) moveBookmark:(NSInteger)startIndex to:(NSInteger)endIndex inGroup:(OBABookmarkGroup*)group;

- (OBAStopPreferencesV2*) stopPreferencesForStopWithId:(NSString*)stopId;
- (void) setStopPreferences:(OBAStopPreferencesV2*)preferences forStopWithId:(NSString*)stopId;

- (BOOL) isVisitedSituationWithId:(NSString*)situationId;
- (void) setVisited:(BOOL)visited forSituationWithId:(NSString*)situationId;

- (OBAServiceAlertsModel*) getServiceAlertsModelForSituations:(NSArray*)situations;

- (void) setOBARegion:(nullable OBARegionV2*)newRegion;
/**
 * We persist hiding location warnings across application settings for users who have disabled location services for the app
 */
- (BOOL) hideFutureLocationWarnings;
- (void) setHideFutureLocationWarnings:(BOOL)hideFutureLocationWarnings;

- (BOOL) readSetRegionAutomatically;
- (void) writeSetRegionAutomatically:(BOOL)setRegionAutomatically;

- (NSString*) readCustomApiUrl;
- (void) writeCustomApiUrl:(NSString*)customApiUrl;

- (void) addCustomApiUrl:(NSString*)customApiUrl;

- (NSString*)normalizedAPIServerURL;
@end

NS_ASSUME_NONNULL_END