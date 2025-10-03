#!/usr/bin/env bash

rm -rf lambda_authorizer/jwt
rm -rf lambda_authorizer/PyJWT*
rm -rf lambda_authorizer.zip
pip install --target lambda_authorizer PyJWT

echo -e "\e[33m Check Docker network for localstack"
DNET=$(docker network ls |grep localstack-tutorial | awk -F' ' {'print $2'})
LSTACK=$(docker ps -a |grep localstack | awk -F' ' {'print $2'} | awk -F'/' {'print $1'})

if [[ ! -d target ]]; then
  echo -e "\e[32m Requires jar file!!!"
  mvn clean package
else
  echo -e "\e[34m Java jar file existed."
  mvn test
fi

if [[ "${DNET}" == "localstack-tutorial" ]]; then
  echo -e "\e[34m Docker Network existed."
  if [[ "${LSTACK}" == "localstack" ]]; then
    tflocal init -reconfigure
    tflocal plan
    tflocal show
    if [[ $? -eq 0 ]]; then
      tflocal apply -auto-approve
    else
      echo -e "\e[31m Error. Check and tries again!!!"
      exit 0
    fi
  else
    echo -e "\e[35m Startup Localstack."
    docker-compose up -d
    sleep 2
    tflocal init -reconfigure
    tflocal plan
    tflocal show
    if [[ $? -eq 0 ]]; then
      tflocal apply -auto-approve
    else
      echo -e "\e[31m Error. Check and tries again!!!"
      exit 0
    fi
  fi
else
  echo -e "\e[35m Create Docker Network."
  docker network create localstack-tutorial
  if [[ "${LSTACK}" == "localstack" ]]; then
    tflocal init -reconfigure
    tflocal plan
    tflocal show
    if [[ $? -eq 0 ]]; then
      tflocal apply -auto-approve
    else
      echo -e "\e[31m Error. Check and tries again!!!"
      exit 0
    fi
  else
    echo -e "\e[35m Startup Localstack."
    docker-compose up -d
    sleep 2
    tflocal init -reconfigure
    tflocal plan
    tflocal show
    if [[ $? -eq 0 ]]; then
      tflocal apply -auto-approve
    else
      echo -e "\e[31m Error. Check and tries again!!!"
      exit 0
    fi
  fi
fi

echo -e "\e[32m Queries API Gateway Details."
#aws --endpoint-url=http://localhost:4566 apigateway get-resources --rest-api-id "$(terraform output api_gateway_id)"
curl -vv http://localhost:4566

DIMAGE=$(docker images |grep devops | awk -F' ' {'print $1'})

if [[ "${DIMAGE}" == "devops" ]]; then
  docker rmi -f devops
  docker build -t devops .
  docker run -d --name devops -p 8080:8080 devops
  curl -vv http://localhost:8080/order
else
  echo "System Error!!!"
  exit 0
fi