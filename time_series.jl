#TODO: IDEAS for analyzing
#use of hashtag and negativity/positivity
#most active users (most from)-> what did they spread?
#most influential users (most RTs) -> what did they spread?
#network with most RTetd content
#color positivity/negativity in responses

#hashtag use
hashtag_df = @where(df_en, occursin.("#",:FullText))
hashtag_df = sort(hashtag_df,:Created)
#add column with only hashtag
insertcols!(hashtag_df,4,:Hashtag => [[] for i in nrow(hashtag_df)])
#regex the full_text so that only hashtags remain
for row in eachrow(hashtag_df)
    matches = collect(eachmatch(r"(#[^\s]+)", row.:FullText))
    row.:Hashtag = (x->String(x.match)).(matches)
end

function top_hashtags(df)
    a = df[1:end,:Hashtag]
    #splat all hashtags to a counter
    dict = Dict(counter(vcat(a...)))

    #and find the top 3 entries
    top1 = findmax(dict)
    delete!(dict, top1[2])
    top2 = findmax(dict)
    delete!(dict, top2[2])
    top3 = findmax(dict)

    return [top1,top2,top3]
end
#generate toptags
toptags = for_x_days(7,hashtag_df,top_hashtags)
#get the top hashtags
top1count = [x[1][1] for x in toptags]
top1tags = [x[1][2] for x in toptags]
plot(top1count)
#generate the annotations
anno = [(i, top1count[i], text(top1tags[i],8)) for i in 1:length(toptags)]
annotate!(anno)

#do it again with second highest tags
top2count = [x[2][1] for x in toptags]
top2tags = [x[2][2] for x in toptags]
plot!(top2count)
anno = [(i, top2count[i], text(top2tags[i],8)) for i in 1:length(toptags)]
annotate!(anno)
