alias vi="nvim"

alias dockup="docker compose up -d"
alias dockdown="docker compose down -v"

alias tf="terraform"

alias dlstart="gcloud compute instances start gal-test --zone me-west1-c"
alias dlstop="gcloud compute instances stop gal-test --zone me-west1-c"
alias dlcode="code --folder-uri 'vscode-remote://ssh-remote+gal-test/home/gal_aharoni_vayyar_com/pyproj'"

# Vayyar
alias sqlp_prod_us="./cloud-sql-proxy walabot-home:us-central1:rdbms-postgresql --credentials-file ./service-accounts/walabot-home-62c43d769083.json"
alias sqlp_prod_eu="./cloud-sql-proxy walabot-home:europe-west1:rdbms-postgresql-eu --credentials-file ./service-accounts/walabot-home-62c43d769083.json"
