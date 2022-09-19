;					TETRIS
;			(C) Rickard Gunee 1998
;
;	This is shareware, use it at your own risk.
;
;	You will find more info about the project
;	and more info on video signals here:
;	http://www.rickard.gunee.com/projects
;
;	Outputs composite NTSC video signal using
;	only two resistors!


		list	p=16F84,r=hex

	__config 0x3FFA


w		equ	0
f		equ	1
pcl		equ	0x02

status		equ	0x03
porta		equ	0x05
portb		equ	0x06
indf		equ	0x00
fsr		equ	0x04
eedata		equ	0x08
eeadr		equ	0x09
eecon1		equ	0x08

rd		equ	0
rp0		equ	5

startspeed	equ	0x18
movespeed	equ	0x06

up1b		equ	3
down1b		equ	2
left1b		equ	5
right1b		equ	4
fire1b		equ	1
up2b		equ	7
down2b		equ	6
left2b		equ	2
right2b		equ	3
fire2b		equ	1
up1p		equ	portb
down1p		equ	portb
left1p		equ	portb
right1p		equ	portb
fire1p		equ	portb
up2p		equ	portb
down2p		equ	portb
left2p		equ	porta
right2p		equ	porta
fire2p		equ	porta

counter0	equ	0x0C
counter1	equ	0x0D
counter2	equ	0x0E
counter3	equ	0x0F
nextblocktyp	equ	0x10
blockx		equ	0x11
blocky		equ	0x12
blocktyp	equ	0x13
line		equ	0x14
x		equ	0x15
y		equ	0x16
delaycnt	equ	0x17
angle		equ	0x18
blockstuff	equ	0x19
fallcnt		equ	0x1A
points		equ	0x1B
random		equ	0x1E	
stuff		equ	0x1F
m_freq		equ	0x20
m_cnt		equ	0x21
m_songcnt	equ	0x22
	
buffer		equ	0x24
currbl		equ	0x44
x0		equ	0x4C
y0		equ	0x4D
movecnt		equ	0x4E
remline		equ	0x4F
hsfall		equ	0
rotate		equ	1
goleft		equ	2
goright		equ	3
drop		equ	4
rotat		equ	5
gameover	equ	5

delay		MACRO
		LOCAL	label
		movwf	delaycnt
label		decfsz	delaycnt,f
		goto label
		ENDM

dnop		MACRO
		LOCAL	label
label		goto	label+1
		ENDM

		org 0x000
		goto inittetris

;------------ This table contains the 3 note lengthes for the 5 speeds --------

getlength	addwf	pcl,f
		retlw	0x0B
		retlw	0x16
		retlw	0x1D
		retlw	0x09
		retlw	0x12
		retlw	0x19
		retlw	0x07
		retlw	0x0D
		retlw	0x11
		retlw	0x04
		retlw	0x08
		retlw	0x0C
		retlw	0x02
		retlw	0x04
		retlw	0x06

;------------------------ set bit in the gamefield ----------------------------

setbit		call	getbit		;get bitbyte and bitmask	20 cycles
		iorwf	indf,f 		;set bit
		return

;----------------------- clear bit in the gamefield ---------------------------

clrbit		call	getbit		;get bitbyte and bitmask	21 cycles
		xorlw	0xff		;invert bitmask
		andwf	indf,f		;clear bit
		return

;-------------------- point at byte, and return bitmask -----------------------

getbit		movlw	buffer 		;15 cycles
		btfsc	x,3
		movlw	buffer+1
		clrc
		rlf	y,f
		addwf	y,w
		movwf	fsr			;fsr = 2*y + x<<3 + buffer
		movfw	x
		andlw	7			;w = x&7
bitmask		addwf	pcl,f
		retlw	0x01
		retlw	0x02
		retlw	0x04
		retlw	0x08
		retlw	0x10
		retlw	0x20
		retlw	0x40
		retlw	0x80

;------------------------ blocks in compressed format -------------------------

blocks		andlw	0xF
		addwf	pcl,f
		retlw	0x50
		retlw	0x44
		retlw	0xD0
		retlw	0x0C
		retlw	0xD0
		retlw	0x0C
		retlw	0xD0
		retlw	0x3C
		retlw	0xD0
		retlw	0xCC
		retlw	0xF4
		retlw	0xC0
		retlw	0x5C
		retlw	0xC0
		retlw	0x00
		retlw	0x6C

;---------------- convert from compressed format to uncompressed --------------

convert		andlw	3
		addwf	pcl,f
		retlw	0
		retlw	1
		retlw	2
		retlw	-1

;------------------------- generate numbers for points ------------------------

chars		movwf	delaycnt	;13 cycles
		clrc
		rlf	delaycnt,f
		rlf	delaycnt,f
		rlf	delaycnt,f
		movfw	delaycnt
		addwf	line,w
		addwf	pcl,f
;number  0 
		retlw 0x1C
		retlw 0x36
		retlw 0x63
		retlw 0x6B
		retlw 0x63
		retlw 0x36
		retlw 0x1C
		retlw 0x0
;number  1 
		retlw 0x18
		retlw 0x1C
		retlw 0x18
		retlw 0x18
		retlw 0x18
		retlw 0x18
		retlw 0x7E
		retlw 0x0
;number  2 
		retlw 0x3E
		retlw 0x63
		retlw 0x60
		retlw 0x38
		retlw 0xC
		retlw 0x66
		retlw 0x7F
		retlw 0x0
;number  3 
		retlw 0x3E
		retlw 0x63
		retlw 0x60
		retlw 0x3C
		retlw 0x60
		retlw 0x63
		retlw 0x3E
		retlw 0x0
;number  4 
		retlw 0x38
		retlw 0x3C
		retlw 0x36
		retlw 0x33
		retlw 0x7F
		retlw 0x30
		retlw 0x78
		retlw 0x0
;number  5 
		retlw 0x7F
		retlw 0x3
		retlw 0x3
		retlw 0x3F
		retlw 0x60
		retlw 0x63
		retlw 0x3E
		retlw 0x0
;number  6 
		retlw 0x1C
		retlw 0x6
		retlw 0x3
		retlw 0x3F
		retlw 0x63
		retlw 0x63
		retlw 0x3E
		retlw 0x0
;number  7 
		retlw 0x7F
		retlw 0x63
		retlw 0x30
		retlw 0x18
		retlw 0xC
		retlw 0xC
		retlw 0xC
		retlw 0x0
;number  8 
		retlw 0x3E
		retlw 0x63
		retlw 0x63
		retlw 0x3E
		retlw 0x63
		retlw 0x63
		retlw 0x3E
		retlw 0x0
;number  9 
		retlw 0x3E
		retlw 0x63
		retlw 0x63
		retlw 0x7E
		retlw 0x60
		retlw 0x30
		retlw 0x1E
		retlw 0x0

;-------------------------- vertical syncing stuff ----------------------------

shortsync	movwf	counter1
shortsync_l0	bcf	porta,0		;2us sync
		bcf	portb,0
		dnop
		movlw	0x1D - 5	;30us black
		movwf	counter2
		nop
		bsf	porta,0
shortsync_l1	decfsz	counter2,f
		goto	shortsync_l1
		call	sound
		decfsz	counter1,f
		goto	shortsync_l0
		retlw	5

vertsync	movlw	5
		btfss	stuff,7
		movlw	6
		call	shortsync

		btfss	stuff,7
		goto	opage
		bcf	stuff,7
opager

longsync	movwf	counter1
longsync_l0	movlw	0x1D - 5
		movwf	counter2
		bcf	porta,0		;30 us sync
		bcf	portb,0	
longsync_l1	decfsz	counter2,f
		goto	longsync_l1
		nop			;2us black
		call	sound
		bsf	portb,0
		nop
		decfsz	counter1,f
		goto	longsync_l0

		movlw	5
		btfss	stuff,7
		movlw	4
		call	shortsync
		return

opage		bsf	stuff,7	
		goto	opager

;----------------- routines for displaying whole empty lines ------------------

emptylines	movwf	counter1
		dnop
		nop
ell		bcf	porta,0
		dnop
ell2		nop
		movlw	2
		delay
		movlw	10
		bsf	porta,0
		delay
		call	sound
		movlw	0x20
		delay
		call	sound
		nop
		decfsz	counter1,f
		goto	ell

		movlw	3
		bcf	porta,0
		delay
		nop
		movlw	0x10
		bsf	porta,0
		delay
		call	sound
		movlw	0x1D
		delay
		dnop
		call	sound
		return

;-- routine for testing if it is possible to place the block on position x,y --

test		movlw	4			;131  cycles
		movwf	counter2		;hitcounter = 4
		movwf	counter0		;test 4 bits
		movlw	currbl			;point at current block
		movwf	fsr			;with fsr
testl		movfw	blockx
		addwf	indf,w
		incf	fsr,f
		movwf	x			;x = x0 + blockdiffx
		movfw	blocky
		addwf	indf,w
		incf	fsr,f
		movwf	y			;y = y0 + blockdiffy
		movfw	fsr
		movwf	counter1		;save fsr
		call	getbit			;get bit
		andwf	indf,w			;test bit
		skpnz
		decf	counter0,f
		movfw	counter1		;restore fsr
		movwf	fsr
		decfsz	counter2,f
		goto	testl
		movf	counter0,f		;set Z if ok
		return

;################### HERE STARTS THE MAIN THREAD OF TETRIS ####################

tetrismain	call	vertsync		;do vertical retrace

		btfsc	stuff,gameover
		goto	nogame

		call	createnext		;create the preview image		(line 0)
		call	remblock		;hide the preview image			(line 1)
		call	createcurrent		;create the current image		(line 2)
		call	remblock		;hide the current image			(line 3)

;----------------------------- make block fall -------------------------------		

		call	hsync			;horizontal sync			(line 4)
		btfsc	blockstuff,hsfall	;check for high speed fall (drop)
		goto	fall
		decfsz	fallcnt,f			;decrease fallcounter
		goto	nofall			;if not zero, then dont fall
fall
		movfw	points			;calculate speed from the most
		sublw	0xa			;significant digit of the score
		movwf	fallcnt
		rlf	fallcnt,f
		rlf	fallcnt,f
		
		incf	blocky,f			;move block down

		call	test			;check if it was ok
		skpnz
		goto	fallok			;if ok, skip the newblock below
		movlw	0x0B
		delay

		decf	blocky,f
		call	showblock		;make the old block visible			(line 5)
		call	hsync			;horizontal sync			(line 6)
newblock	clrf	blockstuff
		movlw	0x9
		movwf	blockx			;blockx = 9
		movlw	0x1
		movwf	blocky			;blocky = 1
		movfw	nextblocktyp
		movwf	blocktyp		;blocktyp = nexttyp
		movfw	random
		movwf	nextblocktyp		;nexttyp = random
		clrf	angle			;angle = 0
		call	incpoints		;add one point

		bcf	blockstuff,hsfall
		movfw	y0
		sublw	1
		skpnz				;if y = 1 then
		bsf	stuff,gameover		;game over

nofallret	

;----------------------------- joystick motion --------------------------------

		btfss	left1p,left1b		;check left
		bsf	blockstuff,goleft
		btfss	right1p,right1b		;check right
		bsf	blockstuff,goright
		btfss	fire1p,fire1b		;check fire (rotate)
		bsf	blockstuff,rotate
		btfss	down1p,down1b		;check down (drop)
		bsf	blockstuff,drop

		btfss	stuff,1			;rotate last time ?
		goto	norotate		;yes, wait for release
		btfsc	blockstuff,rotate	;check rotate
		bsf	blockstuff,rotat	;if rotate start rotate
		btfsc	blockstuff,rotate	;check rotate
		bcf	stuff,1			;if rotation then remember it
		nop
norotater	bcf	blockstuff,rotate	;clear rotation indicator


		btfss	stuff,2			;down last time ?
		goto	nofallu			;yes, wait for release
		btfsc	blockstuff,drop		;check down
		bsf	blockstuff,hsfall	;if down start fall
		btfsc	blockstuff,drop		;check down
		bcf	stuff,2			;if down then remember it
		nop
nofallur	bcf	blockstuff,drop		;and clear down indicator

		movlw	0x23			;wait 33us for line to end
		delay
		nop

;--------------------------- handle rotation ----------------------------------

		btfss	blockstuff,rotat	;rotate ?
		goto	norot			;no, skip all rotation stuff
		incf	angle,f			;try to increase angle
		call	createcurrent		;make block image for this angle	(line 7)
		call	hsync			
		call	test			;ok ?
		skpz				
		decf	angle,f			;no undo angle change
		movlw	0xC			
		delay
		incf	random,f
		movlw	7
		andwf	random,f
		dnop
		call	createcurrent		;create block 				(line 8)
norotr		call	hsync			;					(line 9)
		bcf	blockstuff,rotat	;rotate one step only
		bcf	blockstuff,rotate

;---------------------- move block, left and right ----------------------------

		btfsc	blockstuff,goleft
		decf	blockx,f
		btfsc	blockstuff,goright
		incf	blockx,f
		movlw	0x38
		delay

		call	createcurrent		;create current block image	(line 10)
		call	hsync			;horizontal sync		(line 11)
		call	test
		skpnz
		goto	moveok			;if ok skip restore
		dnop
		dnop
		dnop
nomove		btfsc	blockstuff,goleft
		incf	blockx,f
		btfsc	blockstuff,goright
		decf	blockx,f
		movlw	0x2e
		dnop
		dnop
moveokret	movlw	0x8
		delay


		bcf	blockstuff,goleft	;clear move left indicator
		bcf	blockstuff,goright	;clear move right indicator

;---------------- search for filled line in the 8 first lines ---------------

		bcf	porta,0		;start sync				(line 12)
		dnop
		dnop
		movlw	8		;check the first 8 lines this scanline
		movwf	counter0
		movlw	buffer		;set up pointer to screen buffer
		movwf	fsr		
		clrf	line
		dnop
		bsf	porta,0		;end sync

		movlw	6		;wait for 6 uS
		delay
		clrf	remline

remfilledl11	movfw	indf		;get first byte of line
		incf	fsr,f		;move pointer to next byte
		sublw	0xF0		;is it "filled" ?
		skpz
		goto	nofilled11	;nope, we're outa here
		movfw	indf		;get second byte of line
		incf	fsr,f		;move pointer to next byte (next line)
		sublw	0xFF		;is it "filled" ?
		skpz
		goto	nofilled21	;nope, we're outa here
		movfw	line
		movwf	remline		;save line nr
		nop
nofilledr1	incf	line,f		;count up line nr
		decfsz	counter0,f
		goto	remfilledl11

;------------ search for filled line in the following 7 lines -------------

		bcf	porta,0		;start sync				(line 13)
		movlw	3
		delay
		movlw	7		;check next 7 lines this scanline
		bsf	porta,0		;end sync
		movwf	counter0

remfilledl12	movfw	indf		;get first byte of line
		incf	fsr,f		;move pointer to next byte
		sublw	0xF0		;is it "filled" ?
		skpz
		goto	nofilled12	;nope, we're outa here
		movfw	indf		;get second byte of line
		incf	fsr,f		;move pointer to next byte (next line)
		sublw	0xFF		;is it "filled" ?
		skpz
		goto	nofilled22	;nope, we're outa here
		movfw	line
		movwf	remline		;save line nr
		nop
nofilledr2	incf	line,f		;count up line nr
		decfsz	counter0,f
		goto	remfilledl12

		movlw	0x0B		;wait for 12 uS
		delay

; ---------- if one line is going to be removed, add lots of points -----------

		call	hsync			;		(line 14)
		movf	remline,f
		skpnz
		goto	noaddpoints

		call	incpoints
		call	incpoints
		call	incpoints
		call	incpoints
		call	incpoints
		call	incpoints
		call	incpoints

noaddpointsr	

; --------------- remove line part 1: if neccessary, remove 15 blocks ---------

		bcf	porta,0		;start sync				(line 15)
		movlw	0x10		;remove all crap at top of screen
		movwf	buffer
		movlw	0x80			
		movwf	buffer + 1
		dnop
		movfw	remline
		addwf	remline,w
		movwf	counter0	;half lines to be removed = 2*remline
		addlw	buffer + 1	;start pointer = 2*remline + buffer base + 1
		movwf	fsr
		bsf	porta,0		;end sync

		movlw	0xF
		subwf	counter0,w
		movwf	counter2
		movwf	counter3
		btfsc	counter2,7	;do we only have to move less than 15 blocks ?
		goto	remshort	;yes, skip this part

		movlw	0xF		;else remove 15 lines first
		movwf	counter0

remfilledl21	decf	fsr,f		;move blocks two steps in buffer
		decf	fsr,f
		movfw	indf		;get data at fsr - 2
		incf	fsr,f		;move back again
		incf	fsr,f
		movwf	indf		;put it at fsr
		decf	fsr,f		;point to next block to move
		decfsz	counter0,f
		goto	remfilledl21

		movlw	0x7		;wait 7us for line to end
		delay

; --------------- remove line part 2: remove the other blocks -------------
		
remshortr:	bcf	porta,0		;start sync				(line 16)
		movlw	3
		delay
		nop
		bsf	porta,0		;end sync

		btfsc	counter3,7	;if lines to draw is less than zero
		goto	noremfilled	;then don't draw any lines

remfilledl31	decf	fsr,f		;move blocks two steps in buffer (uses counter1 * 10)
		decf	fsr,f
		movfw	indf		;get data at fsr - 2
		incf	fsr,f
		incf	fsr,f
		movwf	indf		;put it at fsr
		decf	fsr,f		;fsr++ 
		decfsz	counter2,f
		goto	remfilledl31

		movfw	counter3	;calc wait time
		sublw	0xF + 2
		movwf	counter1

remfilledl32	movlw	2		;wait for ((15+2)-counter3)*10 cycles
		delay
		decfsz	counter1,f
		goto	remfilledl32

		dnop
		dnop
		dnop
noremfilledr	

;-------------------------- some block image management -----------------------

		call	createcurrent						;(line 17)
		call	showblock						;(line 18)
		call	createnext						;(line 19)
		call	showblock						;(line 20)

;---------------------- start drawing the graphics on screen ------------------

nogamer		movlw	0x10 			;empty lines at top of screen
		movwf	counter1
		bcf	porta,0
		call	ell2
		movlw	0x0
		tris	portb
		clrf 	portb
		movlw	buffer			;set up pointer to buffer
		movwf	fsr
		movlw	0x10			;16 blocklines (each 11+2 lines)
		movwf	counter2
tml0		movlw	0x9			;9 lines for each block
		movwf	counter3
tml1		bcf	porta,0			;start sync
		movlw	3			;keep low for 4us
		delay	
		nop
		bsf	porta,0

		nop				;colorburst + black  (15.67 us)
		movlw	0x0F - 5 
		delay
		call	sound

		movfw	indf			;get left byte of gfx
		movwf	portb			;start showing first bit
		movlw	7			;set up counter for next 7 bits
		movwf	counter0
		incf	fsr,f			;point at right gfx byte
db0		bcf	portb,0			;one black vertical line between the blocks
		rrf	portb,f			;show next bit
		decfsz	counter0,f		;keep on looping, showing all bits
		goto	db0
		movfw	indf			;get right byte of gfx
		bcf	portb,0			;one black vertical line between the blocks
		movwf	portb			;start showing first bit
		movlw	7			;set up counter for next 7 bits
		movwf	counter0
		decf	fsr,f			;point at left gfxbyte again
db1		bcf	portb,0			;one black vertical line between the blocks
		rrf	portb,f			;show next bit
		decfsz	counter0,f		;keep on looping, showing all bits
		goto	db1
		movlw	0xF - 5
		bcf	portb,0			;set level to black
		delay				;for 16us
		call	sound
		nop
		movlw	2			;prepare for 1 emptyline
		movwf	counter1
		decfsz	counter3,f
		goto	tml1			;do all 9 lines
		bcf	porta,0
		call	ell2			;do 2 emptylines
		dnop
		incf	fsr,f			;point at next line (each line is 2 bytes)
		incf	fsr,f
		decfsz	counter2,f		;do all 16 blocklines
		goto	tml0

;------------------------------- display score --------------------------------

		clrf	line
		call	hsync

		movlw	0x39
		delay
		nop
		movlw	8
		movwf	counter2
shpl		call	hsync
		movlw	0x18
		delay
		call	showp
		movlw	4
		delay
		call	hsync
		movlw	0x18
		delay
		call	showp
		movlw	2
		delay
		dnop
		incf	line,f
		decfsz	counter2,f
		goto	shpl

;--------------- some empty lines, and also some random stuff -----------------

		movlw	0x1C   		;empty lines at bottom of screen
		movwf	counter1
		call	ell

		call	music

		movlw	1
		btfsc	stuff,gameover
		movwf	m_freq

		movlw	0xFE
		tris	portb

		incf	random,f
		movlw	7
		andwf	random,f

		movf	movecnt,f
		skpz
		decf	movecnt,f		
		goto	tetrismain		;next frame

;################ THIS IS THE END OF THE MAIN THREAD OF TETRIS ################


;--------------------------- create next block stuff --------------------------

createnext	bcf	porta,0			;start sync
		movfw	blocktyp
		movwf	counter3		;save current block kind
		movfw	nextblocktyp
		movwf	blocktyp		;set the next block kind
		movfw	angle
		movwf	delaycnt
		clrf	angle
		movlw	1			;set x and ypos, they
		movwf	x0			;are not used here,
		movlw	2			;but we will need them later
		movwf	y0
		bsf	porta,0			;end sync
		call	makeblock		;create block
		movfw	counter3
		movwf	blocktyp
		movfw	delaycnt
		movwf	angle
		return

;------------------ create current block stuff scan line ---------------------

createcurrent	bcf	porta,0			;start sync
		movlw	0x2
		delay
		movfw	blockx			;x0 anf y0 are not
		movwf	x0			;used here, but we will use
		movfw	blocky			;them later
		movwf	y0
		bsf	porta,0			;end sync
		call	makeblock
		return

;------------------------ remove big block scan line -------------------------

remblock	bcf	porta,0			;start sync
		movlw	3
		delay
		nop
		bsf	porta,0			;end sync
		movlw	4
		movwf	counter0
		movlw	currbl
		movwf	fsr
hbl		movfw	x0
		addwf	indf,w
		incf	fsr,f
		movwf	x		;x = x0 + relx
		movfw	y0
		addwf	indf,w
		incf	fsr,f
		movwf	y		;y = y0 + rely
		movfw	fsr
		movwf	counter1
		call	clrbit
		movfw	counter1
		movwf	fsr
		decfsz	counter0,f
		goto	hbl
		movlw	9
		delay
		return

;--------------------------- show block scan line ----------------------------

showblock	bcf	porta,0			;start sync
		movlw	3
		delay
		movlw	4
		bsf	porta,0			;end sync
		movwf	counter0
		movlw	currbl
		movwf	fsr
sbl		movfw	x0
		addwf	indf,w
		incf	fsr,f
		movwf	x			;x = x0 + relx
		movfw	y0
		addwf	indf,w
		incf	fsr,f
		movwf	y		;y = y0 + rely
		movfw	fsr
		movwf	counter1
		call	setbit
		movfw	counter1
		movwf	fsr
		decfsz	counter0,f
		goto	sbl
		movlw	0xA
		delay
		return

;------------------------- output one sync pulse ------------------------------
;17 cycles

hsync		bcf	porta,0
		movlw	3
		delay
		nop
		bsf	porta,0			;end sync
		return

;-------------------------- add one point to score ----------------------------

incpoints	incf	points + 2,f		;25 cycles
		movfw	points + 2
		sublw	0xA
		skpz
		goto	firstok
		clrf	points + 2
		incf	points + 1,f
		movfw	points + 1
		sublw	0xA
		skpz
		goto	secondok
		clrf	points + 1
		incf	points,f
		movlw	2
		delay
		return

firstok		nop
		dnop
		dnop
secondok	dnop
		movlw	3
		delay
		return

;------------------------- part of line of score ------------------------------

showp		movfw	points + 2		;89 cycles
		call	chars
		movwf	counter1
		movfw	points + 1
		call	chars
		movwf	counter0
		movfw	points 
		call	chars
		call	shiftout
		movfw	counter0
		call	shiftout
		movfw	counter1
		call	shiftout
		return

;----------- routine used by showp to shift out one byte to display -----------

shiftout	movwf	portb		;13 cycles
		rrf	portb,f
		rrf	portb,f
		rrf	portb,f
		rrf	portb,f
		rrf	portb,f
		rrf	portb,f
		rrf	portb,f
		bcf	portb,0
		return

;-------- makeblock creates a block of blocktype into the image buffer -------
;167 cycles

makeblock	
		movlw	3			;keep angle 0-3
		andwf	angle,f
		movf	blocktyp,f		;if blocktype = 0
		skpnz
		clrf	angle			;then dont allow rotation

		bcf	stuff,3			;clear x-mirror flag
		bcf	stuff,4			;clear y-mirror flag
		btfsc	angle,1			;if angle = 2 or 3
		bsf	stuff,4			;then set y-mirror flag
		movfw	angle
		xorlw	1			;if angle = 1
		skpnz
		bsf	stuff,3			;then set x-mirror flag
		xorlw	1+2			;if angle = 2
		skpnz
		bsf	stuff,3			;then set x-mirror flag
		clrc
		rlf	blocktyp,w		;pointer = blocktyp * 2
		call	blocks			;get x-blockinfo from pointer
		movwf	counter0		;save x-blockinfo
		clrc
		rlf	blocktyp,w
		addlw	1			;pointer = blocktyp * 2 + 1
		call	blocks			;get y-blockinfo from pointer
		movwf	counter1		;save y-blockinfo
		btfss	angle,0			;if angle = 1, or angle = 3
		goto	mbnoswap
		xorwf	counter0,w		;then swap x and y blockinfo
		xorwf	counter1,f
		xorwf	counter0,f
mbnoswapr	movlw	4
		movwf	counter2		;we have 4 coordinat pairs per block
		movlw	currbl
		movwf	fsr			;setup pointer to image buffer
mbl0		movfw	counter0		;get x-blockinfo
		call	convert			;convert the two first bits into a coordinat value
		btfsc	stuff,3			;if x-mirror flag = 1
		sublw	0			;then make the x-coordinate negative
		movwf	indf			;save x-coordinate in image buffer
		incf	fsr,f			;move pointer to next position in image buffer
		movfw	counter1		;get y-block info
		call	convert			;convert the two first bits into a coordinate value
		btfsc	stuff,4			;if y-mirror flag = 1
		sublw	0			;then make the y-coordinate negative
		movwf	indf			;save y-coordinate in image buffer
		incf	fsr,f			;move pointer to next position in image buffer
		rrf	counter0,f		;rotate x-blockinfo to the next two bits
		rrf	counter0,f
		rrf	counter1,f		;rotate y-blockinfo to the next two bits
		rrf	counter1,f
		decfsz	counter2,f		;do all 4 coordinate pairs
		goto	mbl0
		return

;--------------------- initialize tetris, clear stuff -------------------------

inittetris	movlw	0x0D
		movwf	fsr
		movlw	0x43
		movwf	counter0
cllp		clrf	indf
		incf	fsr,f
		decfsz	counter0,f
		goto	cllp

		movlw	buffer			;point to buffer
		movwf	fsr
		movlw	0xf			;15 blocklines
		movwf	counter0
itl0		movlw	0x10			;left block: ....*...
		movwf	indf
		incf	fsr,f			;point to next block
		movlw	0x80			;right block: .......*
		movwf	indf
		incf	fsr,f			;point to next block
		decfsz	counter0,f		;do all 15 lines
		goto	itl0
		movlw	0xf0			;bottom left ....****
		movwf	buffer + 0x1E
		movlw	0xff			;bottom right ********
		movwf	buffer + 0x1F
		movlw	0xE
		tris	porta
		movlw	0xFE
		tris	portb

		movlw	1
		movwf	fallcnt			;fallcount = 1
		movwf	movecnt			;move count = 1
		movwf	m_songcnt		;song count = 1
		clrf	eeadr
		call	createcurrent
		goto	newblock

;------------------------------ delay stuff -----------------------------------

noaddpoints	movlw	0x39
		delay
		goto	noaddpointsr

nofall		movlw	0x2D
		delay
		dnop

fallok		movlw	0xB
		delay
		call	hsync
		movlw	0x3A
		delay
		call	hsync
		movlw	0xC
		delay
		nop
		goto	nofallret

moveok		nop
		movf	movecnt,f
		skpz
		goto	nomove
		movlw	movespeed
		movwf	movecnt

		incf	random,f
		movlw	7
		andwf	random,f
		dnop
		goto	moveokret

nofilled11	incf	fsr,f
		nop
		dnop
nofilled21	goto	nofilledr1

nofilled12	incf	fsr,f
		nop
		dnop
nofilled22	goto	nofilledr2

remshort	movlw	0x36		;wait 56us for sync to end
		delay
		dnop
		movfw	counter0
		movwf	counter2
		movwf	counter3
		skpnz
		bsf	counter3,7
		goto	remshortr	;then continue removing lines

noremfilled	movlw	0x39		;wait 59us for sync to end
		delay
		dnop
		goto	noremfilledr		;no lines removed, continue and stuff..

norot		call	createcurrent
		call	createcurrent
		call	hsync
		movlw	0x39
		delay
		nop
		goto	norotr

nofallu		btfss	blockstuff,drop
		bsf	stuff,2
		goto	nofallur

norotate	btfss	blockstuff,rotate
		bsf	stuff,1
		goto	norotater

mbnoswap	goto	mbnoswapr

nogame		call	hsync
		btfss	fire1p,fire1b
		goto	inittetris
		movlw	0x14
		call	emptylines
		goto	nogamer


;---------------------------- Sound output routine  ---------------------------
;15 cycles

sound		bsf	porta,4		;set sound output to 1
		btfss	stuff,6		;check sound state
		bcf	porta,4		;if soundstate is 0 then sound output should be 0
		movfw	m_freq		;get current frequency
		decfsz	m_cnt,f		;decrease sound counter, check if it becomes zero
		goto	soundsk
		movwf	m_cnt		;if zero, set music counter to current frequency
		btfsc	stuff,6
		goto	skstuff
		nop
		bsf	stuff,6
		return
skstuff		bcf	stuff,6
		return
soundsk		dnop
		dnop
		return

;------------------------ Set frequency (music routine) -----------------------

music		call	hsync
		movlw	0x36		;prepare for some long delay or something
		decfsz	m_songcnt,f	;update music counter
		goto	nochnote	;if not zero, dont update
		bsf	status,rp0	;setup some eeprom read stuff
		bsf	eecon1,rd
		bcf	status,rp0
		movf	m_freq,f		;check current frequency
		skpz
		goto	pause		;if freq is not zero, make a pause
		movfw	eedata		;get one note
		andlw	0x3F		;mask out frequenvy
		movwf	m_freq		;store it

		swapf	eedata,w	;get note + length, swap upper and lower part into w
		andlw	0xC		;mask out length
		movwf	counter3
		clrc
		rrf	counter3,f	;rotate down the length
		rrf	counter3,f
		clrc
		rrf	points,w
		movwf	delaycnt
		clrc
		rlf	delaycnt,f
		addwf	delaycnt,w	;points/2*3
		addwf	counter3,w	;points/2*3 + shortlength

		call	getlength	;get real length
		movwf	m_songcnt
		incf	eeadr,f		;next song position
		movfw	eeadr
		sublw	0x34		;end of song ?
		skpnz
		clrf	eeadr		;if so, restart song

		movlw	0x2B		;this delay is not very critical
nochnote	delay
		return

pause		clrf	m_freq	
		movlw	2
		movwf	m_songcnt
		movlw	0x2B + 5
		goto	nochnote


;------------------------- the song: karaboschka ------------------------------

m_d3	equ	0x35		; note definitions
m_e3	equ	0x2F
m_f3	equ	0x2D
m_g3	equ	0x28
m_a3	equ	0x24
m_b3x	equ	0x21
m_c4	equ	0x1E
m_d4	equ	0x1B

m_l4	equ	0x00		; length definition
m_l2	equ	0x40
m_l2x	equ	0x80

		org	0x2100
 
		dw	m_a3  +  m_l2
		dw	m_e3  +  m_l4
		dw	m_f3  +  m_l4
		dw	m_g3  +  m_l2
		dw	m_f3  +  m_l4
		dw	m_e3  +  m_l4
		dw	m_d3  +  m_l2x
		dw	m_f3  +  m_l4
		dw	m_a3  +  m_l2
		dw	m_g3  +  m_l4
		dw	m_f3  +  m_l4
		dw	m_e3  +  m_l2x
		dw	m_f3  +  m_l4
		dw	m_g3  +  m_l2
		dw	m_a3  +  m_l2
		dw	m_f3  +  m_l2
		dw	m_d3  +  m_l2
		dw	m_d3  +  m_l2

		dw	m_b3x +  m_l2x
		dw	m_c4  +  m_l4
		dw	m_d4  +  m_l2
		dw	m_c4  +  m_l4
		dw	m_b3x +  m_l4
		dw	m_a3  +  m_l2x
		dw	m_f3  +  m_l4
		dw	m_a3  +  m_l2
		dw	m_g3  +  m_l4
		dw	m_f3  +  m_l4
		dw	m_e3  +  m_l2x
		dw	m_f3  +  m_l4
		dw	m_g3  +  m_l2
		dw	m_a3  +  m_l2
		dw	m_f3  +  m_l2
		dw	m_d3  +  m_l2
		dw	m_d3  +  m_l2
 
		dw	m_b3x +  m_l2x
		dw	m_c4  +  m_l4
		dw	m_d4  +  m_l2
		dw	m_c4  +  m_l4
		dw	m_b3x +  m_l4
		dw	m_a3  +  m_l2x
		dw	m_f3  +  m_l4
		dw	m_a3  +  m_l2
		dw	m_g3  +  m_l4
		dw	m_f3  +  m_l4
		dw	m_e3  +  m_l2x
		dw	m_f3  +  m_l4
		dw	m_g3  +  m_l2
		dw	m_a3  +  m_l2
		dw	m_f3  +  m_l2
		dw	m_d3  +  m_l2
		dw	m_d3  +  m_l2

		end

