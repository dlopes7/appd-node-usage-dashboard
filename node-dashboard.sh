#!/usr/bin/env bash
#set -x 

APPD_CONTROLLER=http://demo.controller.com
APPD_USER=user
APPD_ACCOUNT=customer1
APPD_PASSWORD=password

METRIC_HISTORY_MINUTES=1440
METRIC_HISTORY_MINUTES=60
STARTING_CHARACTERS_IN_HTML=340
WIDGETS_PER_LINE=6

# Source the template
. widget_template.sh

# Create the widgets directory
mkdir -p widgets
rm -f widgets/*

# Grep changes depending on the OS
unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     grep_form="grep -oP";;
    Darwin*)    grep_form="grep -e";;
esac

rest(){
    curl -s --user $APPD_USER@$APPD_ACCOUNT:$APPD_PASSWORD \
    -H "accept: application/json, text/plain, */*" \
    -H "Content-Type: application/json" \
    $APPD_CONTROLLER"$1"
}

rest_ui(){

    curl -s --user $APPD_USER@$APPD_ACCOUNT:$APPD_PASSWORD --cookie-jar cookies.jar $APPD_CONTROLLER/auth?action=login

    curl -s --user $APPD_USER@$APPD_ACCOUNT:$APPD_PASSWORD \
    -H "accept: application/json, text/plain, */*" \
    -H "X-CSRF-TOKEN: $(grep X-CSRF-TOKEN cookies.jar | awk '{print $7}')" \
    -H "Content-Type: application/json;charset=utf-8" \
    --cookie cookies.jar \
    $APPD_CONTROLLER"$1" "${@:2}"

}

# Grab all apps
apps=$(rest "/controller/rest/applications?output=json")
app_ids=($($grep_form  '"id": \K([0-9]+)' <<< $apps))
app_names=($($grep_form  '"name": "\K.*?(?=")' <<< $apps))


# For each app, grab the Calls per Minute, for each node of every tier
metric_path="Overall%20Application%20Performance|%2A|Individual%20Nodes|%2A|Calls%20per%20Minute"
number_of_characters=$STARTING_CHARACTERS_IN_HTML


number_of_wigets=0
x=0
y=0

for ((i=0;i<${#app_ids[@]};++i)); do

    app_id="${app_ids[i]}"
    app_name="${app_names[i]}"
    metrics=$(rest "/controller/rest/applications/$app_id/metric-data?output=json&metric-path=$metric_path&time-range-type=BEFORE_NOW&duration-in-mins=$METRIC_HISTORY_MINUTES")    
    
    #tiers=$(grep -oP 'Overall Application Performance\|\K.*?(?=\|)' <<< $metrics)
    nodes=($($grep_form  'Individual Nodes\|\K.*?(?=\|)' <<< $metrics))
    sums=($($grep_form  'sum": \K.*?(?=,)' <<< $metrics))

    # Merge the array "nodes" with the array "sums"
    k=0
    for node in ${nodes[@]}; do
        c[k++]="$node|${sums[k]}"
    done
    declare c 

    # Sort the array decreasing by sum
    IFS=$'\n' sorted=($(sort -t'|' -nr -k2 <<<"${c[*]}"))
    unset IFS

    table_rows=""

    number_of_characters=$(($number_of_characters + ${#app_name}))
    for ((l=0;l<${#sorted[@]};++l)); do
        element="${sorted[l]}"
        element=$(sed 's,|,</font></td><td><font color=\\"#383\\">,g' <<< $element)

        printf -v table_row '<tr><td><font color=\\"#338\\">%s</font></td></tr>' "${element}"

        number_of_characters=$(($number_of_characters + ${#table_row} ))
        #printf '\n%d = %s - %d\n' "$l" "$app_name" "$number_of_characters"
        # A label widget can have only 1024 characters
        if [ "$number_of_characters" -ge 1024 ]; then

            if [ -n "$table_rows" ]; then
                number_of_wigets=$((number_of_wigets + 1))
                generate_widget "$table_rows" "$app_name" "$number_of_wigets" "$x" "$y"
                x=$((x + 2))
            fi

            if [ "$x" -gt 6 ]; then
                x=0
                y=$((y + 1))
            fi


            number_of_characters=$(($STARTING_CHARACTERS_IN_HTML + ${#app_name}))
            table_rows=""

        fi
        table_rows+="$table_row"

    done

    if [ -n "$table_rows" ]; then
        number_of_wigets=$((number_of_wigets + 1))
        generate_widget "$table_rows" "$app_name" "$number_of_wigets" "$x" "$y"
        x=$((x + 2))
    fi
    
    if [ "$x" -gt 6 ]; then
        x=0
        y=$((y + 1))
    fi    
done

# Remove the comma from the last widget
printf -v file_name "widgets/widget_%05d.json" "$number_of_wigets" 
sed -i '$ s/.$//' $file_name

# Join all widgets
printf "Joining all %d widgets\n" "$number_of_wigets"
cat widgets/widget* > widgets.json

# Create the dashboard
printf "Creating dashboard/dashboard.json\n"
cat dashboard/dashboard_01.json > dashboard/dashboard.json
cat widgets.json >> dashboard/dashboard.json
cat dashboard/dashboard_02.json >> dashboard/dashboard.json
cat widgets.json >> dashboard/dashboard.json
cat dashboard/dashboard_02.json >> dashboard/dashboard.json


rest_ui "/restui/dashboards/updateDashboard" "-d" "@dashboard/dashboard.json"
