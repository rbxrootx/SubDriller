
#!/bin/bash

# Check if a domain is provided
if [ -z "$1" ]
then
    echo "Usage: $0 <domain>"
    exit 1
fi

# Temporary file to store subdomains
temp_file=$(mktemp)

# Simplified function to get the HTTP status code of a website
check_http_status() {
    local url=$1
    local status=$(curl -o /dev/null --silent --head --write-out '%{http_code}' "$url")
    echo $status
}

# Simplified function to print status with color
print_status() {
    local url=$1
    local status=$(check_http_status $url)

    # Color coding based on status
    case $status in
        200) color="\033[32m" ;; # Green for OK
        301) color="\033[33m" ;; # Yellow for Moved Permanently
        404) color="\033[31m" ;; # Red for Not Found
        *)   color="\033[0m"  ;; # Default color
    esac

    # Print URL with color-coded status in a tabular format
    printf "%-50s | ${color}%-6s\033[0m\n" "$url" "$status"
}

# Fetch subdomains and store in temporary file
curl --silent --insecure --tcp-fastopen --tcp-nodelay "https://rapiddns.io/subdomain/$1?full=1#result" | grep "<td><a" | cut -d '"' -f 2 | grep http | cut -d '/' -f3 | sed 's/#results//g' | sort -u >> $temp_file &
curl --silent --insecure --tcp-fastopen --tcp-nodelay "http://web.archive.org/cdx/search/cdx?url=*.$1/*&output=text&fl=original&collapse=urlkey" | sed -e 's_https*://__' -e "s/\/.*//" | sort -u >> $temp_file &
curl --silent --insecure --tcp-fastopen --tcp-nodelay https://crt.sh | grep "<TD>" | cut -d '>' -f 2 | cut -d '<' -f 1 | grep ".$1" | sort -u >> $temp_file &

wait

# Print header for the table
echo -e "\033[1mURL\033[0m                                              | \033[1mStatus\033[0m"
echo "----------------------------------------------------|--------"

# Check status for each subdomain and print in a tabular format
while IFS= read -r line
do
    print_status "http://$line"
done < $temp_file

# Clean up
rm $temp_file
