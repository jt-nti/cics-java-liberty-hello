#
# Unix recipes to build and deploy the sample
#
# Use with https://github.com/casey/just
#

curl := if os_family() == "unix" { require("curl") } else { "" }
npm := if os_family() == "unix" { require("npm") } else { "" }


# Install pre-reqs
[unix]
install: install-zowe install-resource-builder


# Install zowe cli
[unix]
install-zowe:
    {{npm}} install -g prebuild-install
    {{npm}} install -g @zowe/cli@zowe-v3-lts

    zowe plugins install @zowe/zos-ftp-for-zowe-cli@zowe-v3-lts @zowe/cics-for-zowe-cli@zowe-v3-lts
    zowe config init --global-config --overwrite --for-sure --prompt false


# Install CICS Transaction Server resource builder
[unix]
install-resource-builder:
    rm -Rf ~/.local/bin/zrb ~/.local/lib/cics-resource-builder
    mkdir -p ~/.local/bin ~/.local/lib
    {{curl}} -sfL "https://public.dhe.ibm.com/ibmdl/export/pub/software/htp/zos/updates/cics-resource-builder-1.0.3.zip" 2>/dev/null -o /tmp/cics-resource-builder-1.0.3.zip
    cd ~/.local/lib && jar -xvf /tmp/cics-resource-builder-1.0.3.zip cics-resource-builder
    chmod 755 ~/.local/lib/cics-resource-builder/bin/zrb
    ln -s ~/.local/lib/cics-resource-builder/bin/zrb ~/.local/bin/zrb
    rm /tmp/cics-resource-builder-1.0.3.zip


# Update cicsdev zowe profile
#[unix]
update-zowe-profile:
    export CICSDEV_PROFILE=$(jq -cn \
       --arg host {{env("CICSDEV_HOST")}} \
       --arg cmciPort {{env("CICSDEV_CMCI_PORT")}} \
       --arg cicsPlex {{env("CICSDEV_PLEX", "")}} \
       --arg regionName {{env("CICSDEV_REGION", "")}} \
       --arg sshPort {{env("CICSDEV_SSH_PORT")}} \
       --arg zftpPort {{env("CICSDEV_ZFTP_PORT")}} \
       --arg zosmfPort {{env("CICSDEV_ZOSMF_PORT")}} \
       '{properties: {host: $host, rejectUnauthorized: false}, profiles: {cics: {type: "cics", properties: {cicsPlex: $cicsPlex, regionName: $regionName, protocol: "https", port: $cmciPort | tonumber}}, ssh: {type: "ssh", properties: {port: $sshPort | tonumber}}, zftp: {type: "zftp", properties: {protocol: "https", port: $zftpPort | tonumber, secureFtp: true}}, zosmf: {type: "zosmf", properties: {protocol: "https", port: $zosmfPort | tonumber}}}}') && \
    zowe config set "profiles.cicsdev" "$CICSDEV_PROFILE" --global-config --json
    zowe config set "defaults.cics" "cicsdev.cics" --global-config
    zowe config set "defaults.ssh" "cicsdev.ssh" --global-config
    zowe config set "defaults.zftp" "cicsdev.zftp" --global-config
    zowe config set "defaults.zosmf" "cicsdev.zosmf" --global-config


# Create the CICS resource definitions required to configure a JVM server
[unix]
build-resources:
    : {{env("CICSDEV_JVMPROFILE_JAVA_HOME")}}
    : {{env("CICSDEV_JVMPROFILE_WLP_XML")}}
    : {{env("CICSDEV_JVMPROFILE_HTTP_PORT")}}
    : {{env("CICSDEV_JVMPROFILE_HTTPS_PORT")}}
    rm -Rf {{defdir}}
    mkdir -p {{defdir}}
    # TODO substitute variables in resource model/definitions?
    # TODO add option to create prepare file? https://www.ibm.com/docs/en/cics-resource-builder/1.0?topic=dfhcsdup-preparing-csd
    zrb build --model {{cwd}}/etc/cicsdev.cicsresourcemodel.yaml --resources {{cwd}}/etc/cicsdev.cicsresourcedefinitions.yaml --output {{defdir}}/DFHCSD.txt
    envsubst '$CICSDEV_JVMPROFILE_JAVA_HOME,$CICSDEV_JVMPROFILE_WLP_XML,$CICSDEV_JVMPROFILE_HTTP_PORT,$CICSDEV_JVMPROFILE_HTTPS_PORT' < {{cwd}}/etc/CICSDEV_TEMPLATE.jvmprofile > {{defdir}}/CICSDEV.jvmprofile
    cp {{cwd}}/etc/libertyInclude.xml {{defdir}}


# Configure a JVM server using CMCI
[unix]
create-jvmserver: build-resources
    zowe zftp upload ftu --binary --zftp-profile "cicsdev.zftp" {{defdir}}/libertyInclude.xml {{env("CICSDEV_JVMPROFILE_WLP_XML")}}
    zowe zos-ssh issue command --ssh-profile "cicsdev.ssh" "chmod 755 {{env("CICSDEV_JVMPROFILE_WLP_XML")}}"

    zowe zftp upload ftu --zftp-profile "cicsdev.zftp" {{defdir}}/CICSDEV.jvmprofile {{env("CICSDEV_JVMPROFILE_DIR")}}/CICSDEV.jvmprofile
    zowe zos-ssh issue command --ssh-profile "cicsdev.ssh" "chmod 755 CICSDEV.jvmprofile" --cwd {{env("CICSDEV_JVMPROFILE_DIR")}}

    echo "user: \"$CICSDEV_USER:$CICSDEV_PASSWORD\"" | {{curl}} --config - \
        --insecure \
        --request POST \
        --url ${CICSDEV_CMCI_URL:?}/CICSSystemManagement/CICSDefinitionJVMServer/{{env("CICSDEV_PLEX", "")}}/{{env("CICSDEV_REGION", "")}} \
        --header 'content-type: application/xml' \
        --data '<request><create><parameter name="CSD"/><attributes name="{{env("CICSDEV_JVM_SERVER")}}" description="" csdgroup="{{env("CICSDEV_CSD_GROUP")}}" jvmprofile="CICSDEV" status="ENABLED"/></create></request>'

    echo "user: \"$CICSDEV_USER:$CICSDEV_PASSWORD\"" | {{curl}} --config - \
        --insecure \
        --request PUT \
        --url ${CICSDEV_CMCI_URL:?}/CICSSystemManagement/CICSCSDGroup/{{env("CICSDEV_PLEX", "")}}/{{env("CICSDEV_REGION", "")}}?CRITERIA=NAME%3D%3D{{env("CICSDEV_JVM_SERVER")}} \
        --header 'content-type: application/xml' \
        --data '<request><action name="CSDINSTALL"></action></request>'


# Run a gradle build
[unix]
build:
    ./gradlew clean build


# Deploy the sample CICS bundle using gradle
[unix]
deploy-bundle:
    ./gradlew deployCICSBundle


# Deploy the sample war using the Liberty server dropins folder
[unix]
dropin-deploy:
    zowe zftp upload ftu --binary --zftp-profile "cicsdev.zftp" {{cwd}}/cics-java-liberty-hello-web/build/libs/cics-java-liberty-hello-web-1.0.0.war {{env("JVMPROFILE_LIBERTY_DROPIN_DIR")}}/cics-java-liberty-hello-web-1.0.0.war
