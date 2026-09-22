# Alpine Makefile.inc for MUMPS 5.7.3, MPICH + openblas + ScaLAPACK.
# Orderings: PT-Scotch (parallel) + METIS + PORD (serial fallback).

# Begin orderings
ISCOTCH = -I/usr/include
LMETISDIR = /usr/lib
IPORD = -I$(topdir)/PORD/include/
LPORDDIR = $(topdir)/PORD/lib/
LPORD = -L$(LPORDDIR) -lpord$(PLAT)
LMETIS = -L$(LMETISDIR) -lmetis
LSCOTCH = -L/usr/lib -lptscotch -lscotch -lptesmumps -lesmumps -lptscotcherr -lscotcherr

ORDERINGSF  = -Dscotch -Dmetis -Dpord -Dptscotch
ORDERINGSC  = $(ORDERINGSF)

LORDERINGS  = $(LMETIS) $(LPORD) $(LSCOTCH)
IORDERINGSF = $(ISCOTCH)
IORDERINGSC = $(ISCOTCH) $(IMETIS) $(IPORD)
# End orderings
###############################################################################

PLAT =
LIBEXT_SHARED = .so
SONAME = -soname
SHARED_OPT = -shared
FPIC_OPT = -fPIC
LIBEXT = .a
OUTC = -o
OUTF = -o
RM = /bin/rm -f
CC = mpicc
FC = mpifort
FL = mpifort
AR = ar vr
RANLIB = echo
LAPACK = -lopenblas
SCALAP = -lscalapack

LIBPAR = $(SCALAP) $(LAPACK)

INCSEQ = -I$(topdir)/libseq
LIBSEQ = $(LAPACK) -L$(topdir)/libseq -lmpiseq$(PLAT)

LIBBLAS = -lopenblas
LIBOTHERS = -lpthread

# Fortran-from-C name mangling
CDEFS = -DAdd_

#Begin Optimized options
OPTF = -O2 -fPIC -fopenmp -fallow-argument-mismatch
OPTL = -O2 -fPIC -fopenmp
OPTC = -O2 -fPIC
#End Optimized options

INCS = $(INCPAR)
LIBS = $(LIBPAR)
LIBSEQNEEDED =
