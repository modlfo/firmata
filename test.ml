
open Firmata

let main () =
	let port_opt = openPort "/dev/ttyACM0" in
	match port_opt with
	| Some(port) ->
		setSamplingRate port 10 ;
		setPinMode      port 13 OutputPin ;
		digitalWrite    port 13 1 ;
		setPinMode      port 21 AnalogPin ;
		setPinMode      port 4  ServoPin ;

		let rec loop _ =
		   update port 1;
		   let value  = analogRead port 21 in
		   analogWrite port 4 (value/4);
		   loop ()
		in loop ()
	| _ -> ()
;;

main ();;
