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

/*
 *  timer.c
 *  dEngine
 *
 *  Created by fabien sanglard on 15/08/09.
 *
 */

//
// Created by Major F. Tropper on 25/03/16.
//

//#include "globals.h"

import Foundation

public class Timer: NSObject {

    var fps: Int = 0
    var simulationTime: Int = 0
    var timediff: Int = 0

    var paused: Bool = true

    var lastTime: Int = 0
    var currentTime: Int = 0
    var fpsAcc: Int = 0
    var fpsTimeAcc: Int = 0

    func resetTime() {
        //printf("[Timer] simulationTime = %d.\n",simulationTime);
        //lastTime = E_Sys_Milliseconds();

        self.tick();
        simulationTime = 0;
    }

    func tick() {
        if (paused) {
            timediff = 0;
            return;
        }

        lastTime = currentTime;
        currentTime = E_Sys_Milliseconds();

        if (forcedTimeIncrement > 0) {
            timediff = forcedTimeIncrement
            forcedTimeIncrement = 0
        } else {
            timediff = currentTime - lastTime
        }

        simulationTime += timediff
        fpsTimeAcc += timediff
        fpsAcc += 1

        if (fpsTimeAcc > 1000) {
            fps = Int(fpsAcc * 1000 / fpsTimeAcc);
            fpsAcc = 0;
            fpsTimeAcc = 0;
        }

    }

    func pause() {
        self.paused = true
    }
    func resume() {
        self.paused = false
        self.lastTime = currentTime
    }

    var forcedTimeIncrement = 0
    func forceTimeIncrement(ms: Int) {
        Swift.print("***********[Timer] !! WARNING !! Time increment is forced !! WARNING !!");
        forcedTimeIncrement = ms;
    }
}

import Darwin.sys

var secbase: Int = 0
func E_Sys_Milliseconds() -> Int {
    var tp = timeval()
    gettimeofday(&tp, nil);

    if (secbase == 0) {
        secbase = tp.tv_sec;
        return Int(tp.tv_usec / 1000);
    }

    return Int((tp.tv_sec - secbase) * 1000 + tp.tv_usec / 1000);
}


