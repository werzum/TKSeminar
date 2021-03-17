#Find #retweets for bots, compare to average

function compute_retweets(df_en)
    rt_dict = Dict(zip(collect(df_en."ScreenName"),zeros(nrow(df_en))))
    #5. and iterate over the df to count the retweets
    @simd for row in eachrow(df_en)
        if !occursin("RT @", row."FullText")
            rt_dict[row."ScreenName"] += row."Retweet-Count"
        end
    end

    println("mean is $(mean(values(rt_dict)))")
    return rt_dict
end

rts = compute_retweets(df_en)
histogram(collect(values(rts)))
#0.741 for df_en
rts1 = compute_retweets(df_hashtag)
#0.61 for bots
histogram(collect(values(rts1)))
#even more with 0 retweets

function compute_activity(df_en)
    rt_dict = Dict(zip(collect(df_en."From-User-Id"),zeros(nrow(df_en))))
    @simd for row in eachrow(df_en)
        rt_dict[row."From-User-Id"] += 1
    end
    println("mean is $(mean(values(rt_dict)))")
    return rt_dict
end

act = compute_activity(df_en)
histogram(collect(values(act)))
act1 = compute_activity(df_hashtag)
histogram(collect(values(act1)))
