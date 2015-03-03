
open Firmata

let serial_port = "/dev/tty.usbmodem1411" ;;

let rec waitTillReady board =
    update board 1;
    if not (isReady board) then waitTillReady board
;;

let main () =
    match openPort serial_port with
    | OpenOk(board)   ->
        waitTillReady    board ;              (* waits for the board to be ready *)
        printInformation board;               (* prints the information of the board *)
        setSamplingRate  board 10 ;           (* sets the sampling rate to 10 ms *)
        setPinMode       board 21 AnalogPin ; (* configures pin 21 as analog input *)
        setPinMode       board 4  ServoPin ;  (* configures pin 4 as servo *)
        reportAnalogPin  board 21 true;       (* request the value of pin 21 to be reported periodically *)
        (* infinite loop *)
        let rec loop _ =
           update board 1;                    (* updates the board and waits maximum 1 ms *)
           let value = analogRead board 21 in (* gets the value of the analog pin (10 bits) *)
           let angle = value/4 in             (* dives the value by 4 (makes it 8 bits) *)
           analogWrite board 4 angle;         (*  writes it to the servo as angle *)
           loop ()
        in loop ()
    | OpenError(msg) -> print_endline msg

;;

main () ;;