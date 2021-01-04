
#load dataframe
df_en = DataFrame!(CSV.File("df_final.csv"))

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

#for each x days in timeframe
function for_x_days(x,df_en,func)
    first_day = df_en[1,:Created]
    current_day = df_en[1,:Created]
    nrows = 1
    #container
    arr = []
    #a sweet exit condition
    while nrows>0
        #select all days between current_day and current_day+x days
        temp_df = @where(df_en, :Created.>=current_day,
                                :Created.<current_day+Dates.Day(x))
        #check if there are entries and break if there are none
        nrows = nrow(temp_df)
        println(nrows)
        nrows == 0 && continue
        #call the callback
        result = func(temp_df)
        #and add the output to the array which is returned
        push!(arr,result)
        #increment the counter
        current_day = current_day+Dates.Day(x)
    end
    return arr
end

for_x_days(7,df_en,tf)
