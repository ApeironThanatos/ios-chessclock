//
//  CHChessClockSettingsTableViewController.h
//  Chess.com
//
//  Created by Pedro Bolaños on 10/24/12.
//  Copyright (c) 2012 psbt. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CHChessClockSettingsManager;
@class CHChessClockSettings;

@protocol CHChessClockSettingsTableViewControllerDelegate <NSObject>

- (void)settingsTableViewController:(id)settingsTableViewController
                  didUpdateSettings:(CHChessClockSettings *)settings;

@end

//------------------------------------------------------------------------------
#pragma mark - CHChessClockSettingsTableViewController
//------------------------------------------------------------------------------
@interface CHChessClockSettingsTableViewController : UITableViewController

@property (retain, nonatomic) CHChessClockSettingsManager* settingsManager;
@property (weak, nonatomic) id <CHChessClockSettingsTableViewControllerDelegate> delegate;


@end