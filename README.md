# Firmata
Ocaml library to control Firmata boards like Arduino

You can find the complete list of API functions in the `firmata.mli` file.

For examples on how to use the library see `SimpleExample.ml` and `NonBlockingExample.ml`.


### Building the library and the examples

```
$ ./configure
$ make
```

Build the documentation:

```
$make doc
```

After building the documentation you will find the reference for the API in firmata_api.docdir/Firmata.html.


If you want to install the library run:

```
$ make install
```

### IMPORTANT

If you install the library you have to pass a bunch of flags when linking your own program. Therefore I recommend modifying one of the existing examples and use the build system provided.

If you need to compile your own program here are a few examples:

Compiling SimpleExample.native in OSX

```
$ ocamlbuild -use-ocamlfind -pkg firmata -lflags -cclib,-lstdc++,-cclib,-framework,-cclib,CoreFoundation,-cclib,-framework,-cclib,IOKit SimpleExample.native
```

### Using this library

The first thing that you have to do is finding which port your board is connected. You can use the function `getSerialPortNames` to get a list of the ports available.

Once you know the name of your port use `openPort port_name` start the communication with the board.

Depending on the board, it may take some time to initialize and respond. Use `update board ms` to process any incoming data. You can poll the status of the board by using `isReady board`.

Once the board is ready you can display the pin information by calling `printInformation board`. This will print a list of the pins and the capabilities. You can retrieve this information by calling `getPinInformation board` to get a list of all the pins. You can also use `getName` and `getVersion` to get more information about the board.

Now you can start configuring the pins of the board. You can call `setPinMode board pin mode` to define how you want to use it.

Before reading values of you need to request data from the board. If you want to do it manually use `queryPinState board pin`. This will ask the board for the current status of the pin. The data will be available once the once the board answers back.

You can ask the board to send information about a pin periodically. To do so, you need first to define how often you want the data. This is done with the function `setSamplingRate board ms`. Regular Arduino boards are limited by the processor speed and the serial communication speed. Other boards like the Teensy 3.1 can communicate much faster. Once the sampling rate is set, you need to define which pin should periodically update. Use `reportDigitalPin board pin true` or `reportAnalogPin board pin false` for digital or analog pins correspondingly.

You have to consider that you need to call the function `update board ms` to process the incoming data. This function will block `ms` milliseconds waiting for data. If you don't want the function to block call it with `ms` equal zero `update board 0`.

To read or write values from the digital pins use the functions `digitalWrite` and `digitalRead`. For analog inputs use `analogRead` and to control PWM signals or servos use `analogWrite`.

### Known issues

Due to problems with Ocaml compiling and linking C++ code I can only build native executables.

### Authors

- Leonardo Laguna Ruiz (modlfo@gmail.com) : Ocaml library and bindings
- Paul Stoffregen (paul@pjrc.com) : Serial port C++ code (code from https://github.com/firmata/firmata_test )