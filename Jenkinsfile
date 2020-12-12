/*
    This is a pipeline that implement full CI/CD for deploying app-preq,webapp,poller,notififer to AKS cluster.
    The pipeline is made up of 6 main steps
    1. Git clone and setup
    2. Build and local tests
    3. Publish Docker and Helm
    4. Deploy to dev and test
    5. Deploy to staging and test
    6. Optionally deploy to production and test
 */

/*
    Create the kubernetes namespace
 */
def createNamespace (name) {
    echo "Creating namespace ${name} if needed"
    sh "kubectl create namespace ${name} --dry-run -o yaml | kubectl apply -f -"
    echo "${name} namespace created"
}

def helmDryrunAppPrereq () {
    echo "dryrun app-prereq"
    sh "/usr/local/bin/helm upgrade --dry-run --debug --install app-prereq ./helm/app-prereq -n monitoring --debug"
}

def helmInstallAppPrereq () {
    echo "deploying app-prereq"
    sh "/usr/local/bin/helm upgrade --install app-prereq ./helm/app-prereq -n monitoring"
}

def helmDryrunElasticSearch () {
    echo "dryrun app-prereq"
    sh "/usr/local/bin/helm upgrade --install elasticsearch-exporter prometheus-community/prometheus-elasticsearch-exporter -n monitoring --dry-run --debug"
}

def helmInstallElasticSearch () {
    echo "deploying app-prereq"
    sh "/usr/local/bin/helm upgrade --install elasticsearch-exporter prometheus-community/prometheus-elasticsearch-exporter -n monitoring"
}

def applyCRDS (){
    sh "kubectl apply -f ./helm/crds/"
}

def helmDryrunAppNginx () {
    echo "dryrun app-prereq"
    sh "/usr/local/bin/helm upgrade --install app-nginx ./helm/ingress-nginx  -n monitoring --dry-run --debug"
}

def helmInstallAppNginx () {
    echo "deploying app-prereq"
    sh "/usr/local/bin/helm upgrade --install app-nginx ./helm/ingress-nginx  -n monitoring"
}

def addJetstackRepo (){
    sh "/usr/local/bin/helm repo add jetstack https://charts.jetstack.io"
}

def addCertCRDS (){
    sh "kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.0.4/cert-manager.crds.yaml"
}

def helmDryrunCertManager () {
    echo "dryrun app-prereq"
    sh "/usr/local/bin/helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager  --version v1.0.4 --dry-run --debug"
}

def helmInstallCertManager () {
    script {
        echo "dryrun app-prereq"
        sh "/usr/local/bin/helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager  --version v1.0.4"
        sh "sleep 120"
    }
}

def issueIssuer () {
    sh "kubectl apply -f ./helm/issuer/letsencrypt-staging.yaml -n monitoring"
}

def extSvc () {
    sh "kubectl apply -f ./helm/webapp/external-svc.yaml"
}

def helmDryrunWebapp () {
    echo "dryrun webapp"
    sh "/usr/local/bin/helm upgrade --install webapp ./helm/webapp -n api --set image.repository='${webappImage}',secret.regcred.dockerconfigjson=${env.dockerString},configmap.rdsurl='${env.webappRdsurl}' --dry-run --debug"
}

def helmInstallWebapp() {
    echo "deploying webapp"
    sh "/usr/local/bin/helm upgrade --install webapp ./helm/webapp -n api --set image.repository='${webappImage}',secret.regcred.dockerconfigjson=${env.dockerString},configmap.rdsurl='${env.webappRdsurl}'"
}

def helmDryrunPoller () {
    echo "dryrun poller"
    sh "/usr/local/bin/helm upgrade --install poller ./helm/poller -n api --set image.repository='${pollerImage}',secret.regcred.dockerconfigjson=${env.dockerString},configmap.rdsurl='${env.pollerRdsurl}' --dry-run --debug"
}

def helmInstallPoller () {
    echo "deploying poller"
    sh "/usr/local/bin/helm upgrade --install poller ./helm/poller -n api --set image.repository='${pollerImage}',secret.regcred.dockerconfigjson=${env.dockerString},configmap.rdsurl='${env.pollerRdsurl}'"
}

def helmDryrunNotifier () {
    echo "dryrun notifier"
    sh "/usr/local/bin/helm upgrade --install notifier ./helm/notifier -n api --set image.repository='${notifierImage}',secret.regcred.dockerconfigjson=${env.dockerString},configmap.rdsurl='${env.notifierRdsurl}' --dry-run --debug"
}

def helmInstallNotifier () {
    echo "deploying notifier"
    sh "/usr/local/bin/helm upgrade --install notifier ./helm/notifier -n api --set image.repository='${notifierImage}',secret.regcred.dockerconfigjson=${env.dockerString},configmap.rdsurl='${env.notifierRdsurl}'"
}


node {
    stage('Clone repository and setup of azure') {
        /* Cloning the Repository to our Workspace */
        checkout scm
        withCredentials([azureServicePrincipal('AzureID')]) {
            sh 'az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET -t $AZURE_TENANT_ID'   
        }
        sh "az aks show --resource-group aks-csye7125-rg  --name azureCsyeCluster  --query fqdn"
        sh "az aks get-credentials --resource-group aks-csye7125-rg  --name azureCsyeCluster"
         sh "kubectl get nodes"
        // sh "export aws_profile=${env.aws_profile}"
        // sh "export aws_region=${env.aws_region}"
        // sh "export KOPS_STATE_STORE=${env.S3BucketName}"
        // sh "AWS_PROFILE=${env.aws_profile} AWS_ACCESS_KEY_ID=${env.awsKey} AWS_SECRET_ACCESS_KEY=${env.awsSecret} kops export kubecfg ${env.YOUR_CLUSTER_NAME} --state=${env.S3BucketName}"
        
    }
    try {
        stage ('helm test') {
            echo "$pwd"
            helmDryrunAppPrereq ()
            helmDryrunElasticSearch ()
            helmDryrunAppNginx ()
            addJetstackRepo()
            helmDryrunCertManager ()
            helmDryrunWebapp ()
            helmDryrunPoller ()
            helmDryrunNotifier ()
        }

        stage('create namespace') {
            createNamespace('monitoring') 
            createNamespace('cert-manager') 
            createNamespace('api') 
        } 

        stage('appprereq deployment') {
            helmInstallAppPrereq ()
        }
        stage('elasticsearch deployment'){
            helmInstallElasticSearch ()
        }
        stage('nginx deployment') {
            helmInstallAppNginx ()
        }
        stage('crd deployment') {
            applyCRDS ()
            addJetstackRepo ()
            addCertCRDS ()
        }
        stage('nginx deployment') {
            helmInstallCertManager ()
            issueIssuer ()
        }
        stage('webapp deployment') {
            extSvc ()
            helmInstallWebapp()
        }
        stage('poller deployment') {
            helmInstallPoller ()
        }
        stage('notifier deployment') {
            helmInstallNotifier ()
        }   
    }
     catch (Exception err){
            err_msg = "Test had Exception(${err})"
            currentBuild.result = 'FAILURE'
            error "FAILED - Stopping build for Error(${err_msg})"
    }

}