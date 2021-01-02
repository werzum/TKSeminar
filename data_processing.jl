
#load dataframe and find a certain ID
df_ids = DataFrame!(CSV.File("df_ids_alternating.csv"))[1:end,"Id"]
df_ids = DataFrame!(:ID => df_random[1:end,"Id"])
CSV.write("df_ids_2",df_ids)
df_en = DataFrame!(CSV.File("Data\\df_en.csv"))
df_alternating =  DataFrame!(CSV.File("df_alternating_new.csv"))
df_en_matched =  DataFrame!(CSV.File("df_en_full_text.csv"))

const df_en_const = df_en[1:1000000,:]
a = alternating_mixing(df_en)

for row in eachrow(df_en)
    try
        row."full_text" = text_dict[row.Id]
    catch
    end
    try
        row."screen_name" = name_dict[string(row."From-User-Id")]
    catch
    end
end

function alternating_mixing(df_en)
    #select the 1/3 most retweeted messages
    df_rts = sort(df_en, (:"Retweet-Count"))
    df_rts = df_rts[end-333333:end,:]

    #get randomly selected tweets not in the retweet dataframe
    df_random = df_en[shuffle(axes(df_en,1)),:]
    # #select 1ml randomly to speed things up
    # df_random = df_random[1:1000000,:]
    # rows = eachrow(df_rts)
    # df_random = filter(row->!in(row."From-User-Id",rows),df_random)
    df_random = df_random[1:200000,:]

    #generate a dict to rapidly count the number of tweets from each user
    unique_ids_from = Set(unique(df_en."From-User-Id"))
    a = zip(unique_ids_from,Array{Int}(undef,length(unique_ids_from)))
    tweets_from_dict = Dict(a)
    #and then count the tweets in the df
    for row in eachrow(df_en)
        tweets_from_dict[row."From-User-Id"] += 1
    end

    #create a array so we can sort this (out)
    keys = Array{Int}(undef,0)
    vals = Array{Int}(undef,0)
    #extract the keys to sort them
    for (index,val) in enumerate(tweets_from_dict)
        if(val.first)!=0
            push!(keys, val.first)
            push!(vals, val.second)
        end
    end
    result = hcat(keys,vals)
    sort!(result;dims=1)

    #and now draw tweets from the dataframe
    #select tweets from the 200.000 most active users
    result_active = result[end-200000:end,1]
    # rows = eachrow(result_active)
    df_active = filter(row->in(row."From-User-Id",result_active),df_en)
    # #filter the duplicates from the random and retweet dataframe
    # rows = eachrow(df_rts)
    # df_active = filter(row->!in(row."From-User-Id",rows),df_active)
    # rows = eachrow(df_random)
    # df_active = filter(row->!in(row."From-User-Id",rows),df_active)
    print(nrow(df_active))
    #and the reduce this so we remain with 3330000 tweets
    df_active = df_active[shuffle(axes(df_active,1)),:]
    df_active = df_active[1:333333,:]

    #merge the dataframes and eliminate dupes
    df_return = vcat(df_rts,df_random,df_active)
    #and return the df
    return df_return
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

function create_RT_csv(df,words)

    #create dict with the texts
    tweet_ID_text_dict = Dict()
    tweet_ID_name_dict = Dict()
    for elm in words
        elm = JSON.parse(elm)
        tweet_ID_text_dict[elm["id"]] = elm["full_text"]
        tweet_ID_name_dict[elm["in_reply_to_user_id_str"]] = elm["in_reply_to_screen_name"]
    end
    #build a dict of the id - screen names
    #and add it to the RT df
    insertcols!(df_en,2, "full_text" => ["" for i in nrow(df_en)])
    insertcols!(df_en,3, "screen_name" => ["" for i in nrow(df_en)])
    for row in eachrow(df)
        try
            row."full_text" = tweet_ID_text_dict[row.Id]
        catch
        end
        try
            row."screen_name" = tweet_ID_name_dict[string(row."From-User-Id")]
        catch
        end
    end
    #save the DF
    CSV.write("df_en_full_text.csv",a)
    return tweet_ID_name_dict,tweet_ID_text_dict
end

name_dict, text_dict = create_RT_csv(df_alternating,words)
using DataFramesMeta
a = @where(df_en, :full_text != "")
a = filter(x -> (x.:full_text != "",df_en)
dropmissing!(df_en)
a = @where(df_en, :Id .> in(:Id,df_ids))

df_en[1,"Id"]
push!(df_ids,1278368973948694528)
in(1278368973948694528,df_ids)

# a,b,c = create_selected_dfs(df_en)
# write_df = DataFrame("Id" => a[:,"Id"])

#TODO: IDEAS for analyzing
#use of hashtag and negativity/positivity
#most active users (most from)-> what did they spread?
#most influential users (most RTs) -> what did they spread?
#network with most RTetd content
#color positivity/negativity in responses

function create_graph(df_en)
    meta_graph = MetaGraph(SimpleGraph())
    #get unique IDs from the DF, add those vertices to the graph and give it the respective ID
    unique_ids_from = Set(unique(df_en."From-User-Id"))
    unique_ids_to = Set(unique(df_en."To-User-Id"))
    unique_ids = collect(union(unique_ids_to,unique_ids_from))
    #add the vertices to the graph'
    add_vertices!(meta_graph, length(unique_ids))
    #create a dict with the unique ids and their position in the grap
    indexarr = [1:length(unique_ids)...]
    unique_ids_new_dict = Dictionary(unique_ids,indexarr)
    nodelabels = []
    for id in unique_ids
        if haskey(name_dict,string(id))
            #print("found key $id")
            push!(nodelabels, name_dict[string(id)])
        else
            #print("did not find key $id")
            push!(nodelabels, "")
        end
    end
    #and add the edges
    @simd for row in eachrow(df_en)
        add_edge!(meta_graph,unique_ids_new_dict[row."From-User-Id"],unique_ids_new_dict[row."To-User-Id"])
    end
    return meta_graph, nodelabels
end

graph, labels = create_graph(c[end-2005:end,:])
plot_graph(graph,labels)


#which functions?
#for each x days in timeframe
function for_x_days(x,df_en)
    #compute the time passed
    first_day = Date(df_en[1,"Created-At"][1:end-8],"m/d/y")
    last_day = Date(df_en[end,"Created-At"][1:end-8],"m/d/y")
    passed_days = last_day-first_day
    #slice these days in x pieces, select the range in the DataFrame
    timeslots = Int(ceil(passed_days.value/x))
    prev = 1
    df_share = Int(round(nrow(df_en)/timeslots))
    print("timeslts are $timeslots")
    for i in 1:timeslots
        print("from $prev to $i time $x")
        df_temp = df_en[prev:i*df_share,:]
        #here we can do stuff
        #create the graph
        print("tempdf has $(nrow(df_temp))")
        graph = create_graph(df_temp)
        #and plot it
        plot_graph(graph)
        #also compute the centralities
        #centralities(graph)
        #and increment the counter
        prev = prev+df_share
    end
end
