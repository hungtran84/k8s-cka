## Executing tasks with Jobs, check out the file job.yaml
- Ensure you define a `restartPolicy`, the default of a Pod is `Always`, which is not compatible with a Job.
We'll need `OnFailure` or `Never`, let's look at `OnFailure`
```
kubectl apply -f job.yaml
job.batch/hello-world-job created
```

- Follow job status with a watch
```
kubectl get job --watch

NAME              COMPLETIONS   DURATION   AGE
hello-world-job   1/1           8s         16s
```

- Get the list of `Pods`, status is `Completed` and `Ready` is 0/1
```
kubectl get pods

NAME                    READY   STATUS      RESTARTS   AGE
hello-world-job-trd68   0/1     Completed   0          67s
```

- Let's get some more details about the job `labels`, `selectors`, `Start Time`, `Duration` and `Pod Statuses`
```
kubectl describe job hello-world-job

Name:             hello-world-job
Namespace:        default
Selector:         batch.kubernetes.io/controller-uid=ffb45834-4875-439f-933d-337cec9f3128
Labels:           batch.kubernetes.io/controller-uid=ffb45834-4875-439f-933d-337cec9f3128
                  batch.kubernetes.io/job-name=hello-world-job
                  controller-uid=ffb45834-4875-439f-933d-337cec9f3128
                  job-name=hello-world-job
Annotations:      batch.kubernetes.io/job-tracking: 
Parallelism:      1
Completions:      1
Completion Mode:  NonIndexed
Start Time:       Fri, 18 Aug 2023 15:50:59 +0000
Completed At:     Fri, 18 Aug 2023 15:51:07 +0000
Duration:         8s
Pods Statuses:    0 Active (0 Ready) / 1 Succeeded / 0 Failed
Pod Template:
  Labels:  batch.kubernetes.io/controller-uid=ffb45834-4875-439f-933d-337cec9f3128
           batch.kubernetes.io/job-name=hello-world-job
           controller-uid=ffb45834-4875-439f-933d-337cec9f3128
           job-name=hello-world-job
  Containers:
   ubuntu:
    Image:      ubuntu
    Port:       <none>
    Host Port:  <none>
    Command:
      /bin/bash
      -c
      /bin/echo Hello from Pod $(hostname) at $(date)
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Events:
  Type    Reason            Age   From            Message
  ----    ------            ----  ----            -------
  Normal  SuccessfulCreate  2m    job-controller  Created pod: hello-world-job-trd68
  Normal  Completed         112s  job-controller  Job completed
```

- Get the logs from stdout from the Job Pod
```
kubectl get pods -l job-name=hello-world-job
NAME                    READY   STATUS      RESTARTS   AGE
hello-world-job-trd68   0/1     Completed   0          3m56s

kubectl logs hello-world-job-trd68
Hello from Pod hello-world-job-trd68 at Fri Aug 18 15:51:05 UTC 2023
```

- Our Job is completed, but it's up to use to delete the Pod or the Job.
```
kubectl delete job hello-world-job
```

- Which will also delete it's `Pods`
```
kubectl get pods
No resources found in default namespace.
```

## Show `restartPolicy` in action, check out `backoffLimit: 2` and `restartPolicy: Never`
- We'll want to use `Never` so our pods aren't deleted after `backoffLimit` is reached.
```
kubectl apply -f job-failure-OnFailure.yaml
```

- Let's look at the pods, enters a backoffloop after 2 crashes
```
kubectl get pods --watch
NAME                         READY   STATUS   RESTARTS   AGE
hello-world-job-fail-gbfcn   0/1     Error    0          46s
hello-world-job-fail-hktlg   0/1     Error    0          21s
hello-world-job-fail-wwjb2   0/1     Error    0          61s
```
- The pods aren't deleted so we can troubleshoot here if needed.
And the job won't have any completions and it doesn't get deleted
```
kubectl get jobs 
```

- So let's review what the job did
```
kubectl describe jobs | more

Name:             hello-world-job-fail
Namespace:        default
Selector:         batch.kubernetes.io/controller-uid=d60d25d9-fb3a-4f51-bb15-cf5e53771929
Labels:           batch.kubernetes.io/controller-uid=d60d25d9-fb3a-4f51-bb15-cf5e53771929
                  batch.kubernetes.io/job-name=hello-world-job-fail
                  controller-uid=d60d25d9-fb3a-4f51-bb15-cf5e53771929
                  job-name=hello-world-job-fail
Annotations:      batch.kubernetes.io/job-tracking: 
Parallelism:      1
Completions:      1
Completion Mode:  NonIndexed
Start Time:       Fri, 18 Aug 2023 15:58:05 +0000
Pods Statuses:    0 Active (0 Ready) / 0 Succeeded / 3 Failed
Pod Template:
  Labels:  batch.kubernetes.io/controller-uid=d60d25d9-fb3a-4f51-bb15-cf5e53771929
           batch.kubernetes.io/job-name=hello-world-job-fail
           controller-uid=d60d25d9-fb3a-4f51-bb15-cf5e53771929
           job-name=hello-world-job-fail
  Containers:
   ubuntu:
    Image:      ubuntu
    Port:       <none>
    Host Port:  <none>
    Command:
      /bin/bash
      -c
      /bin/ech Hello from Pod $(hostname) at $(date)
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Events:
  Type     Reason                Age    From            Message
  ----     ------                ----   ----            -------
  Normal   SuccessfulCreate      5m1s   job-controller  Created pod: hello-world-job-fail-wwjb2
  Normal   SuccessfulCreate      4m46s  job-controller  Created pod: hello-world-job-fail-gbfcn
  Normal   SuccessfulCreate      4m21s  job-controller  Created pod: hello-world-job-fail-hktlg
  Warning  BackoffLimitExceeded  4m18s  job-controller  Job has reached the specified backoff limit
```

- Clean up this job
```
kubectl delete jobs hello-world-job-fail
kubectl get pods
```



## Defining a Parallel Job
```
kubectl apply -f ParallelJob.yaml
job.batch/hello-world-job-parallel created
```

- 10 Pods will run in parallel up until 50 completions
```
kubectl get pods

NAME                             READY   STATUS      RESTARTS   AGE
hello-world-job-parallel-27w25   0/1     Completed   0          26s
hello-world-job-parallel-2lw7g   0/1     Completed   0          38s
hello-world-job-parallel-2p4j7   0/1     Completed   0          37s
hello-world-job-parallel-2r95c   0/1     Completed   0          50s
hello-world-job-parallel-45fvj   0/1     Completed   0          49s
hello-world-job-parallel-49b8m   0/1     Completed   0          31s
hello-world-job-parallel-4qp6l   0/1     Completed   0          43s
hello-world-job-parallel-6jbnn   0/1     Completed   0          38s
hello-world-job-parallel-6l2db   0/1     Completed   0          50s
hello-world-job-parallel-7hqq7   0/1     Completed   0          21s
hello-world-job-parallel-7kgq2   0/1     Completed   0          38s
hello-world-job-parallel-829df   0/1     Completed   0          49s
hello-world-job-parallel-8lfzb   0/1     Completed   0          23s
hello-world-job-parallel-9grvh   0/1     Completed   0          32s
hello-world-job-parallel-bkftc   0/1     Completed   0          45s
hello-world-job-parallel-ccpdp   0/1     Completed   0          26s
hello-world-job-parallel-chcxl   0/1     Completed   0          26s
hello-world-job-parallel-dbrq7   0/1     Completed   0          25s
hello-world-job-parallel-f4wx5   0/1     Completed   0          50s
hello-world-job-parallel-fl7rz   0/1     Completed   0          37s
hello-world-job-parallel-fwxmj   0/1     Completed   0          45s
hello-world-job-parallel-hbsx2   0/1     Completed   0          49s
hello-world-job-parallel-jbzrv   0/1     Completed   0          25s
hello-world-job-parallel-k682x   0/1     Completed   0          32s
hello-world-job-parallel-kdg8c   0/1     Completed   0          43s
hello-world-job-parallel-kzcrf   0/1     Completed   0          43s
hello-world-job-parallel-ljnlj   0/1     Completed   0          33s
hello-world-job-parallel-m4vxv   0/1     Completed   0          25s
hello-world-job-parallel-mrntc   0/1     Completed   0          39s
hello-world-job-parallel-nktvj   0/1     Completed   0          45s
hello-world-job-parallel-nwh7v   0/1     Completed   0          25s
hello-world-job-parallel-pdn75   0/1     Completed   0          36s
hello-world-job-parallel-q4xgv   0/1     Completed   0          44s
hello-world-job-parallel-q6g7c   0/1     Completed   0          50s
hello-world-job-parallel-qkfdv   0/1     Completed   0          26s
hello-world-job-parallel-r9zbp   0/1     Completed   0          27s
hello-world-job-parallel-rdwbb   0/1     Completed   0          38s
hello-world-job-parallel-rj882   0/1     Completed   0          43s
hello-world-job-parallel-sdg69   0/1     Completed   0          32s
hello-world-job-parallel-sknbv   0/1     Completed   0          31s
hello-world-job-parallel-sksql   0/1     Completed   0          50s
hello-world-job-parallel-sr8nv   0/1     Completed   0          50s
hello-world-job-parallel-tzddz   0/1     Completed   0          37s
hello-world-job-parallel-v4bhg   0/1     Completed   0          38s
hello-world-job-parallel-w2lh4   0/1     Completed   0          50s
hello-world-job-parallel-wpr87   0/1     Completed   0          31s
hello-world-job-parallel-xf9k4   0/1     Completed   0          45s
hello-world-job-parallel-z2b5s   0/1     Completed   0          31s
hello-world-job-parallel-z6ssz   0/1     Completed   0          31s
hello-world-job-parallel-zzvrn   0/1     Completed   0          32s
```

- We can 'watch' the `Statuses` with watch
```
watch 'kubectl describe job | head -n 11'
```

- We'll get to 50 completions very quickly
```
kubectl get jobs
NAME                       COMPLETIONS   DURATION   AGE
hello-world-job-parallel   50/50         35s        2m4s
```

- Let's clean up...
```
kubectl delete job hello-world-job-parallel
```


## Scheduling tasks with `CronJobs`
```
kubectl apply -f CronJob.yaml
cronjob.batch/hello-world-cron created
```

- Quick overview of the job and it's schedule
```
kubectl get cronjobs
NAME               SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
hello-world-cron   */1 * * * *   False     1        2s              20s
```

- But let's look closer at `Schedule`, `Concurrency`, `Suspend`,`Starting Deadline Seconds`, `Events`
```
kubectl describe cronjobs | more 
Name:                          hello-world-cron
Namespace:                     default
Labels:                        <none>
Annotations:                   <none>
Schedule:                      */1 * * * *
Concurrency Policy:            Allow
Suspend:                       False
Successful Job History Limit:  3
Failed Job History Limit:      1
Starting Deadline Seconds:     <unset>
Selector:                      <unset>
Parallelism:                   <unset>
Completions:                   <unset>
Pod Template:
  Labels:  <none>
  Containers:
   ubuntu:
    Image:      ubuntu
    Port:       <none>
    Host Port:  <none>
    Command:
      /bin/bash
      -c
      /bin/echo Hello from Pod $(hostname) at $(date)
    Environment:     <none>
    Mounts:          <none>
  Volumes:           <none>
Last Schedule Time:  Fri, 18 Aug 2023 16:20:00 +0000
Active Jobs:         <none>
Events:
  Type    Reason            Age   From                Message
  ----    ------            ----  ----                -------
  Normal  SuccessfulCreate  113s  cronjob-controller  Created job hello-world-cron-28206259
  Normal  SawCompletedJob   108s  cronjob-controller  Saw completed job: hello-world-cron-28206259, status: Complete
  Normal  SuccessfulCreate  53s   cronjob-controller  Created job hello-world-cron-28206260
  Normal  SawCompletedJob   48s   cronjob-controller  Saw completed job: hello-world-cron-28206260, status: Complete
```

- Get a overview again...
```
kubectl get cronjobs
NAME               SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
hello-world-cron   */1 * * * *   False     0        41s             2m59s
```

- The pods will stick around, in the event we need their logs or other inforamtion. How long?
```
kubectl get pods --watch
NAME                              READY   STATUS      RESTARTS   AGE
hello-world-cron-28206260-lgw6d   0/1     Completed   0          2m36s
hello-world-cron-28206261-8n8r2   0/1     Completed   0          96s
hello-world-cron-28206262-6w724   0/1     Completed   0          36s
hello-world-cron-28206263-t94qb   0/1     Pending     0          0s
hello-world-cron-28206263-t94qb   0/1     Pending     0          0s
hello-world-cron-28206263-t94qb   0/1     ContainerCreating   0          0s
hello-world-cron-28206263-t94qb   0/1     Completed           0          4s
hello-world-cron-28206263-t94qb   0/1     Completed           0          5s
hello-world-cron-28206263-t94qb   0/1     Completed           0          6s
hello-world-cron-28206263-t94qb   0/1     Completed           0          6s
hello-world-cron-28206260-lgw6d   0/1     Terminating         0          3m6s
hello-world-cron-28206260-lgw6d   0/1     Terminating         0          3m6s
```

- They will stick around for `successfulJobsHistoryLimit`, which defaults to `3`
```
kubectl get cronjobs hello-world-cron -oyaml



#Clean up the job...
kubectl delete cronjob hello-world-cron

apiVersion: batch/v1
kind: CronJob
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"batch/v1","kind":"CronJob","metadata":{"annotations":{},"name":"hello-world-cron","namespace":"default"},"spec":{"jobTemplate":{"spec":{"template":{"spec":{"containers":[{"command":["/bin/bash","-c","/bin/echo Hello from Pod $(hostname) at $(date)"],"image":"ubuntu","name":"ubuntu"}],"restartPolicy":"Never"}}}},"schedule":"*/1 * * * *"}}
  creationTimestamp: "2023-08-18T16:18:42Z"
  generation: 1
  name: hello-world-cron
  namespace: default
  resourceVersion: "9310"
  uid: 1e07a52a-3ce0-494b-bcf6-8c79dcf421c6
spec:
  concurrencyPolicy: Allow
  failedJobsHistoryLimit: 1
  jobTemplate:
    metadata:
      creationTimestamp: null
    spec:
      template:
        metadata:
          creationTimestamp: null
        spec:
          containers:
          - command:
            - /bin/bash
            - -c
            - /bin/echo Hello from Pod $(hostname) at $(date)
            image: ubuntu
            imagePullPolicy: Always
            name: ubuntu
            resources: {}
            terminationMessagePath: /dev/termination-log
            terminationMessagePolicy: File
          dnsPolicy: ClusterFirst
          restartPolicy: Never
          schedulerName: default-scheduler
          securityContext: {}
          terminationGracePeriodSeconds: 30
  schedule: '*/1 * * * *'
  successfulJobsHistoryLimit: 3
  suspend: false
status:
  lastScheduleTime: "2023-08-18T16:24:00Z"
  lastSuccessfulTime: "2023-08-18T16:24:05Z"
```

- Cleanup cronjob
```
kubectl delete cronjobs hello-world-cron
cronjob.batch "hello-world-cron" deleted
```
