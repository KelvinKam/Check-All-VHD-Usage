# Check-All-VHD-Usage
# Description
I am not a coder, not writing great code...<br>
This PowerShell script is for checking all VHD located in network drive. It is suitable for you for checking VHD usage especially if you are using FSLogix.

# Background
This script is basically for checking VHDs which stored network drive, you may modify the script yourself for checking local disk VHDs.

# Behavior
  - This script will auto search and mount every VHD/VHDX then save the free space and total quota in csv file.
  - It will use B:\ to mount network drive, you can modify this by changing $DiskLetter.
  - It will auto ignore to mount VHD if that is in use by other programs.
  - **Unexcepted error may occur if press "Ctrl+C" to terminate the script.**

# Requirement
System Requirement<br>
PowerShell 5.1 (Only tested in this version, however older version should work)

Information Requirement<br>
You will required below information to use the script.
  - Network drive location / IP address
  - Network drive credentials

# Expected Result (In CSV Format)
Path,TotalFreeBytesInMB,TotalBytesInMB<br>
S-1-5-21-1501111111-2805555333-123638533-1145_UserA\Profile_UserA.vhd,9554.07,10238.98<br>
S-1-5-21-1502222222-2805555333-123638533-14246_UserB\Profile_UserB.vhd,9872.41,10238.98<br>
S-1-5-21-1503333333-2805555333-123638533-14263_UserC\Profile_UserC.vhd,9744.527,10238.98<br>
S-1-5-21-1504444444-2805555333-123638533-14363_UserD\Profile_UserD.vhd,8770.066,10238.98<br>
