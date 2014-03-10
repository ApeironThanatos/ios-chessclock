//
//  CHTimeControlTableViewController.m
//  Chess.com
//
//  Created by Pedro Bolaños on 10/25/12.
//  Copyright (c) 2012 psbt. All rights reserved.
//

#import "CHChessClockTimeControlTableViewController.h"
#import "CHChessClockSettings.h"
#import "CHChessClockIncrementTableViewController.h"
#import "CHChessClockTimeControlStageTableViewController.h"
#import "CHChessClockIncrement.h"
#import "CHChessClockFischerIncrement.h"
#import "CHChessClockTimeControlStageManager.h"
#import "CHChessClockTimeControlStage.h"
#import "CHChessClockTimeViewController.h"
#import "CHUtil.h"

//------------------------------------------------------------------------------
#pragma mark Private methods declarations
//------------------------------------------------------------------------------
@interface CHChessClockTimeControlTableViewController()
<CHChessClockIncrementTableViewControllerDelegate, CHChessClockTimeControlStageTableViewControllerDelegate,
CHChessClockTimeViewControllerDelegate, UIPopoverControllerDelegate>

@property (retain, nonatomic) IBOutlet UITableViewCell* nameTableViewCell;

@property (assign, nonatomic) BOOL newTimeControlCreated;
@property (assign, nonatomic) BOOL newTimeControlSaved;
@property (weak, nonatomic) CHChessClockTimeControlStage* stageToUpdate;

@end

//------------------------------------------------------------------------------
#pragma mark CHTimeControlTableViewController implementation
//------------------------------------------------------------------------------
@implementation CHChessClockTimeControlTableViewController

static const NSUInteger CHNameSection = 0;
static const NSUInteger CHExistingTimeControlStagesSection = 1;
static const NSUInteger CHNewTimeControlStageSection = 2;
static const NSUInteger CHIncrementSection = 3;
static const NSUInteger CHSectionCount = 4;

static const NSUInteger CHNameTextFieldTag = 1;

static const NSUInteger CHMaxTimeControlStages = 3;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Time Control", nil);
    self.newTimeControlSaved = NO;
    
    if (self.chessClockSettings == nil) {
        self.newTimeControlCreated = YES;
        
        UIBarButtonItem* rightBarButtonItem = [[UIBarButtonItem alloc]
                                               initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                               target:self action:@selector(saveButtonTapped)];

        self.navigationItem.rightBarButtonItem = rightBarButtonItem;
        
        self.navigationItem.rightBarButtonItem.enabled = NO;
        
        // The user wants to create new time control. By default, use a Fischer
        // increment, and a single time stage
        CHChessClockFischerIncrement* increment = [[CHChessClockFischerIncrement alloc] initWithIncrementValue:5];
        CHChessClockTimeControlStageManager* stageManager = [[CHChessClockTimeControlStageManager alloc] init];
        [stageManager addTimeStageWithMovesCount:0 andMaximumTime:300];
        
        CHChessClockSettings* clockSettings = [[CHChessClockSettings alloc] initWithName:nil
                                                                               increment:increment
                                                                         andStageManager:stageManager];
        self.chessClockSettings = clockSettings;
    }
    else {
        self.newTimeControlCreated = NO;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (!self.newTimeControlSaved && !self.newTimeControlCreated) {
        NSString* name = [self validateName];
        if (name != nil) {
            self.chessClockSettings.name = name;
            [self.delegate timeControlTableViewController:self newTimeControlCreated:NO];
        }
    }
}

//------------------------------------------------------------------------------
#pragma mark - UITableViewDataSource methods
//------------------------------------------------------------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if ([self.chessClockSettings.stageManager stageCount] == CHMaxTimeControlStages) {
        return CHSectionCount - 1;
    }
    
    return CHSectionCount;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case CHNameSection:
            return NSLocalizedString(@"Name", nil);
            break;
            
        case CHExistingTimeControlStagesSection:
            return NSLocalizedString(@"Stages", nil);
            break;

        case CHNewTimeControlStageSection:
            if ([self.chessClockSettings.stageManager stageCount] == CHMaxTimeControlStages) {
                // If the number of time control stages is the maximum, it means that
                // that the new time control stage section was deleted. Treat this
                // section as the increment section
                return NSLocalizedString(@"Increment", nil);
            }
            
            return nil;
            break;

        case CHIncrementSection:
            return NSLocalizedString(@"Increment", nil);
            break;
            
        default:
            break;
    }
    
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case CHNameSection:
            return 1;
            break;
            
        case CHExistingTimeControlStagesSection:
            return [self.chessClockSettings.stageManager stageCount];
            break;
            
        case CHNewTimeControlStageSection:
            return 1;
            break;
            
        case CHIncrementSection:
            return 1;
            break;
            
        default:
            break;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 7)
    {
        tableView.tintColor = [UIColor blackColor];
    }
    UITableViewCell* cell = nil;
    switch (indexPath.section) {
        case CHNameSection:
            cell = [self nameCell];
            break;
            
        case CHExistingTimeControlStagesSection:
            cell = [self timeControlStageCellForRow:indexPath.row];
            break;
            
        case CHNewTimeControlStageSection:
            if ([self.chessClockSettings.stageManager stageCount] == CHMaxTimeControlStages) {
                // If the number of time control stages is the maximum, it means that
                // that the new time control section was deleted. Treat this
                // section as the increment section
                cell = [self incrementCell];
            }
            else {
                cell = [self addTimeControlStageCell];
            }
            
            break;
            
        case CHIncrementSection:
            cell = [self incrementCell];
            break;
            
        default:
            break;
    }
    
    [cell.textLabel setFont:[UIFont boldSystemFontOfSize:15]];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Allow editing (deleting rows) if the row is:
    // - One of the time control stages
    // - Not the first time control stage row (we always need at least one stage)
    return indexPath.section == CHExistingTimeControlStagesSection && indexPath.row != 0;
}

//------------------------------------------------------------------------------
#pragma mark - UITableViewDelegate methods
//------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case CHNameSection:
            [self selectedNameCellWithIndexPath:indexPath];
            break;
            
        case CHExistingTimeControlStagesSection:
            [self selectedExistingTimeControllCellWithIndexPath:indexPath];
            break;
        
        case CHNewTimeControlStageSection:
            if ([self.chessClockSettings.stageManager stageCount] == CHMaxTimeControlStages) {
                [self selectedIncrementCellWithIndexPath:indexPath];
            }
            break;
            
        case CHIncrementSection:
            [self selectedIncrementCellWithIndexPath:indexPath];
            break;
            
        default:
            break;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self removeTimeStageAtIndex:indexPath.row];
    }
}

//------------------------------------------------------------------------------
#pragma mark Private methods definitions
//------------------------------------------------------------------------------
- (UITableViewCell*)nameCell
{
    NSString* cellIdentifier = @"CHChessClockTimeControlNameCell";
    UITableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        NSArray* nib = [[NSBundle mainBundle] loadNibNamed:@"CHChessClockTimeControlNameCell" owner:self options:nil];
        if ([nib count] > 0) {
            cell = self.nameTableViewCell;
            
            UITextField* nameTextField = (UITextField*)[cell viewWithTag:CHNameTextFieldTag];
            nameTextField.placeholder = NSLocalizedString(@"Enter time control name", nil);
            [nameTextField addTarget:self action:@selector(nameTextFielEditingDidEndOnExit:) forControlEvents:UIControlEventEditingDidEndOnExit];
            [nameTextField addTarget:self action:@selector(nameTextFieldBeingEdited:) forControlEvents:UIControlEventEditingChanged];
        }
    }
    
    UITextField* nameTextField = (UITextField*)[cell viewWithTag:CHNameTextFieldTag];
    nameTextField.text = self.chessClockSettings.name;
    return cell;
}

- (UITableViewCell*)timeControlStageCellForRow:(NSUInteger)row
{
    NSString* cellIdentifier = @"CHChessClockTimeControlStageCell";
    UITableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                       reuseIdentifier:cellIdentifier];

        cell.detailTextLabel.font = [UIFont systemFontOfSize:15.0f];
    }

    cell.textLabel.text = [NSString stringWithFormat:@"%@ %d", NSLocalizedString(@"Stage", nil), row + 1];
    cell.detailTextLabel.text = [[self.chessClockSettings.stageManager stageAtIndex:row] description];
    
    UIUserInterfaceIdiom idiom = [[UIDevice currentDevice] userInterfaceIdiom];
    if (idiom == UIUserInterfaceIdiomPad && [self.chessClockSettings.stageManager stageCount] == 1) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    return cell;
}

- (UITableViewCell*)addTimeControlStageCell
{
    NSString* cellIdentifier = @"CHChessClockNewTimeControlStageCell";
    UITableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:cellIdentifier];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        // This removes the cell rounded background
        UIView* backgroundView = [[UIView alloc] initWithFrame:cell.bounds];
        cell.backgroundView = backgroundView;
        
        UIButton* addButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        addButton.frame = cell.bounds;
        addButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [addButton setTitle:NSLocalizedString(@"Add stage", nil) forState:UIControlStateNormal];
        [addButton addTarget:self action:@selector(addStageButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:addButton];
    }
    
    return cell;
}

- (UITableViewCell*)incrementCell
{
    NSString* cellIdentifier = @"CHChessClockIncrementCell";
    UITableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                       reuseIdentifier:cellIdentifier];
        
        cell.textLabel.text = NSLocalizedString(@"Type", nil);
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.detailTextLabel.font = [UIFont systemFontOfSize:15.0f];
    }
    
    NSUInteger incrementValue = self.chessClockSettings.increment.incrementValue;
    NSString* incrementValueString = [CHUtil formatTime:incrementValue showTenths:NO];
    
    if (incrementValue < 60) {
        NSString* secondsString = NSLocalizedString(@"secs", @"Abbreviation for seconds");
        if (incrementValue == 1) {
            secondsString = NSLocalizedString(@"sec", @"Abbreviation for second");
        }
        
        incrementValueString = [NSString stringWithFormat:@"%d %@", incrementValue, secondsString];
    }
    
    NSString* detailString = [NSString stringWithFormat:@"%@, %@",
                              [self.chessClockSettings.increment description], incrementValueString];
    
    cell.detailTextLabel.text = detailString;
    return cell;
}

- (NSString*)validateName
{
    UITextField* nameTextField = [self nameTextField];
    NSString* timeControlName = [nameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if ([timeControlName length] == 0) {
        return nil;
    }
    
    return timeControlName;
}

- (void)removeTimeStageAtIndex:(NSUInteger)timeStageIndex
{
    [self.chessClockSettings.stageManager removeTimeStageAtIndex:timeStageIndex];
    
    [self.tableView beginUpdates];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:CHExistingTimeControlStagesSection]
                  withRowAnimation:UITableViewRowAnimationAutomatic];
    
    if ([self.tableView numberOfSections] < CHSectionCount) {
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:CHNewTimeControlStageSection]
                      withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
    [self.tableView endUpdates];
}

- (UITextField*)nameTextField
{
    UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:CHNameSection]];
    UIView* view = [cell viewWithTag:CHNameTextFieldTag];
    if ([view isKindOfClass:[UITextField class]]) {
        UITextField* nameTextField = (UITextField*)view;
        return nameTextField;
    }
    
    return nil;
}

- (void)addStageButtonTapped
{
    // The last stage can't have a number of moves
    CHChessClockTimeControlStage* stage = [[CHChessClockTimeControlStage alloc]
                                           initWithMovesCount:0 andMaximumTime:300];
    
    [self.chessClockSettings.stageManager addTimeStage:stage];
    
    NSUInteger stageCount = [self.chessClockSettings.stageManager stageCount];
    
    [self.tableView beginUpdates];

    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:CHExistingTimeControlStagesSection]
                  withRowAnimation:UITableViewRowAnimationAutomatic];
    
    if (stageCount == CHMaxTimeControlStages) {
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:CHNewTimeControlStageSection]
                      withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
    [self.tableView endUpdates];
}

- (void)reloadRowWithStage:(CHChessClockTimeControlStage*)stage
{
    if (stage != nil) {
        NSUInteger stageIndex = [self.chessClockSettings.stageManager indexOfStage:stage];
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:stageIndex inSection:CHExistingTimeControlStagesSection];
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)selectedNameCellWithIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
    UITextField* nameTextField = (UITextField*)[cell viewWithTag:CHNameTextFieldTag];
    [nameTextField becomeFirstResponder];
}

- (void)selectedExistingTimeControllCellWithIndexPath:(NSIndexPath*)indexPath
{
    if (indexPath.row == 0 && [self.chessClockSettings.stageManager stageCount] == 1) {
        // If there's only one stage, send the player directly to the
        // screen where we can pick the time
        NSString* nibName = [CHUtil nibNameWithBaseName:@"CHChessClockTimeView"];
        CHChessClockTimeViewController* timeViewController = [[CHChessClockTimeViewController alloc]
                                                              initWithNibName:nibName bundle:nil];
        
        self.stageToUpdate = [self.chessClockSettings.stageManager stageAtIndex:indexPath.row];
        
        timeViewController.delegate = self;
        timeViewController.maximumHours = 11;
        timeViewController.maximumMinutes = 60;
        timeViewController.maximumSeconds = 60;
        timeViewController.selectedTime = self.stageToUpdate.maximumTime;
        timeViewController.title = NSLocalizedString(@"Time", nil);
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            UIPopoverController* popover = [[UIPopoverController alloc] initWithContentViewController:timeViewController];
            popover.delegate = self;
            UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
            
            [popover presentPopoverFromRect:cell.bounds inView:cell
                   permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            
        }
        else {
            [self.navigationController pushViewController:timeViewController animated:YES];
        }
    }
    else {
        NSString* nibName = [CHUtil nibNameWithBaseName:@"CHChessClockTimeControlStageView"];
        CHChessClockTimeControlStageTableViewController* stageViewController = [[CHChessClockTimeControlStageTableViewController alloc]
                                                                      initWithNibName:nibName bundle:nil];
        stageViewController.delegate = self;
        stageViewController.title = [self.tableView cellForRowAtIndexPath:indexPath].textLabel.text;
        stageViewController.timeControlStageManager = self.chessClockSettings.stageManager;
        stageViewController.timeControlStage = [self.chessClockSettings.stageManager stageAtIndex:indexPath.row];
        
        [self.navigationController pushViewController:stageViewController animated:YES];
    }
}

- (void)selectedIncrementCellWithIndexPath:(NSIndexPath*)indexPath
{
    NSString* nibName = [CHUtil nibNameWithBaseName:@"CHChessClockIncrementView"];
    CHChessClockIncrementTableViewController* vc = [[CHChessClockIncrementTableViewController alloc]
                                                    initWithNibName:nibName bundle:nil];
    
    vc.increment = self.chessClockSettings.increment;
    vc.delegate = self;

    [self.navigationController pushViewController:vc animated:YES];
}

//------------------------------------------------------------------------------
#pragma mark - IBActions
//------------------------------------------------------------------------------
- (IBAction)saveButtonTapped
{
    self.newTimeControlSaved = YES;

    UITextField* nameTextField = [self nameTextField];
    self.chessClockSettings.name = nameTextField.text;

    [self.delegate timeControlTableViewController:self newTimeControlCreated:YES];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)nameTextFielEditingDidEndOnExit:(UITextField*)sender
{
    [sender resignFirstResponder];
}

- (IBAction)nameTextFieldBeingEdited:(UITextField*)sender
{
    NSString* name = [self validateName];
    if (name != nil) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    else {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
}

//------------------------------------------------------------------------------
#pragma mark - UIPopoverControllerDelegate methods
//------------------------------------------------------------------------------
- (void)popoverControllerDidDismissPopover:(UIPopoverController*)popoverController
{
    NSIndexPath* selectedIndexPath = [self.tableView indexPathForSelectedRow];
    [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
}

//------------------------------------------------------------------------------
#pragma mark - CHChessClockIncrementViewControllerDelegate methods
//------------------------------------------------------------------------------
- (void)chessClockIncrementTableViewControllerUpdatedIncrement:(CHChessClockIncrementTableViewController*)viewController
{
    self.chessClockSettings.increment = viewController.increment;
    
    NSUInteger section = CHIncrementSection;
    if ([self.chessClockSettings.stageManager stageCount] == CHMaxTimeControlStages) {
        // If the number of time control stages is the maximum, it means that
        // that the new time control section was deleted. The increment section
        // is now the "new time control stage" section
        section = CHNewTimeControlStageSection;
    }
    
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:section];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

//------------------------------------------------------------------------------
#pragma mark - CHTimeControlStageTableViewControllerDelegate methods
//------------------------------------------------------------------------------
- (void)timeControlStageTableViewControllerStageUpdated:(CHChessClockTimeControlStageTableViewController*)viewController
{
    [self reloadRowWithStage:viewController.timeControlStage];
}

- (void)timeControlStageTableViewControllerStageDeleted:(CHChessClockTimeControlStageTableViewController*)viewController
{
    NSUInteger stageIndex = [self.chessClockSettings.stageManager indexOfStage:viewController.timeControlStage];
    [self removeTimeStageAtIndex:stageIndex];
}

//------------------------------------------------------------------------------
#pragma mark - CHChessClockTimeViewControllerDelegate methods
//------------------------------------------------------------------------------
- (void)chessClockTimeViewController:(CHChessClockTimeViewController*)timeViewController
              closedWithSelectedTime:(NSUInteger)timeInSeconds
{
    self.stageToUpdate.maximumTime = timeInSeconds;
    [self reloadRowWithStage:self.stageToUpdate];
    self.stageToUpdate = nil;
}

@end