
@interface QSCommandBuilder : QSInterfaceController {
    IBOutlet NSCell * iFrame;
	QSCommand *representedCommand;
}

- (QSCommand *) representedCommand;
- (void) setRepresentedCommand:(QSCommand *)aRepresentedCommand;

- (IBAction) cancel:(id)sender;
- (IBAction) save:(id)sender;
@end
