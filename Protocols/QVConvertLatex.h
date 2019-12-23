@protocol QVConvertLatex
- (NSString *)convertToLatex:(id)quartett withContext:(NSMutableDictionary *)context;
@end

static NSString *latexEscape(NSString *string)
{
	NSMutableString *escaped = [NSMutableString stringWithString:string];
	
	[escaped replaceOccurrencesOfString:@"\\" withString:@"\\textbackslash{}"
								options:NSLiteralSearch range:NSMakeRange(0, [escaped length])];
	[escaped replaceOccurrencesOfString:@"{" withString:@"\\{"
								options:NSLiteralSearch range:NSMakeRange(0, [escaped length])];
	[escaped replaceOccurrencesOfString:@"}" withString:@"\\}"
								options:NSLiteralSearch range:NSMakeRange(0, [escaped length])];
	[escaped replaceOccurrencesOfString:@"\"" withString:@"''"
								options:NSLiteralSearch range:NSMakeRange(0, [escaped length])];
	[escaped replaceOccurrencesOfString:@"%" withString:@"\\%"
								options:NSLiteralSearch range:NSMakeRange(0, [escaped length])];
	[escaped replaceOccurrencesOfString:@"#" withString:@"\\#"
								options:NSLiteralSearch range:NSMakeRange(0, [escaped length])];
	[escaped replaceOccurrencesOfString:@"$" withString:@"\\$"
								options:NSLiteralSearch range:NSMakeRange(0, [escaped length])];
	[escaped replaceOccurrencesOfString:@"&" withString:@"\\&"
								options:NSLiteralSearch range:NSMakeRange(0, [escaped length])];
	[escaped replaceOccurrencesOfString:@"_" withString:@"\\_"
								options:NSLiteralSearch range:NSMakeRange(0, [escaped length])];
	[escaped replaceOccurrencesOfString:@"^" withString:@"\\textasciicircum{}"
								options:NSLiteralSearch range:NSMakeRange(0, [escaped length])];
	[escaped replaceOccurrencesOfString:@"~" withString:@"\\textasciitilde{}"
								options:NSLiteralSearch range:NSMakeRange(0, [escaped length])];
	
	return escaped;
}
