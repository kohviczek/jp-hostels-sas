/* Import the data set */

proc import out=work.hostel 
            datafile="Hostel.csv" 
            dbms=csv replace;
     getnames=yes;
     datarow=2; 
run;

/*** Data cleaning  ***/

/* Replace 'NA' and '.' with SAS missing value for both character and numeric variables */

data work.hostel;
    set work.hostel;
    array char_vars {*} _character_;
    do i = 1 to dim(char_vars);
        if char_vars(i) in ('NA', '.') then char_vars(i) = .;
    end;

    array num_vars {*} _numeric_;
    do i = 1 to dim(num_vars);
        if num_vars(i) in ('NA', '.') then num_vars(i) = .;
    end;

    drop i;
run;

/* Create a new numeric variable for distance */

data work.hostel;
    set work.hostel;
    DistanceFromCityCentre_km = input(prxchange('s/km.*//', 1, Distance), best.);
    drop Distance;
run;

/* Convert specific character columns into numeric */

data work.hostel;
    set work.hostel;

    /* Array of character variables to convert */
    array char_vars {*} summary_score atmosphere cleanliness facilities location_y 
                      security staff valueformoney lon lat;

    /* Array of numeric variables */
    array num_vars {*} summary_score_num atmosphere_num cleanliness_num facilities_num 
                     location_y_num security_num staff_num valueformoney_num lon_num lat_num;

    /* Loop through each character variable to convert */
    do i = 1 to dim(char_vars);
        /* Convert character values to numeric and overwrite the existing variables */
        num_vars{i} = input(char_vars{i}, best.);
    end;

    /* Drop original character variables */
    drop summary_score atmosphere cleanliness facilities location_y 
        security staff valueformoney lon lat i;
run;

/* Check unique rating values */

proc freq data=work.hostel;
    tables rating_band / noprint out=unique_ratings(keep=rating_band);
run;
proc print data=unique_ratings;
run;

/* Examine all columns where rating is equal to 'Rating' */

data rating_reviews;
    set work.hostel;
    where rating_band = 'Rating';
run;

proc print data=rating_reviews;
run;

/* Look at reviews data grouped by rating class */

proc means data=work.hostel;
    class rating_band;
    var summary_score_num atmosphere_num cleanliness_num facilities_num location_y_num security_num staff_num valueformoney_num;
run;

/* Replace 'Rating' with 'Passable' based on the mean reviews */
data work.hostel;
    set work.hostel;
    rating_band = tranwrd(rating_band, 'Rating', 'Passable');
run;

/* Drop the observations with unexpected or missing rating */

data work.hostel;
    set work.hostel (drop=VAR1);
    where not missing(rating_band) and rating_band in ('Fabulous', 'Good', 'Passable', 'Superb', 'Very Good');
run;

/* Check the formatted rating values */

proc freq data=work.hostel;
    tables rating_band / list; 
run;

/* Exclude the outlier with very high price */

data work.hostel;
    set work.hostel;
    if price_from ne 1003200; 
run;

/* Print the cleaned data set */

proc print data=work.hostel;
run;

/* Check the data set using proc contents */

proc contents data=work.hostel;
run;

/*** Exploratory data analysis ***/

/* 1. Visualize descriptive statistics */

proc univariate data=work.hostel;
   var summary_score_num atmosphere_num cleanliness_num facilities_num
       location_y_num security_num staff_num valueformoney_num
       DistanceFromCityCentre_km;
   histogram / normal;
   inset mean std min max / position=ne;
run;

/* Sort the dataset by rating_band */

proc sort data=work.hostel;
    by rating_band;
run;

/* Visualize descriptive statistics grouped by rating_band */

proc univariate data=work.hostel;
   by rating_band;
   var summary_score_num atmosphere_num cleanliness_num facilities_num
       location_y_num security_num staff_num valueformoney_num
       DistanceFromCityCentre_km;
   histogram / normal;
   inset mean std min max / position=ne;
run;

/* Visualize descriptive statistics for prices */

proc univariate data=work.hostel;
   var price_from;
   histogram / normal;
   inset mean std min max / position=ne;
run;

/* Visualize distribution of ratings */

proc sgplot data=work.hostel;
   vbar rating_band / 
         datalabel 
         datalabelattrs=(color=black size=10pt)
         fillattrs=(color=lightcoral)
         outlineattrs=(color=coral)
         transparency=0.5;
   xaxis discreteorder=data 
         label="Rating Categories";
   yaxis grid 
         label="Frequency";
   title "Distribution of Ratings";
run;

/* Calculate frequency of cities and sort data */

proc freq data=work.hostel;
   tables City / out=city_freq(keep=City Count);
run;
proc sort data=city_freq;
   by descending Count;
run;

/* Visualize frequency of cities */

proc sgplot data=city_freq;
   vbar City / freq=Count
         datalabel 
         datalabelattrs=(color=black size=10pt)
         fillattrs=(color=lightcoral)
         outlineattrs=(color=lightcoral)
         transparency=0.5;
   xaxis discreteorder=data 
         label="City";
   yaxis grid 
         label="Frequency";
   title "City Frequency Distribution";
run;

/* 2. Price analysis */

/* Compute correlation matrix  */                                                                                            

proc corr data=work.hostel outp=corr_out noprob nosimple spearman;
   var price_from DistanceFromCityCentre_km summary_score_num atmosphere_num cleanliness_num
       facilities_num location_y_num security_num staff_num valueformoney_num;
run;

/* Visualize the distribution of prices with a density plot */

proc sgplot data=work.hostel;
   histogram price_from / fillattrs=(color=lightcoral) binwidth=100;
   density price_from / type=kernel lineattrs=(color=black);
   title "Distribution of Prices with Density Plot";
   xaxis label="Price" grid;
   yaxis label="Frequency" grid;
run;

/* Check prices per city */

/* Visualize the distribution of prices by city with colors */

proc sgplot data=work.hostel;
   vbar City / response=price_from group=City groupdisplay=cluster stat=mean
            fillattrs=(color=lightorange) outlineattrs=(color=lightorange);
   xaxis discreteorder=data;
   yaxis label="Price" grid;
   title "Average Prices by City";
run;

/* Visualize the distribution of price_from within Cities */

proc sgplot data=work.hostel;
   vbox price_from / category=City fillattrs=(color=lightorange);
   title "Price Distribution by City";
run;

/*  Explore the relationship between price_from and rating_band. */

proc sgplot data=work.hostel;
   vbar rating_band / response=price_from stat=mean fillattrs=(color=lilac) outlineattrs=(color=lilac);
   title "Mean Price by Rating Band";
run;

/* Visualize the distribution of price_from within each level of rating_band */

proc sgplot data=work.hostel;
   vbox price_from / category=rating_band fillattrs=(color=lilac);
   title "Price Distribution by Rating Band";
run;

/* 3. Review analysis */

/*Group data by review category and calculate statistics for each variable */

proc means data=work.hostel mean std median max;
  var atmosphere_num cleanliness_num facilities_num
      location_y_num security_num staff_num valueformoney_num; 
  output out=avg_review_scores 
         mean=avg_atmosphere avg_cleanliness avg_facilities avg_location 
              avg_security avg_staff avg_valueformoney 
         std=std_atmosphere std_cleanliness std_facilities std_location 
             std_security std_staff std_valueformoney
         median=med_atmosphere med_cleanliness med_facilities med_location 
                med_security med_staff med_valueformoney 
         max=max_atmosphere max_cleanliness max_facilities max_location 
             max_security max_staff max_valueformoney; 
run;

/* Visualize the distribution of scores with a density plot */

proc sgplot data=work.hostel;
   histogram summary_score_num / fillattrs=(color=lightcoral) binwidth=0.25;
   density summary_score_num / type=kernel lineattrs=(color=black);
   title "Distribution of Scores with Density Plot";
   xaxis label="Summary Score" grid;
   yaxis label="Frequency" grid;
run;

/* Check scores per city */

proc sgplot data=work.hostel;
   vbar City / response=summary_score_num group=City groupdisplay=cluster stat=mean fillattrs=(color=lightcoral)  outlineattrs=(color=lightcoral);
   xaxis discreteorder=data;
   yaxis label="Summary Score" grid;
   title "Average Summary Scores by City";
run;

/* Visualize the distribution of scores within Cities */

proc sgplot data=work.hostel;
   vbox summary_score_num / category=City fillattrs=(color=orange);
   title "Summary Scores by City";
run;

/* Visualize the distribution of scores within rating bands */

proc sgplot data=work.hostel;
   vbox summary_score_num / category=rating_band fillattrs=(color=orange);
   title "Summary Scores by Rating Band";
run;

/* Create scatterplots for each variable paired with summary_score_num in work.hostel dataset */
%macro create_scatter;
%local i var;
%do i = 1 %to 8;
   %let var = %scan(price_from DistanceFromCityCentre_km atmosphere_num cleanliness_num facilities_num location_y_num security_num staff_num valueformoney_num, &i); /* Extract variable name from the list */
   proc sgplot data=work.hostel;
      scatter x=summary_score_num y=&var / markerattrs=(color=coral);
      title "Scatterplot: Summary Score vs. &var";
   run;
%end;
%mend create_scatter;
%create_scatter;

