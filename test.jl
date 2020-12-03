using CSV, DataFrames, LightGraphs, MetaGraphs, GraphPlot, Plots, StatsPlots, PackageCompiler

#load dataframe and find a certain ID
df_ids = DataFrame!(CSV.File("df_ids.csv"))
df_en = DataFrame!(CSV.File("df_en.csv"))
const df_en_const = df_en[1:100000,:]

#now lets attempt to build a network
graph = SimpleGraph()
meta_graph = MetaGraph(graph)

#get unique IDs from the DF, add those vertices to the graph and give it the respective ID
const unique_ids_from = Set(unique(df_en."From-User-Id"))
const unique_ids_to = Set(unique(df_en."To-User-Id"))
const unique_ids = collect(union(unique_ids_to,unique_ids_from))
#add the vertices to the graph'
add_vertices!(meta_graph, length(unique_ids))

function create_graph(df_en,unique_ids)
    #create a dict with the unique ids and their position in the grap
    for (index,val) in enumerate(unique_ids)
        unique_ids_dict[val] = index
    end
    #and add the edges
    for row in eachrow(df_en)
        add_edge!(meta_graph,unique_ids_dict[row."From-User-Id"],unique_ids_dict[row."To-User-Id"])
    end
end

@time create_graph(df_en_const,unique_ids)

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



#
# function create_2_week_graphs(df_en, unique_ids_dict)
#     start_date = df_en[1,"Created-At"]
