
#import <appkit/appkit.h>
#import "version.h"

@interface InfoView:View
{
	id	version;
	id	date;

	id background;
	id ball;
	int		teflag;
	NXSize	ballSize;
	NXPoint oldpos,newpos,speed;
	DPSTimedEntry te;
}

- initFrame:(const NXRect *) frameRect;
- drawFace:(double)time;
- loadFromFile:sender;
- drawSelf:(NXRect *)r :(int)count;
- windowDidMiniaturize:sender;
- windowDidBecomeKey:sender;
- windowDidResignKey:sender;
@end
