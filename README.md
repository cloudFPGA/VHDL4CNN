 VHDL4CNN
 ============

A VHDL library for dataflow CNN operations.


Introduction
----------------

VHDL4CNN is a VHDL library that implements convolution, pooling, and activation operations on FPGAs using a dataflow architecture. Therefore, the weights of a convolution are "baked in" into the FPGA logic to achieve a high throughput. Consequently, VHDL4CNN does not require access to DRAM, HBM, or other off-chip memory but consumes more FPGA logic, since all operations are fully unrolled.

To use the library, the provided VHDL entities need to be instantiated and parameterized in a top-level HDL.

VHDL4CNN is used within the [IBM cloudFPGA Distributed Operator Set Architectures (DOSA)](https://github.com/cloudFPGA/DOSA) compiler, which also generates all necessary HDL files automatically. Please refer to DOSA for further usage examples.

VHDL4CNN is forked from the [Haddoc2 library](https://github.com/DreamIP/haddoc2) published in 2017, but it is largely refactored and without legacy code.

Further reading about this type of architecture can be found [here](https://doi.org/10.5281/zenodo.7957659) or [here](https://arxiv.org/pdf/1712.04322.pdf).



License
----------------

VHDL4CNN is released under the Apache 2.0 License. For the original haddoc2 license and copyright, please refer to [NOTICES](./NOTICES.md).


