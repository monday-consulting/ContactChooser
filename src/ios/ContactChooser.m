#import "ContactChooser.h"
#import <Cordova/CDVAvailability.h>

@implementation ContactChooser
@synthesize callbackID;

- (void) chooseContact:(CDVInvokedUrlCommand*)command{
    self.callbackID = command.callbackId;
    
    ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
    picker.peoplePickerDelegate = self;
    [self.viewController presentViewController:picker animated:YES completion:nil];
}

- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker
                         didSelectPerson:(ABRecordRef)person
                                property:(ABPropertyID)property
                              identifier:(ABMultiValueIdentifier)identifier
{
    [self peoplePickerNavigationController:peoplePicker shouldContinueAfterSelectingPerson:person
                                  property:property identifier:identifier];
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController*)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person
                                property:(ABPropertyID)property
                              identifier:(ABMultiValueIdentifier)identifier
{
    NSString *email = @"";
    ABMultiValueRef multiEmails = ABRecordCopyValue(person, kABPersonEmailProperty);
    if (kABPersonEmailProperty == property)
    {
        // user selected an email property -> retrieve selected email
        int index = ABMultiValueGetIndexForIdentifier(multiEmails, identifier);
        email = (__bridge NSString *)ABMultiValueCopyValueAtIndex(multiEmails, index);
    }
    else if (ABMultiValueGetCount(multiEmails) > 0)
    {
        // user did not select an email property -> default to the contact's first email (if available)
        email = (__bridge NSString *)ABMultiValueCopyValueAtIndex(multiEmails, 0);
    }

    // retrieve the contact's composite name
    NSString *displayName = (__bridge NSString *)ABRecordCopyCompositeName(person);

    NSString* phoneNumber = @"";
    ABMultiValueRef multiPhones = ABRecordCopyValue(person, kABPersonPhoneProperty);
    if (kABPersonPhoneProperty == property)
    {
        // user selected a phone property -> retrieve selected phone number
        int index = ABMultiValueGetIndexForIdentifier(multiPhones, identifier);
        phoneNumber = (__bridge NSString *)ABMultiValueCopyValueAtIndex(multiPhones, index);
    }
    else if (ABMultiValueGetCount(multiPhones) > 0)
    {
        // user did not select a phone property -> default to the contact's first number (if available)
        phoneNumber = (__bridge NSString *)ABMultiValueCopyValueAtIndex(multiPhones, 0);
    }

    // stick everything together
    NSMutableDictionary* contact = [NSMutableDictionary dictionaryWithCapacity:3];
    [contact setObject:email forKey: @"email"];
    [contact setObject:displayName forKey: @"displayName"];
    [contact setObject:phoneNumber forKey: @"phoneNumber"];

    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:contact];
    [self.commandDelegate sendPluginResult:result callbackId:self.callbackID];
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
    return NO;
}

- (BOOL) personViewController:(ABPersonViewController*)personView shouldPerformDefaultActionForPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifierForValue
{
    return YES;
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                messageAsString:@"People picker abort"];
    [self.commandDelegate sendPluginResult:result callbackId:self.callbackID];
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
}

@end
