#!/bin/bash

# Function to calculate Pearson correlation using awk
calculate_correlation() {
  predictor_column=$1
  awk -v pred_col="$predictor_column" '
  BEGIN {
    FS="\t"
    n = 0
    sum_x = sum_y = sum_xy = sum_x2 = sum_y2 = 0
  }
  NR > 1 {
    x = $pred_col
    y = $6  # Cantril Ladder is the 6th column
    if (x != "" && y != "") {
      x = x + 0
      y = y + 0
      sum_x += x
      sum_y += y
      sum_xy += x * y
      sum_x2 += x * x
      sum_y2 += y * y
      n++
    }
  }
  END {
    if (n < 3) {
      print "Insufficient data"
      exit 1
    }
    mean_x = sum_x / n
    mean_y = sum_y / n
    numerator = sum_xy - n * mean_x * mean_y
    denominator = sqrt((sum_x2 - n * mean_x * mean_x) * (sum_y2 - n * mean_y * mean_y))
    if (denominator == 0) {
      print "Correlation undefined (zero denominator)"
      exit 1
    }
    r = numerator / denominator
    print r
  }
  ' "$datafile"
}

# Check if a data file is provided
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 datafile"
  exit 1
fi

# Input data file
datafile=$1

# Check if the data file exists
if [ ! -f "$datafile" ]; then
  echo "Error: File '$datafile' not found!"
  exit 1
fi

# Define columns for the predictors
GDP_COLUMN=2
POPULATION_COLUMN=3
HOMICIDE_COLUMN=4
LIFE_EXPECTANCY_COLUMN=5

# Calculate correlations for each predictor
correlation_gdp=$(calculate_correlation $GDP_COLUMN)
correlation_population=$(calculate_correlation $POPULATION_COLUMN)
correlation_homicide=$(calculate_correlation $HOMICIDE_COLUMN)
correlation_life_expectancy=$(calculate_correlation $LIFE_EXPECTANCY_COLUMN)

# Handle undefined correlations
if [[ "$correlation_gdp" == "Correlation undefined"* ]] || [[ "$correlation_gdp" == "" ]]; then
  abs_correlation_gdp=0
else
  abs_correlation_gdp=$(echo "$correlation_gdp" | awk '{print ($1 < 0) ? -$1 : $1}')
fi

if [[ "$correlation_population" == "Correlation undefined"* ]] || [[ "$correlation_population" == "" ]]; then
  abs_correlation_population=0
else
  abs_correlation_population=$(echo "$correlation_population" | awk '{print ($1 < 0) ? -$1 : $1}')
fi

if [[ "$correlation_homicide" == "Correlation undefined"* ]] || [[ "$correlation_homicide" == "" ]]; then
  abs_correlation_homicide=0
else
  abs_correlation_homicide=$(echo "$correlation_homicide" | awk '{print ($1 < 0) ? -$1 : $1}')
fi

if [[ "$correlation_life_expectancy" == "Correlation undefined"* ]] || [[ "$correlation_life_expectancy" == "" ]]; then
  abs_correlation_life_expectancy=0
else
  abs_correlation_life_expectancy=$(echo "$correlation_life_expectancy" | awk '{print ($1 < 0) ? -$1 : $1}')
fi

# Find the maximum absolute correlation
max_correlation=$abs_correlation_gdp
best_predictor="GDP per capita"

if (( $(echo "$abs_correlation_population > $max_correlation" | bc -l) )); then
  max_correlation=$abs_correlation_population
  best_predictor="Population"
fi

if (( $(echo "$abs_correlation_homicide > $max_correlation" | bc -l) )); then
  max_correlation=$abs_correlation_homicide
  best_predictor="Homicide Rate per 100,000"
fi

if (( $(echo "$abs_correlation_life_expectancy > $max_correlation" | bc -l) )); then
  max_correlation=$abs_correlation_life_expectancy
  best_predictor="Life Expectancy"
fi

# Output the results
echo "Mean correlation of GDP per capita with Cantril ladder is $correlation_gdp"
echo "Mean correlation of Population with Cantril ladder is $correlation_population"
echo "Mean correlation of Homicide Rate with Cantril ladder is $correlation_homicide"
echo "Mean correlation of Life Expectancy with Cantril ladder is $correlation_life_expectancy"
echo "Most predictive mean correlation with the Cantril ladder is $best_predictor (r = $max_correlation)"
