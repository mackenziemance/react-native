/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "RCTReloadCommand.h"

#import "RCTAssert.h"
#import "RCTKeyCommands.h"
#import "RCTUtils.h"

/** main queue only */
static NSHashTable<id<RCTReloadListener>> *listeners;

NSString *const RCTTriggerReloadCommandNotification = @"RCTTriggerReloadCommandNotification";
NSString *const RCTTriggerReloadCommandReasonKey = @"reason";

void RCTRegisterReloadCommandListener(id<RCTReloadListener> listener)
{
  RCTAssertMainQueue(); // because registerKeyCommandWithInput: must be called on the main thread
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    listeners = [NSHashTable weakObjectsHashTable];
    [[RCTKeyCommands sharedInstance] registerKeyCommandWithInput:@"r"
                                                   modifierFlags:UIKeyModifierCommand
                                                          action:
     ^(__unused UIKeyCommand *command) {
       RCTTriggerReloadCommandListeners(@"Command + R");
     }];
  });
  [listeners addObject:listener];
}

void RCTTriggerReloadCommandListeners(NSString *reason)
{
  RCTAssertMainQueue();

  [[NSNotificationCenter defaultCenter] postNotificationName:RCTTriggerReloadCommandNotification
                                                      object:nil
                                                    userInfo:@{RCTTriggerReloadCommandReasonKey: RCTNullIfNil(reason)} ];

  // Copy to protect against mutation-during-enumeration.
  // If listeners hasn't been initialized yet we get nil, which works just fine.
  NSArray<id<RCTReloadListener>> *copiedListeners = [listeners allObjects];
  for (id<RCTReloadListener> l in copiedListeners) {
    [l didReceiveReloadCommand];
  }
}
