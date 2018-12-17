# DeepDish.jl

A simple package to load HDF5 files saved by the [DeepDish](https://github.com/uchicago-cs/deepdish) python library in Julia. Currently, only lists of simple types, dictionaries and pandas DataFrames are supported.

The only exported function is

`load_deepdish(f)`

where f is the path to the h5 file.
