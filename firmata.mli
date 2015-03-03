(** Allows to control boards supporting the Firmata protocol (http://firmata.org) like Arduino boards *)

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

(** Main type that represents a Firmata board *)
type firmata_type

(** Either return value when opening the port *)
type open_return =
   | OpenOk    of firmata_type
   | OpenError of string

(** [openPort name] : Opens the serial port [name] which should have attached the board. *)
val openPort : string -> open_return

(** [update board ms] : Process all received data. This function receives the value [ms] which
    defines how many milliseconds the board should wait for data before returning. This function
    is a blocking function. If you don't want it to block, call it with zero ms [update board 0]. *)
val update : firmata_type -> int -> unit

(** [isReady board] : Returns true if the board is ready to receive commands *)
val isReady : firmata_type -> bool

(** [digitalWrite board pin value] : Writes the given value to the pin. *)
val digitalWrite : firmata_type -> int -> int -> unit

(** [digitalRead board pin] :  Reads the last reported value of the pin.*)
val digitalRead : firmata_type -> int -> int

(** [analogWrite board pin value] : Writes the given value to the pin. *)
val analogWrite : firmata_type -> int -> int -> unit

(** [analogRead board pin] :  Reads the last reported value of the pin.*)
val analogRead : firmata_type -> int -> int

(** [reportAnalogPin board pin true] : Makes the board continuously return the state of the
    analog pin. The period is defined with the [setSamplingRate] function. *)
val reportAnalogPin : firmata_type -> int -> bool -> unit

(** [reportDigitalPin board pin true] : Makes the board continuously return the state of the
    digital pin. The period is defined with the [setSamplingRate] function. *)
val reportDigitalPin : firmata_type -> int -> bool -> unit

(** [setSampligRate board ms] : Sets the sampling rate in ms of the board. This interval
    defines how often [reportAnalogPin] and [reportDigitalPin] return the state of a pin. *)
val setSamplingRate : firmata_type -> int -> unit

(** [setPinMode board pin mode] : Configures the pin as any of the available modes defined
    in [pin_mode]*)
val setPinMode : firmata_type -> int -> pin_mode -> unit

(** Initiates a request to get the firmware version. Once the board returns the firmware
    information this will be available by calling [getFirmware] *)
val queryFirmware : firmata_type -> unit

(** Initiates a request to get the information about every pin. Once the board returns the
    information this can be read by calling [getPinInfo]. This function is automatically
    called after the firmware information has been received. *)
val queryCapabilities : firmata_type -> unit

(** Initiates a request of get the information about which pin number corresponds to each
    analog port. Once the board returns the information this can be read by calling
    [getPinAnalogPort]. This function is automatically called after the firmware information
    has been received. *)
val queryAnalogMapping : firmata_type -> unit

(** [queryPinState board pin] : Used to manually request the state state of a pin. This function can be used when
    [reportAnalogPin] or [reportDigitalPin] are not used. *)
val queryPinState : firmata_type -> int -> unit

(** [configServo board pin min_pulse max_pulse] : Sets the configuration values of a servo.
    See [http://arduino.cc/en/Reference/ServoAttach]*)
val configServo : firmata_type -> int -> int -> int -> unit

(** [printInformation board] prints the name, pin information and mappings of a board. *)
val printInformation : firmata_type -> unit

