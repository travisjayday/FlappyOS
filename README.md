# FlappyOS
A portable, bootable flappy bird game written in assembly.

Using BIOS interrupts for input and the linear VGA 320x200 16 color mode for output, FlappyOS recreates the popular mobile game Flappy Bird with even more "Retro" graphics than the original! 

# Screenshots

![Color Screenshot](/screenshots/flappyOS_gameplay1.bmp?raw=true "Color Gameplay")


![Black White Screenshot](/screenshots/flappyOS_bw.bmp?raw=true "Black/White")


![Over Screenshot](/screenshots/flappyOS_over.bmp?raw=true "VGA Text over screen")

# Gamemodes
As seen in the screenshots, FlappyOS has two modes: Color and Black/White. These modes can be selected on startup when the bootloader reads the game into memory. 

# Process
On boot, the bootloader reads sectors 1, 2 an 3 into memory (that's right, the game is 3 + 1 sectors, ie 2KiB large!), then prompts the user for a mode, either color, black/white, or exit. Exit reboots the PC. Once the player selects a mode, the game starts. When the player collides, the screen fills with black. After a keypress, the game jumps back to the MBR and re-runs the code in the bootloader.

# Installation
Pre-assembled binary images and iso's of the game are found in the build/ directory. These can either be used in a virtual environment such as VirtualBox or BOCHS. Running `make` in the main directory will assemble the source files and create a floppy.img in the build directory. It will also try to start the BOCHS emulator which should have been installed beforehand. 

<u>`make` has other options too:</u><br>
  - `make usb` assembles all files and attempts to write the image to /dev/sdb <b>This may brick your bootloader depending on your HDD setup!</b><br>
  - `make iso` assembles all files and creates a bootable iso images which can be used in VirtualBox or burned to a disk or USB<br>
  - `make image` only assembles a floppy disk image in the build directory<br>
  
Read the Makefile for more information.

<b>A word of warning: </b> If playing in an emulator, delays and game timings may be too fast or too slow (as explained in <a href="https://stackoverflow.com/questions/45845736/emulated-environments-hardware-clock-ticking-a-lot-faster-than-18-2-times-per?noredirect=1#comment78657194_45845736">this</a> StackOverflow question). If you're using BOCHS, tweak the ips=xxx label in the bochsrc.txt file in the build/ directory or the actual timings of cx:dx in the source file flappy.asm.

# Additional Notes
This has been an educational experience for me. If you have any questions about my code or the game, feel free to raise an issue.
A big <b>Thank You</b> to user flxbe for his asm-space-invaders game and the StackOverflow community for their help & reassurance.  
This has been quite the educational experience!

(Here's a secret: Pressing 'P' in game, pauses the game)
