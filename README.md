# Windows-Installation-via-batch

This script is a Windows batch file that prepares a hard disk for Windows deployment. It does so by using the Diskpart tool and a series of commands to perform operations such as cleaning the disk, converting the disk to either MBR or GPT, creating partitions, and formatting the partitions.

The script starts by asking the user to select the disk number that they would like to prepare, and then warns the user that this will erase all data on the selected disk. If the user confirms that this is the correct disk, the script continues by asking the user to choose whether they want to install Windows in a BIOS or GPT environment.

Based on the user's choice, the script either performs the MBR preparation or GPT preparation. In the MBR preparation, the script creates two partitions (primary and extended), formats them as NTFS, and assigns drive letters to them. In the GPT preparation, the script creates three partitions (EFI, MSR, and primary), formats them as either FAT32 or NTFS, and assigns drive letters to them.

The script then runs the Diskpart tool with the specified commands to perform the preparation. Finally, the script displays a message indicating that the disk is now prepared for installing Windows and provides the assigned drive letters for the boot and installation partitions.
