//
//  whoBumpedTableView.m
//  wtbtest
//
//  Created by Jack Ryder on 17/01/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "whoBumpedTableView.h"
#import "bumperCell.h"
#import "UserProfileController.h"

@interface whoBumpedTableView ()

@end

@implementation whoBumpedTableView

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"B U M P S";
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"bumperCell" bundle:nil] forCellReuseIdentifier:@"Cell"];
    
    self.results = [NSArray array];
    

}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Regular" size:13],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    [self loadBumps];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)loadBumps{
    PFQuery *bumpersQuery = [PFUser query];
    [bumpersQuery whereKey:@"objectId" containedIn:self.bumpArray];
    [bumpersQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            self.results = objects;
            [self.tableView reloadData];
        }
        else{
            NSLog(@"error getting bumpers %@", error);
        }
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.results.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    bumperCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    cell.userImageView.image = nil;
    cell.usernameLabel.text = @"";
    
    PFUser *user = [self.results objectAtIndex:indexPath.row];
    
    cell.usernameLabel.text = user.username;
    
    [cell.userImageView setFile:[user objectForKey:@"picture"]];
    [cell.userImageView loadInBackground];
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 72;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    PFUser *user = [self.results objectAtIndex:indexPath.row];

    UserProfileController *vc = [[UserProfileController alloc]init];
    vc.user = user;
    [self.navigationController pushViewController:vc animated:YES];
}


@end
