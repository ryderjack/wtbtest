//
//  JRComposerTextView.h
//  wtbtest
//
//  Created by Jack Ryder on 23/09/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import <JSQMessagesViewController/JSQMessagesViewController.h>

@class JRComposerTextView;

@protocol JRComposerDelegate <NSObject>
- (void)shouldPaste;
@end

@interface JRComposerTextView : JSQMessagesComposerTextView

@property (nonatomic, weak) id <JRComposerDelegate> JRComposerDelegate;

@end
