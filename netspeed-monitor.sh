#!/bin/sh
#H#
#H# netspeed-monitor.sh — Logs download and upload speed, generates plots, sends them via webhooks
#H#
#H# Examples:
#H#   sh netspeed-monitor.sh --plot 2020-10-04
#H#   sh netspeed-monitor.sh
#H#
#H# Options:
#H#   noarguments           Loops forever, generating logs every 10 min and plots every 24 h
#H#   --plot <YYYY-MM-DD>   Generates a plot based on the logs
#H#   --webhook-test        Sends a message to test the webhook
#H#   --help                Shows this message

help() {
    sed -rn 's/^#H# ?//;T;p' "$0"
}

# Send an image to whatever webhook has been configured.
# $1 - Path to the image
# Returns json output.
sendWebhook() {
    if [ -n "$WEBHOOK" ]; then
        echo "Sending webhook:"
        isSlackWebhook=$(echo "$WEBHOOK" | grep 'slack')
        if [ "$isSlackWebhook" ]; then
            # upload the image and send a link
            downloadLink=$(curl -s -F file=@"$1" https://ttm.sh)
            echo "Image uploaded: $downloadLink"
            curl -s -X POST --data-urlencode "payload={\"username\": \"Netspeed-Monitor\", \"text\": \"Download plot from: $downloadLink\"}" "$WEBHOOK"
        else
            # directly send the image to discord/custom webhook
            curl -X POST -F image=@"$1" "$WEBHOOK"
        fi
    fi
}

# Generates a png image based on the specified log file
# $1 - Log file containing data
# $2 - Output file of the plot
# Returns output from generate_plot.gp
generatePlot() {
    file=$(basename "$1")
    echo "Generating plot:"
    avgDownload=$(awk '{ sum += $2 }; END { printf "%.2f", sum/NR }' "$1")
    avgUpload=$(awk '{ sum += $3 }; END { printf "%.2f", sum/NR }' "$1")
    numOfRows=$(cat "$1" | wc -l)
    plotWidth=$((numOfRows*40))
    [ "$plotWidth" -gt 2000 ] && plotWidth=2000
    [ "$plotWidth" -lt 640 ] && plotWidth=640
    gnuplot -c generate_plot.gp "$1" "${file%.*}  |  Avg. Down: $avgDownload  |  Avg. Up: $avgUpload" "$2" "$plotWidth"
}

# Checks for installed dependencies and kills the script
# Accepts nothing
# Returns nothing
checkDependencies() {
    mainShellPID="$$"
    printf "curl\nsed\nawk\nspeedtest-cli\njq\ngnuplot" | while IFS= read -r program; do
        if ! [ -x "$(command -v "$program")" ]; then
            echo "Error: $program is not installed." >&2
            kill -9 "$mainShellPID" 
        fi
    done
}

checkDependencies
projectRoot=$(dirname "$(realpath "$0")")
# shellcheck source=/dev/null
. "$projectRoot/config.sh"

# loop over the arguments
while [ -n "$1" ]; do

    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then 
        help && exit 1

    elif [ "$1" = "--webhook-test" ]; then
        sendWebhook "$projectRoot/test-image.png"
        exit 1

    elif [ "$1" = "--plot" ]; then
        shift

        if [ ! -f "$projectRoot/logs/$1.log" ]; then
            echo "Couldn't find a log file for $1" >&2
            exit 0
        fi

        outputDirectory='somethingthatshouldnotexistinthisdirectory123!@#$%^'
        while [ ! -d "$outputDirectory" ]; do
            printf "Pick a location to save (enter for current dir.):"
            read -r outputDirectory
            [ -z "$outputDirectory" ] && outputDirectory=$(pwd)
            # validate that the selected directory exists
            if [ ! -d "$outputDirectory" ]; then
                echo "Directory doesn't exist!" >&2
            fi
        done
        generatePlot "$projectRoot/logs/$1.log" "$outputDirectory/$1.png"
        printf "Saved image: %s/%s.png\n\n" "$outputDirectory" "$1"

        while true; do
            printf "Do you want to send the image via webhook? (yes/no):"
            read -r yn
            case $yn in
                [Yy]* ) sendWebhook "$outputDirectory/$1.png" && break;;
                [Nn]* ) break;;
                * ) echo "Please answer yes or no.";;
            esac
        done
        exit 1

    else 
        echo "Invalid argument: $1" >&2 && exit 0
    fi
    shift

done

# if no arguments are passed we dive inside infinite loop
echo 'Speednet plotter started...'
echo 'Use CTRL+C to stop'
logFile="$projectRoot/logs/$(date +%Y-%m-%d).log"

while true; do
    currentTime=$(date +%-M)
    nextTestTime=$((10 - currentTime % 10))

    if [ $nextTestTime -eq 10 ]; then
        now=$(date +%H:%M)
        echo "$now Running a speed test..."
        speedTestResult=$(speedtest-cli --json)
        formattedResult=$(echo "$speedTestResult" | \
                    jq '.download, .upload' --raw-output | \
                    awk '{ printf "%.2f ", $1/1000000 }')
        echo "    - Parsed result: $formattedResult"
        echo "$now $(echo "$formattedResult" | awk '{ printf "%.2f %.2f\n", $1, $2 }')" >> "$logFile"

        if [ "$now" = '23:50' ]; then
            generatePlot "$logFile" "$projectRoot/latest_plot.png"
            sendWebhook "$projectRoot/latest_plot.png"
        fi
    else
        [ "$VERBOSE" = 'true' ] && echo "Next speed test is in $nextTestTime minutes."
    fi
    sleep 60
done