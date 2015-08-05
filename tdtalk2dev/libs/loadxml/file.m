#import <Foundation/Foundation.h>    
#import "file.h"
#import "brlbuf.h"
#include <string.h>
@implementation File
- (void)DataSet:(id)Bufid {
	m_EditBuffer = Bufid;
}

- (int)LoadXmlFile:(const char *)filename ReadMode:(int)RMode {
	FILE *InFp;
	if((InFp = fopen(filename,"r")) == NULL) {
		return(-1);
	}
	if (RMode) {
		[m_EditBuffer End];
	}
//FILE *fp = fopen("log.txt", "a");
//fprintf(fp, "%s\n",filename);
//fclose(fp);
	char TmpDat[1024];
	char rStr[512];
	int Start, End, End2;
	int Midashi = 0;
	int Level = 0;
	int Sent = 0;
	int reply = 0;
	memset(m_EditData.Data,0x00,BRLDOC_DAT_SIZE);
	while (1) {
		if (fgets(TmpDat, 1024, InFp) == NULL) {
			reply = 1;
			break;
		}
		if ([self sSearch:TmpDat Str2:"<h1>" Start:0]) {
			Midashi = 1;


		}
		if ([self sSearch:TmpDat Str2:"</h1>" Start:0]) {
			Midashi = 0;


		}
		if ([self sSearch:TmpDat Str2:"<h2>" Start:0]) {
			Midashi = 2;


		}
		if ([self sSearch:TmpDat Str2:"</h2>" Start:0]) {
			Midashi = 0;
		}
		if ([self sSearch:TmpDat Str2:"<h3>" Start:0]) {
			Midashi = 3;
		}
		if ([self sSearch:TmpDat Str2:"</h3>" Start:0]) {
			Midashi = 0;
		}
		if ([self sSearch:TmpDat Str2:"<h4>" Start:0]) {
			Midashi = 4;
		}
		if ([self sSearch:TmpDat Str2:"</h4>" Start:0]) {
			Midashi = 0;
		}
		if ([self sSearch:TmpDat Str2:"<h5>" Start:0]) {
			Midashi = 5;
		}
		if ([self sSearch:TmpDat Str2:"</h5>" Start:0]) {
			Midashi = 0;
		}
		if ([self sSearch:TmpDat Str2:"<h6>" Start:0]) {
			Midashi = 6;
		}
		if ([self sSearch:TmpDat Str2:"</h6>" Start:0]) {
			Midashi = 0;
		}
		if ([self sSearch:TmpDat Str2:"<level1>" Start:0]) {
			Level |= 1;
		}
		if ([self sSearch:TmpDat Str2:"<level2>" Start:0]) {
			Level |= 0x02;
		}
		if ([self sSearch:TmpDat Str2:"<level3>" Start:0]) {
			Level |= 0x04;
		}
		if ([self sSearch:TmpDat Str2:"<level4>" Start:0]) {
			Level |= 0x08;
		}
		if ([self sSearch:TmpDat Str2:"</p>" Start:0]) {
		}
		if ([self sSearch:TmpDat Str2:"<span class=\"ruby\">" Start:0]) {
			m_EditData.Block.LineAttr.Map.Midashi = Midashi;
			m_EditData.Block.LineAttr.Map.Level = Level;
			memset(rStr, 0x00, sizeof(rStr));
			[self SetRuby:TmpDat rStr:rStr];
			[self SetBuf:rStr];
			Sent = 0;
			Midashi = 0;
			Level = 0;
			continue;
		}
		if ([self sSearch:TmpDat Str2:"<span class=\"italic\">" Start:0] ||
		    [self sSearch:TmpDat Str2:"<span class=\"bold\">" Start:0] ||
		    [self sSearch:TmpDat Str2:"<span class=\"strike\">" Start:0] ||
		    [self sSearch:TmpDat Str2:"<span class=\"underline\">" Start:0]) {
			memset(rStr, 0x00, sizeof(rStr));
			[self SetSpan:TmpDat rStr:rStr];
			m_EditData.Block.LineAttr.Map.Midashi = Midashi;
			m_EditData.Block.LineAttr.Map.Level = Level;
			[self SetBuf:rStr];
			Sent = 0;
			Midashi = 0;
			Level = 0;
			continue;
		}
		Start = 0;
		Start = [self sSearch:TmpDat Str2:"sent id=" Start:0];
		if (Start) {
			if (Sent) {
			}
			Start = [self sSearch:TmpDat Str2:"\">" Start:Start+1];
			End = [self sSearch:TmpDat Str2:"<" Start:Start+1];
			End2 = [self sSearch:TmpDat Str2:"</sent>" Start:Start+1];
			Sent = 1;
			Start += 2;
			if (Start && End && (End == End2) && *(TmpDat + Start) != 0x3c) {
				memset(rStr, 0x00, sizeof(rStr));
				strncpy(rStr, TmpDat + Start, End - Start);
				m_EditData.Block.LineAttr.Map.Midashi = Midashi;
				m_EditData.Block.LineAttr.Map.Level = Level;
				[self SetBuf:rStr];
				Sent = 0;
					Midashi = 0;
					Level = 0;
					continue;
			}
			else {
			}
		}
		Start = 0;
		Start = [self sSearch:TmpDat Str2:"strong>" Start:0];
		if (Start) {
			End = [self sSearch:TmpDat Str2:"</strong>" Start:Start+1];
			if (End) {
				Start += 7;
				memset(rStr, 0x00, sizeof(rStr));
				strncpy(rStr, TmpDat + Start, End - Start);
				m_EditData.Block.LineAttr.Map.Midashi = Midashi;
				m_EditData.Block.LineAttr.Map.Level = Level;
				[self SetBuf:rStr];
			Sent = 0;
				Midashi = 0;
				Level = 0;
				continue;
			}
		}
		Start = 0;
		Start = [self sSearch:TmpDat Str2:"<pagenum id=" Start:0];
		if (Start) {
			Start = [self sSearch:TmpDat Str2:"\">" Start:Start+1];
			End = [self sSearch:TmpDat Str2:"</pagenum>" Start:Start+1];
			if (Start && End) {
				Start += 2;
				strncpy(m_EditData.Data+2, TmpDat + Start, End - Start);
				m_EditData.Block.LineAttr.Map.Page = 1;
				[m_EditBuffer Ins:m_EditData.Data];
				memset(m_EditData.Data,0x00,BRLDOC_DAT_SIZE);
				continue;
			}
		}
	}
	fclose(InFp);
//fp = fopen("log.txt", "a");
//fprintf(fp, "%s\n\n",filename);
//fclose(fp);
	[m_EditBuffer Top];
	return(0);
}

- (int)SaveTdvFile:(const char *)filename {
	FILE *OutFp;
	int reply = 0;
	m_EditHeadder.DatHead.CurLine = 0;
	if((OutFp = fopen(filename,"w+b")) == NULL) {
		return(-1);
	}
	if(!fwrite(&m_EditHeadder,BRLDOC_HEAD_SIZE,1,OutFp)) {
		fclose(OutFp);
		unlink(filename);
		return(3);
	}
	int Ix;
	fflush(OutFp);
	[m_EditBuffer Top];
	while (1) {
		memcpy(m_EditData.Data, [m_EditBuffer GetDat], BRLDOC_DAT_SIZE);
		if(!fwrite(m_EditData.Data, 256, 1, OutFp)) {
			reply = 3;
			break;
		}
		fflush(OutFp);
		if (![m_EditBuffer NextLine]) {
			break;
		}
	}
	fflush(OutFp);
	fclose(OutFp);
	return(reply);
}

- (int)sSearch:(char *)Str1 Str2:(char *)Str2 Start:(int)Start {
	int Ix = 0;
	int Len1 = strlen(Str1);
	int Len2 = strlen(Str2);
	while (Str1[Start]) {
		for (Ix = 0; Ix < Len2; Ix++) {
			if ((Start + Ix) > Len1) {
				break;
			}
			if (Str1[Start + Ix] == Str2[Ix] ||
			    (Str1[Start + Ix] >= 0x41 &&
			     Str1[Start + Ix] <= 0x5a &&
			     (Str1[Start+ Ix] + 0x20) == Str2[Ix])) {
				continue;
			}
			else {
				break;
			}
		}
		if (Ix == Len2) {
			return Start;
		}
		Start++;
	}
	return 0;
}

- (int)IsKugiri:(char *)Str {
	int Start = 251;
	while (Start > 0) {
		if (!strncmp(Str + Start, "。", 3) ||
		    !strncmp(Str + Start, "、", 3) ||
		    !strncmp(Str + Start, "・", 3) ||
		    !strncmp(Str + Start, "」", 3) ||
		    !strncmp(Str + Start, "）", 3) ||
		    !strncmp(Str + Start, "　", 3)) {
			return Start;
		}
		Start--;
	}
	return 0;
}

- (void)SetRuby:(char *)Str rStr:(char *)rStr {
	int Start = 0;
	int End;
	Start = [self sSearch:Str Str2:"sent id=" Start:0];
	if (Start) {
		Start = [self sSearch:Str Str2:"\">" Start:Start+1];
		End = [self sSearch:Str Str2:"<" Start:Start+1];
		if (Start && End && (Start + 2) < End) {
			Start += 2;
			strncpy(rStr, Str + Start, End - Start);
		}
	}
	start:
	Start = [self sSearch:Str Str2:"<span class=\"rt\">" Start:Start];
	if (Start) {
		Start = [self sSearch:Str Str2:"\">" Start:Start+1];
		End = [self sSearch:Str Str2:"<" Start:Start+1];
		if (Start && End) {
			Start += 2;
			strncat(rStr, Str + Start, End - Start);
		}
	}
	Start = [self sSearch:Str Str2:"</span></span>" Start:Start];
	if (Start) {
		Start += 14;
		End = [self sSearch:Str Str2:"<" Start:Start+1];
		if (Start && End) {
			strncat(rStr, Str + Start, End - Start);
		}
		else {
			End = Start;
		}
	}
	if (!strncmp(Str + End, "</sent>", 7)) {
		return;
	}
	else if ([self sSearch:Str Str2:"<span class=\"ruby\">" Start:End]) {
		goto start;
	}
}

- (void)SetSpan:(char *)Str rStr:(char *)rStr {
	int Start = 0;
	int End;
	Start = [self sSearch:Str Str2:"sent id=" Start:0];
	if (Start) {
		Start = [self sSearch:Str Str2:"\">" Start:Start+1];
		End = [self sSearch:Str Str2:"<" Start:Start+1];
		if (Start && End && (Start + 2) < End) {
			Start += 2;
			strncpy(rStr, Str + Start, End - Start);
		}
	}
	start2:
	Start = [self sSearch:Str Str2:"<span class=" Start:Start];
	if (Start) {
		Start = [self sSearch:Str Str2:"\">" Start:Start+1];
		End = [self sSearch:Str Str2:"<" Start:Start+1];
		if (Start && End && (Start + 2) < End) {
			Start += 2;
			strncat(rStr, Str + Start, End - Start);
		}
	}
	start3:
	Start = [self sSearch:Str Str2:"</span>" Start:Start];
	if (Start) {
		Start += 7;
		End = [self sSearch:Str Str2:"<" Start:Start];
		if (Start && End && (Start < End)) {
			strncat(rStr, Str + Start, End - Start);
		}
		else {
			goto start3;
		}
	}
	if (!strncmp(Str + End, "</sent>", 7)) {
		return;
	}
	else if ([self sSearch:Str Str2:"<span class=" Start:End]) {
		goto start2;
	}
}

- (void)SetBuf:(char *)Str {
	int Ix;
	start3:
	if (strlen(Str) <= 254) {
		strcpy(m_EditData.Data+2, Str);
		[m_EditBuffer Ins:m_EditData.Data];
		memset(m_EditData.Data,0x00,BRLDOC_DAT_SIZE);
		return;
	}
	else {
		Ix = [self IsKugiri:Str];
		if (Ix) {
			strncpy(m_EditData.Data+2, Str, Ix+3);
			[m_EditBuffer Ins:m_EditData.Data];
			memset(m_EditData.Data+2,0x00,BRLDOC_DAT_SIZE-2);
			strcpy(Str, Str + Ix+3);
			goto start3;
		}
		else {
			strncpy(m_EditData.Data+2, Str, 254);
			[m_EditBuffer Ins:m_EditData.Data];
			memset(m_EditData.Data+2,0x00,BRLDOC_DAT_SIZE-2);
			strcpy(Str, Str + 254);
			goto start3;
		}
	}
}
@end
