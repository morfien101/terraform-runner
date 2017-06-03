#!/bin/bash
# This is used to hold the creds folder link if it is required.
CREDS=""
CREDS_DIR=/usercreds
function print_header() {
  echo ${#CREDS}
  # Check if there is something in the creds variable.
  if [ ${#CREDS} -eq 0 ]; then
    echo "Remember to add your Auth Keys"
    echo "Example below:"
    echo "######################################################"
    echo "export AWS_ACCESS_KEY_ID=<your key>"
    echo "export AWS_SECRET_ACCESS_KEY=<your secret key>"
    echo "######################################################"
  else
    echo "Credentials have been supplied as files."
    echo "They will be available in /terraform-runner/creds"
  fi
  echo ""
  echo "Lauching container."
  echo "The host name will change now to signal that you are in the container."
  echo "      ▼▼▼▼▼▼▼▼▼▼▼▼"
}

if [ -d $CREDS_DIR ]; then
  CREDS="-v $CREDS_DIR:/terraform-runner/creds"
fi
# Print the header out
print_header
# Launch the containter
docker run -it -v /vagrant/scripts:/terraform-runner/scripts $CREDS morfien101/terraform-runner
