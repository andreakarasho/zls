# script for us in kcov.yml action

SUMMARY=$(cat zig-out/kcov/kcov-merged/coverage.json)

PERCENT_COVERED=$(echo $SUMMARY | jq .percent_covered -cr)
COVERED_LINES=$(echo $SUMMARY | jq .covered_lines -cr)
TOTAL_LINES=$(echo $SUMMARY | jq .total_lines -cr)

echo -e "## Code Coverage Report\n"
echo -e "### $PERCENT_COVERED% covered ($COVERED_LINES / $TOTAL_LINES lines)\n"

echo -e "<details open><summary>Per-file coverage details</summary><br>\n"

FILES=$(echo $SUMMARY | jq '.files | sort_by(.percent_covered | tonumber) | .[]' -cr)

echo "| File | Coverage |   |"
echo "| ---- | -------- | - |"

for FILE in $FILES; do
    FILENAME="$(echo $FILE | jq '.file' -cr)"
    FILENAME=${FILENAME#*zls/}
    FILE_PERCENT_COVERED=$(echo $FILE | jq '.percent_covered' -cr)
    FILE_COVERED_LINES=$(echo $FILE | jq '.covered_lines' -cr)
    FILE_TOTAL_LINES=$(echo $FILE | jq '.total_lines' -cr)

    FILE_STATUS=$(
        if [ $(echo $FILE_PERCENT_COVERED'<25' | bc -l) -eq 1 ];
        then
            echo "❗"
        elif [ $(echo $FILE_PERCENT_COVERED'<75' | bc -l) -eq 1 ];
        then
            echo "⚠️"
        else
            echo "✅"
        fi
    )
    
    echo "| \`$FILENAME\` | $FILE_PERCENT_COVERED% ($FILE_COVERED_LINES / $FILE_TOTAL_LINES lines) | $FILE_STATUS |"
done

echo "</details>"
