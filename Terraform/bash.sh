#!/bin/bash

# Port-Forwarding ausführen
# kubectl port-forward svc/argocd-server -n argocd 8080:443 &

# Terraform initialisieren und anwenden
terraform init
terraform apply -auto-approve

# Überprüfen, ob Terraform erfolgreich ausgeführt wurde
if [ $? -eq 0 ]; then
    
    # Namespace für ArgoCD erstellen und manifeste installieren
    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

    # Auslesen des DNS-Namens des Elastic Load Balancers
    ELB_DNS=$(terraform output elb_dns)

    # Anwenden der YAML-Datei für die Anwendungsbereitstellung
    kubectl apply -f ingress.yaml 

    # Abfrage des ArgoCD-Admin-Passworts
    ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    echo "ArgoCD Admin Passwort: $ARGOCD_PASSWORD"

    # Anwendungskonfiguration für ArgoCD erstellen
    #argocd app create example-app --repo https://github.com/Sadek-Murad/example-k8s-applicationS.git --path example-app --dest-server https://kubernetes.default.svc --dest-namespace default --server a6fb5f83daf7846039a463aea330db24-953897181.eu-central-1.elb.amazonaws.com --insecure

    argocd app create guestbook --repo https://github.com/argoproj/argocd-example-apps.git --path guestbook --dest-server https://kubernetes.default.svc --dest-namespace default --server a6fb5f83daf7846039a463aea330db24-953897181.eu-central-1.elb.amazonaws.com --insecure
    
else
    echo "Terraform-Ausführung fehlgeschlagen. Bitte überprüfen Sie die Fehlermeldungen."
fi
