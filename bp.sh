#!/bin/bash

# Function to calculate Pearson correlation coefficient using awk
calculate_correlation() {
    local predictor_col=$1
    local predictor_name=$2

    awk -v col="$predictor_col" -v pred_name="$predictor_name" '
    BEGIN {
        FS = "\t";
        sx = 0; sy = 0; sxy = 0; sx2 = 0; sy2 = 0; n = 0;
    }
    NR > 1 && $col != "" && $8 != "" {
        x = $col;
        y = $8;
        sx += x;
        sy += y;
        sxy += x * y;
        sx2 += x * x;
        sy2 += y * y;
        n++;
    }
    END {
        mean_x = sx / n;
        mean_y = sy / n;
        var_x = (sx2 / n) - (mean_x ^ 2);
        var_y = (sy2 / n) - (mean_y ^ 2);
        stddev_x = sqrt(var_x);
        stddev_y = sqrt(var_y);
        cov_xy = (sxy / n) - (mean_x * mean_y);

        if (n < 3) {
            print "Correlation undefined (not enough data points)";
        } else if (stddev_x == 0 || stddev_y == 0) {
            print "Correlation undefined (zero denominator)";
        } else {
            correlation = cov_xy / (stddev_x * stddev_y);
            printf "Mean correlation of %s with Cantril ladder is %.6f\n", pred_name, correlation;
            printf "%.6f\n", correlation > "/tmp/correlation_" pred_name;
        }
    }' "$input_file"
}

# Ensure a file is provided as argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <input_file>"
    exit 1
fi

input_file=$1

# Columns for predictors
GDP_col=4
Population_col=5
Homicide_col=6
LifeExpectancy_col=7

# Calculate correlations
GDP_corr=$(calculate_correlation $GDP_col "GDP")
Population_corr=$(calculate_correlation $Population_col "Population")
Homicide_corr=$(calculate_correlation $Homicide_col "Homicide")
LifeExpectancy_corr=$(calculate_correlation $LifeExpectancy_col "LifeExpectancy")

# Print correlations
echo "$GDP_corr"
echo "$Population_corr"
echo "$Homicide_corr"
echo "$LifeExpectancy_corr"

# Read the correlation values from temporary files
GDP_corr=$(cat /tmp/correlation_GDP)
Population_corr=$(cat /tmp/correlation_Population)
Homicide_corr=$(cat /tmp/correlation_Homicide)
LifeExpectancy_corr=$(cat /tmp/correlation_LifeExpectancy)

# Determine the most predictive correlation
best_predictor="GDP"
best_correlation=$GDP_corr

for predictor in "Population" "Homicide" "LifeExpectancy"; do
    eval correlation=\$${predictor}_corr
    if [[ $correlation != "" ]]; then
        abs_correlation=$(echo $correlation | awk '{print ($1 < 0 ? -$1 : $1)}')
        abs_best_correlation=$(echo $best_correlation | awk '{print ($1 < 0 ? -$1 : $1)}')
        if (( $(echo "$abs_correlation > $abs_best_correlation" | bc -l) )); then
            best_predictor=$predictor
            best_correlation=$correlation
        fi
    fi
done

echo "Most predictive mean correlation with the Cantril ladder is $best_predictor (r = $best_correlation)"

# Clean up temporary files
rm -f /tmp/correlation_GDP /tmp/correlation_Population /tmp/correlation_Homicide /tmp/correlation_LifeExpectancy
