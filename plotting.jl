

function centralities(meta_graph)
    #show a degree histogram
    create_histogram(meta_graph)

    #these are too slow for 1ml networks
    #print the global cc
    print("global cc is $(global_clustering_coefficient(meta_graph))")
    #and the betweenness with 0s removed to shrink the graph somewhat
    betweenness = betweenness_centrality(meta_graph)
    betweenness_filtered = filter(x->x!=0, betweenness)
    display(histogram(betweenness_filtered, ylabel="Betweenness"))
end

function plot_graph(meta_graph,labels)
    #plot the graph with node labels for the underlying graph
    gplot(meta_graph;nodelabel = labels, NODELABELSIZE=0.5, layout=stressmajorize_layout)
end

plot = plot_graph(graph,labels)
create_histogram(graph)
centralities(graph)

function create_histogram(meta_graph)
    display(StatsPlots.histogram(degree_histogram(meta_graph),yaxis=(:log10), bins=200, ylabel="Degree"))
end
