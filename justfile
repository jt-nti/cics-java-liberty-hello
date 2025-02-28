#
# Recipes to build and deploy the sample
#
# Use with https://github.com/casey/just
#

import 'unix.just'
import 'windows.just'

set dotenv-load
export CICSDEV_CMCI_URL := "https://" + env("CICSDEV_HOST") + ":" + env("CICSDEV_CMCI_PORT")

cwd := justfile_directory()
defdir := cwd / "resources"

_default:
    @just -f {{justfile()}} --list

# Check CICS connection
get-cics-region:
    zowe cics get resource CICSRegion --cics-profile "cicsdev.cics" --rff applid cicsstatus

# Create bundle
define-bundle:
    zowe cics define bundle {{env("CICSDEV_BUNDLE")}} {{env("CICSDEV_BUNDLE_DIR")}} {{env("CICSDEV_CSD_GROUP")}} --cics-profile "cicsdev.cics"
