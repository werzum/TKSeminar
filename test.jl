using CSV, DataFrames, LightGraphs, MetaGraphs, GraphPlot, Plots, StatsPlots, PackageCompiler, Dictionaries, Distributed, Dates
#load dataframe and find a certain ID
#df_ids = DataFrame!(CSV.File("df_ids.csv"))
df_en = DataFrame!(CSV.File("df_en.csv"))
const df_en_const = df_en[1:1000000,:]

#now lets attempt to build a network
meta_graph = MetaGraph(SimpleGraph())

#get unique IDs from the DF, add those vertices to the graph and give it the respective ID
unique_ids_from = Set(unique(df_en."From-User-Id"))
unique_ids_to = Set(unique(df_en."To-User-Id"))
const unique_ids = collect(union(unique_ids_to,unique_ids_from))
#add the vertices to the graph'
add_vertices!(meta_graph, length(unique_ids))

function create_graph(df_en,unique_ids, meta_graph)
    #create a dict with the unique ids and their position in the grap
    indexarr = [1:length(unique_ids)...]
    unique_ids_new_dict = Dictionary(unique_ids,indexarr)
    #and add the edges
    @simd for row in eachrow(df_en)
        add_edge!(meta_graph,unique_ids_new_dict[row."From-User-Id"],unique_ids_new_dict[row."To-User-Id"])
    end
end

@time create_graph(df_en_const,unique_ids, meta_graph)

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
    for i in 1:timeslots
        print("from $prev to $i time $x")
        df_temp = df_en[prev:i*x,:]
        #here we can do stuff



        
        prev = prev+x
    end
end
#
# function create_2_week_graphs(df_en, unique_ids_dict)
#     start_date = df_en[1,"Created-At"]
