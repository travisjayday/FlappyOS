# FlappyOS
A portable, bootable flappy bird game written in assembly.

Using BIOS interrupts for input and the linear VGA 320x200 16 color mode for output, FlappyOS recreates the popular mobile game Flappy Bird with even more "Retro" graphics than the original! 

![Color Screenshot](/screenshots/flappyOS_gameplay1.bmp?raw=true "Color Gameplay")

![Black White Screenshot](/screenshots/flappyOS_bw.bmp?raw=true "Black/White")

![Over Screenshot](/screenshots/flappyOS_over.bmp?raw=true "VGA Text over screen")

# Gamemodes
As seen in the screenshots, FlappyOS has two modes: Color and Black/White. These modes can be selected on startup when the bootloader reads the game into memory. 

# Process
On boot, the bootloader reads sectors 1, 2 an 3 into memory (that's right, the game is 3 + 1 sectors, ie 2KiB large!), then prompts the user for a mode, either color, black/white, or exit. Exit reboots the PC. Once the player selects a mode, the game starts. When the player collides, the screen fills with black. After a keypress, the game jumps back to the MBR and re-runs the code in the bootloader.

# Additional Notes
This has been an educational experience for me. If you have any questions about my code or the game, feel free to raise an issue.
A big <b>Thank You</b> to user flxbe for his asm-space-invaders game and the StackOverflow community for their help & reassurance.  
This has been quite the educational experience!

(Here's a secret: Pressing 'P' in game, pauses the game)
