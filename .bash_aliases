alias cat="bat"
alias vi="nvim"

alias dockup="docker compose up -d"
alias dockdown="docker compose down -v"

alias tf="terraform"

alias dlstart="gcloud compute instances start gal-test --zone me-west1-c"
alias dlstop="gcloud compute instances stop gal-test --zone me-west1-c"
alias dlcode="code --folder-uri 'vscode-remote://ssh-remote+gal-test/home/gal_aharoni_vayyar_com/sandalwood'"

alias uvci="uv run ruff check && uv run ruff format && uv run ty check"

# Vayyar
alias sqlp_prod_us="./cloud-sql-proxy walabot-home:us-central1:rdbms-postgresql --credentials-file ./service-accounts/walabot-home-62c43d769083.json"
alias sqlp_prod_us_replica="./cloud-sql-proxy walabot-home:us-central1:replica-300f61ef --credentials-file ./service-accounts/walabot-home-62c43d769083.json"
alias sqlp_prod_eu="./cloud-sql-proxy walabot-home:europe-west1:rdbms-postgresql-eu --credentials-file ./service-accounts/walabot-home-62c43d769083.json"
alias sqlp_prod_eu_replica="./cloud-sql-proxy walabot-home:europe-west1:replica-d73e3ed7 --credentials-file ./service-accounts/walabot-home-62c43d769083.json"
alias sqlp_dev="./cloud-sql-proxy walabothome-app-cloud:us-central1:rdbms-postgresql --credentials-file ./service-accounts/walabothome-app-cloud-6cb6a16b1aa8.json"
