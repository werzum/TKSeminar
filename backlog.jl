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


name_dict, text_dict = create_RT_csv(df_alternating,words)
using DataFramesMeta
a = @where(df_en, :full_text != "")
a = filter(x -> (x.:full_text != "",df_en)
dropmissing!(df_en)
a = @where(df_en, :Id .> in(:Id,df_ids))

#piecing together the final DF
CSV.write("df_final.csv",df_full)

df_full = DataFrame!()
df_9_10 = DataFrame(CSV.File("df_9_10.csv";threaded=false))
df_full = vcat(df_full,df_9_10)
for i in 1:8
    println(i)
    df_temp = DataFrame(CSV.File("df_$i.csv"))
    df_full = vcat(df_full,df_temp)
end

file = open("df_1.csv")
cleanfunction(string) = replace(string,"\"\"" =>"\"")
cleaned_file = IOBuffer(cleanfunction(read(file,String)))
test=CSV.read(cleaned_file,DataFrame)

haskey(dict_2,1278368973948694528)
function tweet_dict_f(words)
    tweet_dict = Array{Any}(undef,0)

    @simd for value in words
        push!(tweet_dict,JSON.parse(value))
    end
    return tweet_dict
end

#load tweets from JSON
words = readlines("df_tweets_alternating_2.jsonl", enc"UTF-16")
#build several dicts from the content
dict = tweet_dict_f(words)
dict_id = [x["id"] for x in dict]
dict_text = [x["full_text"] for x in dict]
dict_name = [x["user"]["name"] for x in dict]
dict_2 = Dict(zip(dict_id,dict_text))
dict_3 = Dict(zip(dict_id,dict_name))
#filter the big df for the ids of the tweets
small_df = @where(df_en, in.(:Id,[keys(dict_2)]))
# insertcols!(small_df,2, "full_text" => ["" for i in nrow(small_df)])
# insertcols!(small_df,3, "screen_name" => ["" for i in nrow(small_df)])
#and bring that back together here
small_df = @eachrow small_df begin
    :full_text = dict_2[:Id]
    :screen_name = dict_3[:Id]
end

#loading dfs
#df_alternating =  DataFrame!(CSV.File("df_alternating_new.csv"))
df_en_matched =  DataFrame!(CSV.File("df_en_full_text.csv"))
const df_en_const = df_en[1:1000000,:]
a = alternating_mixing(df_en)

#adjust column names so we have symbols
insertcols!(df_en,1, :Created => [Date(2013) for i in 1:nrow(df_en)])
select!(hashtag_df,Not(:CreatedAt))
#parse the dates so we can sort them
allowmissing!(df_en)
for row in eachrow(df_en)
    try
        row.:Created = Date(match(r"^[^\s]+",row.:CreatedAt).match,"m/d/y")
    catch
        row.:Created = missing
    end
end
#filter out missing dates
filter!(row->!ismissing(row.:Created), df_en)
sort!(df_en,(:Created))
#and drop old dates
select!(df_en,Not(:Created))

CSV.write("df_final_dates.csv",df_en)

dates = [Date(match(r"^[^\s]+",hashtag_df[i,:CreatedAt]).match,"m/d/y") for i in 1:nrow(hashtag_df)]
