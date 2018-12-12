.code16

.equ INITSEG,0x9000
.equ SYSSEG,0x1000
.equ SETUPSEG,0x9020

.global _start,begtext,begdata,begbss,endtext,enddata,endbss

.text
begtext:
.data
begdata:
.bss
begbss:

.text

ljmp $SETUPSEG,$setup_start

setup_start:
   
    #first you should set the ds again,although this has set in the bootsect
    #we should set some systems about the disk to use late in the 0x9000
    mov $INITSEG,%ax
    mov %ax,%ds
    #read cursor position and size to the 0x9000:0000
    mov $0x03,%ah
    xor %bh,%bh
    int $0x10
    mov %dx,%ds:0

    #get the memory size
    #INT 15,88 - Extended Memory Size Determination
    #AH = 88h

    #on return:
    #CF = 80h for PC, PCjr
    #	   = 86h for XT and Model 30
    #	   = other machines, set for error, clear for success
    #	AX = number of contiguous 1k blocks of memory starting
    #	     at address 1024k (100000h)
    mov $0x88,%ah
    int $0x15
    mov %ax,%ds:2

    #get the video-card data
    #INT 10,F - Get Video State
    #	AH = 0F

    #	on return:
    #	AH = number of screen columns
    #	AL = mode currently set (see VIDEO MODES)
    #	BH = current display page  
    mov $0x0f,%ah
    int $0x10
    mov %bx,%ds:4 #display page
    mov %ax,%ds:6 #al=video mode,ah=window width

    #check for EGA/VGA and some config paratems
    #INT 10,12 - Video Subsystem Configuration (EGA/VGA)

    #	AH = 12h
    #	BL = 10  return video configuration information

    #	on return:
    #	BH = 0 if color mode in effect
    #	   = 1 if mono mode in effect
    #	BL = 0 if 64k EGA memory
    #	   = 1 if 128k EGA memory
    #	   = 2 if 192k EGA memory
    #	   = 3 if 256k EGA memory
    #	CH = feature bits
    #	CL = switch settings
    mov $0x12,%ah
    mov $0x10,%bl
    int $0x10
    mov %ax,%ds:8
    mov %bx,%ds:10
    mov %cx,%ds:12

    #get hd0 data
    lds %ds:4*0x41,%dx
    mov $0x0080,%bx
    call read_hd
     
    #get the hd1 data
    lds %ds:4*0x46,%dx
    mov $0x0090,%bx
    call read_hd

    #check that there is hd1
    #INT 13,15 - Read DASD Type (XT BIOS from 1/10/86 & newer)

    #	AH = 15h
    #	DL = drive number (0=A:, 1=2nd floppy, 80h=drive 0, 81h=drive 1)


    # 	on return:
    #	AH = 00 drive not present
    #	   = 01 diskette, no change detection present
    #	   = 02 diskette, change detection present
    #	   = 03 fixed disk present
    #	CX:DX = number of fixed disk sectors; if 3 is returned in AH
    #	CF = 0 if successful
    #	   = 1 if error    
    mov $0x15,%ah
    mov $0x81,%dl
    int $0x15
    jc no_disk1
    cmp $3,%ah
    je is_disk1

    no_disk1:
    mov $INITSEG,%ax
    mov %ax,%es
    mov $0x0090,%di
    mov $0x00,%ax
    mov $0x10,%cx
    rep
    stosb

    is_disk1:
       #now we will move the peotected mode
       cli 
       cld
       mov $0,%ax
   do_move:
       mov %ax,%es
       add $0x1000,%ax
       cmp $0x9000,%ax
       jz end_move
       mov %ax,%ds
       xor %di,%di
       xor %si,%si
       mov $0x8000,%cx
       movsw
       jmp do_move

    end_move:
        mov $SETUPSEG,%ax
        mov %ax,%ds
        lgdt gdt_48
        lidt idt_48

     #below wo can enable the A20 which make the accessed address from
     #2^20=1M  --> 2^32=4GB
     

     #set the 8259
     

    #LMSW: Load Machine Status Word设置处理器状态字
    #SMSW: Store Machine Status Word取处理器状态字
    mov %cr0,%eax
    #BTS -- Bit Test and Set (位测试并置位)
    bts $0,%eax
    mov %eax,%cr0
    ljmp $0x0008,$0

    gdt:
        .word 0,0,0,0
  
        #this is code which can read and execute has the privilege and the base 
        #address is 0x000000 and the limit is 0x07fff and the garnularity is 
        #4KB (this present the the offset is 0xffff to 0xffffffff)
        .word 0x7fff
        .word 0x0000
        .word 0x9a00
        .word 0x00c0    

        #the different of the above is data which can read and write
        .word 0x7fff
        .word 0x0000
        .word 0x9200
        .word 0x00c0

    gdt_48:
        .word 0x800  #the limit is 2048,256 GDT entries
        .word 512 + gdt,0x9  #the base = 0x90200+gdt -> this will jmp to the gdt

    idt_48:
   #set a empty table about interrupt table
        .word 0
        .word 0,0
   
    
    #this is used to read the hd0 and hd1
    read_hd:
    mov $0x0000,%ax
    mov %ax,%ds
    #load the address of %dx to the si
    mov %dx,%si
    mov $INITSEG,%ax
    mov %ax,%es
    mov %bx,%di
    #transform about 16 bytes
    mov $0x10,%cx
    rep
    movsb
    ret

.text
endtext:
.data
enddata:
.bss
endbss:

