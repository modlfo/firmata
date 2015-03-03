(*  Ocaml Firmata library
 *  Copyright 2015, Leonardo Laguna Ruiz (modlfo@gmail.com)
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *)

(** Allows to control boards supporting the Firmata protocol (http://firmata.org) like Arduino boards *)

(** Serial port object *)
type serial_obj

(** Creates a new serial port object
   @return serial_obj - Object used to have access to the port
*)
external newSerial   : unit       -> serial_obj             = "newSerial"

(** Opens a serial port
   @param port    - The serial port object created with newSerial
   @param name    - The name of the serial port
   @return status - SerialOk if the port was opened correctly or SerialError(msg) if the port failed to open
*)
external openSerial  : serial_obj -> string -> string option = "openSerial"

(** Closes a serial port
   @param port - The serial port object
*)
external closeSerial : serial_obj -> unit                   = "closeSerial"

(** Sets the baudrate of the port
   @param port     - The serial port object
   @param baudrate - The desired baudrate. This should be a valid baudrate value
   @return status  - True if the value was set correctly
*)
external setBaudrate : serial_obj -> int -> bool           = "setBaudrate"

(** Returns a list with the names of the available ports
   @param port   - This can be an arbitrary serial_obj object
   @return names - A list with the names of available ports
*)
external portList    : serial_obj -> string list            = "portList"

(** Returs the data the port has received
   @param port  - The serial port object
   @return data - A list of integers containing the received data
*)
external readSerial  : serial_obj -> int list               = "readSerial"

(** Writes the given data to the port
   @param port  - The serial port object
   @param data  - A list of integers that should be send
   @return sent - The number of bytes written to the port
*)
external writeSerial : serial_obj -> int list -> int        = "writeSerial"

(** Waits for a given number of ms and returns the number of bytes available
   @param port - The serial port object
   @param time - Time to wait (in ms) before returning
   @return n   - The number of bytes waiting to be red
*)
external waitSerial  : serial_obj -> int -> int             = "waitSerial"

(** Returns the status of the port
   @param port    - The serial port object
   @return status - True if is open false otherwise
*)
external isOpenSerial: serial_obj -> bool                   = "isOpenSerial"

(** Set the serial port control values
  @param DTR - Data Terminal Ready value
  @param RTS - ?
*)
external setControl  : serial_obj -> bool -> bool -> unit   = "setControl"

(** Modes supported by the pins *)
type pin_mode =
   | InputPin    (** Digital input *)
   | OutputPin   (** Digital output *)
   | AnalogPin   (** Analog input *)
   | PWMPin      (** PWM (Analog) output *)
   | ServoPin    (** Servo output *)
   | ShiftPin    (** Shift (not supported) *)
   | I2CPin      (** I2C (not supported) *)
   | UndefinedPin(** Undefined mode *)

(** Used to store all information about the pins *)
type pin_info =
   {
      number          : int;                   (** Number *)
      mutable mode    : pin_mode;              (** Current mode *)
      mutable analog_channel : int option;     (** Analog channel number *)
      supported_modes : (pin_mode * int) list; (** List of supported modes *)
   }

(** Empty pin information *)
let default_pin_info = { number = -1; mode = UndefinedPin; analog_channel = None; supported_modes = [] }

(** Types of messages returned by the board *)
type msg_type =
   | AnalogMsg       of int * int            (** Pin number, value *)
   | DigitalMsg      of int * int            (** Pin number, value *)
   | FirmwareMsg     of int * int * string   (** Major version, minor version , name *)
   | CapabilitiesMsg of pin_info list        (** Pin information *)
   | MappingMsg      of int option list      (** Channel to pin mappings *)
   | PinStatusMsg    of int * pin_mode * int (** Pin number, mode, value *)

(** Main type that represents a Firmata board *)
type firmata_type =
   {
      mutable name    : string;   (** Name returned by the board *)
      mutable version : string;   (** Version *)
      mutable ready   : bool;     (** True if the board is ready to use *)
      mutable buffer  : int list; (** Used to store unconsumed data *)
      mutable npins   : int;      (** Number of pins *)
      mutable nchan   : int;      (** Number of analog channels *)
      port        : serial_obj;   (** Serial port object *)
      pins        : pin_info array; (** Array containing the information of all pins *)
      values      : int array;    (** Array containing the values of pins *)
      chan_to_pin : int array;    (** Mapping of analog channels to pin number *)
   }

(** Either return value when opening the port *)
type open_return =
   | OpenOk    of firmata_type
   | OpenError of string

(** Converts an integer to its corresponding pin mode *)
let intPinMode (i:int) : pin_mode =
   match i with
   | 0 -> InputPin
   | 1 -> OutputPin
   | 2 -> AnalogPin
   | 3 -> PWMPin
   | 4 -> ServoPin
   | 5 -> ShiftPin
   | 6 -> I2CPin
   | _ -> UndefinedPin

(** Returns the string representation of a pin mode *)
let pinModeStr (mode:pin_mode) : string =
   match mode with
   | InputPin     -> "Input"
   | OutputPin    -> "Output"
   | AnalogPin    -> "Analog"
   | PWMPin       -> "PWM"
   | ServoPin     -> "Servo"
   | ShiftPin     -> "Shift"
   | I2CPin       -> "I2C"
   | UndefinedPin -> "Undefined"

(** Returns the integer representation of the mode *)
let pinModeInt (mode:pin_mode) : int =
   match mode with
   | InputPin     -> 0
   | OutputPin    -> 1
   | AnalogPin    -> 2
   | PWMPin       -> 3
   | ServoPin     -> 4
   | ShiftPin     -> 5
   | I2CPin       -> 6
   | UndefinedPin -> 0

(** Converts a list of characters to a string *)
let implode (l:char list) : string =
  let res = Bytes.create (List.length l) in
  let rec imp i = function
  | [] -> res
  | c :: l -> Bytes.set res i c; imp (i + 1) l in
  imp 0 l

(** Splits an integer value into its lsb and msb of 7 bits each *)
let splitLsbMsb (value:int) : int * int =
   let lsb = value land 0x7F in
   let msb = value lsr 7 in
   lsb,msb

(** Returns a 14 bit integer given the lsb and msb *)
let joinLsbMsb (lsb:int) (msb:int) : int =
   lsb lor (msb lsl 7)

(** Given a message, returns true if the msb is equal to the command *)
let isCmd (v:int) (cmd:int) : bool =
   (v land 0xF0) = cmd

(** Returns all the contents of a sysex message if all the data is available *)
let rec consumeSysex data acc =
   match data with
   | 0xF7::rest -> Some(List.rev acc, rest)
   | h::rest    -> consumeSysex rest (h::acc)
   | []         -> None

(** Parses the data returned by the board *)
let rec parse (data:int list) =
   match data with
   | [] -> [],[]
      (* Analog I/O*)
   | cmd::lsb::msb::tail     when isCmd cmd 0xE0 ->
      let c = cmd land 0x0F in
      let v = joinLsbMsb lsb msb in
      let inner,rem_data = parse tail in
      AnalogMsg(c,v)::inner,rem_data
      (* Digital I/O*)
   | cmd::lsb::msb::tail     when isCmd cmd 0x90 ->
      let c = cmd land 0x0F in
      let v = joinLsbMsb lsb msb in
      let inner,rem_data = parse tail in
      DigitalMsg(c,v)::inner,rem_data
      (* Firware version *)
   | 0xF9::vN::vn::tail ->
      let inner,rem_data = parse tail in
      FirmwareMsg(vN,vn,"")::inner,rem_data
   | 0xF0::tail ->
      begin
         match consumeSysex tail [] with
         | None -> [],data
         | Some(sysex,rest) ->
            let response = parseSysex sysex in
            let inner,rest2 = parse rest in
            response::inner,rest2
      end
   | cmd::tail     when not (isCmd cmd 0xE0)
      && not (isCmd cmd 0x90)
      && cmd<>0xF0 ->
      Printf.printf "Unknown message: %l\n" cmd;
      parse tail
   | _ ->
      [],data
(** Parses sysex messages returned by the board *)
and parseSysex (data: int list) =
   match data with
   (* Query Firmware response *)
   | 0x79::vN::vn::tail ->
      let rec consume name acc =
         match name with
         | [] -> implode (List.rev acc)
         | lsb::msb::rest ->
            let c = joinLsbMsb lsb msb |> char_of_int in
            consume rest (c::acc)
         | _::rest -> implode (List.rev acc)
      in
      let name = consume tail [] in
      FirmwareMsg(vN,vn,name)
   (* Capabilities response *)
   | 0x6C::tail ->
      let pin_modes = parsePinModes tail [] in
      let pin_info =
         List.mapi (fun i modes ->
            {
               number = i;
               mode = UndefinedPin;
               analog_channel = None;
               supported_modes = modes
            } )
         pin_modes
      in
      CapabilitiesMsg(pin_info)
   (* Analog pins mapping response *)
   | 0x6A::tail ->
      let rec consume info acc =
         match info with
         | []         -> List.rev acc
         | 127::rest  -> consume rest (None::acc)
         | n::rest    -> consume rest (Some(n)::acc)
      in
      let mapping = consume tail [] in
      MappingMsg(mapping)
   (* Pin status response *)
   | 0x6E::pin::mode::tail ->
      let rec consume info acc i =
         match info with
         | n::rest -> consume rest (n lsl (i*7) lor acc) (i+1)
         | []      -> acc
      in
      let status = consume tail 0 0 in
      PinStatusMsg(pin,intPinMode mode,status)
   | _ ->
      failwith "Unknown sysex"

(** Parses a pin mode *)
and parsePinMode (data:int list) (acc:(pin_mode * int) list) =
   match data with
   | 127::rest -> List.rev acc,rest
   | mode::resolution::rest ->
      parsePinMode rest (((intPinMode mode),resolution)::acc)
   | _ -> failwith "Fail to parse pin modes"

(** Parses the block of pin modes *)
and parsePinModes (data:int list) acc =
   match data with
   | [] -> List.rev acc
   | _ ->
      let mode,rest = parsePinMode data [] in
      parsePinModes rest (mode::acc)

(** Prints the a pin mode *)
let printPinMode mode =
   Printf.printf "%s(%i) " (mode|>fst|>pinModeStr) (snd mode)

(** Prints all the information of a pin *)
let printPinInfo pin_info =
   if pin_info.number > 0 then
      begin
         Printf.printf "- Pin %i : " pin_info.number;
         List.iter printPinMode pin_info.supported_modes;
         let _ =
            match pin_info.analog_channel with
            | Some(i) -> Printf.printf " - A%i" i
            | _ -> ()
         in
         print_newline ()
      end

let printInformation (handler:firmata_type) : unit =
   Printf.printf "firmata %s v%s\n" handler.name handler.version;
   Array.iter  printPinInfo handler.pins

(** Splits an 8 bit integer into a list containing the bits *)
let splitBits value =
   let rec splitBitsAcc value mask i =
      if i<8 then
         let b  = if mask land value <> 0 then 1 else 0 in
         b::splitBitsAcc value (mask lsl 1) (i+1)
      else []
   in
   splitBitsAcc value 1 0 |> List.rev

(** Makes an 8 bit integer given the list of bits *)
let joinBits bits =
   let rec joinBitsAcc bits mask i =
      match bits with
      | []   -> i
      | h::t ->
         joinBitsAcc t (mask lsr 1) (h*mask lor i)
   in joinBitsAcc bits 0x80 0

(** Returns true if the given pin is configured as digital input *)
let isInput (handler:firmata_type) (pin:int) : bool =
   let info = Array.get handler.pins pin in
   info.mode = InputPin

(** Initializes a list given a function *)
let listInit n f =
   let rec listInitAcc start n f =
      if n>0 then (f (start-n))::listInitAcc start (n-1) f
      else []
   in listInitAcc n n f

let queryFirmware (handler:firmata_type) : unit =
   writeSerial handler.port [0xF0;0x79;0xF7] |> ignore

let queryCapabilities (handler:firmata_type) : unit =
   writeSerial handler.port [0xF0;0x6B;0xF7] |> ignore

let queryAnalogMapping (handler:firmata_type) : unit =
   writeSerial handler.port [0xF0;0x69;0xF7] |> ignore

let queryPinState (handler:firmata_type) (pin:int) : unit =
   writeSerial handler.port [0xF0;0x6D;pin;0xF7] |> ignore

let analogWriteExtended (handler:firmata_type) (pin:int) (value:int) : unit =
   let lsb,msb = splitLsbMsb value in
   writeSerial handler.port [0xF0;0x6F;pin;lsb;msb;0xF7] |> ignore

let setSamplingRate (handler:firmata_type) (ms:int) : unit =
   let lsb,msb = splitLsbMsb ms in
   writeSerial handler.port [0xF0;0x7A;lsb;msb;0xF7] |> ignore

let setPinMode (handler:firmata_type) (pin:int) (mode:pin_mode) =
   let pin_info = Array.get handler.pins pin in
   pin_info.mode <- mode;
   writeSerial handler.port [0xF4;pin;pinModeInt mode] |> ignore

let configServo (handler:firmata_type) (pin:int) (min_pulse:int) (max_pulse:int) : unit =
   let min_lsb,min_msb = splitLsbMsb min_pulse in
   let max_lsb,max_msb = splitLsbMsb max_pulse in
   writeSerial handler.port [0xF0;0x70;pin;min_lsb;min_msb;max_lsb;max_msb;0xF7] |> ignore

let reportAnalogPin (handler:firmata_type) (pin:int) (enabled:bool) : unit =
   writeSerial handler.port [0xC0 lor (pin land 0x0F);if enabled then 1 else 0] |> ignore

let reportDigitalPin (handler:firmata_type) (pin:int) (enabled:bool) : unit =
   writeSerial handler.port [0xD0 lor ((pin/8) land 0x0F);if enabled then 1 else 0] |> ignore

(** Process the messages returned by the board and updates the information *)
let processResponse (handler:firmata_type) msg : unit =
   match msg with
   | AnalogMsg(chan,v) when handler.ready ->
      let pin = Array.get handler.chan_to_pin chan in
      Array.set handler.values pin v
   | DigitalMsg(dport,v) when handler.ready ->
      let start = 8 * dport in
      let bits = splitBits v |> List.mapi (fun i a -> i+start,a) in
      List.iter (fun (pin,b) ->
         if isInput handler pin then Array.set handler.values pin b) bits
   | FirmwareMsg(x,y,name) ->
      let version = Printf.sprintf "%i.%i" x y in
      queryCapabilities handler;
      queryAnalogMapping handler;
      handler.name    <- name;
      handler.version <- version;
   | CapabilitiesMsg(pin_info) ->
      handler.npins <- List.length pin_info;
      List.iteri (fun i a -> Array.set handler.pins i a) pin_info
   | MappingMsg(mappings) ->
      List.iteri (
            fun i a ->
               let pin_info = Array.get handler.pins i in
               pin_info.analog_channel<-a
            ) mappings;
      List.iteri (
            fun i m ->
               match m with
               | Some(c) -> Array.set handler.chan_to_pin c i
               | _ -> ()
            ) mappings;
      handler.ready <- true;
      handler.nchan <- List.length mappings
   | PinStatusMsg(pin,mode,value) when handler.ready ->
      let info       = Array.get handler.pins pin in
      info.mode <- mode;
      Array.set handler.values pin value
   | _ -> ()

let update (handler:firmata_type) (wait_ms:int) : unit =
   if waitSerial handler.port wait_ms > 0 then
      begin
         let data              = readSerial handler.port in
         let append_data       = handler.buffer@data in
         let consumed,rem_data = parse append_data in
         handler.buffer <- rem_data;
         List.iter (fun a -> processResponse handler a) consumed
      end

let openPort (port_name:string) : open_return =
   let port = newSerial() in
   match openSerial port port_name with
   | None ->
      begin
         setBaudrate port 57600 |> ignore;
         setControl port true false;
         waitSerial port 1 |> ignore;
         readSerial port   |>ignore;
         let handler = {
            port    = port;
            pins    = Array.make 128 default_pin_info;
            name    = "" ;
            version = "";
            buffer  = [];
            values      = Array.make 128 0;
            chan_to_pin = Array.make 128 0;
            ready   = false;
            npins   = 0;
            nchan   = 0;
         }
         in
         queryFirmware handler;
         OpenOk(handler)
      end
   | Some(msg) -> OpenError(msg)

let digitalWrite (handler:firmata_type) (pin:int) (value:int) : unit =
   let current_value = Array.get handler.values pin in
   if current_value <> value then
      begin
         Array.set handler.values pin value;
         let port      = pin/8 in
         let bits      = listInit 8 (fun i -> Array.get handler.values (8*port+(7-i))) in
         let bit_value = joinBits bits in
         let lsb,msb   = splitLsbMsb bit_value in
         writeSerial handler.port [0x90 lor port; lsb; msb] |> ignore
      end

let analogWrite (handler:firmata_type) (pin:int) (value:int) : unit =
   let current_value = Array.get handler.values pin in
   if current_value <> value then
      begin
         Array.set handler.values pin value;
         if pin > 15 then
            analogWriteExtended handler pin value
         else
            let lsb,msb = splitLsbMsb value in
            writeSerial handler.port [0xE0 lor pin;lsb;msb] |> ignore
      end

let analogRead (handler:firmata_type) (pin:int) =
   Array.get handler.values pin

let digitalRead (handler:firmata_type) (pin:int) =
   Array.get handler.values pin

let isReady (handler:firmata_type) =
   handler.ready

