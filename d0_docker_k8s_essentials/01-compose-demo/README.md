# Docker compose demo

## Access to Docker playground

- Create your docker account at [Docker Signup](https://hub.docker.com/signup).

- A free Docker playground can be found at [Play-with-docker](https://labs.play-with-docker.com).

- Add new instance

## Deploy the sample application

- Clone the course reposistory

```
git clone https://github.com/hungtran84/k8s-cka.git
Cloning into 'k8s-cka'...
remote: Enumerating objects: 874, done.
remote: Counting objects: 100% (198/198), done.
remote: Compressing objects: 100% (151/151), done.
remote: Total 874 (delta 80), reused 117 (delta 40), pack-reused 676
Receiving objects: 100% (874/874), 3.50 MiB | 19.80 MiB/s, done.
Resolving deltas: 100% (430/430), done.
```

- Deploy the application using Docker compose

```
cd k8s-cka/d0_docker_k8s_essentials/01-compose-demo
docker-compose up -d
```

- Access your application using `playwithdocker` UI
  
![lab01-1](https://github.com/hungtran84/k8s-cka/assets/30172743/e3e0c62b-bc4a-4ceb-afd0-60c973aae952)


![lab01-2](https://github.com/hungtran84/k8s-cka/assets/30172743/57b2427c-865d-436e-ada4-b41fc7e3897a)


- Change application code to view the live update

```
sed -i 's/students/users/g' app.py
```

- Refresh browser to see the update

![lab01-3](https://github.com/hungtran84/k8s-cka/assets/30172743/4a9a86e9-0d67-4a49-8450-76de8ceb6311)

