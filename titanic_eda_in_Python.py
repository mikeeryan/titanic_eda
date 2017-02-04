# -*- coding: utf-8 -*-
"""

Grand Project - for portfolio
Step01 - exploratory data analysis
Titanic data - follow R's EDA methodology/rubric
jupyter notebook "C:\Users\rf\Google Drive\Education\Python\codes\Udacity\Intro_Data_Analysis\grand\titanic_eda.ipynb"

Start putting into the jupyter notebook

"""
#Load libraries and set working directory - import whole libraries to avoid confusion
import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import scipy as sp

from sklearn import linear_model 
#did not work when imported just sklearn

#%matplotlib inline
#put in jupyter to make the plots show up

#Set the correct working directory
print os.getcwd()
os.chdir(r"C:\Users\rf\Google Drive\Education\R\Rwork")
print os.getcwd()
print os.listdir(r"C:\Users\rf\Google Drive\Education\R\Rwork")

#Read the data and review the basic descriptive information
inputdata='titanic_data.csv'
t=pd.read_csv(inputdata) #load data into a pandas dataframe
# Automatically produced summary of the data set
print "Hello, world! Let's review my dataset."
print "\n"
print 'My data set is',inputdata
print 'I imported it into a',type(t)
print 'It has',t.shape[1],'columns and',t.shape[0],'rows.'
print "Here are the columns and their data types in the dataset:"
print t.dtypes
print "\n"
print ("Here are a few rows from this data frame:")
print t.head()
print "\n"
print "Also let's create a variable Minor - if Age <18. It will have missing values when Age does."
#how to make it missing? multi step process but works
t['Minor']=t['Age']
t.loc[(t['Age'] >=0), 'Minor'] = False
t.loc[(t['Age'] >=0) & (t['Age'] <18), 'Minor'] = True
print "\n"
print "Also add dummies for gender which will be useful later."
sdummies = pd.get_dummies(t['Sex'])
t = t.join(sdummies)

#####################################################

print ("Summary statistics for the whole data set")
print t.describe()
print "\n"
print ("Survived will be my Y, Gender is the first X, Age is continuous but has missing values (I will not impute though)")
print "\n"
print ("Quick means (ignoring the missing values by default)")
print t.mean(axis=0)
print "\n"
print ("Let's also look at the distribution by requesting custom percentiles.")
print t.describe(percentiles=[0.01,.25, .5, .75, 0.99])
print "\n"
print ("Let's also describe the categorical variables.")
print t.describe(include=['object'])

#######################################################
# Univariate Plots and Analysis
### Single variable tabulations

print ("Count of missing Age and also same for minor")
survived = t.loc[:,['Survived']]
sur_count= survived.apply(pd.value_counts).fillna(0)
print sur_count
age = t.loc[:,['Age']]
print ("How many rows have missing for Age?")
print age.shape[0] - age.dropna().shape[0] 
minor = t.loc[:,['Minor']]
print ("How many rows have missing for Minor?")
print minor.shape[0] - minor.dropna().shape[0] 
print ("OK, just as expected.")
print "\n"
print ("Frequency of categoricals")
sex = t.loc[:,['Sex']]
sex_count = sex.apply(pd.value_counts).fillna(0)
print sex_count
pclass = t.loc[:,['Pclass']]
pclass_count = pclass.apply(pd.value_counts).fillna(0)
print pclass_count

#Bar Charts
#http://pandas.pydata.org/pandas-docs/stable/generated/pandas.DataFrame.plot.html#pandas.DataFrame.plot
#https://bespokeblog.wordpress.com/2011/07/11/basic-data-plotting-with-matplotlib-part-3-histograms/

print t['Survived'].plot(kind='hist',bins=2,xticks=np.arange(0, 2, 1)
    ,title='Frequency of Survived',legend=True,color='grey')
#this plot is a method for pandas dataframe
print t['Pclass'].plot(kind='hist',bins=3,xticks=np.arange(1, 4, 1)
    ,title='Frequency of Pclass',legend=True,color='blue')
    
#for categoricals - aggregate first
print sex_count.plot(kind='bar',title='Gender distribution',legend=True,color='pink')

###Fancier Charts - stacked bar chart by survived and gender 
#- need to crosstab first
sur_by_sex = pd.crosstab(t.Survived,t.Sex)
sur_by_sex
sur_by_sex.plot(kind='bar', stacked=True)

#The normalized version as well
sur_by_sex_pcts = sur_by_sex.div(sur_by_sex.sum(1).astype(float), axis=0)
sur_by_sex_pcts.plot(kind='bar', stacked=True)

#Histogram and Density plot of Age
print t['Age'].hist(bins=50)

#Histogram and Density plot on the percent scale
hist_age = t['Age'].hist(bins=50 , normed=True, color='red')
dens_age = t['Age'].plot(kind='kde' , color='blue')
print hist_age.set_xlim((0,70))


######################################################
# Bivariate Plots and Analysis
#First, let's drill down into the data
print sur_count
print pd.crosstab(t.Survived, t.Sex, margins=True)
print pd.crosstab(t.Survived, t.Pclass, margins=True)
print t.pivot_table(['Age'], index=['Survived','Sex'], columns='Pclass',margins=True)

#now how to plot these?
#print sur_count.plot(kind='bar')
#percent?
spct = np.round((sur_count / sur_count.sum() * 100))
print sur_count, "\n","\n", spct
print spct.plot(kind='bar')

#Now let's do a survived by gender box chart
sg = pd.DataFrame(pd.crosstab(t.Survived, t.Sex)) 
sg2 = sg / float(sur_count.sum())
print sg2.plot(kind='bar')

#Let's make a faceted chart
#using seaborn http://seaborn.pydata.org/examples/faceted_histogram.html
g = sns.FacetGrid(t, row="Sex", col="Survived", margin_titles=True, row_order=["female", "male"])
age_bins = np.arange(0, 70, 5)
g.map(plt.hist, 'Age', bins=age_bins, color="steelblue")
#need to run all these lines together to avoid errors

# Almost mirror image, but is it statistically significant? Let’s test by Anova.
# need to test separately for survivors and dead by sex
# but first - means by each segment first. 
age_gr = t['Age'].groupby([t['Sex'], t['Survived']]).mean().unstack()
print (age_gr)
# Might be a significant difference among the dead.

s1 = t[t.Survived.isin([1])]
s0 = t[t.Survived.isin([0])]
#refuses to subset
t2 = t.loc[t.Age.notnull()]
age_gr2 = t2.Age.groupby([t2.Sex, t2.Survived]).groups
age_gr2
age_list = np.array(t['Age']) #need to load into np.array, and indexes look at the original t - dataframe!
m1 = age_list[age_gr2['male',1]] 
m0 = age_list[age_gr2['male',0]]
f1 = age_list[age_gr2['female',1]]
f0 = age_list[age_gr2['female',0]]

print ("First Anova test for the survivors.")
print sp.stats.f_oneway(m1,f1)
print ("No significant difference for survivors.")
print  "\n"
print sp.stats.f_oneway(m0,f0)
print ("But significant for the dead - the men who died were older than the women who died.")


########################################################

#Association analysis (Pearson's chi-sq test) Gender and Class vs survived - is the different significant?
# http://docs.scipy.org/doc/scipy-0.15.1/reference/stats.html
# http://hamelg.blogspot.com/2015/11/python-for-data-analysis-part-25-chi.html

print ("Create a frequency table first.")
freq01 = pd.crosstab(t.Sex, t.Survived, margins=True)
print freq01
freq01t = sp.stats.chi2_contingency(freq01)
print "\n"
print ("Here are the expected values.")
print freq01t[3]
print "\n"
print ("Here is the pvalue.")
print freq01t[1]
print ("Yes, definitely significant difference in survival between the two sexes.")

#do the results match SAS? Yes, results match exactly!

#Now also look at the minors only
t3 = t.loc[t.Minor==True]
freq02 = pd.crosstab(t3.Sex, t3.Survived, margins=True)
print freq02
print "\n"
print ("Here are the expected values.")
freq02t = sp.stats.chi2_contingency(freq02)
print freq02t[3]
print "\n"
print ("Here is the pvalue.")
print freq02t[1]
print ("Yes, also significant.")
print "\n"
print ("Calculate Suvived percentages by gender.")
fs = round((freq02.ix['female'][1]) / (freq02.ix['female']['All'] * 1.00) * 100)
ms = round((freq02.ix['male'][1]) / (freq02.ix['male']['All'] * 1.00) * 100)
print "Survival for women was at",fs,"percent." 
print "Survival for men was at",ms,"percent." 

#Yes, males were less likely to survive, and the pattern holds even for minors.Note that there is an almost the same number of male and female minors: 58 and 55. But while 69.1% of females survived, only 39.7% of males survived.
#Let’s look at the distribution of Age for minors separately for males and females

g3 = sns.FacetGrid(t3, row="Sex", col="Survived", margin_titles=True, row_order=["female", "male"])
age_bins3 = np.arange(0, 18, 5)
g3.map(plt.hist, 'Age', bins=age_bins3, color="steelblue")

#This chart really make it obvious - even among minors (look at 15 year olds), men were less likely to survive. It also suggests that even among minors, the older ones were less likely to survive. This calls for a regression to estimate the marginal effects on probability of survival.
#How will the box chart looks like for minors?
sgm = pd.DataFrame(pd.crosstab(t3.Survived, t3.Sex)) 
sgm2 = sg / float(sur_count.sum())
print sgm2.plot(kind='bar')

#Looks similiar to the overall chart above. Shows that Minor or not, males were still less likely to survive.

#Multivariate Plots And Analysis
#Distribution of survival by age faceted by gender
#need a linear plot
# http://nbviewer.jupyter.org/gist/fonnesbeck/5850463
# pick a few useful pieces from it

#http://seaborn.pydata.org/generated/seaborn.regplot.html
print ("Overall linear probability plot.")
sns.regplot(x='Age', y='Survived', data=t, y_jitter=0.1, lowess=True)
sns.despine()


tm = t.loc[t.Sex=='male']
tf = t.loc[t.Sex=='female']
print ("For females")
sns.regplot(x='Age', y='Survived', data=tf, y_jitter=0.1, lowess=True)
sns.despine()

print ("For males")
sns.regplot(x='Age', y='Survived', data=tm, y_jitter=0.1, lowess=True)
sns.despine()
#now put this into a grid

#Pretty stark difference by sex
#Let’s build a Linear probability model first
#Disclaimer: I will not create training/validation set and score as usual
#Linear probability model - Age and Pclass
res = pd.stats.api.ols(y=t2.Survived, x=t2[['Age','Pclass']])
print res
#negative sign on age and pclass
#what if we add sex as well? 
#Linear probability model - Age and Pclass and Sex
res2 = pd.stats.api.ols(y=t2.Survived, x=t2[['Age','Pclass','female']])
print res2
#Age and pclass stay negative and female has a positive sign - the signs are useful to us for significant parameters

#Let’s build a logistic regression to verify and get the odds as well

#Logistic Regression -scikit or ?
#http://scikit-learn.org/stable/modules/generated/sklearn.linear_model.LogisticRegression.html

logreg = linear_model.LogisticRegression()
# now for logistic regression
Yvar = t2[['Survived']]
Xvar = t2[['Age','Pclass']]
log01 = logreg.fit(Xvar, Yvar)

# Check trained model y-intercept
#print(log01.intercept_)
print(log01.coef_)
#comparing to SAS the signs are correct but the actual coefficients are not

#how to get all the other diagnostics SAS spits out?
print ("Check trained model coefficients.")
logreg = linear_model.LogisticRegression()
Yvar = t2[['Survived']]
Xvar2 = t2[['Age','Pclass','female']]
log02 = logreg.fit(Xvar2, Yvar.values.ravel())
print(log02.coef_)
print ("The same signs as the linear model. That's good.")
print ("Need to get exponentiate the parameters to get the odds ratios.")
coefs=log02.coef_
#not vectorized fn?
print np.exp(coefs)
#but numpy's is

#Interpretation: an extra year of age decreases the odds of surviving a 
#factor of 0.96. Going from class 1 to 2 or 2 to 3 decreases the odds
#by a factor of 0.27. Finally, going from female to male decreases 
#the odds by a factor of 0.08 or 12.5 times. 
#That is females were 12 times more likely to survive that males. 
#Also, as we have seen above, this holds true even among minors (<18 years old)
#- females were more likely to survive.


#######################################################

#Final plots and summary
#Plot One: Bar chart of Survived and Gender
#plot is the matplotlib.pyplot fn
#http://pandas.pydata.org/pandas-docs/version/0.18.1/visualization.html
#can use either the procedural matlab like pyplot interface
#or the object oriented native matplotlib API - try this instead
#these plots are just dataframe methods

#get the tabulations first
#use the dataframe method from pandas
sur_count.plot(kind='bar',title='Survival Distribution',legend=True,color='grey')
#use the plt fn from matplotlib for additional customization
plt.ylabel('Frequency (Count)')
plt.xlabel('Survived (0=no, 1=yes')

#same for gender)
#use the dataframe method from pandas
sex_count.plot(kind='bar',title='Gender distribution',legend=True,color='pink')
#use the plt fn from matplotlib for additional customization
plt.ylabel('Frequency (Count)')

print ("Here are the actual percentages for the charts above.")
print sur_count, "\n","\n", np.round(sur_count / sur_count.sum() * 100)
print "\n"
print sex_count, "\n","\n", np.round(sex_count / sex_count.sum() * 100)

#Plot One Discussion
#Interesting, the distributions of Survived and Sex are almost identical.
#That is 65% of passengers were male and 62% of passengers did not survive.
#Is there a link between being male and not surviving?

#Plot Two: Distribution of Age by Survived separately by Sex
g = sns.FacetGrid(t, row="Sex", col="Survived", margin_titles=True, row_order=["female", "male"])
age_bins = np.arange(0, 70, 5)
g.map(plt.hist, 'Age', bins=age_bins, color="steelblue")
plt.ylabel('Frequency (Count)')
plt.xlabel('Age (Years)')
plt.title('Distribution of Age by Gender and Survival')
plt.show()
#Hmm - title is only for the last chart? oh, well

#Plot Two Discussion
#This plot looks like a mirror image: most of men did not survive, while most women did.
#Plot Three: Linear probability model by Sex

#http://seaborn.pydata.org/tutorial/axis_grids.html
g = sns.FacetGrid(t, col="Sex", margin_titles=True)
g.map(sns.regplot, "Age", "Survived", lowess=True, y_jitter=.1);

'''
Plot Three Discussion
The blue line can be interpreted as the predicted probability of surviving by age. For men this probability falls rapidly at 15 years old and stays pretty low. For women of all ages the probability of surviving is much higher.


Issues, Reflections, Conclusions (Speculations)
Issues: What we have is an incomplete data set - obviously there were more than 891 passengers on Titanic. We can make no assumptions about whether we got a random sample or a biased one.
There is missing data for Age. I did no imputations because I cannot make any assumptions whether the values are MCAR (missing completely at random). Those observations were just dropped by the R’s procedures when Age variable was invovled.
My exploratory data analysis suggested a link between survival and gender, so I pursued this and conducted statistical tests.
Chi-squared test of the frequency of survival based on gender (Sex) returned a very low p-value meaning this pattern could not have occurred by chance.
Both the linear and logistic probability models returned negative estimates for being male on survival.
The odds ratio of survival of being female comparing to being a male was 12.5.
This means that females were 12 times more likely to survive that males.
This pattern holds even for minors (<18 years old) - females were still more likely to survive.
This seems to suggest that in the good old saying “women and children first” boys of 15 years or older do not count as “children.”

Appendix: Data Dictionary
Data source: https://www.kaggle.com/c/titanic/data

VARIABLE DESCRIPTIONS:
survival Survival
(0 = No; 1 = Yes)
pclass Passenger Class
(1 = 1st; 2 = 2nd; 3 = 3rd)
name Name
sex Sex
age Age
sibsp Number of Siblings/Spouses Aboard
parch Number of Parents/Children Aboard
ticket Ticket Number
fare Passenger Fare
cabin Cabin
embarked Port of Embarkation
(C = Cherbourg; Q = Queenstown; S = Southampton)

The End.
'''