Install localstack Terraform to your local machine by following the url below.

https://docs.localstack.cloud/aws/integrations/infrastructure-as-code/terraform/ 


```
docker network create localstack-tutorial
docker-compose up -d --build
docker ps -a    # make sure the localstack is running
tflocal init -reconfigure
tflocal plan
tflocal apply
```

cleanup the localstack
```
tflocal destroy
docker ps -a
docker rm -f <containerID>
docker network prune
docker container prune
````