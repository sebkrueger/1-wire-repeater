Extern interrupt example
========================

A LED connect to Pin 7 (RA0/General purpose I/O) of a PIC12F1840
with 82 Ohm resistor to GND, will toggle, when button connect from 
Pin 5 (RA0/ INT input) to GND.

You can use this code as a test, if you try to modfiy und upload the main
code. This example will be usefull to get in touch with extern interrupts.

Some notes:
- Use intern pull-up on Pin 5
- Very basic software debonce, should work with good button

Examples:
---------

- 01: Simple button click and LED toggle.
