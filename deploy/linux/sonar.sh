#!/bin/bash

# Crée un réseau Docker personnalisé
docker network create mon-reseau

env_file="../env.env"

env_value=""
# Vérifier si le fichier existe
if [ -f "$env_file" ]; then
    # Utiliser grep pour rechercher la ligne contenant la variable env
    env_line=$(grep '^env=' "$env_file")

    # Vérifier si la ligne a été trouvée
    if [ -n "$env_line" ]; then
        # Utiliser cut pour extraire la valeur de la variable env
        env_value=$(echo "$env_line" | cut -d'=' -f2)
        echo "La valeur de 'env' est : $env_value"
    else
        echo "La variable 'env' n'a pas été trouvée dans $env_file."
    fi
else
    echo "Le fichier $env_file n'existe pas."
fi

adminUsername="admin"
adminPassword="admin"
newPassword="admin1"
sonarqubeURL="http://localhost:9000"

# Vérifie si un conteneur SonarQube est déjà lancé sur les mêmes ports
existingContainer=$(docker ps --filter "publish=9000" --filter "publish=9092" -q)
if [ -z "$existingContainer" ]; then
    echo "Un conteneur SonarQube n'est pas déjà en cours d'exécution sur les mêmes ports."
    docker run -d --name sonarqube --network mon-reseau -p 9000:9000 -p 9092:9092 sonarqube:latest
    sonarqubeIP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' sonarqube)
    echo "ip du conteneur : $sonarqubeIP"
    if [ -z "$sonarqubeIP" ]; then
        echo "Erreur : L'adresse IP du conteneur SonarQube n'a pas été récupérée."
        exit 1
    fi
    echo "URL de SonarQube : $sonarqubeURL"
    echo "On va attendre ensemble 40 sec que SonarQube se lance"
    sleep 40
    echo "SonarQube est maintenant prêt !"
    curl -u admin:admin -X POST "http://localhost:9000/api/users/change_password?login=admin&previousPassword=admin&password=$newPassword"
else
    sonarqubeIP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' sonarqube)
fi

# Mise à jour des informations d'authentification avec le nouveau mot de passe
base64AuthInfo=$(echo -n "${adminUsername}:${newPassword}" | base64)

# Vérifie si l'URL de SonarQube est accessible avec le nouveau mot de passe
if ! curl -s -f -u "${adminUsername}:${newPassword}" $sonarqubeURL; then
    echo "Erreur : Impossible de se connecter à l'URL de SonarQube ($sonarqubeURL) avec le nouveau mot de passe."
    exit 1
fi

# Configuration des paramètres pour la requête de création de projet
projectName="front"
projectKey="front"
projectVisibility="public"

# URL pour interroger les projets existants
sonarqubeProjectsQueryURL="$sonarqubeURL/api/projects/search"

# Requête pour vérifier si le projet existe
projectsResponse=$(curl -s -u "${adminUsername}:${newPassword}" "$sonarqubeProjectsQueryURL?projects=$projectKey")

# Extraire la présence du projet à partir de la réponse
projectExists=$(echo $projectsResponse | grep -o "\"key\":\"$projectKey\"")

if [ -z "$projectExists" ]; then
    echo "Le projet '$projectName' n'existe pas. Création du projet en cours."

    # URL pour la création de projet
    sonarqubeCreateProjectURL="$sonarqubeURL/api/projects/create"

    # Données pour la création de projet
    projectCreateData="name=$projectName&project=$projectKey&visibility=$projectVisibility"

    # Envoi de la requête POST pour créer le projet
    createProjectResponse=$(curl -s -o /dev/null -w "%{http_code}" -u "${adminUsername}:${newPassword}" -X POST -d "$projectCreateData" "$sonarqubeCreateProjectURL")

    if [ "$createProjectResponse" -eq "200" ]; then
        echo "Projet '$projectName' créé avec succès dans SonarQube."
    else
        echo "Erreur lors de la création du projet '$projectName'. Réponse HTTP: $createProjectResponse"
        exit 1
    fi
else
    echo "Le projet '$projectName' existe déjà dans SonarQube."
fi
# Génération d'un nom de token aléatoire
generate_random_string() {
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 20 | head -n 1
}

tokenName=$(generate_random_string)
echo "Nom du token généré : $tokenName"

# Préparation du payload pour la requête
tokenGenerationQueryString="name=$tokenName"

# URL pour la génération du token
sonarqubeTokenGenerationURL="$sonarqubeURL/api/user_tokens/generate"

# Envoi de la requête
tokenResponse=$(curl -s -u "${adminUsername}:${newPassword}" -X POST -d "$tokenGenerationQueryString" -H "Content-Type: application/x-www-form-urlencoded" $sonarqubeTokenGenerationURL)
if [ -z "$tokenResponse
" ]; then
echo "Erreur lors de la génération du token"
exit 1
fi
echo "Token généré avec succès"

sonarToken=$(echo "$tokenResponse" | grep -oP '(?<="token":")[^"]*')

sonarqubeURL="http://$sonarqubeIP:9000"

echo "SonarQube URL: $sonarqubeURL"
echo "Sonar Token: $sonarToken"

nomConteneur="projet-rentree-front-$env_value"

# Assurez-vous que ce conteneur est déjà en cours d'exécution
dockerCommand="docker exec -e SONAR_HOST_URL=$sonarqubeURL -e SONAR_TOKEN=$sonarToken $nomConteneur sonar-scanner"

echo "Exécution de la commande Docker pour l'analyse SonarQube"
eval "$dockerCommand"
