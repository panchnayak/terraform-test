def cleanWs() {
        sh "echo clean-workspace"
    }
pipeline {
    agent {
        kubernetes {
            yaml '''
                    apiVersion: v1
                    kind: Pod
                    spec:
                      containers:
                      - name: shell
                        image: hashicorp/terraform:latest
                        command:
                        - sleep
                        args:
                        - infinity
                 '''
            defaultContainer 'shell'
        }
    }
  
    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
    }
    stages {
        stage('Setup Parameters') {
          steps {
            script {
              properties([
                        parameters([
                            choice(choices: ['Default: Do Nothing', 'Apply', 'Destroy'],name: 'ACTION_REQUESTING', description: 'Select the Action')
                        ])
                    ])
            }
          }
        }
        stage('Checkout Code') {
            steps {
				script {
					git url: 'https://github.com/panchnayak/terraform-test.git'
					sh 'ls -la'
				}
            }
        }
        
        stage('Terraform Init') {
            
            steps {
                script {
                    sh 'terraform init'
                }
            }
        }
        stage('Get the Statefile from S3') {
            when { expression { params.ACTION_REQUESTING == 'Destroy'  }  }
            steps {
                script {
                    withAWS(credentials: "AWS_CREDS", region: "us-east-1") {
                        s3Download(file:'tfplan', bucket:'pnayak-demo-bucket', path:'jenkins-jobs/tfplan', force:true) 
                        s3Download(file:'terraform.tfstate', bucket:'pnayak-demo-bucket', path:'jenkins-jobs/terraform.tfstate', force:true) 
                    }
                }
            }
        }
        stage('Terraform Plan') {
            when { expression { params.ACTION_REQUESTING == 'Apply'  }  }
            steps {
                script {
                    sh 'terraform plan -out=tfplan'
                }
            }
        }
        stage('Terraform Apply') {
            when { expression { params.ACTION_REQUESTING == 'Apply'  }  }
            steps {
                script {
                    
                    sh "echo Applying"
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }
        stage('Terraform Destroy') {
            when { expression { params.ACTION_REQUESTING == 'Destroy'  }  }
            steps {
                script {
                    sh "echo Destroying"
                    sh 'terraform destroy -auto-approve tfplan'
                    
                }
            }
        }
       
        stage('Upload State to S3') {
            when { expression { params.ACTION_REQUESTING == 'Apply'  }  }
            steps {
                script {
                    withAWS(credentials: "AWS_CREDS", region: "us-east-1") {
                        s3Upload(file:'terraform.tfstate', bucket:'pnayak-demo-bucket', path:'jenkins-jobs/')
                        s3Upload(file:'tfplan', bucket:'pnayak-demo-bucket', path:'jenkins-jobs/')
                    }
                }
            }
        }
    }
    post {
        always {
            cleanWs()
        }
    }
}
