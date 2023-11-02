REM set ARM_TENANT_ID=chgeuerfte.aad.geuer-pollmann.de
REM set ARM_SUBSCRIPTION_ID=724467b5-bee4-484b-bf13-d6a5505d2b51
REM set ARM_CLIENT_ID=53bd3124-6358-4a70-9490-64b45c9c9c9c
REM Read the secret from a text file into the environment variable
REM set /p ARM_CLIENT_SECRET=<%HOME%\%ARM_CLIENT_ID%.client_secret


set ARM_OIDC_REQUEST_TOKEN=secrettoken
set ARM_OIDC_REQUEST_URL=https://hp.geuer-pollmann.de:3000/token/issue?prettyplease

terraform init

terraform apply