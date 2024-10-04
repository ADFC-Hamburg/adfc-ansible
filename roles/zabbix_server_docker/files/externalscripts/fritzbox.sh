#!/bin/bash
# Shell script to query the Fritzbox via Curl and UPNP to get status information and statistics
#
# Inspired by the following scripts:
# https://github.com/jhubig/FritzBoxShell/blob/master/fritzBoxShell.sh
# http://schwender-beyer.de/artikel.php?n=3&p=fb.monitoring

# VARIABLES
# IP address of the FritzBox
FritzBoxIP=$2
FritzBoxUsername=$3
FritzBoxPassword=$4

# Function to send a SOAP query via curl and process it
# $1 = location
# S2 = uri
# $3 = action
# $4 = XML tag to be parsed
function SoapRequest {

	# Triggers if only a specific XML tag or everything is returned
	if [ -z $4 ]; then
		bashparameter=".*"
	else
		bashparameter="(?<=<$4>).*?(?=</$4>)"
	fi

	# If a Fritz box username and password was delivered, it is used or no
	if [ "$FritzBoxUsername" = "" ] && [ "$FritzBoxPassword" = "" ]; then
		Curluser=""
	else
		Curluser="--anyauth -u "$FritzBoxUsername:$FritzBoxPassword" "
	fi

	# Curl command to send SOAP request to FritzBox
	curl -k -m 5 $Curluser-H "Content-Type: text/xml; charset="utf-8"" \
		-H "SoapAction:$2#$3" \
		-d "<?xml version='1.0' encoding='utf-8'?><s:Envelope s:encodingStyle='http://schemas.xmlsoap.org/soap/encoding/' xmlns:s='http://schemas.xmlsoap.org/soap/envelope/'><s:Body><u:$3 xmlns:u='$2'></u:$3></s:Body></s:Envelope>" \
		-s "http://$FritzBoxIP:49000/$1" | grep -oP "$bashparameter"
}

# Function to query the status screen of FritzBox and process the readings
# $1 = XML tag to be parsed
function GetRequest {
	curl -s "http://$FritzBoxIP:49000/tr64desc.xml" | tr -d "\n" | grep -oP "(?<=<specVersion>).*?(?=</iconList>)" | grep -oP "(?<=<$1>).*?(?=</$1>)"
}

# Stop script if no host is given
if [ -z $2 ]; then
	echo "Missing target IP or name for query"
	exit 1
fi

# Selector based on the parameter sent to script to decide which information should be requested
case $1 in
down)
	SoapRequest "igdupnp/control/WANCommonIFC1" "urn:schemas-upnp-org:service:WANCommonInterfaceConfig:1" "GetAddonInfos" "NewByteReceiveRate"
	;;
up)
	SoapRequest "igdupnp/control/WANCommonIFC1" "urn:schemas-upnp-org:service:WANCommonInterfaceConfig:1" "GetAddonInfos" "NewByteSendRate"
	;;
ipv4)
	SoapRequest "igdupnp/control/WANIPConn1" "urn:schemas-upnp-org:service:WANIPConnection:1" "GetExternalIPAddress" "NewExternalIPAddress"
	;;
ipv6)
	SoapRequest "igdupnp/control/WANIPConn1" "urn:schemas-upnp-org:service:WANIPConnection:1" "X_AVM_DE_GetExternalIPv6Address" "NewExternalIPv6Address"
	;;
status)
	SoapRequest "igdupnp/control/WANIPConn1" "urn:schemas-upnp-org:service:WANIPConnection:1" "GetStatusInfo" "NewConnectionStatus"
	;;
wan)
	SoapRequest "upnp/control/wanipconnection1" "urn:dslforum-org:service:WANIPConnection:1" "GetInfo"
	;;
maxdown)
	SoapRequest "igdupnp/control/WANCommonIFC1" "urn:schemas-upnp-org:service:WANCommonInterfaceConfig:1" "GetCommonLinkProperties" "NewLayer1DownstreamMaxBitRate"
	;;
maxup)
	SoapRequest "igdupnp/control/WANCommonIFC1" "urn:schemas-upnp-org:service:WANCommonInterfaceConfig:1" "GetCommonLinkProperties" "NewLayer1UpstreamMaxBitRate"
	;;
linkstatus)
	SoapRequest "igdupnp/control/WANCommonIFC1" "urn:schemas-upnp-org:service:WANCommonInterfaceConfig:1" "GetCommonLinkProperties" "NewPhysicalLinkStatus"
	;;
totalbytessent)
	SoapRequest "igdupnp/control/WANCommonIFC1" "urn:schemas-upnp-org:service:WANCommonInterfaceConfig:1" "GetTotalBytesSent" "NewTotalBytesSent"
	;;
totalbytesrec)
	SoapRequest "igdupnp/control/WANCommonIFC1" "urn:schemas-upnp-org:service:WANCommonInterfaceConfig:1" "GetTotalBytesReceived" "NewTotalBytesReceived"
	;;
totalpacketssent)
	SoapRequest "igdupnp/control/WANCommonIFC1" "urn:schemas-upnp-org:service:WANCommonInterfaceConfig:1" "GetTotalPacketsSent" "NewTotalPacketsSent"
	;;
totalpacketsrec)
	SoapRequest "igdupnp/control/WANCommonIFC1" "urn:schemas-upnp-org:service:WANCommonInterfaceConfig:1" "GetTotalPacketsReceived" "NewTotalPacketsReceived"
	;;
manufacturer)
	GetRequest "manufacturer"
	;;
serial)
	SoapRequest "upnp/control/deviceinfo" "urn:dslforum-org:service:DeviceInfo:1" "GetInfo" "NewSerialNumber"
	;;
swversion)
	SoapRequest "upnp/control/deviceinfo" "urn:dslforum-org:service:DeviceInfo:1" "GetInfo" "NewSoftwareVersion"
	;;
uptime)
	SoapRequest "upnp/control/deviceinfo" "urn:dslforum-org:service:DeviceInfo:1" "GetInfo" "NewUpTime"
	;;
friendlyname)
	GetRequest "friendlyName"
	;;
modelname)
	GetRequest "modelName"
	;;
version)
	GetRequest "Display"
	;;
wlan2g)
	SoapRequest "upnp/control/wlanconfig1" "urn:dslforum-org:service:WLANConfiguration:1" "GetInfo"
	;;
wlan5g)
	SoapRequest "upnp/control/wlanconfig2" "urn:dslforum-org:service:WLANConfiguration:2" "GetInfo"
	;;
wlan2gchannel)
	SoapRequest "upnp/control/wlanconfig1" "urn:dslforum-org:service:WLANConfiguration:1" "GetInfo" "NewChannel"
	;;
wlan5gchannel)
	SoapRequest "upnp/control/wlanconfig2" "urn:dslforum-org:service:WLANConfiguration:2" "GetInfo" "NewChannel"
	;;
wlan2genable)
	SoapRequest "upnp/control/wlanconfig1" "urn:dslforum-org:service:WLANConfiguration:1" "GetInfo" "NewEnable"
	;;
wlan5genable)
	SoapRequest "upnp/control/wlanconfig2" "urn:dslforum-org:service:WLANConfiguration:2" "GetInfo" "NewEnable"
	;;
lan)
	SoapRequest "upnp/control/lanethernetifcfg" "urn:dslforum-org:service:LANEthernetInterfaceConfig:1" "GetStatistics"
	;;
lanbytessent)
	SoapRequest "upnp/control/lanethernetifcfg" "urn:dslforum-org:service:LANEthernetInterfaceConfig:1" "GetStatistics" "NewBytesSent"
	;;
lanbytesrec)
	SoapRequest "upnp/control/lanethernetifcfg" "urn:dslforum-org:service:LANEthernetInterfaceConfig:1" "GetStatistics" "NewBytesReceived"
	;;
lanpacketssent)
	SoapRequest "upnp/control/lanethernetifcfg" "urn:dslforum-org:service:LANEthernetInterfaceConfig:1" "GetStatistics" "NewPacketsSent"
	;;
lanpacketsrec)
	SoapRequest "upnp/control/lanethernetifcfg" "urn:dslforum-org:service:LANEthernetInterfaceConfig:1" "GetStatistics" "NewPacketsReceived"
	;;
*)
	echo "No valid request parameter found"
	exit 1 # terminate and indicate error
	;;
esac
