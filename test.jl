using CSV, DataFrames, LightGraphs, MetaGraphs, GraphPlot, Plots, StatsPlots, PackageCompiler, Dictionaries, Distributed, Dates
#load dataframe and find a certain ID
#df_ids = DataFrame!(CSV.File("df_ids.csv"))
df_en = DataFrame!(CSV.File("df_en.csv"))
#added an index since accessing the row index during iteration seems impossible (or well hidden)
# CSV.write("df_en.csv",df_en)
#df_en.:index = collect(1:nrow(df_en))
const df_en_const = df_en[1:1000000,:]

#select the million most retweeted messages
df_rts = sort!(df_en, (:"Retweet-Count"))
df_rts = df_rts[end-1000000:end,:]

#select each nth row to reduce the dataframe to 1 million tweets
df_1ml = filter(row->(row.:index%21)==0,df_en)

#select the million most polarized tweets
df_pol = sort!(df_en, (:"Score"))
df_pol = vcat(df_pol[1:500000,:],df_pol[end-500000:end,:])


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
    #and add the edges
    @simd for row in eachrow(df_en)
        add_edge!(meta_graph,unique_ids_new_dict[row."From-User-Id"],unique_ids_new_dict[row."To-User-Id"])
    end
    return meta_graph
end

@time create_graph(df_en_const)

function centralities(meta_graph)
    #show a degree histogram
    display(StatsPlots.histogram(degree_histogram(meta_graph)))
    #print the global cc
    print("global cc is $(global_clustering_coefficient(meta_graph))")
    #and the betweenness with 0s removed to shrink the graph somewhat
    betweenness = betweenness_centrality(meta_graph)
    betweenness_filtered = filter(x->x!=0, betweenness)
    display(histogram(betweenness_filtered))
end

function plot_graph(meta_graph)
    display(gplot(meta_graph))
end

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
    for i in 1:timeslots
        print("from $prev to $i time $x")
        df_temp = df_en[prev:i*df_share,:]
        #here we can do stuff
        #create the graph
        graph = create_graph(df_temp)
        #and plot it
        plot_graph(graph)
        #also compute the centralities
        centralities(graph)
        #and increment the counter
        prev = prev+df_share
    end
    end
end
#
# function create_2_week_graphs(df_en, unique_ids_dict)
#     start_date = df_en[1,"Created-At"]
