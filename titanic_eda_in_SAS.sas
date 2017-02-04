* Follow sas methodology for EDA and answer:
Titanic Data Q: What factors made people more likely to survive?
;

libname t "/folders/myfolders/ECPMLR93";

%let input=titanic_data.csv;
%let dataset=titanic;

/*
FILENAME REFFILE '/folders/myfolders/ECPMLR93/titanic_data.csv';
PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV REPLACE
	OUT=t.titanic;
	GETNAMES=YES;
RUN;
*/

ods escapechar = '^' ;

ods text="^S={just=c fontsize=16pt color=black font_weight=bold} EDA in SAS on Titanic data by Michael Eryan";
ods text="^S={just=c fontsize=16pt color=black}General data set examination and preparation";
ods text="^S={just=c fontsize=14pt color=black font_weight=bold} ";

ods text="^S={just=c fontsize=14pt color=black}Add the Minor variable and load the data set
 into macro variables to avoid typos.";
proc sql;
create table titanic as
select
*
,case when age is not null then 
	(case when age < 18 then 1 else 0 end)
	else . end as minor
from t.titanic
;quit;



proc odstext;
   p '^S={just=c fontsize=14pt color=black} The data is a sample and incomplete,
   so we cannot make any generalizations or definitive conclusions.
   My goal is just exploration, observation and some speculation.';
run;

ods text="^S={just=c fontsize=16pt color=black}Automatically produced summary of the data set";
ods text="^S={just=c fontsize=14pt color=black}The input data set is &input..";
ods text="^S={just=c fontsize=14pt color=black}Proc Contents provides all the info about the data set.";

ods select Attributes Variables ;
proc contents data=&dataset ;
run;
ods select default;

ods text="^S={just=c fontsize=16pt color=black}Print a few rows of the data set";
proc print data=&dataset (obs=10);
run;

ods text="^S={just=c fontsize=16pt color=black}Print a summary of all the numerical variables in the data";
proc means data=&dataset n nmiss min mean median max range std fw=8 maxdec=2;
run;

***************************;
ods text="^S={just=c fontsize=14pt color=black font_weight=bold} ";
ods text="^S={just=c fontsize=16pt color=black}Univariate Plots and Analysis";
ods text="^S={just=c fontsize=14pt color=black}Single variable tabulations";

proc format;
	value survfmt 1="Survived" 0="Died";
	value $sexfmt  "male"="1_Male" "female"="2_Female";
run;

proc sql;
select survived,count(*) as count from &dataset group by 1;
select sex,count(*) as count from &dataset group by 1;
select pclass,count(*) as count from &dataset group by 1;
select minor,count(*) as count from &dataset group by 1;
quit;

ods text="^S={just=c fontsize=14pt color=black}Bar Charts";
proc sgplot data=&dataset ;                                                                                                                 
   vbar survived / seglabel;                                                                                                         
run; 
proc sgplot data=&dataset;                                                                                                                 
   vbar sex / seglabel;                                                                                                        
run; 
proc sgplot data=&dataset;                                                                                                                 
   vbar pclass / seglabel;                                                                                                         
run; 
proc sgplot data=&dataset;                                                                                                                 
   vbar minor / seglabel;                                                                                                       
run; 

ods text="^S={just=c fontsize=14pt color=black}Observations: more males than females,
 more died than survived, 3 is the poorest socio-econ class.";
 ods text="^S={just=c fontsize=14pt color=black font_weight=bold} ";
ods text="^S={just=c fontsize=16pt color=black}Fancier bar charts - Counts and Proportions of Gender vs Survival.";

proc sgplot data=&dataset;                                                                                                                 
   vbar sex / group=survived seglabel seglabelattrs=(size=12);
   format survived survfmt.;                                                                                                         
run; 

ods text="^S={just=c fontsize=14pt color=black}Histogram with Density Plot of Age";
proc sgplot data=&dataset;                                                                                                                 
   histogram age ;
   density age / type=kernel; 
   keylegend / location=inside position=topright;                                                                                                      
run; 

******************************************************;
ods text="^S={just=c fontsize=14pt color=black font_weight=bold} ";
ods text="^S={just=c fontsize=16pt color=black}Bivariate Plots and Analysis";
ods text="^S={just=c fontsize=14pt color=black}Let’s facet Age by Sex and Survival";

proc sgpanel data = &dataset;
  panelby sex survived / columns = 2 rows =2;
  histogram age / scale=count;
  density age ;
  colaxis values= (0 to 80 by 5);
  format survived survfmt.;
run;

ods text="^S={just=c fontsize=14pt color=black}Almost mirror image, but is it statistically significant? Let’s test by Anova.";
/*
### First, let's look at the mean of Age by gender*survival - groupby
mean_age = aggregate(t$Age, list(t$Sex,t$Survived), mean,na.rm=TRUE)
print (mean_age)
### For survivors, the means are pretty close, but not so for dead. But is it significant?
aov_age_s1 = aov(Age ~ Sex, data=subset(t, subset= Survived==1))
print (summary(aov_age_s1))
### Not significant among the survivors.
aov_age_s0 = aov(Age ~ Sex, data=subset(t, subset= Survived==0))
print (summary(aov_age_s0))
### But definitely significant among the dead.
### Yes, the difference in age by sex is definitely significant among the dead.
*/

ods text="^S={just=c fontsize=14pt color=black}First, let's look at the mean of Age by gender*survival.";
proc sql;
select sex,survived,mean(age) as mean_age
from &dataset
group by 1,2
order by 2,1 desc
;quit;
ods text="^S={just=c fontsize=14pt color=black}For survivors, the means are pretty close, but not so for dead. But is it significant?";

data t1;
set &dataset;
where survived=1;
run;

ods select OverallANOVA;
proc anova data=t1 plots=none;
	class sex;
	model Age = sex;
run;
ods text="^S={just=c fontsize=14pt color=black}Age difference is not significant among the survivors.";
ods select default;

data t0;
set &dataset;
where survived=0;
run;
ods select OverallANOVA;
proc anova data=t0 plots=none;
	class sex;
	model Age = sex;
run;
ods select default;

ods text="^S={just=c fontsize=14pt color=black}But definitely significant among the dead.";
ods text="^S={just=c fontsize=14pt color=black}Yes, the difference in age by sex is definitely significant.";
ods text="^S={just=c fontsize=14pt color=black} The men who died were older than the women who died.";


ods text="^S={just=c fontsize=14pt color=black}Let’s look closer at survival * sex * pclass";
proc freq data=&dataset;
	tables survived sex pclass
			sex * survived pclass*survived / 
			plots (only)=freqplot(scale=percent);
	format survived survfmt.;
run;
ods text="^S={just=c fontsize=14pt color=black}We see that there might be a link between being male and not surviving.";
ods text="^S={just=c fontsize=14pt color=black}Let's do a test for association (contingency table test).";
ods text="^S={just=c fontsize=14pt color=black}Hypothesis: There is an association between sex and survival
	also try class and age.";

proc freq data=&dataset;
	tables 
			(sex pclass) * survived  / 
			chisq expected cellchi2 nocol nopercent relrisk;
	format survived survfmt.;
run;

ods text="^S={just=c fontsize=14pt color=black}Odds ratio (top row/bottom row) is significant at 0.08 - women are more likely than men to survive.";
ods text="^S={just=c fontsize=14pt color=black}0.08 says that a female has about 8% of the odds of dying compared to a male.";
ods text="^S={just=c fontsize=14pt color=black}Alternatively males have 92% lower odds of surviving than females.";

ods text="^S={just=c fontsize=14pt color=black font_weight=bold} ";
ods text="^S={just=c fontsize=14pt color=black}Does this pattern hold among the minors?";
proc freq data=&dataset;
	tables 
			sex  * survived  / 
			chisq expected cellchi2 nocol nopercent relrisk;
	where minor=1;
	format survived survfmt.;
run;
ods text="^S={just=c fontsize=14pt color=black}Yes, it does.";
proc sgpanel data = &dataset;
  panelby sex survived / columns = 2 rows =2;
  histogram age / scale=count;
  density age ;
  colaxis values= (0 to 18 by 3);
  where minor=1;
  format survived survfmt.;
run;
proc sgplot data=&dataset;                                                                                                                 
   vbar sex / group=survived seglabel seglabelattrs=(size=12);
   where minor=1;
   format survived survfmt.;                                                                                                         
run; 
ods text="^S={just=c fontsize=14pt color=black} Looks similiar to the overall chart above. 
Shows that Minor or not, males were still less likely to survive.";

ods text="^S={just=c fontsize=14pt color=black font_weight=bold} ";
ods text="^S={just=c fontsize=14pt color=black} Detecting Ordinal Associations - survival and socio-economic class.";
proc freq data=&dataset;
	tables 
			pclass * survived  / 
			chisq measures cl;
	format survived survfmt.;
run;
ods text="^S={just=c fontsize=14pt color=black} Yes, there is a relationsip between class and survival chisq is significant and spearman is -0.3397." ;

****************************************;
ods text="^S={just=c fontsize=14pt color=black font_weight=bold} ";
ods text="^S={just=c fontsize=16pt color=black} Multivariate Plots And Analysis";
ods text="^S={just=c fontsize=14pt color=black} Distribution of survival by age faceted by gender";

proc sgplot data=&dataset;
 	pbspline x=age y=survived / group=sex; 
 	where age <70;          
run;
ods text="^S={just=c fontsize=14pt color=black} Does not look very similiar to R's plot, but proves the same point.";

ods text="^S={just=c fontsize=14pt color=black}Let’s build a Linear probability model first.";
proc glm data=&dataset alpha=0.5;
	class sex pclass;
	model survived  = age sex pclass /solution;
	title 'Linear probability model: survived  = age sex pclass';
run;

ods text="^S={just=c fontsize=14pt color=black}Signs make sense: Age has a negative sign,
 being female has a positive sign, being of higher social class has a positive sign
  on probability of survival.";

ods text="^S={just=c fontsize=14pt color=black font_weight=bold} ";
ods text="^S={just=c fontsize=14pt color=black}Let’s build a logistic regression and get the odds as well.";
proc logistic data=&dataset alpha=0.5
	plots (only) = (effect oddsratio);
	model survived (event='1') = age / clodds=pl;
	title 'Logistic Model (1): survived=age';
run;
ods text="^S={just=c fontsize=14pt color=black}Odds ratio is 0.992 - so by increasing age by 1 year we decrease odds of surviving by 0.8%.";

ods text="^S={just=c fontsize=14pt color=black font_weight=bold} ";
ods text="^S={just=c fontsize=14pt color=black} Logistic model with a categorical predictor.";
proc logistic data=&dataset alpha=0.5
	plots (only) = (effect oddsratio);
	class sex(ref='male') pclass(ref='3') / param=ref;
	model survived (event='1') = age sex pclass / clodds=pl;
	units age=10;
	title 'Logistic Model (2): survived=age sex class';
run;
ods text="^S={just=c fontsize=14pt color=black}Interpretation of odds ratios: 
Increasing age by 10 years decreases the odds of surviving by 0.691,
 going from male to female increases the odds by 12.463,
  going from Pllass=3 to 1 increases the odds by 13.205 etc.";

ods text="^S={just=c fontsize=14pt color=black font_weight=bold} ";
ods text="^S={just=c fontsize=14pt color=black}Logistic regression: backward elimination with interactions.";
proc logistic data=&dataset alpha=0.5
	plots (only) = (effect oddsratio);
	class sex(ref='male') pclass(ref='3') / param=ref;
	model survived (event='1') = age|sex|pclass @2/ selection=backward slstay=0.01 clodds=pl;
	units age=10;
	title 'Logistic Model (3): Backward elimination, survived=age sex class';
run;

title;
ods text="^S={just=c fontsize=14pt color=black} Plot empirical estimated logits - to verify if the assumption of linear holds.";
proc means data=&dataset noprint nway;
	class pclass;
	var survived;
	output out=bins1 sum(survived)=nevent n(survived)=ncases;
run;
data bins2;
	set bins1;
	logit=log((nevent + 1)/(ncases - nevent+1));
run;
proc sgplot data=bins2;
	reg y=logit x=pclass / markerattrs=(symbol=asterisk color=blue size=15);
	pbspline y=logit x=pclass / nomarkers;
	xaxis integer;
	title "Estimated logit plot of passenger class";
run;
quit;
ods text="^S={just=c fontsize=14pt color=black}Looks sort of linear, so logistic regression is applicable.";

ods text="^S={just=c fontsize=14pt color=black}Same but for a continuous variable - 
bin into 50 groups of at least 20 obs to have enough obs for logit.";
proc rank data=&dataset groups=50 out=ranks;
	var age;
	ranks Rank;
run;
proc means data=ranks noprint nway;
	class rank;
	var survived age;
	output out=bins3 sum(survived)=nevent n(survived)=ncases mean(age)=age;
run;
data bins4;
	set bins3;
	logit=log((nevent + 1)/(ncases - nevent+1));
run;
proc sgplot data=bins4;
	reg y=logit x=age/ markerattrs=(symbol=asterisk color=blue size=15);
	pbspline y=logit x=age/ nomarkers;
	xaxis integer;
	title "Estimated logit plot of passenger age";
run;
quit;
title;
ods text="^S={just=c fontsize=14pt color=black} Nonlinearity detected - perhaps we need to transform Age before plugging into a logistic regression.";

********************************************;
ods text="^S={just=c fontsize=14pt color=black font_weight=bold} ";
ods text="^S={just=c fontsize=14pt color=black font_weight=bold} ";
ods text="^S={just=c fontsize=16pt color=black}Final Plots and Summary.";
ods text="^S={just=c fontsize=14pt color=black}Plot One: Bar chart of Survived and Gender.";

proc sgplot data=&dataset;                                                                                                                 
   vbar survived / seglabel fillattrs= (color= lightgrey);
   xaxis discreteorder=formatted; 
   format survived survfmt.;                                                                                                        
run; 
proc sgplot data=&dataset ;                                                                                                                 
   vbar sex / seglabel fillattrs= (color= pink);
   xaxis discreteorder=formatted; 
   format sex $sexfmt.;                                                                                                        
run; 

proc sql noprint;
select count(*) into :total from &dataset;
quit;
proc sql;
select survived,count(*) as count, count(*) / &total  as percent format=percent10. from &dataset group by 1;
select sex,count(*) as count, count(*) / &total  as percent format=percent10. from &dataset group by 1 order by sex desc;
quit;

ods text="^S={just=c fontsize=14pt color=black} Plot One Discussion.";
ods text="^S={just=c fontsize=14pt color=black} Interesting, the distributions of Survived and Sex are almost identical.";
ods text="^S={just=c fontsize=14pt color=black} That is 65pct of passengers were male and 62pct of passengers did not survive.";
ods text="^S={just=c fontsize=14pt color=black} Is there a link between being male and not surviving?";

ods text="^S={just=c fontsize=14pt color=black font_weight=bold} ";
ods text="^S={just=c fontsize=14pt color=black} Plot Two: Distribution of Age by Survived separately by Sex.";

proc sgpanel data = &dataset;
  panelby sex survived / columns = 2 rows =2;
  histogram age / scale=count;
  density age ;
  colaxis values= (0 to 80 by 5);
  format survived survfmt. sex $sexfmt.;
run;

ods text="^S={just=c fontsize=16pt color=black} Plot Two Discussion.";
ods text="^S={just=c fontsize=14pt color=black} This plot looks like a mirror image: most of men did not survive, while most women did.";
ods text="^S={just=c fontsize=14pt color=black} Plot Three: Linear probability model by Sex.";

proc sgplot data=&dataset;
 	pbspline x=age y=survived / group=sex;   
 	format survived survfmt. ;
 	where age <70;        
run;

ods text="^S={just=c fontsize=14pt color=black font_weight=bold} ";
ods text="^S={just=c fontsize=14pt color=black} Plot Three Discussion.";
ods text="^S={just=c fontsize=14pt color=black} The blue line can be interpreted as the predicted 
probability of surviving by age. For men this probability falls rapidly at 15 
years old and stays pretty low. For women of all ages the probability of surviving is much higher.";

ods text="^S={just=c fontsize=14pt color=black} ";

ods text="^S={just=c fontsize=16pt color=black} Issues, Reflections, Conclusions (Speculations)";
ods text="^S={just=c fontsize=14pt color=black} ";
ods text="^S={just=c fontsize=14pt color=black} Issues: What we have is an incomplete data set - 
obviously there were more than 891 passengers on Titanic. We can make no assumptions about 
whether we got a random sample or a biased one. Therefore we cannot really make 
any general conclusions but we can speculate about the results. ";
ods text="^S={just=c fontsize=14pt color=black} There is missing data for Age. 
I did no imputations because I cannot make any assumptions whether the values are 
MCAR (missing completely at random). Those observations were just dropped by the R’s 
procedures when Age variable was invovled.";
ods text="^S={just=c fontsize=14pt color=black} My exploratory data analysis suggested 
a link between survival and gender, so I pursued this and conducted statistical tests.";
ods text="^S={just=c fontsize=14pt color=black} Chi-squared test of the frequency 
of survival based on gender (Sex) returned a very low p-value meaning 
this pattern could not have occurred by chance.";
ods text="^S={just=c fontsize=14pt color=black} Both the linear and logistic probability models 
returned negative estimates for being male on survival.";
ods text="^S={just=c fontsize=14pt color=black} The odds ratio of survival of being female comparing to being a male was 12.5.";
ods text="^S={just=c fontsize=14pt color=black} This means that females were 12 times more likely to survive that males.";
ods text="^S={just=c fontsize=14pt color=black} This pattern holds even for minors (<18 years old) - females were still more likely to survive.";
ods text="^S={just=c fontsize=14pt color=black} This seems to suggest that in the good old saying
 “women and children first” boys of 15 years or older do not count as “children.”";
ods text="^S={just=c fontsize=14pt color=black} Next steps? In the future I could review other tragic events and disasters 
and analyze factors that influence the probability of survival.";

ods text="^S={just=c fontsize=14pt color=black} ";

ods text="^S={just=c fontsize=14pt color=black font_weight=bold}Appendix: Data Dictionary ";
ods text="^S={just=c fontsize=14pt color=black}Data source: https://www.kaggle.com/c/titanic/data ";
ods text="^S={just=c fontsize=14pt color=black} ";
ods text="^S={just=c fontsize=14pt color=black}VARIABLE DESCRIPTIONS: ";
ods text="^S={just=c fontsize=14pt color=black}survival Survival ";
ods text="^S={just=c fontsize=14pt color=black}(0 = No; 1 = Yes) ";
ods text="^S={just=c fontsize=14pt color=black}pclass Passenger Class ";
ods text="^S={just=c fontsize=14pt color=black}(1 = 1st; 2 = 2nd; 3 = 3rd) ";
ods text="^S={just=c fontsize=14pt color=black}name Name ";
ods text="^S={just=c fontsize=14pt color=black}sex Sex ";
ods text="^S={just=c fontsize=14pt color=black}age Age ";
ods text="^S={just=c fontsize=14pt color=black}sibsp Number of Siblings/Spouses Aboard ";
ods text="^S={just=c fontsize=14pt color=black}parch Number of Parents/Children Aboard ";
ods text="^S={just=c fontsize=14pt color=black}ticket Ticket Number ";
ods text="^S={just=c fontsize=14pt color=black}fare Passenger Fare ";
ods text="^S={just=c fontsize=14pt color=black}cabin Cabin ";
ods text="^S={just=c fontsize=14pt color=black}embarked Port of Embarkation ";
ods text="^S={just=c fontsize=14pt color=black}(C = Cherbourg; Q = Queenstown; S = Southampton) ";
ods text="^S={just=c fontsize=14pt color=black} ";
ods text="^S={just=c fontsize=14pt color=black font_weight=bold}The End. ";

