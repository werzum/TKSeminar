#load tweets and select only ones of english language
df = DataFrame!(CSV.File("tweets.csv"))
df_en = filter(x -> x.Language == "en", df)
CSV.write("df_en.csv", df_en)
#get tweet IDs and save them to a new csv
df_ids = DataFrame()
df_ids."Ids" = df_en.Id
CSV.write("df_ids.csv", df_ids)


create_sysimage([:Plots,:CSV,:DataFrames,:LightGraphs,:MetaGraphs, :GraphPlot,:Plots,:StatsPlots], sysimage_path="sys_plots.so", precompile_execution_file="precompile.jl")
