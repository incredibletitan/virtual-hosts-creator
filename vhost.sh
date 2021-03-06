#!/bin/bash

# Check if all required parameters are specified 
if [ $# -ne 2 ]; then
	echo "Please, specify hostname and path";
	exit 1;
fi

#Detect current file directory.
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

hostname=$1
path_to_host=$2
apache_path="/etc/apache2/sites-available/"
hosts_file_path="/etc/hosts";

# Check does path to destination folder exist on server
if [ ! -d ${path_to_host} ]; then
	echo "Invalid path to host directory: ${path_to_host}" 
	exit 1;
fi

template_file_path="$DIR/basic.conf"

# Check does configuaration file exist
if [ ! -f ${template_file_path} ]; then
    echo "File ${template_file_path} not found!"
    exit 1
fi

destination_file_path="$path_to_host$hostname"

if [ ! -d ${destination_file_path} ]; then
	# Create directory for virtual host
	mkdir "${destination_file_path}"
fi

replaced_content=$(sed "s/{{SERVER_NAME}}/${hostname}/g" $template_file_path)
replaced_content=$(echo "$replaced_content" | sed "s@{{DIRECTORY}}@${destination_file_path}@g")

result_conf_file_path=$apache_path$hostname.conf

if [ ! -f ${result_conf_file_path} ]; then
	# Write replaced content to configuaration file
	echo "$replaced_content" | sudo tee -a "$result_conf_file_path" > /dev/null;
else
	echo "File \"$result_conf_file_path\" already exist"
	exit 1
fi

# Enable host
sudo a2ensite $hostname

#Restart apache
sudo service apache2 restart

echo "127.0.0.1 	www.$hostname" | sudo tee -a  $hosts_file_path > /dev/null
echo "127.0.0.1 	$hostname" | sudo tee -a  $hosts_file_path > /dev/null
