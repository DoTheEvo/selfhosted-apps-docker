kopia server start --insecure --config-file=C:\Kopia\repository.config --log-dir=C:\Kopia\Kopia_Logs --address=127.0.0.1:51515 --server-username=admin --server-password=aaa --enable-actions

:: to have full functinality of a kopia server
:: replace the above command with the one below
:: in it the address was changed to 0.0.0.0 to allow connection over network
:: and tls cert stuff was added without which server does not functions

:: kopia server start --tls-generate-cert --tls-cert-file C:\Kopia\tls_kopia.cert --tls-key-file C:\Kopia\tls_kopia.key --config-file=C:\Kopia\repository.config --log-dir=C:\Kopia\Kopia_Logs --address=0.0.0.0:51515 --server-username=admin --server-password=aaa

:: restart the kopia service and check C:\Kopia if the tls_kopia files are now there
:: now again edit this file to remove "--tls-generate-cert" part from the command
:: restart the service again

:: log in to the webGUI and create a repo

:: now theres need to add users that will be able to backup to that repo
:: no GUI for that for whatever reason
:: open windows cmd / powershell as admin
:: connect to the repo manually
:: could help going to the webgui > repository > small shell-icon at the bottom
:: click on it and it will show command to execute to get repo status
:: adjust the command to be about adding a user

::  C:\Kopia\kopia.exe --config-file=C:\Kopia\repository.config server user add myuser@mylaptop

:: once again restart the kopia service

:: now finally can go to the client machine
:: Kopia Repository Server
:: give the ip address and port, use https, something like https://10.0.19.95:51515
:: write random stuff in to "Trusted server certificate fingerprint (SHA256)"
:: kopia on connect attempt will tell what the the real fingerprint is
:: kopy it in to the field and try connect agan
:: can override username/machine name in the advanced section
