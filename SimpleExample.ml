
open Firmata

let serial_port = "/dev/ttyACM0" ;;

let main () =
    match openPort serial_port with
    | OpenOk(board)   ->
        update          board 1000 ; (* waits up to 1000 ms for the board to respond *)
        setSamplingRate board 10 ;   (* sets the sampling rate to 10 ms *)
        setPinMode      board 21 AnalogPin ; (* configures pin 21 as analog input *)
        setPinMode      board 4  ServoPin ;  (* configures pin 4 as servo *)
        let rec loop _ =  (* infinite loop *)
           update port 1; (* updates the board and waits maximum 1 ms *)
           let value = analogRead port 21 in (* gets the value of the analog pin (10 bits) *)
           let angle = value/4 in            (* dives the value by 4 (makes it 8 bits) *)
           analogWrite port 4 angle;         (*  writes it to the servo as angle *)
           loop ()
        in loop ()
    | OpenError(msg) -> print_endline msg

;;

main () ;;