//
//  FBGroupShareViewController.h
//  
//
//  Created by Jack Ryder on 25/03/2016.
//
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>


@interface FBGroupShareViewController : UITableViewController

//extras
@property (weak, nonatomic) IBOutlet UITextView *textView;

@property (nonatomic, strong) NSArray *groupsArray;

@property (strong, nonatomic) IBOutlet UIView *headerView;
@property (nonatomic, strong) NSString *objectId;
@property (nonatomic, strong) NSMutableArray *arrayOfGroups;
@property (weak, nonatomic) IBOutlet UIButton *textCopyButton;

//search
@property (nonatomic) BOOL filtered;
@property (strong, nonatomic) NSMutableArray *filteredGroups;
@end
