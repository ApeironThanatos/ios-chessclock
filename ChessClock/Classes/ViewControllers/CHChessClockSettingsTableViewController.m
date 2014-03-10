//
//  CHChessClockSettingsTableViewController.m
//  Chess.com
//
//  Created by Pedro Bolaños on 10/24/12.
//  Copyright (c) 2012 psbt. All rights reserved.
//

#import "CHChessClockSettingsTableViewController.h"
#import "CHChessClockViewController.h"
#import "CHChessClockSettingsManager.h"
#import "CHChessClockSettings.h"
#import "CHChessClockTimeControlTableViewController.h"
#import "CHUtil.h"
//#import "ChessAppDelegate.h"

//------------------------------------------------------------------------------
#pragma mark - Private methods declarations
//------------------------------------------------------------------------------
@interface CHChessClockSettingsTableViewController()
<CHChessClockTimeControlTableViewControllerDelegate, UIActionSheetDelegate>

@property (retain, nonatomic) IBOutlet UITableViewCell* orientationTableViewCell;
@property (retain, nonatomic) IBOutlet UIButton* startClockButton;
@property (retain, nonatomic) UIViewController* currentViewController;

@end

//------------------------------------------------------------------------------
#pragma mark - CHChessClockSettingsTableViewController implementation
//------------------------------------------------------------------------------
@implementation CHChessClockSettingsTableViewController

static const NSUInteger CHAddNewTimeControlSection = 0;
static const NSUInteger CHExistingTimeControlSection = 1;
static const NSUInteger CHLandscapeMode = 2;
static const NSUInteger CHRestoreDefaultsSection = 3;

static const NSUInteger CHRestoreDefaultsButtonTag = 1;
static const NSUInteger CHDestructiveButtonIndex = 0;

- (void)viewDidLoad
{
    [super viewDidLoad];
 
    CHChessClockSettingsManager* settingsManager = [[CHChessClockSettingsManager alloc]
                                                     initWithUserName:@"settingsManager"];
    self.settingsManager = settingsManager;
    
    self.title = NSLocalizedString(@"Settings", nil);
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [self.startClockButton setBackgroundImage:nil forState:UIControlStateHighlighted];
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 7){
        self.edgesForExtendedLayout = UIRectEdgeLeft | UIRectEdgeRight;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    self.currentViewController = nil;

    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if(self.currentViewController == nil)
        [self.navigationController setNavigationBarHidden:YES animated:YES];
    
    [super viewWillDisappear:animated];
    [self saveSettings];
}

//------------------------------------------------------------------------------
#pragma mark - Private methods definitions
//------------------------------------------------------------------------------
- (void)updateClockSettings:(CHChessClockSettings*)clockSettings
{
    self.settingsManager.currentTimeControl = clockSettings;
    
    if ([self.delegate respondsToSelector:@selector(settingsTableViewController:didUpdateSettings:)]) {
       [self.delegate performSelector:@selector(settingsTableViewController:didUpdateSettings:)
                           withObject:self withObject:clockSettings];
    }
}

- (void)saveSettings
{
    // TODO: The settings should only be saved when there are modifications!
    [self.settingsManager saveTimeControls];
}

- (UIColor*)selectedSettingTextColor
{
    return [UIColor colorWithRed:50.0f / 255.0f green:79.0f / 255.0f blue:133.0f / 255.0f alpha:1.0f];
}

- (void)selectCell:(UITableViewCell*)cell
{
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    cell.textLabel.textColor = [self selectedSettingTextColor];
}

- (UITableViewCell*)cellWithIdentifier:(NSString*)identifier
{
    UITableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    return cell;
}

- (UITableViewCell*)restoreDefaultsCell
{
    NSString* cellIdentifier = @"CHRestoreDefaultsCell";
    UITableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        // This removes the cell rounded background
        UIView* backgroundView = [[UIView alloc] initWithFrame:cell.bounds];
        cell.backgroundView = backgroundView;
        
        UIButton* button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        button.frame = cell.bounds;
        button.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        button.tag = CHRestoreDefaultsButtonTag;
        [button setTitle:NSLocalizedString(@"Restore defaults", nil) forState:UIControlStateNormal];
        [button addTarget:self action:@selector(restoreDefaultsTapped) forControlEvents:UIControlEventTouchUpInside];
        button.titleLabel.textColor = [UIColor blackColor];
        [button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [cell.contentView addSubview:button];
    }
    
    return cell;
}

- (UITableViewCell*)orientationCell
{
    UITableViewCell* cell = [self cellWithIdentifier:@"CHChessClockOrientationCell"];
    
    if (cell.accessoryView == nil) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.text = NSLocalizedString(@"Landscape Mode", nil);
        
        UISwitch* orientationSwitch = [[UISwitch alloc] init];
        [orientationSwitch addTarget:self action:@selector(landscapeValueChanged:)
                    forControlEvents:UIControlEventValueChanged];
        
        cell.accessoryView = orientationSwitch;
    }
    
    UISwitch* orientationSwitch = (UISwitch*)cell.accessoryView;
    orientationSwitch.on = [self.settingsManager isLandscape];
    
    return cell;
}


- (void)populateNewTimeControlCell:(UITableViewCell*)cell withIndexPath:(NSIndexPath*)indexPath
{
    cell.textLabel.text = NSLocalizedString(@"Add new", nil);
}

- (void)populateExistingTimeControlCell:(UITableViewCell*)cell withIndexPath:(NSIndexPath*)indexPath
{
    CHChessClockSettings* settings = [[self.settingsManager allChessClockSettings] objectAtIndex:indexPath.row];
    cell.textLabel.text = settings.name;
    
    if (settings == self.settingsManager.currentTimeControl) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        cell.textLabel.textColor = [self selectedSettingTextColor];
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.textColor = [UIColor blackColor];
    }
}

- (void)existingTimeControlSelectedAtIndexPath:(NSIndexPath*)indexPath inTableView:(UITableView*)tableView
{
    CHChessClockSettings* selectedSetting = [[self.settingsManager allChessClockSettings] objectAtIndex:indexPath.row];
    
    if ([tableView isEditing]) {
        [self timeControlSelected:selectedSetting];
    }
    else {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        CHChessClockSettings* lastSelectedSetting = self.settingsManager.currentTimeControl;
        
        if (selectedSetting != lastSelectedSetting) {
            
            // Remove the check mark from the last selected cell
            NSUInteger lastSelectedIndex = [[self.settingsManager allChessClockSettings] indexOfObject:lastSelectedSetting];
            UITableViewCell* lastSelectedCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:lastSelectedIndex
                                                                                                    inSection:CHExistingTimeControlSection]];
            lastSelectedCell.accessoryType = UITableViewCellAccessoryNone;
            lastSelectedCell.textLabel.textColor = [UIColor blackColor];
            
            // Add checkmark to the newly selected cell
            UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
            [self selectCell:cell];
            
            [self updateClockSettings:selectedSetting];
        }
    }
}

- (void)timeControlSelected:(CHChessClockSettings*)selectedSettings
{
    NSString* nibName = [CHUtil nibNameWithBaseName:@"CHChessClockTimeControlView"];
    CHChessClockTimeControlTableViewController* timeControlViewController = [[CHChessClockTimeControlTableViewController alloc]
                                                                   initWithNibName:nibName bundle:nil];
    timeControlViewController.chessClockSettings = selectedSettings;
    timeControlViewController.delegate = self;
    self.currentViewController = timeControlViewController;
    
    [self.navigationController pushViewController:timeControlViewController animated:YES];
}

//------------------------------------------------------------------------------
#pragma mark - UITableViewDataSource methods
//------------------------------------------------------------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == CHAddNewTimeControlSection) {
        return NSLocalizedString(@"Time controls", nil);
    }
    
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == CHAddNewTimeControlSection ||
        section == CHRestoreDefaultsSection)
    {
        return 1;
    }
    else if(section == CHLandscapeMode)
    {
#warning What do we do with delegate?
//        if(self.m_pAppDelegate.m_bIPad)
//            return 0;
        return 1;
    }
    
    return [[self.settingsManager allChessClockSettings] count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 7)
    {
        tableView.tintColor = [UIColor blackColor];
    }
    UITableViewCell* cell = nil;
    
    switch (indexPath.section) {
        case CHAddNewTimeControlSection:
            cell = [self cellWithIdentifier:@"CHAddNewTimeControlCell"];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            [self populateNewTimeControlCell:cell withIndexPath:indexPath];
            break;
            
        case CHExistingTimeControlSection:
            cell = [self cellWithIdentifier:@"CHExistingTimeControlCell"];
            cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
            [self populateExistingTimeControlCell:cell withIndexPath:indexPath];
            break;
            
        case CHLandscapeMode:
            cell = [self orientationCell];
            break;
            
        case CHRestoreDefaultsSection:
            cell = [self restoreDefaultsCell];
            break;
            
        default:
            break;
    }
    
    [cell.textLabel setFont:[UIFont boldSystemFontOfSize:15]];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section == CHExistingTimeControlSection;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section == CHExistingTimeControlSection;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath
      toIndexPath:(NSIndexPath *)destinationIndexPath
{
    [self.settingsManager moveTimeControlFrom:sourceIndexPath.row to:destinationIndexPath.row];
}

//------------------------------------------------------------------------------
#pragma mark - Control Event Handlers
//------------------------------------------------------------------------------

- (void)landscapeValueChanged:(UISwitch*)sender
{
    [self.settingsManager setIsLandscape:sender.on];
}

//------------------------------------------------------------------------------
#pragma mark - UITableViewDelegate methods
//------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case CHAddNewTimeControlSection:
            [self timeControlSelected:nil];
            break;
            
        case CHExistingTimeControlSection:
            [self existingTimeControlSelectedAtIndexPath:indexPath inTableView:tableView];
            break;
                    
        default:
            break;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if ([[self.settingsManager allChessClockSettings] count] > 1) {
            NSUInteger selectedSettingIndex = [[self.settingsManager allChessClockSettings] indexOfObject:self.settingsManager.currentTimeControl];
            NSUInteger settingToDeleteIndex = indexPath.row;
        
            [self.settingsManager removeTimeControlAtIndex:settingToDeleteIndex];
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
            // If the deleted time contol is the one currently selected,
            // select the first time control from the list automatically
            if (selectedSettingIndex == settingToDeleteIndex) {
                NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:CHExistingTimeControlSection];
                [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            
                [self updateClockSettings:[[self.settingsManager allChessClockSettings] objectAtIndex:0]];
            
                UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
                [self selectCell:cell];
            }
        }
        else {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Can't delete!", nil)
                                                            message:NSLocalizedString(@"There must be at least one time control.", nil)
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                  otherButtonTitles:nil, nil];
            [alert show];
        }
    }
}

//------------------------------------------------------------------------------
#pragma mark - UIActionSheetDelegate methods
//------------------------------------------------------------------------------
- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == CHDestructiveButtonIndex) {
        [self.settingsManager restoreDefaultClockSettings];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:CHExistingTimeControlSection]
                      withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

//------------------------------------------------------------------------------
#pragma mark - CHChessClockTimeControlTableViewControllerDelegate
//------------------------------------------------------------------------------
- (void)timeControlTableViewController:(CHChessClockTimeControlTableViewController*)viewController
                 newTimeControlCreated:(BOOL)newTimeControlCreated
{
    CHChessClockSettings* settings = viewController.chessClockSettings;
    
    if (newTimeControlCreated) {
        [self.settingsManager addTimeControl:settings];
        
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0
                                                    inSection:CHExistingTimeControlSection];
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    else {
        NSUInteger savedSettingIndex = [[self.settingsManager allChessClockSettings] indexOfObject:settings];
        if (savedSettingIndex != NSNotFound) {
            NSIndexPath* savedSetttingIndexPath = [NSIndexPath indexPathForRow:savedSettingIndex inSection:CHExistingTimeControlSection];
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:savedSetttingIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}

//------------------------------------------------------------------------------
#pragma mark - IBAction methods
//------------------------------------------------------------------------------
- (IBAction)restoreDefaultsTapped
{
    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                               destructiveButtonTitle:NSLocalizedString(@"Restore defaults", nil)
                                                    otherButtonTitles:nil, nil];
    
    UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:CHRestoreDefaultsSection]];
    UIButton* restoreButton = (UIButton*)[cell viewWithTag:CHRestoreDefaultsButtonTag];
    [actionSheet showFromRect:restoreButton.bounds inView:restoreButton animated:YES];
}

- (IBAction)startClockTapped
{
    /*if (self.chessClockViewController == nil) {
        NSString* nibName = [CHUtil nibNameWithBaseName:@"CHChessClockView"];
        CHChessClockViewController* chessClockVC = [[CHChessClockViewController alloc] initWithNibName:nibName bundle:nil];
        self.chessClockViewController = chessClockVC;
    }
    
    //self.chessClockViewController.settingsManager = self.settingsManager;
    self.currentViewController = self.chessClockViewController;
    [self.navigationController pushViewController:self.chessClockViewController animated:YES];*/
}

@end