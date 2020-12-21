#load tweets and select only ones of english language
df = DataFrame!(CSV.File("tweets.csv"))
df_en = filter(x -> x.Language == "en", df)
CSV.write("df_en.csv", df_en)
#get tweet IDs and save them to a new csv
df_ids = DataFrame()
df_ids."Ids" = df_en.Id
CSV.write("df_ids.csv", df_ids)
#for most RTet
df_ids_RTs = DataFrame()
df_ids_RTs.id = c.Id
CSV.write("df_ids_RTs.csv", df_ids_RTs)


create_sysimage([:Plots,:CSV,:DataFrames,:LightGraphs,:MetaGraphs, :GraphPlot,:Plots,:StatsPlots], sysimage_path="sys_plots.so", precompile_execution_file="precompile.jl")

#confirm that the last row of the tweets_RT corresponds to the last row of the RT dataframe
res = [i for i in eachrow(c) if i.Id == 1323457576927850496]
