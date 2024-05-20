#!/bin/bash

# Ensure we have exactly one input file
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <cleaned_data.tsv>"
    exit 1
fi

input_file="$1"

# Function to calculate Pearson correlation
calculate_correlation() {
    local x_values=("$1")
    local y_values=("$2")

    local n=${#x_values[@]}
    local sum_x=0
    local sum_y=0
    local sum_xy=0
    local sum_x2=0
    local sum_y2=0

    for ((i=0; i<n; i++)); do
        local x=${x_values[$i]}
        local y=${y_values[$i]}
        sum_x=$(echo "$sum_x + $x" | bc)
        sum_y=$(echo "$sum_y + $y" | bc)
        sum_xy=$(echo "$sum_xy + ($x * $y)" | bc)
        sum_x2=$(echo "$sum_x2 + ($x * $x)" | bc)
        sum_y2=$(echo "$sum_y2 + ($y * $y)" | bc)
    done

    local numerator=$(echo "($n * $sum_xy) - ($sum_x * $sum_y)" | bc)
    local denominator=$(echo "sqrt((($n * $sum_x2) - ($sum_x * $sum_x)) * (($n * $sum_y2) - ($sum_y * $sum_y)))" | bc)

    if [ "$denominator" == "0" ]; then
        echo "0"
    else
        local correlation=$(echo "scale=4; $numerator / $denominator" | bc)
        echo "$correlation"
    fi
}

# Extract unique country codes
countries=$(cut -f 1 "$input_file" | tail -n +2 | sort -u)

# Initialize arrays to store correlations for each predictor
GDP_correlations=()
Population_correlations=()
Homicide_correlations=()
Life_expectancy_correlations=()

# Loop through countries
for country in $countries; do
    GDP_values=()
    Population_values=()
    Homicide_values=()
    Life_expectancy_values=()
    Cantril_values=()

    # Loop through data rows for the current country
    while IFS=$'\t' read -r _country _code _year GDP Population Homicide Life_expectancy Cantril; do
        if [ "$_country" == "$country" ]; then
            GDP_values+=("$GDP")
            Population_values+=("$Population")
            Homicide_values+=("$Homicide")
            Life_expectancy_values+=("$Life_expectancy")
            Cantril_values+=("$Cantril")
        fi
    done < "$input_file"

    # Skip countries with incomplete data
    if [ ${#GDP_values[@]} -lt 3 ] || [ ${#Population_values[@]} -lt 3 ] || [ ${#Homicide_values[@]} -lt 3 ] || [ ${#Life_expectancy_values[@]} -lt 3 ] || [ ${#Cantril_values[@]} -lt 3 ]; then
        continue
    fi

    # Calculate correlations for each predictor
    if [ ${#GDP_values[@]} -ge 3 ]; then
        GDP_correlation=$(calculate_correlation "${GDP_values[@]}" "${Cantril_values[@]}")
        GDP_correlations+=("$GDP_correlation")
    fi
    if [ ${#Population_values[@]} -ge 3 ]; then
        Population_correlation=$(calculate_correlation "${Population_values[@]}" "${Cantril_values[@]}")
        Population_correlations+=("$Population_correlation")
    fi
    if [ ${#Homicide_values[@]} -ge 3 ]; then
        Homicide_correlation=$(calculate_correlation "${Homicide_values[@]}" "${Cantril_values[@]}")
        Homicide_correlations+=("$Homicide_correlation")
    fi
    if [ ${#Life_expectancy_values[@]} -ge 3 ]; then
        Life_expectancy_correlation=$(calculate_correlation "${Life_expectancy_values[@]}" "${Cantril_values[@]}")
        Life_expectancy_correlations+=("$Life_expectancy_correlation")
    fi
done

# Calculate mean correlations for each predictor
mean_GDP_correlation=0
mean_Population_correlation=0
mean_Homicide_correlation=0
mean_Life_expectancy_correlation=0

# Calculate sum of correlations for each predictor
if [ ${#GDP_correlations[@]} -gt 0 ]; then
    for correlation in "${GDP_correlations[@]}"; do
        mean_GDP_correlation=$(echo "$mean_GDP_correlation + $correlation" | bc)
    done
    mean_GDP_correlation=$(echo "scale=4; $mean_GDP_correlation / ${#GDP_correlations[@]}" | bc)
fi

if [ ${#Population_correlations[@]} -gt 0 ]; then
    for correlation in "${Population_correlations[@]}"; do
        mean_Population_correlation=$(echo "$mean_Population_correlation + $correlation" | bc)
    done
    mean_Population_correlation=$(echo "scale=4; $mean_Population_correlation / ${#Population_correlations[@]}" | bc)
fi

if [ ${#Homicide_correlations[@]} -gt 0 ]; then
    for correlation in "${Homicide_correlations[@]}"; do
        mean_Homicide_correlation=$(echo "$mean_Homicide_correlation + $correlation" | bc)
    done
    mean_Homicide_correlation=$(echo "scale=4; $mean_Homicide_correlation / ${#Homicide_correlations[@]}" | bc)
fi

if [ ${#Life_expectancy_correlations[@]} -gt 0 ]; then
    for correlation in "${Life_expectancy_correlations[@]}"; do
        mean_Life_expectancy_correlation=$(echo "$mean_Life_expectancy_correlation + $correlation" | bc)
    done
    mean_Life_expectancy_correlation=$(echo "scale=4; $mean_Life_expectancy_correlation / ${#Life_expectancy_correlations[@]}" | bc)
fi

# Print mean correlations
echo "Mean correlation of GDP_per_capita with Cantril ladder is $mean_GDP_correlation"
echo "Mean correlation of Population with Cantril ladder is $mean_Population_correlation"
echo "Mean correlation of Homicide Rate with Cantril ladder is $mean_Homicide_correlation"
echo "Mean correlation of Life Expectancy with Cantril ladder is $mean_Life_expectancy_correlation"

