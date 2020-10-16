# Check-All-VHD-Usage
# Description
I am not a coder, not writing great code...
This PowerShell script is for checking all VHD located in network drive. It is suitable for you for checking VHD usage especially for FSLogix.

# Background
This script is basically for checking VHDs which stored network drive, you may modify the script yourself for checking local disk VHDs.

# Behavior
This script will auto search and mount every VHDs than save the free space and total quota in csv file. During script initial, it will use B:\ as temporary drive.
Unexcepted error may be occurred if press "Ctrl+C" to terminate the script.

# Requirement
System Requirement
PowerShell 5.1 (Only tested in this version, however older version should work)

Information Requirement
You will required below information to use the script.
  - Network drive location / IP address
  - Network drive credentials
