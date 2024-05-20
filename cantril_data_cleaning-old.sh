#!/bin/bash

# Check if the right number of arguments is provided
if [ $# -ne 3 ]; then
  echo "Usage: $0 <file1.tsv> <file2.tsv> <file3.tsv>"
  exit 1
fi

# Function to process each .tsv file
process_file() {
  local file="$1"
  local headers=("Entity" "Code" "Year" "GDP per capita" "Population" "Homicide Rate" "Life Expectancy" "Cantril Ladder score")

  # Identify the header and determine the column positions
  local header_line=$(head -n 1 "$file")
  local header_array=($(echo "$header_line" | tr '\t' '\n'))
  declare -A columns
  for index in "${!header_array[@]}"; do
    columns[${header_array[$index]}]=$index
  done

  # Check for missing columns
  for header in "${headers[@]}"; do
    if [ -z "${columns[$header]}" ]; then
      echo "Missing required column: $header in $file" >&2
      exit 2
    fi
  done

  # Print data rows excluding "Continent" column and non-country rows
  tail -n +2 "$file" | awk -v FS='\t' -v OFS='\t' -v EntityCol="${columns[Entity]}" -v CodeCol="${columns[Code]}" -v YearCol="${columns[Year]}" -v GDPCol="${columns["GDP per capita"]}" -v PopCol="${columns["Population"]}" -v HomicideCol="${columns["Homicide Rate"]}" -v LifeExpCol="${columns["Life Expectancy"]}" -v LadderCol="${columns["Cantril Ladder score"]}" '
    {
      if ($EntityCol != "" && $CodeCol != "" && $YearCol != "" && $YearCol >= 2005 && $YearCol <= 2020) {
        print $EntityCol, $CodeCol, $YearCol, $GDPCol, $PopCol, $HomicideCol, $LifeExpCol, $LadderCol
      }
    }
  '
}

# Combine all files
combine_files() {
  local files=("$@")
  echo -e "Entity\tCode\tYear\tGDP per capita\tPopulation\tHomicide Rate\tLife Expectancy\tCantril Ladder score"
  for file in "${files[@]}"; do
    process_file "$file"
  done
}

# Call combine_files with input files in any order
combine_files "$@"
