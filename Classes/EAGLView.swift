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


////
////  EAGLView.m
////  dEngine
////
////  Created by fabien sanglard on 09/08/09.
////
//
//
//
//
////  EAGLView.h
////  dEngine
////
////  Created by fabien sanglard on 09/08/09.
////
//
//
//#import <UIKit/UIKit.h>
//#import <OpenGLES/EAGL.h>
//#import <OpenGLES/ES1/gl.h>
//#import <OpenGLES/ES1/glext.h>
//
//
//#include "../src/ItextureLoader.h";
//#include "../src/globals.h";
//
//#define MAX_FPS 1.0f/45.f
//
///*
//This class wraps the CAEAGLLayer from CoreAnimation into a convenient UIView subclass.
//The view content is basically an EAGL surface you render your OpenGL scene into.
//Note that setting the view non-opaque will only work if the EAGL surface has an alpha channel.
//*/
//@interface EAGLView : UIView {
//
//	@private
//	/* The pixel dimensions of the backbuffer */
//	GLint backingWidth;
//	GLint backingHeight;
//
//	EAGLContext *context;
//
//	/* OpenGL names for the renderbuffer and framebuffers used to render to this view */
//	GLuint viewRenderbuffer, viewFramebuffer;
//
//	/* OpenGL name for the depth buffer that is attached to viewFramebuffer, if it exists (0 if it does not exist) */
//	GLuint depthRenderbuffer;
//
//
//	BOOL animating;
//	BOOL displayLinkSupported;
//	NSTimer *animationTimer;
//	id displayLink;
//	NSInteger animationFrameInterval;
//}
//
//@property (readonly, nonatomic, getter=isAnimating) BOOL animating;
//@property (nonatomic) NSInteger animationFrameInterval;
//
//- (void)startAnimation;
//- (void)stopAnimation;
//- (void)drawView:(id)sender;
//- (void) loadTexture:(texture_t*) tmpTex;
//
//@end

import Foundation;
import UIKit;
import OpenGLES;
import QuartzCore;

//
//
//
//
//#import <QuartzCore/QuartzCore.h>
//#import <OpenGLES/EAGLDrawable.h>
//
//#import "EAGLView.h"
//#import "dEngine.h"
//#import "filesystem.h"
//#import "renderer.h"
//#import "commands.h"
//#import "camera.h"
//#import "timer.h"
//
//#include <sys/types.h>
//#include <sys/sysctl.h>
//
//
//#define RECORDING_VIDEO 0
//#define PLAY_VIDEO 1
//
//EAGLView *eaglview;
//
//
//texture_t fontTexture;
//

let PLAY_VIDEO = true
let RECORDING_VIDEO = false

class EAGLView : UIView {

    let screenShotDirectory = "/Users/fabiensanglard/Pictures/dEngine/"

    /* The pixel dimensions of the backbuffer */
    var backingWidth: GLint = 0; // GLint
    var backingHeight: GLint = 0; // GLint

    var context: EAGLContext?;

    /* OpenGL names for the renderbuffer and framebuffers used to render to this view */
    var viewRenderbuffer: GLuint = 0 // GLuint
    var viewFramebuffer: GLuint = 0 // GLuint

    /* OpenGL name for the depth buffer that is attached to viewFramebuffer, if it exists (0 if it does not exist) */
    var depthRenderbuffer: GLuint = 0 // GLuint

    var animating: Bool = false;
    var displayLink: CADisplayLink?

    var animationFrameInterval: Int = 0;

    /* You must implement this method */
    @objc override class func layerClass() -> AnyClass {
        return CAEAGLLayer.self;
    }

    @objc class func loadNativePNG(texture: UnsafePointer<texture_t>) -> Void {
        loadTexture(texture.memory);
    }

    class func loadTexture(var text: texture_t) {

//	//GLubyte *spriteData;
//	//size_t	width = 1, height=1 , bpp=0 , bytePerRow = 0;
//


        // Get the width and height of the image
        text.file = nil;

        let name = String.fromCString(text.path)!

        //NSString* name = [[NSString alloc] initWithCString:text->path encoding:NSASCIIStringEncoding];

        let uiImage: UIImage? = UIImage.init(named: name);
        let spriteImage: CGImageRef? = uiImage!.CGImage;

        if let sprite = spriteImage {
            text.width = Int32(CGImageGetWidth(sprite));
            text.height = Int32(CGImageGetHeight(sprite));
            text.bpp = Int32(CGImageGetBitsPerPixel(sprite));

            // (ubyte *)calloc(text->width * text->height * 4,sizeof(ubyte));
            text.data = calloc(Int(text.width * text.height * 4), Int(sizeof(UInt8)));

            var spriteContext: CGContextRef?;
            if (text.bpp == 24) {
                text.format = TEXTURE_GL_RGB;
                print("TEXTURE_GL_RGB, bpp=\(text.bpp)");
                spriteContext = CGBitmapContextCreate(text.data,
                        Int(text.width), Int(text.height),
                        8, Int(text.width * 4),
                        CGImageGetColorSpace(sprite), CGImageAlphaInfo.NoneSkipLast.rawValue);
            } else {
                text.format = TEXTURE_GL_RGBA;
                print("TEXTURE_GL_RGBA, bpp=\(text.bpp)");
                spriteContext = CGBitmapContextCreate(text.data,
                        Int(text.width), Int(text.height),
                        8, Int(text.width * 4),
                        CGImageGetColorSpace(sprite), CGImageAlphaInfo.PremultipliedLast.rawValue);
            }

            CGContextDrawImage(spriteContext, CGRectMake(CGFloat(0.0), CGFloat(0.0), CGFloat(text.width), CGFloat(text.height)), sprite);
        } else {
            print("Error: [PNG Loader] could not load image with \(name)");
        }
    }

    convenience init () {
        self.init(frame:CGRect.zero)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }


    //The GL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:
    override init (frame : CGRect) {
        super.init(frame : frame)

        // Get the layer
        let eaglLayer: CAEAGLLayer = self.layer as! CAEAGLLayer
        eaglLayer.opaque = true;
        eaglLayer.drawableProperties = [
            kEAGLDrawablePropertyRetainedBacking : false,
            kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8
        ]

        //Set stats enabled
        let userDefaults = NSUserDefaults.standardUserDefaults()
        renderer.statsEnabled = 1 // [@"1" isEqualToString:[userDefaults stringForKey:@"StatisticsEnabled"]];

        renderer.materialQuality = 1 // MATERIAL_QUALITY_HIGH;
        //renderer.materialQuality = 0 // MATERIAL_QUALITY_LOW;

        context = EAGLContext(API: .OpenGLES3)
        EAGLContext.setCurrentContext(context)

        let rect = UIScreen.mainScreen().bounds
        let vp_width = rect.size.width
        let vp_height = rect.size.height

//        #define GL_11_RENDERER 0
//        #define GL_20_RENDERER 1
        dEngine_Init(1 /*GL_20_RENDERER*/, Int32(vp_width), Int32(vp_height))

//        renderer.props |= PROP_SHADOW
//        //renderer.props &= ~PROP_SHADOW
//
//        renderer.props |= PROP_BUMP
//        //renderer.props &= ~PROP_BUMP ;
//
//        renderer.props |= PROP_SPEC ;
//        //renderer.props &= ~PROP_SPEC ;

        Swift.print("Engine properties");
        //MATLIB_printProp(renderer.props);

        animating = false;
        displayLink = nil;
        animationFrameInterval = 1
    }

    var triggeredPlay = false

    func drawView(sender: AnyObject?) -> Void {

        glBindRenderbufferOES(GLenum(GL_RENDERBUFFER_OES), self.viewRenderbuffer)
        self.context?.presentRenderbuffer(Int(GL_RENDERBUFFER))

        if (PLAY_VIDEO && !triggeredPlay) {
            triggeredPlay = true
            CAM_StartPlaying("data/cameraPath/fps.cp"); //fps.cp //ikarauga_level5.cp

            if (RECORDING_VIDEO) {
                Timer_ForceTimeIncrement(33);
            }
        }

        dEngine_HostFrame();

        if (RECORDING_VIDEO) {
            //Location
            //Rotate
            dEngine_WriteScreenshot(self.screenShotDirectory, true);
        }
    }


    override func layoutSubviews() -> Void {
        EAGLContext.setCurrentContext(self.context);
        self.destroyFramebuffer();
        self.createFramebuffer();
        self.drawView(nil);
    }

//
//
//- (void) setAnimationFrameInterval:(NSInteger)frameInterval
//{
//	// Frame interval defines how many display frames must pass between each time the
//	// display link fires. The display link will only fire 30 times a second when the
//	// frame internal is two on a display that refreshes 60 times a second. The default
//	// frame interval setting of one will fire 60 times a second when the display refreshes
//	// at 60 times a second. A frame interval setting of less than one results in undefined
//	// behavior.
//	NSLog(@"frameInterval=%d",frameInterval);
//	if (frameInterval >= 1)
//	{
//		animationFrameInterval = frameInterval;
//
//		if (animating)
//		{
//			[self stopAnimation];
//			[self startAnimation];
//		}
//	}
//}
//
//
    func createFramebuffer() -> Bool {

        glGenFramebuffersOES(1, &viewFramebuffer)
        glGenRenderbuffersOES(1, &viewRenderbuffer)

        glBindFramebufferOES(GLenum(GL_FRAMEBUFFER_OES), viewFramebuffer)
        glBindRenderbufferOES(GLenum(GL_RENDERBUFFER_OES), viewRenderbuffer)
        context!.renderbufferStorage(Int(GL_RENDERBUFFER_OES), fromDrawable:self.layer as! EAGLDrawable)
        glFramebufferRenderbufferOES(GLenum(GL_FRAMEBUFFER_OES), GLenum(GL_COLOR_ATTACHMENT0_OES), GLenum(GL_RENDERBUFFER_OES), viewRenderbuffer)

        glGetRenderbufferParameterivOES(GLenum(GL_RENDERBUFFER_OES), GLenum(GL_RENDERBUFFER_WIDTH_OES), &backingWidth)
        glGetRenderbufferParameterivOES(GLenum(GL_RENDERBUFFER_OES), GLenum(GL_RENDERBUFFER_HEIGHT_OES), &backingHeight)

        //Depth buffer
	    glGenRenderbuffersOES(1, &depthRenderbuffer)
	    glBindRenderbufferOES(GLenum(GL_RENDERBUFFER_OES), depthRenderbuffer)
	    glRenderbufferStorageOES(GLenum(GL_RENDERBUFFER_OES), GLenum(GL_DEPTH_COMPONENT16_OES), backingWidth, backingHeight)
	    glFramebufferRenderbufferOES(GLenum(GL_FRAMEBUFFER_OES), GLenum(GL_DEPTH_ATTACHMENT_OES), GLenum(GL_RENDERBUFFER_OES), depthRenderbuffer)

	    renderer.mainFramebufferId = viewFramebuffer

        if(glCheckFramebufferStatusOES(GLenum(GL_FRAMEBUFFER_OES)) != GLenum(GL_FRAMEBUFFER_COMPLETE_OES)) {
            Swift.print("failed to make complete framebuffer object \(glCheckFramebufferStatusOES(GLenum(GL_FRAMEBUFFER_OES)))")
            return false
        }

        return true
    }

    func destroyFramebuffer() {

        glDeleteFramebuffersOES(1, &viewFramebuffer);
        viewFramebuffer = 0;
        glDeleteRenderbuffersOES(1, &viewRenderbuffer);
        viewRenderbuffer = 0;

        if(depthRenderbuffer > 0) {
            glDeleteRenderbuffersOES(1, &depthRenderbuffer);
            depthRenderbuffer = 0;
        }
    }


    func startAnimation() {
        if (!animating) {
            displayLink = CADisplayLink(target:self, selector:"drawView:")
            displayLink?.frameInterval = animationFrameInterval
            displayLink?.addToRunLoop(NSRunLoop.currentRunLoop(), forMode:NSDefaultRunLoopMode)
            animating = true;
        }
    }

    func stopAnimation() {
        if (animating) {
            displayLink?.invalidate()
            displayLink = nil;
            animating = false;
        }
    }

//
////Native methods
//void loadNativePNG(texture_t* tmpTex) {
//	[eaglview loadTexture:tmpTex ];
//}
//
//- (void)dealloc {
//
//    [self stopAnimation];
//
//    if ([EAGLContext currentContext] == context) {
//        [EAGLContext setCurrentContext:nil];
//    }
//}
//
//CGPoint previousLookAround;
//- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
//	NSArray* allTouches = [touches allObjects];
//
//	if (allTouches.count == 4) {
//		if (!camera.recording)
//			CAM_StartRecording();
//		else
//			CAM_StopRecording();
//	}
//
//	for(int i=0 ; i <allTouches.count ; i++) {
//
//        UITouch *touch = [allTouches objectAtIndex:i];
//        CGPoint currentPosition = [touch locationInView:self];
//
//	//	NSLog(@"id: %d, posx=%.2f, posy=%.2f",i,currentPosition.x,currentPosition.y);
//
//		if (currentPosition.y > 240) {
//			previousLookAround = currentPosition;
//		}
//	}
//}
//
//- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
//
//	NSArray* allTouches = [touches allObjects];
//
//	for(int i=0 ; i <allTouches.count ; i++) {
//
//        UITouch *touch = [allTouches objectAtIndex:i];
//        CGPoint previousPosition= [touch previousLocationInView:self];
//        CGPoint currentPosition = [touch locationInView:self];
//
//		float deltaX = previousPosition.x - currentPosition.x;
//		float deltaY = previousPosition.y - currentPosition.y;
//
//	//	printf("\n\n");
//	//	NSLog(@"previousLookAround.x=%.2f",previousLookAround.x);
//	//	NSLog(@"previousPosition.x=%.2f",previousPosition.x);
//	//	NSLog(@"previousLookAround.y=%.2f",previousLookAround.y);
//	//	NSLog(@"previousPosition.y=%.2f",previousPosition.y);
//
//		command_t command;
//
//		if (previousPosition.x == previousLookAround.x && previousPosition.y == previousLookAround.y) {
//			//this was originally a lookAround touch
//			//Comm_AddHead(-deltaY/100);
//			//Comm_AddPitch(deltaX/100);
//
//			command.type = COMMAND_TYPE_HEAD;
//			command.value = -deltaY;
//			Comm_AddCommand(&command);
//
//			command.type = COMMAND_TYPE_PITCH;
//			command.value = deltaX;
//
//			Comm_AddCommand(&command);
//
//
//			previousLookAround = currentPosition;
//		} else {
//			//this was originally a move touch
//			command.type = COMMAND_TYPE_MOVE_NORTH_SOUTH;
//			command.value = -deltaX;
//			Comm_AddCommand(&command);
//
//			command.type = COMMAND_TYPE_MOVE_EAST_WEST;
//			command.value = deltaY;
//			Comm_AddCommand(&command);
//
//			//Comm_AddForBackWard(-deltaX);
//			//Comm_Strafe(deltaY);
//		}
//	}
//}
//
//- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
//
//}


}