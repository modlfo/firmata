
(* - NonBlockingExample -
 * This example is similar to 'SimpleExample' but the main difference is that
 * the calls to the firmata functions do not block since they are called with
 * a wait time of zero [update board 0].
 *)

open Firmata

let serial_port = "/dev/tty.usbmodem1411" ;;

type board_states =
  | Waiting
  | Configure
  | Loop

let updateBoard board state =
  update board 0; (* updates the board without waiting *)
  match state with
  | Waiting   -> (* if the board is ready move to configure state *)
    if isReady board then Configure else Waiting
  | Configure ->
    printInformation board;               (* prints the information of the board *)
    setSamplingRate  board 10 ;           (* sets the sampling rate to 10 ms *)
    setPinMode       board 21 AnalogPin ; (* configures pin 21 as analog input *)
    setPinMode       board 4  ServoPin ;  (* configures pin 4 as servo *)
    reportAnalogPin  board 21 true;       (* request the value of pin 21 to be reported periodically *)
    Loop
  | Loop ->
    let value = analogRead board 21 in (* gets the value of the analog pin (10 bits) *)
    let angle = value/4 in             (* dives the value by 4 (makes it 8 bits) *)
    analogWrite board 4 angle;         (*  writes it to the servo as angle *)
    Loop
;;

let main () =
    match openPort serial_port with
    | OpenOk(board)   ->
        (* infinite loop *)
        let rec loop state =
          let new_state = updateBoard board state in
          Unix.sleep 1;  (* Do other stuff or sleep *)
          loop new_state
        in loop Waiting
    | OpenError(msg) -> print_endline msg

;;

main () ;;