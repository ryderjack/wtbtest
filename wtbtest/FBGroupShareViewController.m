//
//  FBGroupShareViewController.m
//  
//
//  Created by Jack Ryder on 25/03/2016.
//
//

#import "FBGroupShareViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "groupWVController.h"
#import <Crashlytics/Crashlytics.h>

@interface FBGroupShareViewController ()

@end

@implementation FBGroupShareViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.textView.text = @"";
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.navigationItem.title = @"G R O U P  S H A R E";
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
    
    [self.tableView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    
    self.tableView.tableHeaderView = self.headerView;
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc]initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(dismissVC)];
    
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    //fb group stuff
    self.arrayOfGroups = [NSMutableArray array];
    self.filteredGroups = [NSMutableArray array];
    
    //deleting schema on backend messes with undeleted objects so watch out!
    
    PFQuery *groupsQuery = [PFQuery queryWithClassName:@"groups"];
    [groupsQuery orderByAscending:@"groupName"];
    [groupsQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            [self.arrayOfGroups addObjectsFromArray:objects];
            [self.tableView reloadData];
        }
        else{
            NSLog(@"error getting groups%@", error);
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Regular" size:13],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;

    PFQuery *query = [PFQuery queryWithClassName:@"wantobuys"];
    [query whereKey:@"objectId" equalTo:self.objectId];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            NSString *title = [object objectForKey:@"title"];
            NSString *condition = [object objectForKey:@"condition"];
            NSString *size = [object objectForKey:@"sizeLabel"];
            
            self.textView.text = [NSString stringWithFormat:@"WTB:\n%@\nCondition: %@\nSize: %@", title, condition, size];
            
            //\nPosted via Bump http://apple.co/2aY3rBk
        }
        else{
            NSLog(@"error %@", error);
        }
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//    if (self.filtered) {
//        return self.filteredGroups.count;
//    }
//    else{
       return self.arrayOfGroups.count;
//    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    PFObject *group = [self.arrayOfGroups objectAtIndex:indexPath.row];
    cell.textLabel.text = [group objectForKey:@"groupName"];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [Answers logCustomEventWithName:@"Viewed page"
                   customAttributes:@{
                                      @"pageName":@"Group Share"
                                      }];

    
    NSString *groupId = [[NSString alloc]init];
//    
//    if (self.filtered) {
//        groupId = [[self.filteredGroups objectAtIndex:indexPath.row] objectForKey:@"groupId"];
//    }
//    else{
        groupId = [[self.arrayOfGroups objectAtIndex:indexPath.row] objectForKey:@"groupId"];
//    }
    
    NSString *url = [NSString stringWithFormat:@"https://www.facebook.com/groups/%@/", groupId];
    groupWVController *vc = [[groupWVController alloc]init];
    vc.groupURL = url;
    [self.navigationController pushViewController:vc animated:YES];
}
- (IBAction)copyPressed:(id)sender {
    self.textCopyButton.titleLabel.text = @"Copied!";
    
    double delayInSeconds = 5.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            self.textCopyButton.titleLabel.text = @"Copy";
    });
    UIPasteboard *pb = [UIPasteboard generalPasteboard];
    [pb setString:[self.textView text]];
}

-(void)dismissVC{
    [self dismissViewControllerAnimated:YES completion:nil];
}
     
@end
