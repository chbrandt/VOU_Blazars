#!/bin/bash
comp_libs () {
    [ -f status.codes ] || { echo "Error: file 'status.codes' not found. Exiting."; return 1; }
    echo "-> Compiling 'mylib'"
    gfortran -c mylib.f -ffixed-line-length-132
    echo "-> Compiling 'nhdeabsorb'"
    gfortran -c nhdeabsorb.f -ffixed-line-length-132
}

comp_bins () {
    echo "-> Compiling '$1'.."
    gfortran -o ${1} ${1}.f -ffixed-line-length-132 mylib.o nhdeabsorb.o -L${HOME}/pgplot -lpgplot \
      || { echo "Error: apparently '$1' was not compiled properly. Exiting."; return 1; }
    echo "..done."
}

comp_libs || { echo "Error: Failed during 'mylib' and 'nhdeabsorb' compiling"; exit 1; }

for F in `ls -1 *.f`
do
    [ $F == mylib.f -o $F == nhdeabsorb.f ] && continue
    FX="${F%.f}"
    comp_bins $FX || { echo "Error: Failed during '$F' compiling"; exit 1; }
done
