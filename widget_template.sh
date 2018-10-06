#!/usr/bin/env bash

generate_widget(){

html_table="$1"
app_name="$2"
widget_number="$3"
x="$4"
y="$5"

printf -v file_name "widgets/widget_%05d.json" "$widget_number" 
printf "Creating %s %s %s \n" "$file_name"

cat  << EOF > $file_name
{
            "widgetType": "TextWidget",
            "title": null,
            "height": 1,
            "width": 2,
            "minHeight": 0,
            "minWidth": 0,
            "x": $x,
            "y": $y,
            "label": null,
            "description": null,
            "drillDownUrl": null,
            "useMetricBrowserAsDrillDown": false,
            "drillDownActionType": null,
            "backgroundColor": 16777215,
            "backgroundColors": null,
            "backgroundColorsStr": "16777215,16777215",
            "color": 1646891,
            "fontSize": 12,
            "useAutomaticFontSize": false,
            "borderEnabled": false,
            "borderThickness": 0,
            "borderColor": 14408667,
            "backgroundAlpha": 1,
            "showValues": false,
            "formatNumber": null,
            "numDecimals": 0,
            "removeZeros": null,
            "compactMode": false,
            "showTimeRange": false,
            "renderIn3D": false,
            "showLegend": null,
            "legendPosition": null,
            "legendColumnCount": null,
            "startTime": null,
            "endTime": null,
            "minutesBeforeAnchorTime": 15,
            "isGlobal": true,
            "propertiesMap": null,
            "dataSeriesTemplates": null,
            "text": "<table style=\"width:100%\"><tr><th bgcolor=\"#5D7B9D\"><font color=\"#fff\">$app_name</font></th><th bgcolor=\"#5D7B9D\"><font color=\"#fff\">Calls</font></th></tr>$html_table</table>",
            "textAlign": "LEFT",
            "margin": 4
        },
EOF
}

