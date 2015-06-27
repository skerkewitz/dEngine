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
//  EAGLView.m
//  dEngine
//
//  Created by fabien sanglard on 09/08/09.
//



#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import "dEngineAppDelegate.h"

#import "EAGLView.h"
#import "dEngine.h"
#import "filesystem.h"
#import "renderer.h"
#import "commands.h"
#import "camera.h"
#import "timer.h"

#include <sys/types.h>
#include <sys/sysctl.h>


#define RECORDING_VIDEO 0
#define PLAY_VIDEO 1

EAGLView *eaglview;


texture_t fontTexture;

char* screenShotDirectory = "/Users/fabiensanglard/Pictures/dEngine/";

// A class extension to declare private methods
@interface EAGLView ()

@property (nonatomic, retain) EAGLContext *context;


- (BOOL) createFramebuffer;
- (void) destroyFramebuffer;

@end


@implementation EAGLView

@synthesize context;

@synthesize animating;
@dynamic animationFrameInterval;


// You must implement this method
+ (Class)layerClass {
    return [CAEAGLLayer class];
}


//The GL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:
- (id)init {
    
    if ((self = [super init])) {
		
		eaglview = self;
		
        // Get the layer
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
        
        eaglLayer.opaque = YES;
        eaglLayer.drawableProperties = @{
                kEAGLDrawablePropertyRetainedBacking : @NO,
                //kEAGLColorFormatRGBA8,
                kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8};

		//Set stats enabled
        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
        renderer.statsEnabled = [@"1" isEqualToString:[userDefaults stringForKey:@"StatisticsEnabled"]];

        NSString *rendererType = [userDefaults stringForKey:@"RendererType"];
		bool fixedDesired = [@"0" isEqualToString:rendererType];

		//Set the texture quality
        if ([userDefaults stringForKey:@"MaterialQuality"] == nil
                || [[userDefaults stringForKey:@"MaterialQuality"] intValue] ) {
            renderer.materialQuality = MATERIAL_QUALITY_HIGH;
        } else {
            renderer.materialQuality = MATERIAL_QUALITY_LOW;
        }

		if (!fixedDesired) {
            context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
        }

        if (!context || ![EAGLContext setCurrentContext:context]) {
            return nil;
        }

        CGRect rect = [[UIScreen mainScreen] bounds];
        int vp_width = rect.size.width;
        int vp_height = rect.size.height;
        dEngine_Init(GL_20_RENDERER,vp_width,vp_height);

		
		//Set shadow enabled/disabled
		//Set shadow type
		if ([userDefaults stringForKey:@"ShadowType"] == nil
                || [[userDefaults stringForKey:@"ShadowType"] intValue])
			renderer.props |= PROP_SHADOW ;
		else 
			renderer.props &= ~PROP_SHADOW ;

		
		if ([userDefaults stringForKey:@"NormalMappingEnabled"] == nil
                || [[userDefaults stringForKey:@"NormalMappingEnabled"] intValue])
			renderer.props |= PROP_BUMP ;
		else 
			renderer.props &= ~PROP_BUMP ;

		
		if ([userDefaults stringForKey:@"SpecularMappingEnabled"] == nil
                || [[userDefaults stringForKey:@"SpecularMappingEnabled"] intValue])
			renderer.props |= PROP_SPEC ;		
		else
			renderer.props &= ~PROP_SPEC ;

		//NSLog(@"Engine properties");
		//MATLIB_printProp(renderer.props);

		animating = FALSE;
		//displayLinkSupported = FALSE;
		displayLink = nil;
		animationTimer = nil;
		displayLinkSupported = TRUE;
        [self setAnimationFrameInterval:1];
    }
	
    return self;
}

int triggeredPlay = 0;
- (void)drawView:(id)sender 
{
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER_OES];
	
	if (PLAY_VIDEO && !triggeredPlay) {
		triggeredPlay = 1;
			CAM_StartPlaying("data/cameraPath/fps.cp");		//fps.cp //ikarauga_level5.cp

		if (RECORDING_VIDEO) {
            Timer_ForceTimeIncrement(33);
        }
	}
	
	dEngine_HostFrame();
	
	if (RECORDING_VIDEO) {
		//Location
		//Rotate
		dEngine_WriteScreenshot(screenShotDirectory, 1);
	}
	
//	if (timediff > (1/60.0f *1000))
//		[self setAnimationFrameInterval:2];
//	else
//		[self setAnimationFrameInterval:1];
	
	//setAnimationFrameInterval
		
	//[[NSRunLoop currentRunLoop] runUntilDate: [NSDate distantPast]]; // Makes inputs more responsive  
}


- (void)layoutSubviews {

    [EAGLContext setCurrentContext:context];
    [self destroyFramebuffer];
    [self createFramebuffer];
    [self drawView:nil];
}

- (NSInteger) animationFrameInterval {
	return animationFrameInterval;
}


- (void) setAnimationFrameInterval:(NSInteger)frameInterval
{
	// Frame interval defines how many display frames must pass between each time the
	// display link fires. The display link will only fire 30 times a second when the
	// frame internal is two on a display that refreshes 60 times a second. The default
	// frame interval setting of one will fire 60 times a second when the display refreshes
	// at 60 times a second. A frame interval setting of less than one results in undefined
	// behavior.
	NSLog(@"frameInterval=%d",frameInterval);
	if (frameInterval >= 1)
	{
		animationFrameInterval = frameInterval;
		
		if (animating)
		{
			[self stopAnimation];
			[self startAnimation];
		}
	}
}


- (BOOL)createFramebuffer {
    
    glGenFramebuffersOES(1, &viewFramebuffer);
    glGenRenderbuffersOES(1, &viewRenderbuffer);
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    [context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)self.layer];
    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, viewRenderbuffer);
    
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
    
    //Depth buffer
	glGenRenderbuffersOES(1, &depthRenderbuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, depthRenderbuffer);
	glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, backingWidth, backingHeight);
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, depthRenderbuffer);

	renderer.mainFramebufferId = viewFramebuffer;
	
    if(glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES) {
        NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
        return NO;
    }
    
    return YES;
} 


- (void)destroyFramebuffer {
    
    glDeleteFramebuffersOES(1, &viewFramebuffer);
    viewFramebuffer = 0;
    glDeleteRenderbuffersOES(1, &viewRenderbuffer);
    viewRenderbuffer = 0;
    
    if(depthRenderbuffer) {
        glDeleteRenderbuffersOES(1, &depthRenderbuffer);
        depthRenderbuffer = 0;
    }
}


- (void)startAnimation {
    if (!animating) {
		if (displayLinkSupported) {

			// CADisplayLink is API new to iPhone SDK 3.1. Compiling against earlier versions will result in a warning,
			// but can be dismissed if the system version runtime check for CADisplayLink exists in -initWithCoder:.
			// The runtime check ensures this code will not be called in system versions earlier than 3.1.
			displayLink = [NSClassFromString(@"CADisplayLink") displayLinkWithTarget:self selector:@selector(drawView:)];
			[displayLink setFrameInterval:animationFrameInterval];
			[displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		} else {
            animationTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)((MAX_FPS) * animationFrameInterval)
                                                              target:self
                                                            selector:@selector(drawView:)
                                                            userInfo:nil
                                                             repeats:TRUE];
        }

		animating = TRUE;
	}
}

- (void)stopAnimation {
	if (animating) {
		if (displayLinkSupported) {
			[displayLink invalidate];
			displayLink = nil;
		} else {
			[animationTimer invalidate];
			animationTimer = nil;
		}
		animating = FALSE;
	}
}

- (void)  loadTexture:(texture_t*)text {

	//GLubyte *spriteData;
	//size_t	width = 1, height=1 , bpp=0 , bytePerRow = 0;
	
	NSString* name = [[NSString alloc] initWithCString:text->path encoding:NSASCIIStringEncoding];
    CGImageRef spriteImage = [UIImage imageNamed:name].CGImage;

	// Get the width and height of the image
	text->file = NULL;
	
	if(spriteImage) {
		text->width = CGImageGetWidth(spriteImage);
		text->height = CGImageGetHeight(spriteImage);
		text->bpp = CGImageGetBitsPerPixel(spriteImage);//
		
		text->data = (ubyte *)calloc(text->width * text->height * 4,sizeof(ubyte));

        CGContextRef spriteContext;
        if (text->bpp == 24) {
			text->format = TEXTURE_GL_RGB;
			//NSLog(@"TEXTURE_GL_RGB, bpp=%d ",text->bpp);
			spriteContext = CGBitmapContextCreate(text->data, text->width, text->height, 8, text->width * 4, CGImageGetColorSpace(spriteImage), kCGImageAlphaNoneSkipLast);
		} else {
			text->format = TEXTURE_GL_RGBA;		
			//NSLog(@"TEXTURE_GL_RGBA, bpp=%d  ",text->bpp);
			spriteContext = CGBitmapContextCreate(text->data, text->width, text->height, 8, text->width * 4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
		}

		CGContextDrawImage(spriteContext, CGRectMake(0.0, 0.0, (CGFloat)text->width, (CGFloat)text->height), spriteImage);
		CGContextRelease(spriteContext);
	} else {
		NSLog(@"[PNG Loader] could not load: %@",name);
	}
}

//Native methods
void loadNativePNG(texture_t* tmpTex) {
	[eaglview loadTexture:tmpTex ];
}

- (void)dealloc {
    
    [self stopAnimation];
    
    if ([EAGLContext currentContext] == context) {
        [EAGLContext setCurrentContext:nil];
    }
}

CGPoint previousLookAround;
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	NSArray* allTouches = [touches allObjects];

	if (allTouches.count == 4) {
		if (!camera.recording)
			CAM_StartRecording();
		else 
			CAM_StopRecording();
	}

	for(int i=0 ; i <allTouches.count ; i++) {

        UITouch *touch = [allTouches objectAtIndex:i];
        CGPoint currentPosition = [touch locationInView:self];
		
	//	NSLog(@"id: %d, posx=%.2f, posy=%.2f",i,currentPosition.x,currentPosition.y);
		
		if (currentPosition.y > 240) {
			previousLookAround = currentPosition;
		}
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {

	NSArray* allTouches = [touches allObjects];

	for(int i=0 ; i <allTouches.count ; i++) {

        UITouch *touch = [allTouches objectAtIndex:i];
        CGPoint previousPosition= [touch previousLocationInView:self];
        CGPoint currentPosition = [touch locationInView:self];
		
		float deltaX = previousPosition.x - currentPosition.x;
		float deltaY = previousPosition.y - currentPosition.y;
		
	//	printf("\n\n");
	//	NSLog(@"previousLookAround.x=%.2f",previousLookAround.x);
	//	NSLog(@"previousPosition.x=%.2f",previousPosition.x);
	//	NSLog(@"previousLookAround.y=%.2f",previousLookAround.y);
	//	NSLog(@"previousPosition.y=%.2f",previousPosition.y);
		
		command_t command;
		
		if (previousPosition.x == previousLookAround.x && previousPosition.y == previousLookAround.y) {
			//this was originally a lookAround touch
			//Comm_AddHead(-deltaY/100);
			//Comm_AddPitch(deltaX/100);
			
			command.type = COMMAND_TYPE_HEAD;
			command.value = -deltaY;
			Comm_AddCommand(&command);
			
			command.type = COMMAND_TYPE_PITCH;
			command.value = deltaX;
			
			Comm_AddCommand(&command);
			
			
			previousLookAround = currentPosition;
		} else {
			//this was originally a move touch
			command.type = COMMAND_TYPE_MOVE_NORTH_SOUTH;
			command.value = -deltaX;
			Comm_AddCommand(&command);
			
			command.type = COMMAND_TYPE_MOVE_EAST_WEST;
			command.value = deltaY;
			Comm_AddCommand(&command);

			//Comm_AddForBackWard(-deltaX);
			//Comm_Strafe(deltaY);
		}
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	
}

@end
