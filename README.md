# Sum

An Assembly project for the Computer Architecture and Operating Systems university course.

## Problem statement

Write a program that takes an array of 64-bit integers `x[]` and calculates the following number (placing it back in `x`):
```tex
sum_{i = 0}^n ( x[i] * 2^((64 * i^2) / n) )
```

## Example test

An example test is available in the `sum_example.c` file.

## Technical requirements

The program will be compiled with `make` (for compilation details see the makefile).

Try to achieve the lowest number of bytes possible for the executable.