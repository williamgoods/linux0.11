.code16

.global _startboot,begintext,begindata,beginbss,endtext,enddata,endbss

.text
begintext:
.data
begindata:
.bss
bedinbss:
.text

.equ BOOTSEG,0x07c0
.equ INITSEG,0x9000
.equ SETUPSEG,0x9020
.equ SYSSEG,0x1000

.equ SYSSIZE,0x3000
.equ ENDSYS,SYSSEG+SYSSIZE

.equ BOOTSIZE,4
.equ LEN,24

.equ ROOT_DEV,0x301

.text
ljmp $BOOTSEG,$_startboot

_startboot:
     mov $BOOTSEG,%ax
     mov %ax,%ds
     mov %ax,%es
     #read the cursor location
     #xor %bh,%bh
     #mov $0x03,%ah
     #int $0x10

     #write the string
     #mov $_string,%bp
     #mov $0x1301,%ax
     #mov $0x0004,%bx
     #mov $LEN,%cx
     #int $0x10

     #将0x7c00的bootsect迁移到0x9000
     mov $INITSEG,%ax
     mov %ax,%es
     mov $BOOTSEG,%ax
     mov %ax,%ds
     mov $256,%cx
     sub %di,%di
     sub %si,%si
     rep
     movsw

     ljmp $INITSEG,$go

     go:
       mov %cs,%ax
       mov %ax,%ds
       mov %ax,%es 
       #set stack
       mov %ax,%ss
       #the range of stack is 0x900o:0000 -> 0x9000:ff00 
       mov $0xff00,%sp

       loop_forever:
            jmp loop_forever

        #       AH = 02
        #AL = number of sectors to read (1-128 dec.)
        #CH = track/cylinder number  (0-1023 dec., see below)
        #CL = sector number  (1-17 dec.)
        #DH = head number  (0-15 dec.)
        #DL = drive number (0=A:, 1=2nd floppy, 80h=drive 0, 81h=drive 1)
        #ES:BX = pointer to buffer

        #on return:
        #AH = status  (see INT 13,STATUS)
        #AL = number of sectors read
        #CF = 0 if successful
        #  = 1 if error
     #read the load setup
     loadsetup:
     mov $0x0000,%dx
     mov $0x0002,%cx
     mov $0x0200,%bx
     mov $0x02,%ah
     mov $BOOTSIZE,%al
     int $0x13
     jnc ok_load_setup
     mov $0x0000,%ax
     mov $0x0000,%dx
     int $0x13
     jmp loadsetup

     ok_load_setup:
        #INT 13,8 - Get Current Drive Parameters (XT & newer)

	#AH = 08
	#DL = drive number (0=A:, 1=2nd floppy, 80h=drive 0, 81h=drive 1)

	#on return:
	#AH = status  (see INT 13,STATUS)
	#BL = CMOS drive type
	#     01 - 5¬  360K	     03 - 3«  720K
	#     02 - 5¬  1.2Mb	     04 - 3« 1.44Mb
	#CH = cylinders (0-1023 dec. see below)
	#CL = sectors per track	(see below)
	#DH = number of sides (0 based)
	#DL = number of drives attached
	#ES:DI = pointer to 11 byte Disk Base Table (DBT)
	#CF = 0 if successful
	#   = 1 if error
        #read the currrnt drive paramters
        mov $0x00,%dl
        mov $0x08,%ah
        int $0x13
        #this is to make the high level of cx to 0x00
        mov $0x00,%ch
        mov %cx,%cs:sector
        #the over step of the operation has change th es
        mov $INITSEG,%ax
        mov %ax,%es

        #read the cursor location
        xor %bh,%bh
        mov $0x03,%ah
        int $0x10

        #write the string
        mov $_string,%bp
        mov $0x1301,%ax
        mov $0x0004,%bx
        mov $LEN,%cx
        int $0x10

        #load the system 
        mov $SYSSEG,%ax
        mov %ax,%es
        
        call read_it 
        call kil_motor

        #in this location,I can't understand it
        mov %cs:sector,%bx
        mov $0x0208,%ax
        cmp $15,%bx
        je root_defined
        mov $0x021c,%ax
        mov $18,%bx
        je root_defined
 
    undef_root:
        loop undef_root
 
    root_defined:
        mov %ax,%cs:root_dev
        
        #jmp to the 0x9000
        ljmp $SETUPSEG,$0
   
        #C language to achieve the assembly read_it
        #void  read_it(){
        #    if((es&0xfff) != 0){
        #         while(1);
        #     }
        #    
        #     bx = 0;  //bx is the representation of offset
        # rp_read:
        #     while(es<ENDSEG){
        #         ok_raed1:
        #         ax = sectors - sread; //ax is the sectors which should been read
        #         if((ax*512+bx)>0x10000){
        #              ax = (0x10000 - bx)/512; //0x10000 is to represent the max bytes can be        #                                       //read      
        #          }
        #                  
        #         ok_read2:  
        #         read_trace(ax);  // al is the size of sectors should be read
        #         cx = ax;    //cx is the sectors which have been read at this operating
        #         ax += sread;   //ax is all the sectors which has been read now
        #         
        #         if(ax == SECTORS){
        #               if(head == 1){
        #                 trace ++;
        #                 head = 0; 
        #               }else
        #                 head =1;
        #               }
        #                ax = 0;
        #         }
        #         ok_read3:
        #         sread = ax;
        #         bx += cx*512;
        #         
        #         if(bx == 0x10000){
        #              es += 0x1000;
        #              bx = 0;
        #              jmp rp_read;
        #         }
        #       return;
        #}
        #
        #
        #}

sread: .word 1+SETUPSIZE
head:  .word 0
trace: .word 0
        
        #use assembly
        read_it:
            mov %es,%ax
            test $0xfff,%ax
            jne die
        die:jmp die
            xor %bx,%bx  #set bx -> 0
            
       rp_read:
            mov %es,%ax
            cmp $ENDSYS,%ax
            jb ok_read1
            ret
       ok_read1:
            mov %cs:sector,%ax
            sub sread,%ax
            mov %ax,%cx      #this is to separate the sectors and the bytes
            shl $9,%cx 
            add $bx,%cx      

            jnc ok_read2
            je ok_read2
            xor %ax,%ax  #set ax -> 0
            sub %bx,%ax
            shr $9,%ax

       ok_read2:
            call read_track
            mov %ax,%cx     #cs is the sector which has been read below the operatation read_t                            #race
            add sread,%ax  #ax is the sector which has been read now
            
            cmp sector,%ax
            jne ok_read3
            
            mov $1,%ax
            sub head,%ax
            jne ok_read4 
 
            incw trace
 
       ok_read4:
            mov %ax,head
            xor %ax,%ax

       ok_read3:
           mov %ax,sread
           shl $9,%cx
           add %cx,%bx
           jnc rp_read
            
           mov %es,%ax
           add $0x1000,%ax
           mov %ax,%es
           xor %bx,%bx
           jmp rp_read
  
       read_trace:
           push ax
           push bx
           push cx
           push dx
           mov trace,%dx  #trace
           mov sread,%cx  #the sectors which has been read in the trace now
           inc %cx
         
           mov %dl,%ch
           mov head,%dx
           mov %dl,%dh
           mov $0,%dl
           add %dx,0x0100
           mov $0x02,%ah
           int $0x13
           jc bad_manage
           pop dx
           pop cx
           pop bx
           pop ax

       bad_manage:
           mov $0,%ax
           mov $0,%dx
           int $0x13
           pop dx
           pop cx
           pop bx
           pop ax

       kill_motor:   #close the motor 
           push dx
           mov $0x3f7,%dx
           mov $0,%al
           outsb 
           pop dx
           ret

_string:
    .byte 13,10
    .ascii "Loading system..."
    .byte 13,10,13,10

sector:
    .word 0

.=508

root_dev:
    .word ROOT_DEV

signature:
     .word 0xaa55

.text
endtext:
.data
enddata:
.bss
endbss:

