# netspeed-monitor

A POSIX compliant shell script that checks internet speeds every 10 minutes and generates a plot in PNG format every 24 hours. Also capable of sending the image to a webhook. (I use it for Discord webhooks)
![Showcase](https://github.com/Ivstiv/netspeed-monitor/blob/master/showcase.png)
## Installation

1. Make sure you have the main dependencies: jq, speedtest-cli, gnuplot
    ```
    # Amend according to your distro

    # Arch
    sudo pacman -S jq speedtest-cli gnuplot
    # Debian based
    sudo apt-get install jq speedtest-cli gnuplot
    ```
2. Clone the repository
    ```
    git clone https://github.com/Ivstiv/netspeed-monitor.git && cd netspeed-monitor
    ```
3. Configure your webhook
    ```
    cp example-config.sh config.sh
    # > edit config.sh
    ```
4. Run the script

## Usage
```
netspeed-monitor.sh — Logs download and upload speed, generates plots, sends them via webhooks

Examples:
  sh netspeed-monitor.sh --plot 2020-10-04
  sh netspeed-monitor.sh

Options:
  noarguments           Loops forever, generating logs every 10 min and plots every 24 h
  --plot <YYYY-MM-DD>   Generates a plot based on the logs
  --webhook-test        Sends a message to test the webhook
  --help                Shows this message
```

## FAQ
- The --plot argument asks you for save location and if you want to send the image via webhook.
- The logs are not being cleaned automatically, so your logs folder will grow indefinitely.
- Probably a good idea to leave the script running in tmux or screen session: `screen -dmS netspeed-monitor sh netspeed-monitor.sh`
- Other questions - find me in [my Discord server](https://discord.gg/VMSDGVD).
- You can probably write your own endpoint for the webhook. Here is an example in PHP:
```
php code here
```