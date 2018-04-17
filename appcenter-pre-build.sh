
#!/bin/bash

#Argument should be $(P12Password)
export PASSWORD="$1"

CERTNAME=$(openssl pkcs12 -in ./.certs/ios_cert.p12 -nokeys -passin pass:$PASSWORD | openssl x509 -noout -subject | sed 's/^.*CN=//' | sed 's/\/.*$//')

# For debugging
echo "CERTNAME: $CERTNAME"

echo "##vso[task.setvariable variable=APPLE_CERTIFICATE_SIGNING_IDENTITY]$CERTNAME"

echo "Create temp keychain"
/usr/bin/security create-keychain -p $PASSWORD $AGENT_TEMPDIRECTORY/ios_signing_temp.keychain

echo "Set keychain unlock timeout"
/usr/bin/security set-keychain-settings -lut 7200 $AGENT_TEMPDIRECTORY/ios_signing_temp.keychain

echo "Unlock the temp keychain"
/usr/bin/security unlock-keychain -p $PASSWORD $AGENT_TEMPDIRECTORY/ios_signing_temp.keychain

echo "Import the p12"
/usr/bin/security import .certs/ios_cert.p12 -P $PASSWORD -A -t cert -f pkcs12 -k $AGENT_TEMPDIRECTORY/ios_signing_temp.keychain

echo "Add the temporary keychain to the search list"
/usr/bin/security list-keychain -d user -s $AGENT_TEMPDIRECTORY/ios_signing_temp.keychain

# For debugging
/usr/bin/security list-keychain -d user

echo "Get the UUID"
/usr/bin/security cms -D -i .certs/ios_cert.mobileprovision >> temp_profile.plist
UUID=$(/usr/libexec/PlistBuddy -c "print UUID" temp_profile.plist)
echo "UUID: $UUID"
rm temp_profile.plist

echo "Copy the provisioning profile under ~/Library/MobileDevice/Provisioning\ Profiles"
/bin/mkdir /Users/vsts/Library/MobileDevice
/bin/mkdir /Users/vsts/Library/MobileDevice/Provisioning\ Profiles
/bin/cp -f .certs/ios_cert.mobileprovision /Users/vsts/Library/MobileDevice/Provisioning\ Profiles/$UUID.mobileprovision

echo "##vso[task.setvariable variable=APPLE_PROV_PROFILE_UUID]$UUID"