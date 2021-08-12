# Add Device to Jamf
This script can receive input to add a device to a Jamf PreStage Enrollment scope as well as Jamf Inventory Preload.

This is used in our environment with a web form and a Jenkins job, but this could be connected to other automations with minimal work. 

## How We Use This

Using the form, an employee submits the Serial Number, Asset Tag, Device Use (Faculty or Labs) and Device Type (Mac, iPad, iPod, iPhone, or Apple TV) which emails that information to Jenkins. We also make an AppleScript utility available in Self Service for our Help Desk employees to submit information directly from their Mac instead of the web form. 

The script takes the inputs from the form and passes them through, matching the Device Use input to the PreStage ID on the Jamf server and the Device Type into a value Jamf expects for Inventory Preload. As an example, a new Faculty Mac will be assigned to PreStage ID 2 (as defined in the script for our environment), and identified to Jamf as “Computer”, which is the required value for Inventory Preload to properly identify the Jamf object based on the serial number. 

This script uses the Jamf Pro API (/uapi) which uses a token-based authentication scheme. 

This directly builds on [this script by talkingmoose](https://gist.github.com/talkingmoose/327427d23b422000f9d17183f8ef1d22).