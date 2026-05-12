# Locate spack packages automatically
SPACK_SETUP  := $(HOME)/spack/share/spack/setup-env.sh

HIGHFIVE_PREFIX := $(shell . $(SPACK_SETUP) && spack location -i highfive)
HDF5_PREFIX     := $(shell . $(SPACK_SETUP) && spack location -i hdf5)
MPI_PREFIX      := $(shell . $(SPACK_SETUP) && spack location -i openmpi)

CXX      = g++
CXXFLAGS = -std=c++20 -O3 -fopenmp

INCLUDES = -I$(HIGHFIVE_PREFIX)/include \
           -I$(HDF5_PREFIX)/include \
           -I$(MPI_PREFIX)/include

LDFLAGS  = -L$(HDF5_PREFIX)/lib \
           -Wl,-rpath,$(HDF5_PREFIX)/lib \
           -L$(MPI_PREFIX)/lib \
           -Wl,-rpath,$(MPI_PREFIX)/lib \
           -lhdf5 -lmpi -lm

TARGET = a.out
SRC    = Lotka_Volterra_stochastic_model.cpp
HEADER = nrm_heap_header.h

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(SRC) $(HEADER)
	$(CXX) $(CXXFLAGS) $(INCLUDES) $(SRC) $(LDFLAGS) -o $(TARGET)

clean:
	rm -f $(TARGET)
