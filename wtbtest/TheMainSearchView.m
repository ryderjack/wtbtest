//
//  TheMainSearchView.m
//  
//
//  Created by Jack Ryder on 22/12/2016.
//
//

#import "TheMainSearchView.h"
#import "UserProfileController.h"
#import "NavigationController.h"
#import <Crashlytics/Crashlytics.h>
#import "SearchCell.h"
#import "UIImageView+Letters.h"
#import <Intercom/Intercom.h>

@interface TheMainSearchView ()

@end

@implementation TheMainSearchView

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self.tableView registerNib:[UINib nibWithNibName:@"SearchCell" bundle:nil] forCellReuseIdentifier:@"Cell"];
    
    self.searchString = @"";
    
    self.userSearch = NO;
    self.sellingSearch = YES;
    
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchBar.delegate = self;
    self.navigationItem.titleView = self.searchBar;
    [self.searchBar sizeToFit];
    self.searchBar.showsCancelButton = YES;

    //set search bar font attributes
    [[UITextField appearanceWhenContainedInInstancesOfClasses:@[[UISearchBar class]]] setDefaultTextAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"PingFangSC-Regular" size:14]}];
    
    //force cancel button to be enabled
    UIButton *btnCancel = [self.searchBar valueForKey:@"_cancelButton"];
    [btnCancel setEnabled:YES];

    if (@available(iOS 11.0, *)) {
        //nav bar height will be 56 (coz of bigger search bars)
        //move placeholder view and table view slightly down
        //was 12
        
        int adjust = 12;
        //iPhone X has a bigger status bar - was 20px now 44px
        
        if ([ [ UIScreen mainScreen ] bounds ].size.height == 812) {
            //iPhone X
            adjust = 34;
        }
        
        [self.placeholderView setFrame:CGRectMake(self.placeholderView.frame.origin.x, self.placeholderView.frame.origin.y+adjust, [UIApplication sharedApplication].keyWindow.frame.size.width,self.placeholderView.frame.size.height)];
        
        [self.tableView setContentInset:UIEdgeInsetsMake(adjust, 0, 0, 0)];
    }
    else{
        //nav bar height will be standard 44
        self.searchBar.placeholder = @"Search through items for sale";
    }
    
    //segment control
    self.segmentedControl = [[HMSegmentedControl alloc] init];
    self.segmentedControl.frame = CGRectMake(self.placeholderView.frame.origin.x, self.placeholderView.frame.origin.y, [UIApplication sharedApplication].keyWindow.frame.size.width,self.placeholderView.frame.size.height);
    
    self.segmentedControl.selectionStyle = HMSegmentedControlSelectionStyleFullWidthStripe;
    self.segmentedControl.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocationDown;
    self.segmentedControl.selectionIndicatorColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0];
    self.segmentedControl.selectionIndicatorHeight = 2;
    self.segmentedControl.titleTextAttributes = @{NSFontAttributeName : [UIFont fontWithName:@"PingFangSC-Medium" size:9],NSForegroundColorAttributeName : [UIColor lightGrayColor]};
    self.segmentedControl.selectedTitleTextAttributes = @{NSForegroundColorAttributeName : [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0]};
    
    [self.segmentedControl addTarget:self action:@selector(segmentControlChanged) forControlEvents:UIControlEventValueChanged];
    [self.segmentedControl setSectionTitles:@[@"F O R  S A L E",@"W A N T E D",@"P E O P L E"]];
    [self.view addSubview:self.segmentedControl];
    
    
//    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelPressed)];
//    self.navigationItem.rightBarButtonItem = cancelButton;
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
    
    self.wantedSearchResults = [[[[PFUser currentUser]objectForKey:@"searches"] reverseObjectEnumerator] allObjects];
    self.sellingSearchResults = [[[[PFUser currentUser]objectForKey:@"sellingSearches"] reverseObjectEnumerator] allObjects];

    self.userResults = [NSArray array];
    
    [self addDoneButton];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self.searchBar becomeFirstResponder];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if (@available(iOS 11.0, *)) {
        NSString *placeholder = @"";
        
        if (self.segmentedControl.selectedSegmentIndex == 0) {
            placeholder = @"Search through items for sale";
        }
        else if (self.segmentedControl.selectedSegmentIndex == 1) {
            placeholder = @"Search through items people want";
        }
        else{
            placeholder = @"Search for users";
        }
        
        UITextField *txfSearchField = [self.searchBar valueForKey:@"searchField"];
        [txfSearchField setAttributedPlaceholder:[[NSAttributedString alloc] initWithString:placeholder attributes:@{NSFontAttributeName: [UIFont fontWithName:@"PingFangSC-Regular" size:14]}]];
    }
    
    
    [self.navigationController.navigationBar setHidden:NO];
    self.searchBar.text = @"";
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)segmentControlChanged{
    NSString *placeholder = @"";
    
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        self.userSearch = NO;
        self.sellingSearch = YES;
        
        placeholder = @"Search through items for sale";
        
        if (self.noUserLabel) {
            [self.noUserLabel removeFromSuperview];
            self.noUserLabel = nil;
        }
    }
    else if (self.segmentedControl.selectedSegmentIndex == 1) {
        self.userSearch = NO;
        self.sellingSearch = NO;
       
        placeholder = @"Search through wanted items";
        
        if (self.noUserLabel) {
            [self.noUserLabel removeFromSuperview];
            self.noUserLabel = nil;
        }
    }
    else{
        self.userSearch = YES;
        self.sellingSearch = NO;
        
        placeholder = @"Search for users";
    }
    
    UITextField *txfSearchField = [self.searchBar valueForKey:@"searchField"];
    [txfSearchField setAttributedPlaceholder:[[NSAttributedString alloc] initWithString:placeholder attributes:@{NSFontAttributeName: [UIFont fontWithName:@"PingFangSC-Regular" size:14]}]];
    

    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.userSearch == NO && self.sellingSearch == NO) {
        return self.wantedSearchResults.count;
    }
    else if (self.userSearch == NO && self.sellingSearch == YES) {
        return self.sellingSearchResults.count;
    }
    else{
        return self.userResults.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SearchCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    cell.usernameLabel.text = @"";
    cell.nameLabel.text = @"";
    cell.userImageView.image = nil;
    
    if (self.userSearch == YES) {
        if (self.userResults.count >=indexPath.row+1) {
            PFUser *user = self.userResults[indexPath.row];
            
            [cell.userImageView setHidden:NO];
            [self setImageBorder:cell.userImageView];
            
            cell.usernameLabel.text = user.username;
            cell.nameLabel.text = [user objectForKey:@"fullname"];
            
            if(![user objectForKey:@"picture"]){
                
                NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Medium" size:15],
                                                NSFontAttributeName, [UIColor lightGrayColor],NSForegroundColorAttributeName, nil];
                
                [cell.userImageView setImageWithString:user.username color:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1] circular:NO textAttributes:textAttributes];
            }
            else{
                [cell.userImageView setFile:[user objectForKey:@"picture"]];
                [cell.userImageView loadInBackground];
            }
        }
    }
    else if (self.sellingSearch == NO && self.userSearch == NO){
        [cell.userImageView setHidden:YES];
        cell.usernameLabel.text = self.wantedSearchResults[indexPath.row];
    }
    else if (self.sellingSearch == YES && self.userSearch == NO){
        [cell.userImageView setHidden:YES];
        cell.usernameLabel.text = self.sellingSearchResults[indexPath.row];
    }
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 70;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if (self.userSearch == YES) {
        PFUser *user = [self.userResults objectAtIndex:indexPath.row];
        
        if ([user.objectId isEqualToString:[PFUser currentUser].objectId]) {
            //do something? //CHECK
        }
        UserProfileController *vc = [[UserProfileController alloc]init];
        vc.user = user;
        vc.fromSearch = YES;
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if(self.userSearch == NO && self.sellingSearch == NO){
        //wanted selected
        NSString *searchText = [NSString stringWithFormat:@"%@",[self.wantedSearchResults objectAtIndex:indexPath.row]];
        self.searchString = searchText;
        
        NSMutableArray *placeholder = [NSMutableArray arrayWithArray:self.wantedSearchResults];
        
        if (![[placeholder firstObject] isEqualToString:searchText]) {
            [placeholder removeObject:searchText];
            [placeholder insertObject:searchText atIndex:0];
        }
        
        self.wantedSearchResults = placeholder;
        
        NSArray *arrayToSave = [[placeholder reverseObjectEnumerator] allObjects];
        
        [[PFUser currentUser] setObject:arrayToSave forKey:@"searches"];
        [[PFUser currentUser] saveInBackground];
        
        [self.searchBar resignFirstResponder];
        searchedViewC *vc = [[searchedViewC alloc]init];
        vc.searchString = searchText;
        vc.currencySymbol = self.currencySymbol;
        vc.currency = self.currency;
        vc.delegate = self;
        vc.currentLocation = self.geoPoint;
        vc.tabBarHeight = self.tabBarHeight;
        vc.sellingSearch = self.sellingSearch;
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if(self.userSearch == NO && self.sellingSearch == YES){
        //selling selected
        NSString *searchText = [NSString stringWithFormat:@"%@",[self.sellingSearchResults objectAtIndex:indexPath.row]];
        self.searchString = searchText;
        
        NSMutableArray *placeholder = [NSMutableArray arrayWithArray:self.sellingSearchResults];
        
        NSLog(@"PLACEHOLDER: %@", placeholder);
        
        if (![[placeholder firstObject] isEqualToString:searchText]) {
            [placeholder removeObject:searchText];
            [placeholder insertObject:searchText atIndex:0];
        }
        
        self.sellingSearchResults = placeholder;
        
        //need to reverse before saving because when we load it we reverse it
        NSArray *arrayToSave = [[placeholder reverseObjectEnumerator] allObjects];

        [[PFUser currentUser] setObject:arrayToSave forKey:@"sellingSearches"]; //was placeholder
        [[PFUser currentUser] saveInBackground];

        [self.searchBar resignFirstResponder];
        searchedViewC *vc = [[searchedViewC alloc]init];
        vc.searchString = searchText;
        vc.currencySymbol = self.currencySymbol;
        vc.currency = self.currency;
        vc.delegate = self;
        vc.currentLocation = self.geoPoint;
        vc.tabBarHeight = self.tabBarHeight;
        vc.sellingSearch = self.sellingSearch;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    NSLog(@"cancel button clicked");
    [self cancelPressed];
}

-(void)cancelPressed{
    NSLog(@"cancel pressed");

    [self.searchBar resignFirstResponder];
    [self.delegate cancellingMainSearch];
    [self.noUserLabel removeFromSuperview];
    self.noUserLabel = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar{
    NSLog(@"did end editing");
    
    self.searchString = searchBar.text;
    NSString *stringCheck = [self.searchString stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    //force cancel button to be enabled
    UIButton *btnCancel = [self.searchBar valueForKey:@"_cancelButton"];
    [btnCancel setEnabled:YES];
    
    if (self.userSearch == NO && self.sellingSearch == NO){
        //wanted selected
        NSMutableArray *history = [NSMutableArray array];
        
        //save the search term and if there's 10 or more items in the search array delete the oldest and add the latest term
        if (![stringCheck isEqualToString:@""]) {
            
            // if haven't searched before create empty array to avoid crashing
            if ([[PFUser currentUser] objectForKey:@"searches"]) {
                NSMutableArray *searchHistory = [NSMutableArray array];
                [searchHistory addObjectsFromArray:[[PFUser currentUser] objectForKey:@"searches"]];
                
                if (searchHistory.count >= 15) {
                    [searchHistory removeObjectAtIndex:0];
                }
                
                if (![[searchHistory lastObject] isEqualToString:self.searchString] && [history containsObject:self.searchString]) {
                    [searchHistory removeObject:self.searchString];
                    [searchHistory addObject:self.searchString];
                }
                else if (![searchHistory containsObject:self.searchString]) {
                    [searchHistory addObject:self.searchString];
                }
                [[PFUser currentUser] setObject:searchHistory forKey:@"searches"];
            }
            else{
                NSLog(@"no history as new user so add first object");
                [history addObject:self.searchString];
                [[PFUser currentUser] setObject:history forKey:@"searches"];
            }
            [[PFUser currentUser] saveInBackground];
        }
        
        //update results controller UI since only updated via query every time search button pressed
        NSMutableArray *searchesList = [NSMutableArray arrayWithArray:self.wantedSearchResults];
        
        if (searchesList.count > 0) {
            if ([searchesList containsObject:self.searchString] && ![searchesList[0] isEqualToString:self.searchString]) {
                [searchesList removeObject:self.searchString];
            }
            
            if (![searchesList[0] isEqualToString:self.searchString] && ![stringCheck isEqualToString:@""]) {
                [searchesList insertObject:self.searchString atIndex:0];
            }
            else if ([searchesList[0] isEqualToString:self.searchString] && ![stringCheck isEqualToString:@""]) {
                //do nothing as already last entry
            }
        }
        else if (![stringCheck isEqualToString:@""]){
            [searchesList insertObject:self.searchString atIndex:0];
        }
        
        self.wantedSearchResults = searchesList;
        [self.tableView reloadData];
    }
    else if (self.userSearch == NO && self.sellingSearch == YES){
        //selling selected
        NSMutableArray *history = [NSMutableArray array];
        
        //save the search term and if there's 10 or more items in the search array delete the oldest and add the latest term
        if (![stringCheck isEqualToString:@""]) {
            
            // if haven't searched before create empty array to avoid crashing
            if ([[PFUser currentUser] objectForKey:@"sellingSearches"]) {
                NSMutableArray *searchHistory = [NSMutableArray array];
                [searchHistory addObjectsFromArray:[[PFUser currentUser] objectForKey:@"sellingSearches"]];
                
                if (searchHistory.count >= 15) {
                    [searchHistory removeObjectAtIndex:0];
                }
                
                if (![[searchHistory lastObject] isEqualToString:self.searchString] && [history containsObject:self.searchString]) {
                    [searchHistory removeObject:self.searchString];
                    [searchHistory addObject:self.searchString];
                }
                else if (![searchHistory containsObject:self.searchString]) {
                    [searchHistory addObject:self.searchString];
                }
                
                NSLog(@"SEARCH HISTORY: %@", searchHistory);
                
                [[PFUser currentUser] setObject:searchHistory forKey:@"sellingSearches"];
            }
            else{
                NSLog(@"no history as new user so add first object");
                [history addObject:self.searchString];
                [[PFUser currentUser] setObject:history forKey:@"sellingSearches"];
            }
            [[PFUser currentUser] saveInBackground];
        }
        
        //update results controller UI since only updated via query every time search button pressed
        NSMutableArray *searchesList = [NSMutableArray arrayWithArray:self.sellingSearchResults];
        
        if (searchesList.count > 0) {
            if ([searchesList containsObject:self.searchString] && ![searchesList[0] isEqualToString:self.searchString]) {
                [searchesList removeObject:self.searchString];
            }
            
            if (![searchesList[0] isEqualToString:self.searchString] && ![stringCheck isEqualToString:@""]) {
                [searchesList insertObject:self.searchString atIndex:0];
            }
            else if ([searchesList[0] isEqualToString:self.searchString] && ![stringCheck isEqualToString:@""]) {
                //do nothing as already last entry
            }
        }
        else if (![stringCheck isEqualToString:@""]){
            [searchesList insertObject:self.searchString atIndex:0];
        }
        
        self.sellingSearchResults = searchesList;
        [self.tableView reloadData];
    }
    else{
        //user selected
//        NSLog(@"entered username");
    }
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    
    BOOL createdToday = NO;
    if ([self isDateToday:[PFUser currentUser].createdAt]) {
        createdToday = YES;
    }
    else{
        createdToday = NO;
    }
    if (self.userSearch == YES){
        
        [Answers logCustomEventWithName:@"Search"
                       customAttributes:@{
                                          @"type":@"User search",
                                          @"newUser": [NSNumber numberWithBool:createdToday]
                                          }];
        NSString *searchCheck = [self.searchBar.text stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        PFQuery *userQueryForRand = [PFUser query];
//        [userQueryForRand whereKey:@"username" matchesRegex:self.searchBar.text modifiers:@"i"];

        [userQueryForRand whereKey:@"username" equalTo:[self.searchBar.text lowercaseString]];
        [userQueryForRand whereKey:@"completedReg" equalTo:@"YES"];
        
        PFQuery *facebookNameSearch = [PFUser query];
        
        //if just typed an empty string, don't search for names that contain this
        if (![searchCheck isEqualToString:@""]) {
            [facebookNameSearch whereKey:@"fullnameLower" equalTo:[self.searchBar.text lowercaseString]];
        }
        
        PFQuery *query = [PFQuery orQueryWithSubqueries:@[userQueryForRand,facebookNameSearch]];

        [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            if (objects) {
                self.userResults = objects;

                if (objects.count == 0) {
                    if (!self.noUserLabel) {
                        self.noUserLabel = [[UILabel alloc]initWithFrame:CGRectMake((self.view.frame.size.width/2)-125, self.view.frame.size.height/5, 250, 200)];
                        self.noUserLabel.textAlignment = NSTextAlignmentCenter;
                        self.noUserLabel.text = @"No users found";
                        [self.noUserLabel setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:20]];
                        self.noUserLabel.numberOfLines = 1;
                        self.noUserLabel.textColor = [UIColor lightGrayColor];
                    }
                    [[UIApplication sharedApplication].keyWindow addSubview:self.noUserLabel];
                }
                else{
                    if (self.noUserLabel) {
                        [self.noUserLabel removeFromSuperview];
                    }
                }
                self.userSearch = YES;
                [self.tableView reloadData];
            }
            else{
                NSLog(@"error getting users %@", error);
            }
        }];
    }
    else if(self.userSearch == NO && self.sellingSearch == NO){
        [Answers logCustomEventWithName:@"Search"
                       customAttributes:@{
                                          @"type":@"Wanted search",
                                          @"newUser": [NSNumber numberWithBool:createdToday]
                                          }];
        
        [Intercom logEventWithName:@"searched_wanted_listings"];

        self.searchString = self.searchBar.text;
        [self gotoListingsInSellingMode:NO];
    }
    else if(self.userSearch == NO && self.sellingSearch == YES){
        
        [Intercom logEventWithName:@"searched_listings"];
        
        [Answers logCustomEventWithName:@"Search"
                       customAttributes:@{
                                          @"type":@"For Sale search",
                                          @"newUser": [NSNumber numberWithBool:createdToday]
                                          }];
        self.searchString = self.searchBar.text;
        [self gotoListingsInSellingMode:YES];
    }
    
    //force cancel button to be enabled
    UIButton *btnCancel = [self.searchBar valueForKey:@"_cancelButton"];
    [btnCancel setEnabled:YES];
}

-(void)gotoListingsInSellingMode:(BOOL)sellingSearch{
    [Answers logCustomEventWithName:@"Search"
                   customAttributes:@{
                                      @"type":@"Listing search"
                                      }];
    
    [self.searchBar resignFirstResponder];
    
//    NSLog(@"search string %@", self.searchString);
    
    searchedViewC *vc = [[searchedViewC alloc]init];
    vc.searchString = self.searchString;
    vc.currencySymbol = self.currencySymbol;
    vc.currency = self.currency;
    vc.delegate = self;
    vc.sellingSearch = sellingSearch;
    vc.currentLocation = self.geoPoint;
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)cancellingOtherSearch{
    [self.delegate cancellingMainSearch];
}

-(void)enteredSearchTerm:(NSString *)term inSellingSearch:(BOOL)mode{
    if (mode == NO) {
        //wanted search
        NSMutableArray *history = [[NSMutableArray alloc]init];
        self.searchString = term;
        NSString *stringCheck = [self.searchString stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        if (![stringCheck isEqualToString:@""]) {
            
            if ([[PFUser currentUser] objectForKey:@"searches"]) {
                NSMutableArray *searches = [NSMutableArray array];
                [searches addObjectsFromArray:[[PFUser currentUser] objectForKey:@"searches"]];
                
                if (searches.count >= 15) {
                    [searches removeObjectAtIndex:0];
                }
                
                if (![[searches lastObject] isEqualToString:self.searchString] && [history containsObject:self.searchString]) {
                    [searches removeObject:self.searchString];
                    [searches addObject:self.searchString];
                }
                else if (![searches containsObject:self.searchString]) {
                    [searches addObject:self.searchString];
                }
                [[PFUser currentUser]addObject:[NSDate date] forKey:@"searchDates"];
                [[PFUser currentUser] setObject:searches forKey:@"searches"];
            }
            else{
                NSLog(@"no history as new user so add first object");
                [history addObject:self.searchString];
                [[PFUser currentUser] setObject:history forKey:@"searches"];
            }
            [[PFUser currentUser] saveInBackground];
        }
        
        //update results controller UI since only updated via query every time search button pressed
        NSMutableArray *searchesList = [NSMutableArray arrayWithArray:self.wantedSearchResults];
        
        if (searchesList.count > 0) {
            if ([searchesList containsObject:self.searchString] && ![searchesList[0] isEqualToString:self.searchString]) {
                [searchesList removeObject:self.searchString];
            }
            
            if (![searchesList[0] isEqualToString:self.searchString] && ![stringCheck isEqualToString:@""]) {
                [searchesList insertObject:self.searchString atIndex:0];
            }
            else if ([searchesList[0] isEqualToString:self.searchString] && ![stringCheck isEqualToString:@""]) {
                //do nothing as already last entry
            }
        }
        else if (![stringCheck isEqualToString:@""]){
            [searchesList insertObject:self.searchString atIndex:0];
        }
        
        self.wantedSearchResults = searchesList;
        [self.tableView reloadData];
    }
    else{
        //selling search
        NSMutableArray *history = [[NSMutableArray alloc]init];
        self.searchString = term;
        NSString *stringCheck = [self.searchString stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        if (![stringCheck isEqualToString:@""]) {
            
            if ([[PFUser currentUser] objectForKey:@"sellingSearches"]) {
                NSMutableArray *searches = [NSMutableArray array];
                [searches addObjectsFromArray:[[PFUser currentUser] objectForKey:@"sellingSearches"]];
                
                if (searches.count >= 15) {
                    [searches removeObjectAtIndex:0];
                }
                
                if (![[searches lastObject] isEqualToString:self.searchString] && [history containsObject:self.searchString]) {
                    [searches removeObject:self.searchString];
                    [searches addObject:self.searchString];
                }
                else if (![searches containsObject:self.searchString]) {
                    [searches addObject:self.searchString];
                }
                [[PFUser currentUser]addObject:[NSDate date] forKey:@"searchDates"];
                [[PFUser currentUser] setObject:searches forKey:@"sellingSearches"];
            }
            else{
                NSLog(@"no history as new user so add first object");
                [history addObject:self.searchString];
                [[PFUser currentUser] setObject:history forKey:@"sellingSearches"];
            }
            [[PFUser currentUser] saveInBackground];
        }
        
        //update results controller UI since only updated via query every time search button pressed
        NSMutableArray *searchesList = [NSMutableArray arrayWithArray:self.sellingSearchResults];
        
        if (searchesList.count > 0) {
            if ([searchesList containsObject:self.searchString] && ![searchesList[0] isEqualToString:self.searchString]) {
                [searchesList removeObject:self.searchString];
            }
            
            if (![searchesList[0] isEqualToString:self.searchString] && ![stringCheck isEqualToString:@""]) {
                [searchesList insertObject:self.searchString atIndex:0];
            }
            else if ([searchesList[0] isEqualToString:self.searchString] && ![stringCheck isEqualToString:@""]) {
                //do nothing as already last entry
            }
        }
        else if (![stringCheck isEqualToString:@""]){
            [searchesList insertObject:self.searchString atIndex:0];
        }
        
        self.sellingSearchResults = searchesList;
        [self.tableView reloadData];
    }
}

- (void)addDoneButton {
    UIToolbar* keyboardToolbar = [[UIToolbar alloc] init];
    [keyboardToolbar sizeToFit];
    UIBarButtonItem *flexBarButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                      target:nil action:nil];
    UIBarButtonItem *doneBarButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                      target:self action:@selector(hideKeyb)];
    
    [doneBarButton setTintColor:[UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1]];
    keyboardToolbar.barTintColor = [UIColor colorWithRed:1.00 green:1.00 blue:1.00 alpha:1.0];

    keyboardToolbar.items = @[flexBarButton, doneBarButton];

    self.searchBar.inputAccessoryView = keyboardToolbar;
}

-(void)hideKeyb{
    [self.searchBar resignFirstResponder];
    
    //force cancel button to be enabled
    UIButton *btnCancel = [self.searchBar valueForKey:@"_cancelButton"];
    [btnCancel setEnabled:YES];
}

-(void)setImageBorder:(UIImageView *)imageView{
    imageView.layer.cornerRadius = imageView.frame.size.width / 2;
    imageView.layer.masksToBounds = YES;
    imageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    imageView.contentMode = UIViewContentModeScaleAspectFill;
}

- (BOOL) isDateToday: (NSDate *) aDate
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:(NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:[NSDate date]];
    NSDate *today = [cal dateFromComponents:components];
    
    components = [cal components:(NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:aDate];
    
    NSDate *otherDate = [cal dateFromComponents:components];
    
    if([today isEqualToDate:otherDate]) {
        return YES;
    }
    else{
        return NO;
    }
}

@end
