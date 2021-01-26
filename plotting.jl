

function centralities(meta_graph)
    #show a degree histogram
    create_histogram(meta_graph)

    #these are too slow for 1ml networks
    #print the global cc
    print("global cc is $(global_clustering_coefficient(graph))")
    #and the betweenness with 0s removed to shrink the graph somewhat
    betweenness = betweenness_centrality(graph)
    betweenness_filtered = filter(x->x!=0 && x<0.01, betweenness)
    display(histogram(betweenness_filtered, ylabel="Betweenness", label=""))
end

create_histogram(graph)

function plot_graph(meta_graph, labels)
    #plot the graph with node labels for the underlying graph
    draw(PNG("mygraph.png", 100cm, 100cm), gplot(meta_graph, nodelabel = labels, NODELABELSIZE=5, layout=stressmajorize_layout))
end

plot_graph(graph,labels)
gplot(graph;nodelabel = labels)

# create_histogram(graph)
# centralities(graph)

function create_histogram(meta_graph)
    display(StatsPlots.histogram(degree_histogram(meta_graph),yaxis=(:log10), bins=250, ylabel="Degree", label="", xformatter=:plain))
end

histogram(df_en[1:1000,"Negativity"])
histogram!(df_en[1:1000,"Positivity"])


function posneg_histogram(df_en)
    dropmissing!(df_en)
    filter!(x -> (x."Negativity" != 0 && x."Positivity" !=0),df_en)
    histogram(df_en[:,"Negativity"])
    display(histogram!(df_en[:,"Positivity"]))
end

for_x_days(14,df_en,posneg_histogram)
