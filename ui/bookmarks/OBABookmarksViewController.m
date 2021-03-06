//
//  OBABookmarksViewController.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/9/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBABookmarksViewController.h"
#import <DZNEmptyDataSet/UIScrollView+EmptyDataSet.h>
#import "OBAApplication.h"
#import "OBABookmarkGroup.h"
#import "OBAStopViewController.h"
#import "OBAEditStopBookmarkViewController.h"

@interface OBABookmarksViewController ()<DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

@end

@implementation OBABookmarksViewController

- (instancetype)init {
    self = [super init];

    if (self) {
        self.tabBarItem.title = NSLocalizedString(@"Bookmarks", @"Bookmarks tab title");
        self.tabBarItem.image = [UIImage imageNamed:@"Bookmarks"];
    }
    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Set up the empty data set UI.
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;

    self.tableView.allowsSelectionDuringEditing = YES;
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    NSString *title = nil;
    if (self.currentRegion) {
        title = [NSString stringWithFormat:NSLocalizedString(@"Bookmarks - %@", @""), self.currentRegion.regionName];
    }
    else {
        title = NSLocalizedString(@"Bookmarks", @"");
    }
    self.navigationItem.title = title;

    [self loadData];
}

#pragma mark OBANavigationTargetAware

- (OBANavigationTarget *)navigationTarget {
    return [OBANavigationTarget target:OBANavigationTargetTypeBookmarks];
}

#pragma mark - Data Loading

- (void)loadData {
    OBAModelDAO *modelDAO = [OBAApplication sharedApplication].modelDao;

    NSMutableArray *sections = [[NSMutableArray alloc] init];

    for (OBABookmarkGroup *group in modelDAO.bookmarkGroups) {
        NSArray *rows = [self tableRowsFromBookmarks:group.bookmarks];
        OBATableSection *section = [[OBATableSection alloc] initWithTitle:group.name rows:rows];

        if (section.rows.count > 0) {
            [sections addObject:section];
        }
    }

    OBATableSection *looseBookmarks = [[OBATableSection alloc] initWithTitle:NSLocalizedString(@"Bookmarks", @"") rows:[self tableRowsFromBookmarks:modelDAO.bookmarks]];
    if (looseBookmarks.rows.count > 0) {
        [sections addObject:looseBookmarks];
    }

    self.sections = sections;
    [self.tableView reloadData];
}

#pragma mark - UITableView

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

// TODO: Disabled for now. This requires more time and attention than I can give it at the
// moment. I'd love to re-enable this feature, and soon, though.
- (BOOL)tableView:(UITableView*)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {

    OBATableSection *tableSection = self.sections[indexPath.section];
    OBATableRow *tableRow = tableSection.rows[indexPath.row];

    NSMutableArray *rows = [NSMutableArray arrayWithArray:tableSection.rows];
    [rows removeObjectAtIndex:indexPath.row];
    tableSection.rows = rows;

    if (tableRow.deleteModel) {
        tableRow.deleteModel();
    }

    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - DZNEmptyDataSet

#pragma mark TODO - This is duplicated from the Recent Stops controller. DRY up!

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    NSString *text = NSLocalizedString(@"No Bookmarks", @"");

    NSDictionary *attributes = @{NSFontAttributeName: [OBATheme titleFont],
                                 NSForegroundColorAttributeName: [OBATheme darkDisabledColor]};

    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = NSLocalizedString(@"Tap 'Add to Bookmarks' from a stop to save a bookmark to this screen.", @"");

    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    paragraph.alignment = NSTextAlignmentCenter;

    NSDictionary *attributes = @{NSFontAttributeName: [OBATheme bodyFont],
                                 NSForegroundColorAttributeName: [OBATheme lightDisabledColor],
                                 NSParagraphStyleAttributeName: paragraph};

    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView
{
    // Totally arbitrary value. It just 'looks right'.
    return -44;
}

#pragma mark - Accessors

- (OBARegionV2*)currentRegion {
    return [OBAApplication sharedApplication].modelDao.region;
}

#pragma mark - Private

- (NSArray<OBATableRow*>*)tableRowsFromBookmarks:(NSArray<OBABookmarkV2*>*)bookmarks {
    NSMutableArray *rows = [NSMutableArray array];

    for (OBABookmarkV2 *bm in bookmarks) {

        if (bm.stopId.length == 0) {
            // bookmark was somehow corrupted. Skip it and continue on.
            NSLog(@"Corrupted bookmark: %@", bm);
            continue;
        }

        if (bm.regionIdentifier != NSNotFound && bm.regionIdentifier != [self currentRegion].identifier) {
            // We are special-casing bookmarks that don't have a region set on them, as there's no way to know
            // for sure which region they belong to. However, if this bookmark has a valid regionIdentifier and
            // the current region's identifier doesn't match the bookmark, then this bookmark belongs to a
            // different region. Skip it.
            continue;
        }

        OBATableRow *row = [[OBATableRow alloc] initWithTitle:bm.name action:^{
            OBAStopViewController *controller = [[OBAStopViewController alloc] initWithStopID:bm.stopId];
            [self.navigationController pushViewController:controller animated:YES];
        }];

        row.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        [row setEditAction:^{
            OBAEditStopBookmarkViewController *editor = [[OBAEditStopBookmarkViewController alloc] initWithBookmark:bm editType:OBABookmarkEditExisting];
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:editor];
            [self presentViewController:nav animated:YES completion:nil];
        }];
        [row setDeleteModel:^{
            [[OBAApplication sharedApplication].modelDao removeBookmark:bm];
        }];
        [rows addObject:row];
    }

    return rows;
}

@end