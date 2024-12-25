kopia server start --insecure --config-file=C:\Kopia\repository.config --log-dir=C:\Kopia\Kopia_Logs --address=127.0.0.1:51515 --server-username=admin --server-password=aaa --enable-actions

:: to have full functinality of kopia server
:: replace the above command with the new one below
:: in it the address was changed to 0.0.0.0 to allow connection over network
:: and tls cert stuff was added to allow server functinality

rem kopia server start --tls-generate-cert --tls-cert-file C:\Kopia\tls_kopia.cert --tls-key-file C:\Kopia\tls_kopia.key --config-file=C:\Kopia\repository.config --log-dir=C:\Kopia\Kopia_Logs --address=0.0.0.0:51515 --server-username=admin --server-password=aaa

:: restart the kopia service and check C:\Kopia if the tls_kopia files are there
:: now again edit this file - remove "--tls-generate-cert" part from it

:: to add user that will be able to backup
:: execute when connected to the repo
rem kopia server user add myuser@mylaptop
