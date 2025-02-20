    Tabulated Equations of State (EOS) for Rotating Neutron Star Code.

A tabulated EOS for the rotating NS code requires three entries:
   1) Baryon number density
   2) Total energy density
   3) Pressure

Values can, of course, be given in any format and I can convert them
to a file which can be read by the code.  However, the following format
is preferable.

   1) Output as 3 columns using FORTRAN format 3E24.14
   2) Each column contains the base 10 logarithm of a 
      quantity in cgs units.

        Column 1: Baryon number density - [cm^(-3)]. 
                  (*From rest mass density where the mass of one
                   baryon is taken as 1.659e-24 g*.)
      
        Column 2: Total energy density  - [g cm^(-3)]. 
        (*Note that the total energy density is given in terms of a mass density,
not energy density*.)
      
        Column 3: Pressure              - [dyne cm^(-2)].

A tabulated EOS typically has about 500 entries which are roughly
evenly spaced in the base 10 log of the total energy density.
A table starts at about 7.86 g cm^(-3) (beginning of the FMT EOS)
and ends wherever the given "high-density" EOS ends (typically
around 5 to 10 times 10^16 g cm^(-3)).

I use a large number of entries in this table so that in the rotating
NS code I can simply use linear interpolation from the table.  This
is faster than high order interpolation, and it is easy to handle
phase transitions.  Since most tabulated EOS are not so finely resolved,
I usually use 4th order interpolation in the base 10 logs of quantities
to create the larger table.  I use even spacing in the base 10 log of
the total energy density over individual sections of the full EOS.
I try to put more resolution wherever it is needed, and I NEVER
interpolate across phase transitions.  Wherever a phase transition
occurs, I make sure to put a point in the table at each end of the
transition.
