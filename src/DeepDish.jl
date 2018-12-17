module DeepDish

import HDF5
import DataFrames

export load_deepdish

function load_deepdish(f)
    data = h5open(f, "r") do file
        recursive_load(file)  # alternatively, say "@write file A"
    end
    return data
end

function recursive_load(g)
    ret_dict = Dict{String,Any}()
    if g isa HDF5Group || g isa HDF5File
        title = read(attrs(g)["TITLE"])
        if isa(title, String) && startswith(title, "list:")
            n_items = parse(Int, split(title, ":")[2])
            return ["i$i" in names(attrs(g)) ?
                    read(attrs(g)["i$i"]) : recursive_load(g["i$i"])
                 for i in 0:n_items-1]
        elseif isa(title, String) && startswith(title, "dict:")
            merge!(ret_dict,
                   Dict{String, Any}(k=>read(attrs(g)[k])
                        for k in names(attrs(g))
                        if !in(k, ["CLASS", "TITLE", "VERSION"])))

        elseif "pandas_type" in names(attrs(g))
            return load_pytable(g)
        end
        return merge(ret_dict, Dict{String, Any}(split(name(n),"/")[end]=>recursive_load(n) for n in g))
    elseif read(attrs(g)["CLASS"])=="CARRAY"
        return read(g)
    else
        return nothing
    end
end

function load_pytable(obj)
    df = DataFrames.DataFrame()
    index = read(obj["axis0"])
    columns = read(obj["axis1"])
    n_blocks = read(attrs(obj)["nblocks"])
    for i_block in 1:n_blocks
        block_cols = read(obj["block$(i_block-1)_items"])
        block_vals = read(obj["block$(i_block-1)_values"])
        for (i_col, colname) in enumerate(block_cols)
            setproperty!(df, Symbol(colname), block_vals[i_col, :])
        end
    end
    return df
end

end # module
