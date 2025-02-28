# CICS Liberty Web Application
[![Build](https://github.com/cicsdev/cics-java-liberty-hello/actions/workflows/java.yaml/badge.svg?branch=cicsts%2Fv5.5)](https://github.com/cicsdev/cics-java-liberty-hello/actions/workflows/java.yaml)

A simple enterprise Java web application that can run in a CICS Liberty JVM server.

This sample demonstrates a simple Java web application using JavaServer Pages to echo information about the CICS task the page is running on.

## Using a dev container (work in progress!)

This is an experiment with getting a CICSDev sample working in a [VS Code dev container](https://code.visualstudio.com/docs/devcontainers/containers). There are definitely more than a few rough edges so feedback is very welcome!

Before starting you need to create a `.env` file and fill in the settings for your mainframe environment.
In the real world, you'll probably need a friendly sys prog to set things up for you and let you know what all the settings should be.
See the [sample.env](sample.env) file for the settings you need.

If you're using VS Code in the dev container, there are a few tasks defined which should get you all the way to a working deployment.

1. update-zowe-profile

   Run this task after creating or updating you `.env` file to update the Zowe connection settings.

2. create-jvmserver

   On a development system, you might be able to create your own JVM server. If so, run this task!

3. define-bundle

   On a development system, you might be able to create your own bundle definition. If so, run this task!

4. deploy-bundle

   This runs the gradle deployCICSBundle task. You will need all of the following for it to run successfully!

   ✅ A CMCI server with the [CICS bundle deployment API configured](https://www.ibm.com/docs/en/cics-ts/6.x?topic=suc-configuring-cmci-jvm-server-cics-bundle-deployment-api)

   ✅ A Liberty JVM server with the correct features enabled

   ✅ A bundle defined with a directory matching the bundle you're deploying, i.e.

   `<bundle_deploy_root>/<bundle_id>_<bundle_version>`

   where,
   
   - `<bundle_deploy_root>` **must** match the `-Dcom.ibm.cics.jvmserver.cmci.bundles.dir=<bundles_directory>` setting in the JVM profile of the CMCI JVM server,
   - `<bundle_id>` matches the ID of the bundle you're deploying, e.g. `cics-java-liberty-hello-bundle`, and
   - `<bundle_version>` matches the version of the bundle you're deploying, e.g. `1.0.0`

All these tasks can also be run outside VS Code using the [just](https://github.com/casey/just) command runner. There is also a `just install` recipe to install the required tools.


## Requirements
* CICS TS for z/OS V5.5 or later
* Java SE 1.8 or later on the local workstation
* Eclipse with the IBM CICS SDK for Java EE, Jakarta EE and Liberty, or any IDE
  that supports usage of the Maven Central artifact
  [com.ibm.cics:com.ibm.cics.server](https://search.maven.org/artifact/com.ibm.cics/com.ibm.cics.server).
* _Optional_ A build tool such as Apache Maven or Gradle.

## Downloading
- Clone the repository using your IDEs support, such as the Eclipse Git plugin
- **or**, download the sample as a [compressed file](https://github.com/cicsdev/cics-java-template/archive/main.zip) and unzip onto the workstation.

_**Tip:** Eclipse Git provides an 'Import existing Projects' check-box when cloning a repository._

## Building
The sample can be built with CICS Explorer, Gradle or Apache Maven. Using the supplied Gradle or Maven wrappers will give a consistent and updated version of build tooling.

Once run, Gradle will generate a WAR file in the `/cics-java-liberty-hello-web/build/libs` directory, while Maven will generate it in the `/cics-java-liberty-hello-web/target` directory.

The bundle ZIP file for Gradle will be generated in the `/cics-java-liberty-hello-bundle/build/distributions` directory, while Maven will generate it in the `/cics-java-liberty-hello-bundle/target` directory.

### Building with CICS Explorer
The sample should automatically be built in CICS Explorer. If not, select **Project** &rarr; **Build Project**.

### Building with Gradle
From the root directory, run the appropriate Gradle command.

If using the CICS bundle ZIP, the CICS JVM server name should be modified in the jvmserver property in the gradle build properties file to match the required CICS JVMSERVER resource name, or alternatively can be set on the command line.

**Gradle Wrapper (Linux/Mac):**
```shell
./gradlew clean build
```
**Gradle Wrapper (Windows):**
```shell
gradle.bat clean build
```
**Gradle (command-line):**
```shell
gradle clean build
```
**Gradle (command-line & setting jvmserver):**
```shell
gradle clean build -Pcics.jvmserver=MYJVM
```

### Building with Apache Maven
From the root directory, run the appropriate Maven command.

If building a CICS bundle ZIP the CICS bundle plugin bundle-war goal is driven using the maven verify phase. The CICS JVM server name should be modified in the property in the pom.xml to match the required CICS JVMSERVER resource name, or alternatively can be set on the command line.

**Maven Wrapper (Linux/Mac):**
```shell
./mvnw clean verify
```
**Maven Wrapper (Windows):**
```shell
mvnw.cmd clean verify
```
**Maven (command-line):**
```shell
mvn clean verify
```
**Maven (command-line & setting jvmserver):**
```shell
mvn clean verify -Dcics.jvmserver=MYJVM
```


## Deploying

### Configuring the Liberty JVM server
1. Create a Liberty JVM server.
2. Install the JVM server.

> [!NOTE]
> The server.xml feature list should be updated to correspond to the JavaEE/JakartaEE your Liberty server is configured to. See the table below.

| EE Version | Feature |
| ----------- | ----------- |
| JEE6 | ```<feature>jsp-2.2</feature>``` |
| JEE7/8 | ```<feature>jsp-2.3</feature>``` |
| JEE9 | ```<feature>pages-3.0</feature>``` |
| JEE10 | ```<feature>pages-3.1</feature>``` |

### Deploying the application to z/FS
The application can be deployed to z/FS as either a CICS bundle file, or as an application.

#### Deploying a CICS bundle using CICS Explorer
1. Create a new CICS bundle project.
2. Add the `cics-java-liberty-hello-web` project as a Dynamic Web Project include.
3. Deploy the bundle by clicking **Export Bundle Project to z/OS UNIX File System**.

#### Deploying a CICS bundle using command line tools
1. Copy the compressed CICS bundle file to z/FS.
   * Gradle: `projects/cics-java-liberty-hello-bundle/build/distributions/cics-java-liberty-hello-bundle-1.0.0.zip`
   * Maven: `projects/cics-java-liberty-hello-bundle/target/cics-java-liberty-hello-bundle-1.0.0.zip` 
2. Extract the compressed file on z/FS.
   ```sh
   jar xf cics-java-liberty-hello-bundle-1.0.0.zip
   ```

#### Deploying an application using command line tools
1. Copy the application file to z/FS
   * Gradle: `projects/cics-java-liberty-hello-web/build/libs/cics-java-liberty-hello-web-1.0.0.war`
   * Maven: `projects/cics-java-liberty-hello-web/target/cics-java-liberty-hello-web-1.0.0.war`
3. Configure the Liberty server to include the application using the following `server.xml` configuration.
   ```xml
   <application id="cics-java-liberty-hello" location="/path/to/cics-java-liberty-hello-web-1.0.0.war" />
   ```

### Configuring the CICS bundle
If the application is deployed as a CICS bundle, use the following steps to define and install the CICS bundle.

1. Create a bundle definition, setting the BUNDLEDIR to the path to the deployed CICS bundle on z/FS.
2. Install the bundle definition.

## Running
1. Ensure the web application started successfully in Liberty by checking for the CWWKT0016I message in the Liberty messages.log:
   > A CWWKT0016I: Web application available (default_host): http://zos.example.com:9080/cics-java-liberty-hello-1.0.0
2. Access the URL printed in the CWWKT0016I message (`http://zos.example.com:9080/cics-java-liberty-hello-1.0.0/`) to access the JSP.
3. When deploying with CICS Explorer, the URL may be (`http://zos.example.com:9080/cics-java-liberty-hello/`) 

## License
This project is licensed under [Eclipse Public License - v 2.0](LICENSE).
