using CSV, DataFrames, LightGraphs, MetaGraphs, GraphPlot, Plots, StatsPlots, PackageCompiler

create_sysimage([:Plots,:CSV,:DataFrames,:LightGraphs,:MetaGraphs, :GraphPlot,:Plots,:StatsPlots], sysimage_path="sys_plots.so", precompile_execution_file="precompile.jl")
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
const df_en_const = df_en[1:1000000,:]

#now lets attempt to build a network
graph = SimpleGraph()
meta_graph = MetaGraph(graph)

#get unique IDs from the DF, add those vertices to the graph and give it the respective ID
const unique_ids_from = Set(unique(df_en."From-User-Id"))
const unique_ids_to = Set(unique(df_en."To-User-Id"))
const unique_ids = collect(union(unique_ids_to,unique_ids_from))
const unique_ids_dict = Dict()
#add the vertices to the graph'
add_vertices!(meta_graph, length(unique_ids))

@time create_graph(df_en_const,unique_ids,unique_ids_dict)

function create_graph(df_en,unique_ids,unique_ids_dict)
    #create a dict with the unique ids and their position in the grap
    for (index,val) in enumerate(unique_ids)
        unique_ids_dict[val] = index
    end
    #and add the edges
    for row in eachrow(df_en)
        add_edge!(meta_graph,unique_ids_dict[row."From-User-Id"],unique_ids_dict[row."To-User-Id"])
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
