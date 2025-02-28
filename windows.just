#
# Windows recipes to build and deploy the sample
#
# Use with https://github.com/casey/just
#

# Install pre-reqs
[windows]
@install:
    echo TODO: no pre-req install recipes for Windows yet


# Create CICS resource definitions to configure a JVM server
[windows]
@resource-defs:
    echo TODO: no resource-defs recipe for Windows yet


# Configure a JVM server using CMCI
[windows]
@bootstrap: resource-defs
    echo TODO: no bootstrap recipe for Windows yet


# Run a gradle build
[windows]
build:
  gradle.bat clean build


# Deploy the sample CICS bundle using gradle
[windows]
bundle-deploy:
  gradle.bat deployCICSBundle


# Deploy the sample war using the Liberty server dropins folder
[windows]
@dropin-deploy:
    echo TODO: no dropin-deploy recipe for Windows yet
