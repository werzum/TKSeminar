using CSV, DataFrames, LightGraphs, MetaGraphs, GraphPlot, Plots, StatsPlots

#load tweets and select only ones of english language
df = DataFrame!(CSV.File("tweets.csv"))
df_en = filter(x -> x.Language == "en", df)
CSV.write("df_en.csv", df_en)
#get tweet IDs and save them to a new csv
df_ids = DataFrame()
df_ids."Ids" = df_en.Id
CSV.write("df_ids.csv", df_ids)

#load dataframe and find a certain ID
df_ids = DataFrame!(CSV.File("df_ids.csv"))
df_en = DataFrame!(CSV.File("df_en.csv"))
df_en = df_en[1:100000,:]
const df_en_const = df_en

#now lets attempt to build a network
graph = SimpleGraph()
meta_graph = MetaGraph(graph)

#get unique IDs from the DF, add those vertices to the graph and give it the respective ID
const unique_ids_from = Set(unique(df_en."From-User-Id"))
const unique_ids_to = Set(unique(df_en."To-User-Id"))
const unique_ids = collect(union(unique_ids_to,unique_ids_from))
unique_ids_dict = Dict()
#add the vertices to the graph'
add_vertices!(meta_graph, length(unique_ids))

#create a dict with the unique ids and their position in the grap
for (index::Int64,val::Int64) in enumerate(unique_ids)
    unique_ids_dict[val] = index
end
const unique_ids_dict_const = unique_ids_dict

@time create_graph(df_en_const,unique_ids,unique_ids_dict_const)

function create_graph(df_en,unique_ids,unique_ids_dict)
    for (index,val) in enumerate(unique_ids)
        #set the id for the edge
        set_prop!(meta_graph, index, :id, val)

        #and generate an edge between all tweets of this one and its targets
        #find all tweets from this user
        tweets_between = findall((df_en."To-User-Id" .== val).|(df_en."From-User-Id" .== val))
        #index is this users number in the metagraph
        user = index
        user_id = val
        #iterate over all outgoing tweets
        for (index,val) in enumerate(tweets_between)
            this_row = df_en[val,:]
            #set the other receiving user
            target_user = 0
            if user_id == this_row."To-User-Id"
                target_user = this_row."From-User-Id"
            elseif user_id == this_row."From-User-Id"
                target_user = this_row."To-User-Id"
            else
                print("user $user_id not found in row $this_row")
            end
            #and add an edge between this and the receiving user. Hopefully twice as fast
            add_edge!(meta_graph,user,unique_ids_dict[target_user])
        end
    end
end

function centralities()
    #show a degree histogram
    StatsPlots.histogram(degree_histogram(meta_graph))
    #print the global cc
    print(global_clustering_coefficient(meta_graph))
    #and the betweenness with 0s removed to shrink the graph somewhat
    betweenness = betweenness_centrality(meta_graph)
    betweenness_filtered = filter(x->x!=0, betweenness)
    histogram(betweenness_filtered)
end

function plot_graph()
    gplot(meta_graph)
end

function create_2_week_graphs(df_en, unique_ids_dict)
    start_date = df_en[1,"Created-At"]
