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

@interface FBGroupShareViewController ()

@end

@implementation FBGroupShareViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.navigationItem.title = @"Share to groups";
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"AvenirNext-Regular" size:17],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    [self.tableView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    
    self.tableView.tableHeaderView = self.headerView;
    
    //fb group stuff
    self.arrayOfGroups = [[NSMutableArray alloc]init];
    self.filteredGroups = [NSMutableArray array];
    
    //set up search
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    
    self.navigationItem.titleView = self.searchController.searchBar;
    self.searchController.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchController.searchBar.delegate = self;
    [self.searchController.searchBar sizeToFit];
    self.definesPresentationContext = NO;
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    self.navigationController.extendedLayoutIncludesOpaqueBars = true;
    self.searchController.searchBar.placeholder = @"Search groups";
    self.searchController.searchBar.tintColor = [UIColor colorWithRed:0.525 green:0.745 blue:1 alpha:1];
    
    PFQuery *groupsQuery = [PFQuery queryWithClassName:@"groups"];
    [groupsQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            [self.arrayOfGroups addObjectsFromArray:objects];
            [self.tableView reloadData];
        }
        else{
            NSLog(@"error %@", error);
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    PFQuery *query = [PFQuery queryWithClassName:@"wantobuys"];
    [query whereKey:@"objectId" equalTo:self.objectId];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            NSString *title = [object objectForKey:@"title"];
            NSString *condition = [object objectForKey:@"condition"];
            NSString *size = [object objectForKey:@"size"];
            
            self.textView.text = [NSString stringWithFormat:@"WTB: %@ %@ in a %@. More details on wantobuy", condition, title, size];
        }
        else{
            NSLog(@"error %@", error);
        }
    }];
}

-(void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString *searchString = searchController.searchBar.text;
    [self searchForText:searchString];
}

- (void)searchForText:(NSString*)searchText
{
    if ([searchText isEqualToString:@""]) {
        self.filtered = NO;
        [self.tableView reloadData];
    }
    else{
        NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"groupName contains[c] %@", searchText];
        NSArray *array = [self.arrayOfGroups filteredArrayUsingPredicate:resultPredicate];
        [self.filteredGroups removeAllObjects];
        [self.filteredGroups addObjectsFromArray:array];
        self.filtered = YES;
        
        //update table view
        [self.tableView reloadData];
    }
}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.filtered) {
        return self.filteredGroups.count;
    }
    else{
       return self.arrayOfGroups.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    
    PFObject *group;
    
    if (self.filtered) {
        group = [self.filteredGroups objectAtIndex:indexPath.row];
    }
    else{
        group = [self.arrayOfGroups objectAtIndex:indexPath.row];
    }
    
    cell.textLabel.text = [group objectForKey:@"groupName"];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *groupId = [[NSString alloc]init];
    
    if (self.filtered) {
        groupId = [[self.filteredGroups objectAtIndex:indexPath.row] objectForKey:@"groupId"];
    }
    else{
        groupId = [[self.arrayOfGroups objectAtIndex:indexPath.row] objectForKey:@"groupId"];
    }
    
    NSString *url = [NSString stringWithFormat:@"https://www.facebook.com/groups/%@/", groupId];

//    NSString *url = [NSString stringWithFormat:@"https://m.facebook.com/groups/%@?tsid=0.12355867517180741&source=typeahead&soft=composer", groupId];
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
     
@end
