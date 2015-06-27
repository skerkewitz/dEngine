/*
 dEngine Source Code 
 Copyright (C) 2009 - Fabien Sanglard
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

//
//  dEngineAppDelegate.m
//  dEngine
//
//  Created by fabien sanglard on 09/08/09.
//

#import "dEngineAppDelegate.h"
#import "EAGLView.h"

@implementation dEngineAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	[[UIApplication sharedApplication] setStatusBarHidden:YES ];

    // create the base window
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];


    UIViewController* uiViewController = [UIViewController new];
    self.glView = [EAGLView new];
    self.glView.frame =uiViewController.view.frame;
    [uiViewController.view addSubview:self.glView];
    self.glView.backgroundColor = [UIColor greenColor];
    uiViewController.view.backgroundColor = [UIColor redColor];

    [self.window setRootViewController:uiViewController];
    self.window.rootViewController.view.backgroundColor = [UIColor yellowColor];
    [self.window makeKeyAndVisible];

    [self.glView startAnimation];

    return YES;
}

- (void) applicationWillResignActive:(UIApplication *)application {
	[self.glView stopAnimation];
}

- (void) applicationDidBecomeActive:(UIApplication *)application {
	[self.glView startAnimation];
}

- (void)applicationWillTerminate:(UIApplication *)application {
	[self.glView stopAnimation];
}

- (void) stopEngineActivity {
	[self.glView stopAnimation];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    //No multi-tasking, when you die, you die. Period.
	exit(0);
	//[self stopEngineActivity];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
	[self.glView startAnimation];
}

@end
