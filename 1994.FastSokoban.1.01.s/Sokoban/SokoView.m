
#import "SokoView.h"

@implementation SokoView

- setSokoWindow:sender
{
	sokoWindow=sender;
	return self;
}

- setWaitPanel:sender
{
	waitPanel=sender;
	return self;
}

- initFrame:(const NXRect *)rect;
{
	[super initFrame:rect];
	[self allocateGState];
	[[super window] useOptimizedDrawing:YES];
	[[super window] addToEventMask:NX_RMOUSEDOWN];
	fieldX	=10;
	fieldY	=10;
	winOverhead.width	=2.0;	// good approx.
	winOverhead.height	=23.0;	// will be corrected at runtime

	way			=calloc(1,sizeof(char));
	east		=calloc(1,sizeof(int));
	west		=calloc(1,sizeof(int));
	north		=calloc(1,sizeof(int));
	south		=calloc(1,sizeof(int));

	wayDescription	=calloc(1,sizeof(int));
	knownWays		=calloc(1,sizeof(int));
	testWays		=calloc(1,sizeof(int));
	waysToTest		=calloc(1,sizeof(int));

	background	=	[[[NXImage allocFromZone:[self zone]] init] setScalable:NO];
					[background useDrawMethod:@selector(drawBackground:) inObject:self];
	women		=	[[[NXImage allocFromZone:[self zone]] init] setScalable:NO];
					[women useDrawMethod:@selector(drawWomen:) inObject:self];
	brick		=	[[[NXImage allocFromZone:[self zone]] init] setScalable:NO];
					[brick useDrawMethod:@selector(drawBrick:) inObject:self];
	gold		=	[[[NXImage allocFromZone:[self zone]] init] setScalable:NO];
					[gold useDrawMethod:@selector(drawGold:) inObject:self];
	base		=	[[[NXImage allocFromZone:[self zone]] init] setScalable:NO];
					[base useDrawMethod:@selector(drawBase:) inObject:self];

	return self;
}






- readLevelFromFile:(char *)level
{	
	FILE *fd;
	char	filename[MAXPATHLEN];
	
	int i,ix,iy;
	int minx=MAXGAMESIZE_X;
	int	miny=MAXGAMESIZE_Y;
	int	maxx=0;
	int maxy=0;
	
	goldN=0;baseN=0,solved=0;initSolved=0;
	
	strcpy(filename,NXArgv[0]);
	filename[strlen(filename)-strlen([NXApp appName])]=0;
	sprintf(filename,"%sLevels/screen.%s",filename,level);
	if((fd=fopen(filename,"r"))==NULL)
	{
		sprintf(filename,"%s/Levels/screen.%s",getwd(filename),level);
		if((fd=fopen(filename,"r"))==NULL)
		
		if(atoi(level)>50)
			NXRunAlertPanel("Congratulations !","You solved all Levels - you can mail me for new Levels","Quit",NULL,NULL);
		else
		 	NXRunAlertPanel("File not found Error",filename,"Quit",NULL,NULL);
		[NXApp terminate:self];
	}
	for(i=0;i<MAXGAMESIZE_X*MAXGAMESIZE_Y;i++)field[i]=ILLEGAL;
	fieldX=0;
	fieldY=0;
	while(!feof(fd) && fieldY<MAXGAMESIZE_Y)
		fgets(field+((fieldY++)*MAXGAMESIZE_X),MAXGAMESIZE_X,fd);
	fclose(fd);
	
	for(iy=0;iy<fieldY;iy++)
		for(ix=0;ix<MAXGAMESIZE_X;ix++)
			if(field[iy*MAXGAMESIZE_X+ix]==BRICK)
			{	
				if(ix<minx) minx=ix;
				if(iy<miny)	miny=iy;
				if(ix>maxx)	maxx=ix;
				if(iy>maxy) maxy=iy;
			}
	
	fieldX=maxx-minx+1;
	fieldY=maxy-miny+1;

	for(iy=0;iy<fieldY;iy++)
	{
		for(ix=0;ix<fieldX;ix++)
		{	
			field[iy*fieldX+ix]	=field[((miny+iy)*MAXGAMESIZE_X)+minx+ix];
			if(field[iy*fieldX+ix]==WOMEN || field[iy*fieldX+ix]==W_O_B)	womenPosition			=ix+iy*fieldX;
			if(field[iy*fieldX+ix]==GOLD)		goldPosition[goldN++]	=ix+iy*fieldX;
			if(field[iy*fieldX+ix]==G_O_B)	{	goldPosition[goldN++]	=ix+iy*fieldX; initSolved++; }
			if(field[iy*fieldX+ix]==BASE || field[iy*fieldX+ix]==G_O_B || field[iy*fieldX+ix]==W_O_B) basePosition[baseN++]	=ix+iy*fieldX;
		}
	}
	solved=initSolved;
	sprintf(filename,"Sokoban -  Level : %s",level);
	[[super window] setTitle:filename];
	[self sizeTo:bounds.size.width :bounds.size.height];
	[self display];
	NXPing();
	[waitPanel makeKeyAndOrderFront:self];
	[waitPanel display];
	
		NXPing();	
		[self setupWayfinder];
		[self savePosition];
	
	[waitPanel orderOut:self];
	return self;
}

- restartLevel
{
	int p;
	
	goldN=0;baseN=0,solved=initSolved;

	for(p=0;p<pieces;p++)
	{
		if(field[p]==WOMEN || field[p]==W_O_B)						womenPosition			=p;
		if(field[p]==GOLD || field[p]==G_O_B)						goldPosition[goldN++]	=p;
		if(field[p]==BASE || field[p]==G_O_B || field[p]==W_O_B) 	basePosition[baseN++]	=p;
	}
	//[self savePosition]; this was yodas idea not mine !
	[self display];
	return self;
}


- restorePosition
{	
	solved			=last_solved;
	womenPosition	=last_womenPosition;
	bcopy(last_goldPosition,goldPosition,goldN*sizeof(int));
	bcopy(last_basePosition,basePosition,baseN*sizeof(int));

	[self display];
	return self;
}


- savePosition
{	
	last_solved			=solved;
	last_womenPosition	=womenPosition;
	bcopy(goldPosition,last_goldPosition,goldN*sizeof(int));
	bcopy(basePosition,last_basePosition,baseN*sizeof(int));
	
	return self;
}




- setupWayfinder
{
	int	p,q,k,r;
	int test;
	pieces=fieldX*fieldY;

	free(way);
	free(east);
	free(west);
	free(north);
	free(south);

	free(wayDescription);
	free(knownWays);
	free(testWays);
	free(waysToTest);

	way			=calloc(pieces*pieces,sizeof(char));
	east		=calloc(pieces,sizeof(int));
	west		=calloc(pieces,sizeof(int));
	north		=calloc(pieces,sizeof(int));
	south		=calloc(pieces,sizeof(int));
		
	wayDescription	=calloc(pieces,sizeof(int));
	knownWays		=calloc(pieces,sizeof(int));
	testWays		=calloc(pieces,sizeof(int));
	waysToTest		=calloc(pieces,sizeof(int));

	cway		=calloc(pieces*pieces,sizeof(char));

	for(p=0;p<pieces;p++)
	{
		if(field[p]!=BRICK)
		{
			way[p*pieces+p]=MYWAY;
			test	=(p/fieldX)*fieldX+((p%fieldX+1)%fieldX);if(field[test]!=BRICK){way[p*pieces+test]=EAST;east[p]=test;}else east[p]=-1;
			test	=(p/fieldX)*fieldX+((p-1+fieldX)%fieldX);if(field[test]!=BRICK){way[p*pieces+test]=WEST;west[p]=test;}else west[p]=-1;
			test	=(p-fieldX	+pieces)%pieces;	if(field[test]!=BRICK){way[p*pieces+test]=NORTH;north[p]=test;}else north[p]=-1;
			test	=(p+fieldX	+pieces)%pieces;	if(field[test]!=BRICK){way[p*pieces+test]=SOUTH;south[p]=test;}else south[p]=-1;
		}
	}
			
	bcopy(way,cway,pieces*pieces);
	do
	{
		test=FALSE;
		for(p=0;p<pieces;p++)							// p=piece,q=question,k=known
		{
			r=p*pieces;
			if(field[p]!=BRICK)
			{
				if((q=east[p])!=-1)
				{
					for(k=0;k<pieces;k++)
						if(way[r+k]==NOWAY && way[q*pieces+k]!=NOWAY)
							test=cway[r+k]=EAST;
				}		
				if((q=west[p])!=-1)
				{
					for(k=0;k<pieces;k++)
						if(way[r+k]==NOWAY && way[q*pieces+k]!=NOWAY)
							test=cway[r+k]=WEST;
				}		
				if((q=north[p])!=-1)
				{
					for(k=0;k<pieces;k++)
						if(way[r+k]==NOWAY && way[q*pieces+k]!=NOWAY)
							test=cway[r+k]=NORTH;
				}		
				if((q=south[p])!=-1)
				{
					for(k=0;k<pieces;k++)
						if(way[r+k]==NOWAY && way[q*pieces+k]!=NOWAY)
							test=cway[r+k]=SOUTH;
				}		
			}
		}
		
		for(p=0;p<pieces*pieces;p+=pieces)
			if(field[p/pieces]!=BRICK)
				bcopy(cway+p,way+p,pieces);

	}
	while(test);
	
	free(cway);
	return self;
}


- (int)findWay:(int)end
{
	return way[womenPosition*pieces+end];
}






- findWayWithoutConflicts:(int)end
{
	int i;
	int mom,moves;
	int *tw,*wtt;
	int	*beg_tw,*beg_wtt,*beg_mom;
	
	
	memset(knownWays,0xff,pieces*sizeof(int));
	
	for(i=0;i<goldN;i++)												// removing goldbars from possible ways 
		knownWays[goldPosition[i]]=-2;
	
	knownWays[womenPosition]=-2;
	
	waysToTest[0]	=womenPosition;
	waysToTest[1]	=-1;
	beg_tw			=testWays;
	beg_wtt			=waysToTest;
	moves			=0;
	
	do
	{
		beg_mom	=beg_wtt;
		beg_wtt	=beg_tw;
		beg_tw	=beg_mom;
		beg_wtt[0]=-1;
		
		tw	=beg_tw;
		wtt	=beg_wtt;
	
		do
		{
			if(	(mom=east[*tw])!=-1 	&& knownWays[mom]==-1) knownWays[*wtt++=mom]=*tw;
			if(	(mom=west[*tw])!=-1 	&& knownWays[mom]==-1) knownWays[*wtt++=mom]=*tw;
			if(	(mom=north[*tw])!=-1	&& knownWays[mom]==-1) knownWays[*wtt++=mom]=*tw;
			if(	(mom=south[*tw])!=-1 	&& knownWays[mom]==-1) knownWays[*wtt++=mom]=*tw;
		}
		while(end!=*tw && *++tw!=-1);
		*wtt=-1;
	moves++;
	}
	while(end!=*tw && wtt!=beg_wtt);
	
	if(end!=*tw)
	{
		wayDescription[0]=-1;
		return self;
	}
	
	
	mom=*tw;
	while(moves)
	{
		wayDescription[--moves]=mom;
		mom=knownWays[mom];
	}

	return self;
}






- (int)findPositionFromDirection:(int)begin :(int)direction
{
	int newPosition;
	
	switch(direction)
	{
		case EAST	:newPosition=east[begin];break;
		case WEST	:newPosition=west[begin];break;
		case NORTH	:newPosition=north[begin];break;
		case SOUTH	:newPosition=south[begin];break;
		default		:newPosition=begin;
	}
	if(newPosition==-1) return begin;
	return newPosition;
}

/****************************************************animation */


- moveWomen:(int)end
{
	int direction;
	int	newPosition,behind;
	int	flag,mom;
	int isBase,wasBase;
	int firstMove=TRUE;
	
	do
	{
		if((direction=[self findWay:end])==NOWAY)
		{
			NXBeep();
			return self;
		}
		newPosition=[self findPositionFromDirection:womenPosition :direction];
		if(newPosition==womenPosition)
		{
			NXBeep();
			return self;
		}
		
		flag=-1;
		wasBase=0;
		isBase=0;
		for(mom=0;mom<goldN;mom++)
		{
			if(goldPosition[mom]==newPosition)	flag=mom;
			if(basePosition[mom]==newPosition)	wasBase=1;
		}
		if(flag!=-1)
		{
			behind=[self findPositionFromDirection:newPosition :direction];
			for(mom=0;mom<goldN;mom++)
			{
				if(goldPosition[mom]==behind)	flag=-2;
				if(basePosition[mom]==behind) isBase=1;
			}
			if(flag==-2)
			{
				NXBeep();
				return self;
			}
			if(firstMove)
			{
				[self savePosition];
				firstMove=FALSE;	
			}
			[self animateWomenWithGold:newPosition :behind];
			goldPosition[flag]=behind;
			solved=solved+isBase-wasBase;
			if(end==behind) return self;
		}	
		else
		{
			[self animateWomen:newPosition];
		}				
	}
	while(newPosition!=end);
	
	return self;
}



- animateWomen:(int)newPosition
{
	NXRect	rect={0.0,0.0,matrix.width,matrix.height};
	
	[self lockFocus];
		rect.origin.x=(float)(	(womenPosition%fieldX)*matrix.width );
		rect.origin.y=(bounds.size.height-matrix.height)-(float)(	(womenPosition/fieldX)*matrix.height );
		[background composite:NX_COPY fromRect:&rect toPoint:&rect.origin];		
		
		rect.origin.x=(float)(	(newPosition%fieldX)*matrix.width );
		rect.origin.y=(bounds.size.height-matrix.height)-(float)(	(newPosition/fieldX)*matrix.height );
		[women composite:NX_SOVER toPoint:&rect.origin];
	NXPing();
usleep(300);
	[self unlockFocus];
	womenPosition=newPosition;
	return self;
}

- animateWomenWithGold:(int)newPosition :(int)behind
{
	NXRect	rect={0.0,0.0,matrix.width,matrix.height};
	
	[self lockFocus];
		rect.origin.x=(float)(	(newPosition%fieldX)*matrix.width );
		rect.origin.y=(bounds.size.height-matrix.height)-(float)(	(newPosition/fieldX)*matrix.height );
		[background composite:NX_COPY fromRect:&rect toPoint:&rect.origin];		
		
		rect.origin.x=(float)(	(behind%fieldX)*matrix.width );
		rect.origin.y=(bounds.size.height-matrix.height)-(float)(	(behind/fieldX)*matrix.height );
		[gold composite:NX_SOVER toPoint:&rect.origin];

		rect.origin.x=(float)(	(newPosition%fieldX)*matrix.width );
		rect.origin.y=(bounds.size.height-matrix.height)-(float)(	(newPosition/fieldX)*matrix.height );
		[women composite:NX_SOVER toPoint:&rect.origin];

		rect.origin.x=(float)(	(womenPosition%fieldX)*matrix.width );
		rect.origin.y=(bounds.size.height-matrix.height)-(float)(	(womenPosition/fieldX)*matrix.height );
		[background composite:NX_COPY fromRect:&rect toPoint:&rect.origin];		
	NXPing();
	[self unlockFocus];
	
	womenPosition=newPosition;
	return self;
}





/********************************************************** drawing the Images */

- drawBackground:imageRep
{
	int ix,iy;
	NXPoint		ori;
	NXRect		rect={0.0,0.0,matrix.width,matrix.height};
	
	PSsetgray(NX_DKGRAY);
	NXRectFill(&bounds);
	
	for(iy=0;iy<fieldY;iy++)
	{
		for(ix=0;ix<fieldX;ix++)
		{
			ori.x=(float)ix*matrix.width;
			ori.y=(bounds.size.height-matrix.height)-(float)iy*matrix.height;
			if(field[iy*fieldX+ix]==BRICK)
				[brick composite:NX_COPY fromRect:&rect toPoint:&ori];
			if(field[iy*fieldX+ix]==BASE ||field[iy*fieldX+ix]==W_O_B || field[iy*fieldX+ix]==G_O_B)
				[base composite:NX_COPY fromRect:&rect toPoint:&ori];
		}
	}
	return self;
}


- drawWomen:imageRep
{
	NXRect rect={0.0,0.0,matrix.width,matrix.height};
#define RADIUS		8.0 				// Ball radius
#define BALLWIDTH	(RADIUS * 2.0)		// Ball width
#define BALLHEIGHT	(RADIUS * 2.0)		// Ball height
#define SHADOWOFFSET 3.0

	PSsetalpha(0.0);
	NXRectFill(&rect);
	PSsetalpha(1.0);

	PSscale (matrix.width / BALLWIDTH, matrix.height / BALLHEIGHT);
	
    PSarc (RADIUS-SHADOWOFFSET/2, RADIUS+SHADOWOFFSET/2, RADIUS-SHADOWOFFSET-1.0, 0.0, 360.0);
    PSsetgray (NX_LTGRAY);
    PSfill ();
	
    PSarcn(RADIUS-SHADOWOFFSET/2 , RADIUS+SHADOWOFFSET/2, RADIUS-SHADOWOFFSET-3.0, 170.0, 100.0);
    PSarc (RADIUS-SHADOWOFFSET/2 , RADIUS+SHADOWOFFSET/2, RADIUS-SHADOWOFFSET-2.0, 100.0, 170.0);
    PSsetgray (NX_WHITE);
    PSfill ();
 
    PSarcn(RADIUS-SHADOWOFFSET/2, RADIUS+SHADOWOFFSET/2, RADIUS-SHADOWOFFSET-2.0, 350.0, 280.0);
    PSarc (RADIUS-SHADOWOFFSET/2, RADIUS+SHADOWOFFSET/2, RADIUS-SHADOWOFFSET-2.0, 280.0, 350.0);
    PSsetgray (NX_DKGRAY);
    PSfill ();

	return self;
}

- drawBrick:imageRep
{
	NXRect rect={0.0,0.0,matrix.width,matrix.height};
	NXDrawButton(&rect,NULL);
	return self;
}

- drawGold:imageRep
{
	NXRect rect={0.0,0.0,matrix.width,matrix.height};
	
	PSsetalpha(0.0);
	NXRectFill(&rect);
	PSsetalpha(1.0);

	rect.size.height=matrix.height*2/3;
	rect.size.width	=matrix.width*2/3;
	rect.origin.x	=matrix.width/6;
	rect.origin.y	=matrix.height/6;
	
    NXDrawButton (&rect, NULL);
    NXInsetRect (&rect, matrix.width/10, matrix.height/10);
    NXDrawWhiteBezel (&rect, NULL);

	return self;
}

- drawBase:imageRep
{
	NXRect rect={0.0,0.0,matrix.width,matrix.height};
	
	PSsetgray(NX_DKGRAY);
	NXRectFill(&rect);
	NXDrawWhiteBezel(&rect,NULL);	
	return self;
}








/******************* class Methods */

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (BOOL)acceptsFirstMouse
{
    return NO;
}


- rightMouseDown:(NXEvent *)event
{
	static	NXPoint mouse;
	static	int		posx,posy;
	static	int		end;
	static	char	str[10];
	
	[sokoWindow getMouseLocation:&mouse];
	[self convertPoint:&mouse fromView:nil];

	posx=(int)floor(mouse.x/matrix.width);
	posy=(int)floor((bounds.size.height-mouse.y)/matrix.height);
	
	end=posx+posy*fieldX;
	[self moveWomen:end];
	if(solved==baseN)
	{
		solved=atoi((char *)NXGetDefaultValue([NXApp appName],"Level"));
		sprintf(str,"%d",++solved);
		NXWriteDefault([NXApp appName],"Level",str);
		[self readLevelFromFile:str];
	}
	return self;
}


- mouseDown:(NXEvent *)event
{
	static	NXPoint mouse;
	static	int		posx,posy;
	static	int		end;
	static	char	str[10];
	static	int		*mom;
	
	[sokoWindow getMouseLocation:&mouse];
	[self convertPoint:&mouse fromView:nil];

	posx=(int)floor(mouse.x/matrix.width);
	posy=(int)floor((bounds.size.height-mouse.y)/matrix.height);
	
	end=posx+posy*fieldX;
	if(womenPosition==end) return self;
	if([self findWay:end]==NOWAY)
	{
		NXBeep();
		return self;
	}

	[self findWayWithoutConflicts:end];
	
	if(*wayDescription==-1)
	{
		NXBeep();
		return self;
	}

	mom=wayDescription;
	do
	{
		[self animateWomen:*mom++];
	}
	while(end!=womenPosition);

	if(solved==baseN)
	{
		solved=atoi((char *)NXGetDefaultValue([NXApp appName],"Level"));
		sprintf(str,"%d",++solved);
		NXWriteDefault([NXApp appName],"Level",str);
		[self readLevelFromFile:str];
	}

	return self;
}

- keyDown:(NXEvent *)event
{
	static char str[10];
	
	
	if(event->data.key.charSet==NX_SYMBOLSET)
	{
		switch(event->data.key.charCode)
		{
			case 0xAD:	[self moveWomen:[self findPositionFromDirection:womenPosition :NORTH]];break;
			case 0xAE:	[self moveWomen:[self findPositionFromDirection:womenPosition :EAST]];break;
			case 0xAF:	[self moveWomen:[self findPositionFromDirection:womenPosition :SOUTH]];break;
			case 0xAC:	[self moveWomen:[self findPositionFromDirection:womenPosition :WEST]];break;
		}
	}
	if(event->data.key.charSet==NX_ASCIISET)
	{
		switch(event->data.key.charCode)
		{
			case '8':	[self moveWomen:[self findPositionFromDirection:womenPosition :NORTH]];break;
			case '6':	[self moveWomen:[self findPositionFromDirection:womenPosition :EAST]];break;
			case '2':	[self moveWomen:[self findPositionFromDirection:womenPosition :SOUTH]];break;
			case '4':	[self moveWomen:[self findPositionFromDirection:womenPosition :WEST]];break;
			case 'u':	return [self restorePosition];
			case 'U':	return [self restorePosition];
			case 'r':	return [self restartLevel];
			case 'R':	return [self restartLevel];
		}
	}
	
	if(solved==baseN)
	{
		solved=atoi((char *)NXGetDefaultValue([NXApp appName],"Level"));
		sprintf(str,"%d",++solved);
		NXWriteDefault([NXApp appName],"Level",str);
		[self readLevelFromFile:str];
	}
	return self;

}



- sizeTo:(NXCoord)width :(NXCoord)height
{
	NXRect	rect;
	
	width	=floor(width);
	height	=floor(height);
	
	matrix.width=floor(width/(float)fieldX);
	matrix.height=floor(height/(float)fieldY);

	if(matrix.width !=width/fieldX || matrix.height!=height/fieldY)
	{
		[sokoWindow getFrame:&rect];
		winOverhead.width	=rect.size.width-width;
		winOverhead.height	=rect.size.height-height;
		
		return [sokoWindow	sizeWindow:(matrix.width*(float)fieldX):(matrix.height*(float)fieldY)];			
		
	}

	if(width==bounds.size.width && height==bounds.size.height)
	{
		[background lockFocus];
		[self drawBackground:self];
		[background unlockFocus];
	}

	[super sizeTo:width :height];	
	[women	setSize:&matrix];
	[brick	setSize:&matrix];
	[gold	setSize:&matrix];
	[base	setSize:&matrix];
	[background setSize:&bounds.size];
	return self;
}

- drawSelf:(NXRect *)zone :(int)count
{
	NXPoint		ori;
	int i;
	
	[background setSize:&matrix];			// cursed background ! 
	[background setSize:&bounds.size];
	[background composite:NX_COPY fromRect:zone toPoint:&bounds.origin];

	for(i=0;i<goldN;i++)
	{
		ori.x=(float)(goldPosition[i]%fieldX)*matrix.width;
		ori.y=(bounds.size.height-matrix.height)-(float)(goldPosition[i]/fieldX)*matrix.height;
		[gold composite:NX_SOVER toPoint:&ori];
	}
	ori.x=(float)(womenPosition%fieldX)*matrix.width;
	ori.y=(bounds.size.height-matrix.height)-(float)(womenPosition/fieldX)*matrix.height;
	[women composite:NX_SOVER toPoint:&ori];

	return self;
}




/****************** delegated Methods */

- windowWillResize:sender toSize:(NXSize *)frameSize
{
	frameSize->width	=frameSize->width-winOverhead.width;
	frameSize->height	=frameSize->height-winOverhead.height;


		frameSize->width	=rint(	frameSize->width  / (float)fieldX -.5)*(float)fieldX;
		frameSize->height	=rint(	frameSize->height / (float)fieldY -.5)*(float)fieldY;
	
		if(frameSize->width <(float)(fieldX*10)) frameSize->width =(float)(fieldX*10);
		if(frameSize->height<(float)(fieldY*10)) frameSize->height=(float)(fieldY*10);


	frameSize->width	=frameSize->width+winOverhead.width;
	frameSize->height	=frameSize->height+winOverhead.height;
	
	return sender;
}


@end




