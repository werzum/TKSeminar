#TODO: IDEAS for analyzing
#use of hashtag and negativity/positivity
#most active users (most from)-> what did they spread?
#most influential users (most RTs) -> what did they spread?
#network with most RTetd content
#color positivity/negativity in responses

#hashtag use
hashtag_df = @where(df_en, occursin.("#",:full_text))
hashtag_df = sort(hashtag_df,"Created-At")
#add column with only hashtag
insertcols!(hashtag_df,4,"Hashtag" => [[] for i in nrow(hashtag_df)])
#regex the full_text so that only hashtags remain
for row in eachrow(hashtag_df)
    matches = collect(eachmatch(r"(#[^\s]+)", row."full_text"))
    row.:Hashtag = (x->String(x.match)).(matches)
end
