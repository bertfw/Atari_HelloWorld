; ============================================================
; HELLO WORLD for Atari 400/800/XL/XE
; 6502 Assembly — uses the Atari OS CIO (Central I/O) system
;
; Sources: "Mapping the Atari" (1985)
;   - IOCB0 layout: pp.82-86 (locs 832-847, $0340-$034F)
;     ICCOM  = IOCB+2   Command byte
;     ICBAL  = IOCB+4   Buffer address low
;     ICBAH  = IOCB+5   Buffer address high
;     ICBLL  = IOCB+8   Buffer length low
;     ICBLH  = IOCB+9   Buffer length high
;     ICAX1  = IOCB+10  Auxiliary byte 1 (open mode)
;     ICAX2  = IOCB+11  Auxiliary byte 2
;   - CIO commands: p.87-88
;     $03 = Open channel
;     $09 = Put text record (outputs string + EOL)
;     $0C = Close channel
;   - CIOV entry point: loc 58454 = $E456  (p.83)
;   - ICAX1 mode 12 = keyboard input + screen output (p.86/101)
;   - E: device (display editor) = device name 'E', number 0
;
; Assembled to load/run at $0600 (safe user RAM area)
; Compatible with ATASM, MADS, MAC/65, or any 6502 assembler.
; ============================================================

        .org    $0600           ; Load address — safe user RAM

; --- OS equates (from Mapping the Atari) ---------------------

IOCB0   = $0340                 ; Base of IOCB channel 0
ICCOM   = IOCB0 + 2             ; $0342  Command
ICBAL   = IOCB0 + 4             ; $0344  Buffer address low
ICBAH   = IOCB0 + 5             ; $0345  Buffer address high
ICBLL   = IOCB0 + 8             ; $0348  Buffer length low
ICBLH   = IOCB0 + 9             ; $0349  Buffer length high
ICAX1   = IOCB0 + 10            ; $034A  Auxiliary byte 1
ICAX2   = IOCB0 + 11            ; $034B  Auxiliary byte 2

CIOV    = $E456                 ; CIO entry vector (loc 58454)

; CIO commands
CMD_OPEN  = $03                 ; Open channel
CMD_PRINT = $09                 ; Put text record (string + EOL)
CMD_CLOSE = $0C                 ; Close channel

; ICAX1 open modes (for E: device)
MODE_RW   = 12                  ; Keyboard input + screen output
MODE_W    = 8                   ; Screen output only

; --- Step 1: Open channel 0 to the E: (editor) device -------
;
; Although the OS already has channel 0 open to E: at boot,
; we open it explicitly to guarantee a clean, known state.
;
; ICCOM  = $03  (open)
; ICBAL/H = address of device name string "E:"
; ICAX1  = 12   (read + write, standard editor mode)
; ICAX2  = 0
; X      = 0    (channel 0 * 16 = offset into IOCB table)

START:
        ; Close first, in case channel was left open
        LDX     #0              ; X = channel 0 * 16 = 0
        LDA     #CMD_CLOSE
        STA     ICCOM
        JSR     CIOV            ; Close — ignore any error

        ; Now open E: for read/write
        LDA     #CMD_OPEN
        STA     ICCOM

        LDA     #<DEVNAME       ; Low byte of device name address
        STA     ICBAL
        LDA     #>DEVNAME       ; High byte
        STA     ICBAH

        LDA     #MODE_RW        ; ICAX1 = 12 (keyboard + screen)
        STA     ICAX1
        LDA     #0
        STA     ICAX2

        LDX     #0              ; Channel 0
        JSR     CIOV            ; Call CIO — open the channel
        BPL     DO_PRINT        ; Branch if no error (N flag clear)
        JMP     DONE            ; Error — bail out

; --- Step 2: Write "Hello World!" to the screen --------------
;
; CMD_PRINT ($09) sends the buffer as a text record.
; CIO appends an EOL (end-of-line) character automatically.
;
; ICCOM  = $09
; ICBAL/H = address of message string
; ICBLL/H = length of string (not counting terminator)

DO_PRINT:
        LDA     #CMD_PRINT
        STA     ICCOM

        LDA     #<MESSAGE       ; Low byte of message address
        STA     ICBAL
        LDA     #>MESSAGE       ; High byte
        STA     ICBAH

        LDA     #MSGLEN         ; Length of "Hello World!" = 12
        STA     ICBLL
        LDA     #0
        STA     ICBLH           ; High byte of length = 0

        LDX     #0              ; Channel 0
        JSR     CIOV            ; Call CIO — print the string

; --- Step 3: Close the channel ------------------------------

        LDA     #CMD_CLOSE
        STA     ICCOM
        LDX     #0
        JSR     CIOV

; --- Step 4: Return to DOS / BASIC --------------------------

DONE:
        RTS                     ; Return to caller (DOS or BASIC)

; --- Data ---------------------------------------------------

DEVNAME:
        .byte   "E:", $9B       ; Device name + EOL terminator
                                ; ($9B is Atari's EOL character)

MESSAGE:
        .byte   "Hello World!"
MSGLEN  = * - MESSAGE           ; Assembler computes length = 12

; --- Atari binary load header (for .XEX / DOS load) --------
;
; Uncomment the block below if you want a self-contained
; Atari binary (.xex) file. The header tells DOS where to load
; the code and where to start running it.
;
; When using an assembler like ATASM or MADS that handles this
; automatically (e.g. .opt obj), you don't need this manually.
;
;       .org    $02E2           ; RUNAD — run address vector
;       .word   START           ; Point DOS here after loading

        .end    START