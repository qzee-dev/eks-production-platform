#cluster and worker nodes provisioning
#HPA horizontal pod autoscaller
#autoscaler /kerpenter provisioning
#Loadbalancer Aws ALB/NLB





i) ensure adding lifecycle ignore changes to your terraform to avoiding tiring down and conflict between autos caller and terraform
2)before deploying an autoscaller you need a pod identity to attach the required role necessary for the autoscaller to run in your cluster, we  use pod identity over OIDC
 i)ensure pod identity addons is initially installed before deploying an autoscaller
