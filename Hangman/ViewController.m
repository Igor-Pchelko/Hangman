//
//  ViewController.m
//  Hangman
//
//  Created by Igor Pchelko on 10/09/2014.
//  Copyright (c) 2014 Igor Pchelko. All rights reserved.
//

#import "AFNetworking.h"
#import "ViewController.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *hangmanImage;
@property (weak, nonatomic) IBOutlet UILabel *wordLabel;
@property (weak, nonatomic) IBOutlet UITextView *userLetterText;
@property (weak, nonatomic) IBOutlet UILabel *gameResultLabel;
@property (weak, nonatomic) IBOutlet UIButton *theNewGameButton;

@property (strong, nonatomic) NSString *word;
@property (strong, nonatomic) NSString *userLetters;
@property (nonatomic) int mistakesCount;
@property (nonatomic) int foundLetters;

@property (nonatomic) bool wordIsReady;

@end

@implementation ViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self requestNewWord];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)requestNewWord
{
    self.wordIsReady = NO;
    self.gameResultLabel.text = @"Getting word...";
    self.theNewGameButton.hidden = YES;
    
    static NSString * const kBaseURLString = @"http://www.thefreedictionary.com/_/WoD/hangmanjs.aspx?f=2&shr=1lang=enr=%d";

    NSString *string = [NSString stringWithFormat:kBaseURLString, arc4random()];
    NSURL *url = [NSURL URLWithString:string];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSData * data = (NSData *)responseObject;
        NSString *html = [NSString stringWithUTF8String:[data bytes]];
        
        //NSLog(@"html: %@", html);
        
        // Parse html, try to find that random word
        static NSString * const kWordPrefix = @"tfd_hm_word='";

        NSScanner *scanner = [NSScanner scannerWithString:html];
        NSString *dummy;
        [scanner scanUpToString:kWordPrefix intoString:&dummy];
        [scanner setScanLocation:scanner.scanLocation + kWordPrefix.length];
        
        NSString *word = nil;
        [scanner scanUpToString:@"'" intoString:&word];
        
        if (word != nil && word.length > 0)
        {
            self.word = [word uppercaseString];
            
            NSLog(@"self.word: %@", self.word);
            [self newGame];
            [self.userLetterText becomeFirstResponder];
        }
        else
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error in parsing html"
                                                            message:@""
                                                           delegate:nil
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil];
            
            [alertView show];

            self.gameResultLabel.text = @"Failed to get word";
            self.theNewGameButton.hidden = NO;
        }
     
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error Retrieving word"
                                                            message:[error localizedDescription]
                                                           delegate:nil
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil];
        [alertView show];

        self.gameResultLabel.text = @"Failed to get word";
        self.theNewGameButton.hidden = NO;
    }];
    
    // 5
    [operation start];
}

- (void)newGame
{
    self.mistakesCount = 0;
    self.foundLetters = 0;
    self.userLetters = @"";
    
    NSUInteger len = [self.word length];
    unichar labelBuf[len*2+1];

    // setup word label
    int j=0;
    for (int i=0; i<len; i++)
    {
        labelBuf[j++] = '_';
        labelBuf[j++] = ' ';
    }
    
    self.userLetterText.text = @"";
    self.wordLabel.text = [NSString stringWithCharacters:labelBuf length:len*2];
    self.hangmanImage.image = [UIImage imageNamed:@"hangman-1"];
    
    self.gameResultLabel.hidden = YES;
    self.theNewGameButton.hidden = YES;
}

- (NSString*)formatUserLetters
{
    NSUInteger len = [self.userLetters length];
    unichar srcBuf[len+1];
    unichar dstBuf[len*2+1];
    
    [self.userLetters getCharacters:srcBuf range:NSMakeRange(0, len)];

    int j = 0;
    for (int i=0; i<len; i++)
    {
        dstBuf[j] = srcBuf[i];
        dstBuf[j+1] = ' ';
        j+=2;
    }
    
    return [NSString stringWithCharacters:dstBuf length:len*2];
}

- (void)newCharDidEnter:(unichar)ch
{
    // find char in word
    NSUInteger len = [self.word length];
    unichar buf[len+1];
    unichar labelBuf[len*2+1];
    
    [self.word getCharacters:buf range:NSMakeRange(0, len)];
    [self.wordLabel.text getCharacters:labelBuf range:NSMakeRange(0, len*2)];
    
    bool found = NO;
    
    for (int i=0; i<len; i++)
    {
        if (buf[i] == ch)
        {
            found = YES;
            labelBuf[i*2] = ch;
            self.foundLetters++;
        }
    }

    if (found)
    {
        self.wordLabel.text = [NSString stringWithCharacters:labelBuf length:len*2];
        
        if (self.foundLetters == len)
        {
            self.gameResultLabel.text = @"You win!";
            [self.gameResultLabel setHidden:NO];
            [self.theNewGameButton setHidden:NO];
            [self.userLetterText endEditing:YES];
        }
    }
    else
    {
        self.mistakesCount++;
        
        self.hangmanImage.image = [UIImage imageNamed:[NSString stringWithFormat:@"hangman-%d", 1 + self.mistakesCount]];

        if (self.mistakesCount >= 10)
        {
            // Lost
            self.hangmanImage.image = [UIImage imageNamed:[NSString stringWithFormat:@"hangman-%d", 1 + self.mistakesCount]];
            self.gameResultLabel.text = @"You lost!";
            [self.gameResultLabel setHidden:NO];
            [self.theNewGameButton setHidden:NO];
        }
    }
}


- (IBAction)newGameDidPress:(id)sender
{
    [self requestNewWord];
}

#pragma mark - UITextViewDelegate protocol implementation

- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
    return NO;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if (text.length > 0 && self.mistakesCount < 10)
    {
        unichar ch = [[text uppercaseString] characterAtIndex:0];
        NSCharacterSet *letters = [NSCharacterSet letterCharacterSet];
        
        if ([letters characterIsMember:ch])
        {
            // The first character is a letter in some alphabet
            NSString *chStr = [NSString stringWithCharacters:&ch length:1];
            
            if ([self.userLetters rangeOfString:chStr].location == NSNotFound)
            {
                // Add new char to letters
                self.userLetters = [self.userLetters stringByAppendingString:chStr];
                self.userLetterText.text = [self formatUserLetters];
                [self newCharDidEnter:ch];
            }
        }
    }
    
    return NO;
}

@end
