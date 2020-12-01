using CSV, DataFrames, LightGraphs, MetaGraphs, GraphPlot

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
findall(df_ids.Ids .== 1282356402242097154)
df_ids[1190584,:]

#now lets attempt to build a network
#with a smaller df at first, create a graph
df_en = df_en[1:10000,:]
graph = SimpleGraph()
meta_graph = MetaGraph(graph)

#get unique IDs from the DF, add those vertices to the graph and give it the respective ID
unique_ids_from = Set(unique(df_en."From-User-Id"))
unique_ids_to = Set(unique(df_en."To-User-Id"))
unique_ids = union(unique_ids_to,unique_ids_from)
add_vertices!(meta_graph, length(unique_ids))
for (index,val) in enumerate(unique_ids)
    set_prop!(meta_graph, index, :id, val)
end

#responses are edges, add them to the network
@time for row in eachrow(df_en)
    add_edge!(meta_graph,first(filter_vertices(meta_graph,:id,row."From-User-Id")),first(filter_vertices(meta_graph,:id,row."To-User-Id")),:tweetId, row.Id)
end
#and plot it
gplot(meta_graph)
