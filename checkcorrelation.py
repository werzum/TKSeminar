import numpy as np
import pandas as pd
import matplotlib.pyplot as plt


variable_spalte1 = ("Score")
variable_spalte2 = ("univ_raw_score_overall")

df = pd.read_csv("40,000_dataset_botometer_flags.csv",sep=";",
                usecols=[variable_spalte1, variable_spalte2])


#Korrelationen
df.corr(method='pearson')
print(df.corr)



y = df[variable_spalte1]
x = df[variable_spalte2]

#np.corrcoef(x)
#print(np.corrcoef)

plt.scatter(x, y)
#plt.title('A plot to show the correlation between ' + variable_spalte1 +' and '+ variable_spalte2)
plt.xlabel('Universal Bot Score')
plt.ylabel('Sentiment Score')
#plt.plot(np.unique(x), np.poly1d(np.polyfit(x, y, 1))(np.unique(x)), color='yellow')
plt.show()

print(np.corrcoef(x, y))