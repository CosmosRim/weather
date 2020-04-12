#! /bin/zsh

declare -r shpw=`pwd`
declare -r cfgpw="${shpw}/../01_config"
declare -r infopw="${shpw}/../02_weatherInfo"
declare -r city=`grep -a1 '\[city\]' ${cfgpw}/weatherInfo.cfg | tail -1`
declare -r language='zh-CN'
declare -r unit='m'
declare -r dateOfNow=`date '+%Y%m%d'`
declare -r os=`grep -a1 '\[os\]' ${cfgpw}/weatherInfo.cfg | tail -1`
declare -r token=`grep -a1 '\[token2\]' ${cfgpw}/weatherInfo.cfg | tail -1`
declare -r secret=`grep -a1 '\[secret2\]' ${cfgpw}/weatherInfo.cfg | tail -1`
#declare -r timestamp=$((`date '+%s'`*1000+`date '+%N'`/1000000))
#declare -r strToSign="${timestamp}\n${secret}"
#declare -r strAftSign=`echo -n ${strToSign} | shasum -a 256 | awk '{print $1}'`
#declare -r strAftbase64=$(base64 <<< ${strAftSign})
#declare -r strAftUrl=`echo -n ${strAftbase64} | xxd -plain | tr -d "\n" | sed 's/\(..\)/%\1/g'`
#declare -r tokenTail="&timestamp=${timestamp}&sign=${strAftUrl}"
declare -r tokenTail=`./dingTalkSign_${os} ${secret}`

function get_weather_info() {
    if [[ `find . -type f -name ${city}${dateOfNow}.json` ]];then
        rm -f ${city}${dateOfNow}.json
    fi
    
    curl -s -o ../02_weatherInfo/${city}${dateOfNow}.json "wttr.in/${city}?format=j1"

    if [[ $? == 0 ]];then
        echo "got weather info successfully."
    else
        echo "failed to get weather info."
    fi
}

function get_json_value() {
    local json=$1
    local key=$2
    
    if [[ -z "$3" ]];then
      local num=1
    else
      local num=$3
    fi
    
    local value=$(cat "${json}" | awk -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/'${key}'\042/){print $(i+1)}}}' | tr -d '"' | sed -n ${num}p)
    
    echo ${value}
}

function post() {
    curl "${token}${tokenTail}"\
        -H "Content-Type:application/json"\
        -d "{
            'msgtype': 'markdown',
            'markdown': {
                'title': 'Weather',
                'text': '## Weather of ${city} \nToday is ${localTime% *} \t\n Weather is ${weather} \t\nTemperature is ${tempC}°C and it feels like ${feelTempC}°C \t\n![](https://wttr.in/${city}.png)'
             }
        }" && echo "\r"

    if [[ $? == 0 ]];then
        echo "post weather info to dingtalk finished."
    else
        echo "failed to post weather info to dingtalk."
    fi
}


echo "[`date '+%Y/%m/%d %H:%M:%S'`] warming engine."

while :
do

    get_weather_info
    
    jsonFile="${infopw}/${city}${dateOfNow}.json"
    weather=`get_json_value ${jsonFile} value`
    tempC=`get_json_value ${jsonFile} temp_C`
    feelTempC=`get_json_value ${jsonFile} FeelsLikeC`
    localTime=`get_json_value ${jsonFile} localObsDateTime`
    
    post

    sleep 10
done

echo "[`date '+%Y/%m/%d %H:%M:%S'`] all finished."
