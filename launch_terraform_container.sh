#!/bin/bash
echo "Remember to add your AWS Keys"
echo ""
echo "######################################################"
echo "export AWS_ACCESS_KEY_ID=<your key>"
echo "export AWS_SECRET_ACCESS_KEY=<your secret key>"
echo "######################################################"
echo ""
echo "Lauching container."
echo "The host name should change now to signal that you are in the container."
echo "     ▼▼▼▼▼▼▼▼▼▼▼▼"
docker run -it -v /vagrant/scripts:/terraform-runner/scripts morfien101/terraform-runner
