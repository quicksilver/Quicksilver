

#import "QSKeyboardTriggerReferenceView.h"



@implementation QSKeyboardTriggerReferenceView


- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        // Initialization code here.
    }
    return self;
}

- (void)awakeFromNib{
    rects=[[[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Keymap" ofType:@"map"]]
componentsSeparatedByString:@"\r"]retain];
    
    dict=[[NSMutableDictionary dictionaryWithCapacity:[rects count]]retain];
    
    
    NSString *thisRect;
    NSString *key;
    NSRect rect;
    enclosingRect=NSZeroRect;
    NSScanner *thisScanner;
    int i=0;
    for (thisRect in rects){
        thisScanner=[NSScanner scannerWithString:thisRect];
        [thisScanner scanString:@"rect" intoString:nil];
        [thisScanner scanCharactersFromSet:[[NSCharacterSet whitespaceCharacterSet]invertedSet] intoString:&key];
        
        [thisScanner scanFloat:&rect.origin.x];
        [thisScanner scanString:@"," intoString:nil];
        [thisScanner scanFloat:&rect.origin.y];
        
        [thisScanner scanFloat:&rect.size.width];
        [thisScanner scanString:@"," intoString:nil];
        [thisScanner scanFloat:&rect.size.height];
        
        rect.size.height-=rect.origin.y;
        rect.size.width-=rect.origin.x;
        
        
        enclosingRect=NSUnionRect(enclosingRect, rect);
      //  logRect(rect);
        
        if ([key isEqualToString:@"#"]) key=[NSString stringWithFormat:@"?%d?",i++];
if (key) [dict setObject:NSStringFromRect(rect) forKey:key];

    }


//QSLog(@"r%@",dict);      
}

- (BOOL)isFlipped{
    return YES;
}
    
- (void)drawRect:(NSRect)rect {
    NSRect expandedRect=centerRectInRect(fitRectInRect(enclosingRect,rect,0),rect);
    

NSAffineTransform *transform=[NSAffineTransform transform];

    [transform scaleXBy:NSWidth(expandedRect)/NSWidth(enclosingRect) yBy:NSHeight(expandedRect)/NSHeight(enclosingRect)]; 
    [transform concat];

    NSEnumerator *rectEn=[dict keyEnumerator];
    NSString *key;
 //   NSArray *rectAttributes;
    while (key=[rectEn nextObject]){
        
        [[NSColor lightGrayColor]set];
        NSRect thisRect=NSRectFromString([dict objectForKey:key]);
        NSBezierPath *roundRect=[NSBezierPath bezierPath];
        [roundRect appendBezierPathWithRoundedRectangle:thisRect withRadius:4.0];
        [roundRect fill];    
        
        NSDictionary *attrib=[key attributesToFitRect:thisRect withAttributes:nil];
        
        NSRect drawRect=centerRectInRect(rectFromSize([key sizeWithAttributes:attrib]),thisRect);
        [key drawInRect:NSInsetRect(drawRect,-1,-1) withAttributes:attrib];
    }
    
    // Drawing code here.
}

@end
