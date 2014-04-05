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
#import "CHAppDelegate.h"

//------------------------------------------------------------------------------
#pragma mark - Private methods declarations
//------------------------------------------------------------------------------
@interface CHChessClockSettingsTableViewController()
<CHChessClockTimeControlTableViewControllerDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) UIViewController* currentViewController;
@property (weak, nonatomic) IBOutlet UIButton *startClockButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) CHChessClockSettings* timeControlUponAppearance;

@end

//------------------------------------------------------------------------------
#pragma mark - CHChessClockSettingsTableViewController implementation
//------------------------------------------------------------------------------
@implementation CHChessClockSettingsTableViewController

static const NSUInteger CHAddNewTimeControlSection = 0;
static const NSUInteger CHExistingTimeControlSection = 1;

- (void)viewDidLoad
{
    [super viewDidLoad];
 
    CHChessClockSettingsManager* settingsManager = [[CHChessClockSettingsManager alloc] init];
    self.settingsManager = settingsManager;
    self.timeControlUponAppearance = self.settingsManager.currentTimeControl;
    
    self.title = NSLocalizedString(@"Settings", nil);
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    
    
    [self.startClockButton setTitle:NSLocalizedString(@"Start", nil)
                           forState:UIControlStateNormal];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
        
    if ([self.tableView isEditing]) {
        // If the tableView is already in edit mode, turn it off. Also change the title of the button to reflect the intended verb (‘Edit’, in this case).
        [self.tableView setEditing:NO animated:YES];
        self.navigationItem.rightBarButtonItem.title = @"Edit";
    }
    else {
        self.navigationItem.rightBarButtonItem.title = @"Done";
        
        // Turn on edit mode
        
        [self.tableView setEditing:YES animated:YES];
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

- (void)populateNewTimeControlCell:(UITableViewCell*)cell withIndexPath:(NSIndexPath*)indexPath
{
    cell.textLabel.text = NSLocalizedString(@"New Time Control", nil);
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

- (void)startClockAndReset:(BOOL)reset
{
    [self.delegate settingsTableViewControllerDidStartClock:self andReset:reset];
    [self.navigationController popViewControllerAnimated:YES];
}

//------------------------------------------------------------------------------
#pragma mark - UITableViewDataSource methods
//------------------------------------------------------------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 10.f;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == CHAddNewTimeControlSection)
    {
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
#pragma mark - CHChessClockTimeControlTableViewControllerDelegate
//------------------------------------------------------------------------------
- (void)timeControlTableViewController:(CHChessClockTimeControlTableViewController*)viewController
                 newTimeControlCreated:(BOOL)newTimeControlCreated
{
    CHChessClockSettings* settings = viewController.chessClockSettings;
    
    if (newTimeControlCreated)
    {
        [self.settingsManager addTimeControl:settings];
        
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0
                                                    inSection:CHExistingTimeControlSection];
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    else
    {
        if (self.settingsManager.currentTimeControl == settings)
        {
            // So that the clock has the correct state in the case in which the user edits a time control,
            // and immediately after that, tapped the Start button
            [self.delegate settingsTableViewController:self didUpdateSettings:settings];
            
            // This means the player returned from the time control screen (possibly editing the time control),
            // so in this case we want to reset the clock as soon as the Start button is tapped
            self.timeControlUponAppearance = nil;
        }
        
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
- (IBAction)startClockTapped
{
    if (self.timeControlUponAppearance == self.settingsManager.currentTimeControl)
    {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Reset Clock?", nil)
                                                        message:nil
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Yes", nil)
                                              otherButtonTitles:NSLocalizedString(@"No", nil), nil];
        [alert show];
    }
    else
    {
        [self startClockAndReset:YES];
    }
}

- (IBAction)didTouchUpInsideChessLogoButton:(id)sender
{
    NSURL *url = [NSURL URLWithString:@"https://itunes.apple.com/app/chess-play-learn/id329218549?mt=8"];
    
    [[UIApplication sharedApplication] openURL:url];
}

//------------------------------------------------------------------------------
#pragma mark - UIAlertViewDelegate methods
//------------------------------------------------------------------------------
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self startClockAndReset:buttonIndex == alertView.cancelButtonIndex];
}

@end
