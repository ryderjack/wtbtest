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

@interface TheMainSearchView ()

@end

@implementation TheMainSearchView

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self.tableView registerNib:[UINib nibWithNibName:@"SearchCell" bundle:nil] forCellReuseIdentifier:@"Cell"];
    
    self.searchString = @"";
    
    self.userSearch = NO;
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchBar.delegate = self;
    self.navigationItem.titleView = self.searchBar;
    [self.searchBar sizeToFit];
    self.searchBar.placeholder = @"Search for stuff you're selling";
    
    //segment control
    self.segmentedControl = [[HMSegmentedControl alloc] init];
    self.segmentedControl.frame = CGRectMake(self.placeholderView.frame.origin.x, self.placeholderView.frame.origin.y, [UIApplication sharedApplication].keyWindow.frame.size.width,self.placeholderView.frame.size.height);
    self.segmentedControl.selectionStyle = HMSegmentedControlSelectionStyleFullWidthStripe;
    self.segmentedControl.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocationDown;
    self.segmentedControl.selectionIndicatorColor = [UIColor colorWithRed:0.30 green:0.64 blue:0.99 alpha:1.0];
    self.segmentedControl.titleTextAttributes = @{NSFontAttributeName : [UIFont fontWithName:@"PingFangSC-Medium" size:10]};
    self.segmentedControl.selectedTitleTextAttributes = @{NSForegroundColorAttributeName : [UIColor colorWithRed:0.30 green:0.64 blue:0.99 alpha:1.0]};
    [self.segmentedControl addTarget:self action:@selector(segmentControlChanged) forControlEvents:UIControlEventValueChanged];
    [self.segmentedControl setSectionTitles:@[@"W A N T E D", @"P E O P L E"]];
    [self.view addSubview:self.segmentedControl];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelPressed)];
    self.navigationItem.rightBarButtonItem = cancelButton;
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
    
    self.listingResults = [[[[PFUser currentUser]objectForKey:@"searches"] reverseObjectEnumerator] allObjects];
    self.userResults = [NSArray array];
    
    [self addDoneButton];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self.searchBar becomeFirstResponder];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setHidden:NO];
    self.searchBar.text = @"";
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)segmentControlChanged{
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        self.userSearch = NO;
        self.searchBar.placeholder = @"Search for stuff you're selling";
        
        if (self.noUserLabel) {
            [self.noUserLabel removeFromSuperview];
            self.noUserLabel = nil;
        }
    }
    else{
        self.userSearch = YES;
        self.searchBar.placeholder = @"Search for users";
    }
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.userSearch == NO) {
        return self.listingResults.count;
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
            [cell.userImageView setFile:[user objectForKey:@"picture"]];
            [cell.userImageView loadInBackground];
        }
    }
    else{
        [cell.userImageView setHidden:YES];
        cell.usernameLabel.text = self.listingResults[indexPath.row];
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
            
        }
        UserProfileController *vc = [[UserProfileController alloc]init];
        vc.user = user;
        vc.fromSearch = YES;
        [self.navigationController pushViewController:vc animated:YES];
    }
    else{
        self.searchString = [NSString stringWithFormat:@"%@",[self.listingResults objectAtIndex:indexPath.row]];
        
        [self.searchBar resignFirstResponder];
        searchedViewC *vc = [[searchedViewC alloc]init];
        vc.searchString = [NSString stringWithFormat:@"%@",[self.listingResults objectAtIndex:indexPath.row]];
        vc.currencySymbol = self.currencySymbol;
        vc.currency = self.currency;
        vc.delegate = self;
        vc.currentLocation = self.geoPoint;
        vc.tabBarHeight = self.tabBarHeight;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    [self cancelPressed];
}

-(void)cancelPressed{
    [self.searchBar resignFirstResponder];
    [self.delegate cancellingMainSearch];
    [self.noUserLabel removeFromSuperview];
    self.noUserLabel = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar{
    self.searchString = searchBar.text;
    NSString *stringCheck = [self.searchString stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if (self.userSearch == NO){
        
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
        NSMutableArray *searchesList = [NSMutableArray arrayWithArray:self.listingResults];
        
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
        
        self.listingResults = searchesList;
        [self.tableView reloadData];
    }
    else{
        //user entered
//        NSLog(@"entered username");
    }
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    if (self.userSearch == YES){
        
        [Answers logCustomEventWithName:@"Search"
                       customAttributes:@{
                                          @"type":@"User search"
                                          }];
        
        PFQuery *userQueryForRand = [PFUser query];
        [userQueryForRand whereKey:@"username" containsString:[self.searchBar.text lowercaseString]];
        [userQueryForRand whereKey:@"completedReg" equalTo:@"YES"];
        
        PFQuery *facebookNameSearch = [PFUser query];
        [facebookNameSearch whereKey:@"fullnameLower" containsString:[self.searchBar.text lowercaseString]];
        
        PFQuery *query = [PFQuery orQueryWithSubqueries:@[userQueryForRand,facebookNameSearch]];

        [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            if (objects) {
//                NSLog(@"users found %lu", objects.count);
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
                    self.userResults = objects;
                    self.userSearch = YES;
                    [self.tableView reloadData];
                }
            }
            else{
                NSLog(@"error getting users %@", error);
            }
        }];
    }
    else{
        self.searchString = self.searchBar.text;
        [self gotoListings];
    }
}

-(void)gotoListings{
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
    vc.currentLocation = self.geoPoint;
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)cancellingOtherSearch{
    [self.delegate cancellingMainSearch];
}

-(void)enteredSearchTerm:(NSString *)term{
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
    NSMutableArray *searchesList = [NSMutableArray arrayWithArray:self.listingResults];
    
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
    
    self.listingResults = searchesList;
    [self.tableView reloadData];
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
    keyboardToolbar.items = @[flexBarButton, doneBarButton];
    self.searchBar.inputAccessoryView = keyboardToolbar;
}

-(void)hideKeyb{
    [self.searchBar resignFirstResponder];
}

-(void)setImageBorder:(UIImageView *)imageView{
    imageView.layer.cornerRadius = imageView.frame.size.width / 2;
    imageView.layer.masksToBounds = YES;
    imageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    imageView.contentMode = UIViewContentModeScaleAspectFill;
}
@end
