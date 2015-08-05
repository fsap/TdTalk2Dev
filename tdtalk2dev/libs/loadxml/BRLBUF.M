#import <Foundation/Foundation.h>    
#import "brlbuf.h"
#import "list.h"
@implementation BrlBuffer 
- (void)Setinit {
	m_lpList = [[BrlList alloc] init];
	m_lpList = [m_lpList autorelease];
	id lpTmpList = [[BrlList alloc] init];
	lpTmpList = [lpTmpList autorelease];
	m_lpDelList = [[BrlList alloc] init];
	m_lpDelList = [m_lpDelList autorelease];
	id lpTmpDelList = [[BrlList alloc] init];
	lpTmpDelList = [lpTmpDelList autorelease];
	// Xg?f[^?WA??
	[m_lpList SetAttr:BUF_LIST_HEAD];
	[m_lpList SetStart:m_lpList];
	[m_lpList SetNext:lpTmpList];
	[m_lpList SetBefore:lpTmpList];
	[lpTmpList SetAttr:BUF_LIST_END];
	[lpTmpList SetStart:m_lpList];
	[lpTmpList SetNext:m_lpList];
	[lpTmpList SetBefore:m_lpList];
	// ?Xg?\z
	[m_lpDelList SetAttr:BUF_DEL_LIST_HEAD];
	[m_lpDelList SetStart:m_lpDelList];
	[m_lpDelList SetNext:lpTmpDelList];
	[m_lpDelList SetBefore:lpTmpDelList];
	[lpTmpDelList SetAttr:BUF_DEL_LIST_END];
	[lpTmpDelList SetStart:m_lpDelList];
	[lpTmpDelList SetNext:m_lpDelList];
	[lpTmpDelList SetBefore:m_lpDelList];
/*
FILE *fp = fopen("log.txt", "a");
fprintf(fp, "setinit\n");
fclose(fp);
*/
}

- (void)Ins:(unsigned char *)Dat {
	id TmpList;
	m_lpDelList = [m_lpDelList GetStart];
	if ([[m_lpDelList GetNext] GetAttr] != BUF_LIST_END) {	// XgbNIuWFNg?
		TmpList = [m_lpDelList GetNext];
		[[TmpList GetNext] SetBefore:m_lpDelList];
		[m_lpDelList SetNext:[TmpList GetNext]];
	} else {	// XgbN????VIuWFNg?
		TmpList = [[BrlList alloc] init];
		TmpList = [TmpList autorelease];
		[TmpList SetAttr:BUF_LIST_DATA];
	}
	[TmpList SetStart:[m_lpList GetStart]];
	[TmpList SetNext:[m_lpList GetNext]];
	[TmpList SetBefore:m_lpList];
	[[m_lpList GetNext] SetBefore:TmpList];
	[m_lpList SetNext:TmpList];
	m_lpList = TmpList;
	[m_lpList SetData:Dat];
	[m_lpList SetUserInfo:*Dat];
}

- (char *)GetDat {
	char* str = (char *)[m_lpList GetData];
//	Word = [NSString stringWithCString: str encoding:NSUTF8StringEncoding];
	return str;
}

- (BOOL)NextLine {
	if ([[m_lpList GetNext] GetAttr] == BUF_LIST_END)
		return FALSE;
	m_lpList = [m_lpList GetNext];
	return TRUE;
}


- (void)Top {
	m_lpList = [[m_lpList GetStart] GetNext];
}

- (void)End {
	m_lpList = [[[m_lpList GetStart] GetBefore] GetBefore];
}

@end
