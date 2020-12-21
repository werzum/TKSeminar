
#load dataframe and find a certain ID
#df_ids = DataFrame!(CSV.File("df_ids.csv"))
df_en = DataFrame!(CSV.File("df_en.csv"))
const df_en_const = df_en[1:1000000,:]

function alternating_mixing(df_en)
    #select the 1/3 most retweeted messages
    df_rts = sort!(df_en, (:"Retweet-Count"))
    df_rts = df_rts[end-3330000:end,:]

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
    #select tweets from the 100.000 most active users
    result_active = result[end-100000:end]
    df_active = filter(row->in(row."From-User-Id",result_active),df_en)
    #and the reduce this so we remain with 3330000 tweets
    reduce_number = 333333/nrow(df_active)
    df_active = filter(row->(row.:index%reduce_number)==0,df_en)

    #the last part gets randomly selected
    df_random = filter(row->(row.:index%60)==0,df_en)

    #merge the dataframes and eliminate dupes
    df_return = vcat(df_rts,df_active,df_random)
    #and return the df
    return df_return
end

function create_RT_csv()
    #read the highest RT texts
    tweet_dict = JSON.parsefile("tweets_RT_UTF8.txt")
    #create dict with the texts
    tweet_ID_text_dict = Dict()
    tweet_ID_name_dict = Dict()
    for elm in tweet_dict
        tweet_ID_text_dict[elm["id"]] = elm["full_text"]
        tweet_ID_name_dict[elm["in_reply_to_user_id_str"]] = elm["in_reply_to_screen_name"]
    end
    #build a dict of the id - screen names
    #and add it to the RT df
    insertcols!(c,2, "full_text" => ["" for i in nrow(c)])
    insertcols!(c,3, "screen_name" => ["" for i in nrow(c)])
    for row in eachrow(c)
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
    #CSV.write("df_RT.csv",c)
    return tweet_ID_name_dict,tweet_ID_text_dict
end

name_dict, text_dict = create_RT_csv()

#added an index since accessing the row index during iteration seems impossible (or well hidden)
# CSV.write("df_en.csv",df_en)
#df_en.:index = collect(1:nrow(df_en))

function create_selected_dfs(df_en)
    #select the million most retweeted messages
    df_rts = sort!(df_en, (:"Retweet-Count"))
    df_rts = df_rts[end-1000000:end,:]

    #select each nth row to reduce the dataframe to 1 million tweetssoun
    df_1ml = filter(row->(row.:index%21)==0,df_en)

    #select the million/100.000 most polarized tweets
    df_pol = sort!(df_en, (:"Score"))
    df_pol = vcat(df_pol[1:50000,:],df_pol[end-50000:end,:])

    return df_rts,df_1ml,df_pol
end

a,b,c = create_selected_dfs(df_en)
# write_df = DataFrame("Id" => a[:,"Id"])
# CSV.write("df_ids_RTs.csv",write_df)

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
