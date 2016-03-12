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

//#import "dEngineAppDelegate.h"
//#import "EAGLView.h"

//
//@class EAGLView;
//
//@interface dEngineAppDelegate : NSObject <UIApplicationDelegate> {
//}
//
//@property (strong, nonatomic) UIWindow *window;
//@property (strong, nonatomic) EAGLView *glView;
//
//@end
//
//

import UIKit;

@UIApplicationMain
class dEngineAppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var glView: EAGLView?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        /* Create the base window. */
        self.window = UIWindow(frame:UIScreen.mainScreen().bounds)
        self.window!.backgroundColor = .whiteColor()

        let uiViewController = UIViewController()
        self.glView = EAGLView()
        self.glView!.frame = uiViewController.view.frame
        uiViewController.view.addSubview(self.glView!)
        self.glView!.backgroundColor = .greenColor()
        uiViewController.view.backgroundColor = .redColor()

        self.window!.rootViewController = uiViewController;
        self.window!.rootViewController!.view.backgroundColor = UIColor.yellowColor()

        self.window!.makeKeyAndVisible()

        self.glView!.startAnimation()

        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        self.glView?.stopAnimation()
    }

    func applicationDidBecomeActive(application: UIApplication) {
        self.glView?.startAnimation()
    }

    func applicationWillTerminate(application: UIApplication) {
        self.glView?.stopAnimation()
    }

    func stopEngineActivity() {
        self.glView?.stopAnimation()
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // No multi-tasking, when you die, you die. Period.
        exit(0);
        //[self stopEngineActivity];
    }

    func applicationWillEnterForeground(application: UIApplication) {
        self.glView?.startAnimation()
    }
}
