#import "InfoView.h"



void runOneStep(DPSTimedEntry timedEntry, double timeNow, void *data)
{
    [(id)data drawFace:timeNow];
}


@implementation InfoView

- initFrame:(const NXRect *)rect;
{
	
	[super initFrame:rect];
	[self allocateGState];



	teflag=0;
	background=[[NXImage allocFromZone:[self zone]] initFromSection:"Jolly.tiff"];
    [background setScalable:YES];
	ball=[[NXImage allocFromZone:[self zone]] initFromSection:"Jolly.tiff"];
    [ball setScalable:YES];
	[self sizeTo:bounds.size.width :bounds.size.height];
	//te=DPSAddTimedEntry((float).7/(float)67,&runOneStep,self,NX_BASETHRESHOLD);
	return self;
}


- drawFace:(double)time
{
	NXRect brect;
	if(teflag)
	{
		DPSRemoveTimedEntry(te);
		teflag=0;
	}
	if(newpos.x >bounds.size.width-ballSize.width || newpos.x<bounds.origin.x ) speed.x=floor(-speed.x);
	if(newpos.y >bounds.size.height-ballSize.height || newpos.y<bounds.origin.y ) speed.y=floor(-speed.y);
	
	newpos.x=floor(oldpos.x+speed.x);
	newpos.y=floor(oldpos.y+speed.y);
	[self lockFocus];
	
		if(speed.x>0)
		{
			brect.size.width	=speed.x;
			brect.origin.x		=oldpos.x;
		}
		else
		{
			brect.size.width	=-speed.x;
			brect.origin.x		=oldpos.x+speed.x+ballSize.width;
		}
		brect.size.height	=ballSize.height;
		brect.origin.y		=oldpos.y;
		[background composite:NX_COPY fromRect:&brect toPoint:&brect.origin];

		if(speed.y>0)
		{
			brect.size.height	=speed.y;
			brect.origin.y		=oldpos.y;
		}
		else
		{
			brect.size.height	=-speed.y;
			brect.origin.y		=oldpos.y+speed.y+ballSize.height;
		}
		brect.size.width	=ballSize.width;
		brect.origin.x		=oldpos.x;
		[background composite:NX_COPY fromRect:&brect toPoint:&brect.origin];


		
		oldpos.x=newpos.x;
		oldpos.y=newpos.y;
		[ball composite:NX_COPY toPoint:&newpos];
	//[[self window] flushWindow];
	//NXPing();
	[self unlockFocus];	
	NXPing();
	if(!teflag)
	{
		te=DPSAddTimedEntry((float)1/(float)67,&runOneStep,self,NX_BASETHRESHOLD);
		teflag=1;
    }
	return self;
}

- loadFromFile:sender
{
    return self;
}


- sizeTo:(NXCoord)width :(NXCoord)height
{
	[super sizeTo:width :height];
	[background setSize:&bounds.size];
    
	ballSize.width = floor(bounds.size.width/3);
    ballSize.height = floor(bounds.size.height/3);
    [ball setSize:&ballSize];	
	
	oldpos.x=floor(bounds.size.width/2.0); 	//bounds.size.width/2+bounds.origin.x;
	oldpos.y=floor(bounds.size.height/2.0);	//bounds.size.height/2+bounds.origin.y;
	speed.x=2;//floor(bounds.size.width/100.0);	//bounds.size.width/20;
	speed.y=2;//floor(bounds.size.height/100.0);	//bounds.size.height/20;

return self;
}

- drawSelf:(NXRect *)rect :(int)count
{
//	printf("Frame  w:%f   h:%f\n",frame.size.width,frame.size.height);
//	printf("Bounds w:%f   h:%f\n",bounds.size.width,bounds.size.height);
//	printf("Rect   w:%f   h:%f\n",rect->size.width,rect->size.height);

	//[background setSize:&frame.size];
	[background composite:NX_COPY fromRect:rect toPoint:&bounds.origin];
	return self;
}

/***********delegated methods should prevent wasting cpu */

- windowDidMiniaturize:sender
{
	if(teflag)
	{
		DPSRemoveTimedEntry(te);
		teflag=0;
	}
	return self;
}

- windowDidBecomeKey:sender
{
	char	str[100];
	
	sprintf(str,"Version :\n%s",VERSION);
	[version setStringValue:str];
	sprintf(str,"Created :\n%s ",DATE);
	[date setStringValue:str];
	
	[[super window] useOptimizedDrawing:YES];

	if(!teflag)
	{
		te=DPSAddTimedEntry((float)1/(float)67,&runOneStep,self,NX_BASETHRESHOLD);
		teflag=1;
	}
	return self;
}

- windowDidResignKey:sender
{
	if(teflag)
	{
		DPSRemoveTimedEntry(te);
		teflag=0;
	}
	return self;
}


@end
