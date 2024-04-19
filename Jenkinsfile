def aws_region
pipeline {
    agent any

    stages {
        stage('Setup Parameters') {
          steps {
            script {
              properties([
                        parameters([
                            choice(choices: ['Default: Do Nothing', 'QTS_RTOP','QTS_Chicago','QTS_Dallas','AWS_US_EAST_2', 'AWS_US_WEST_2'],name: 'Select_The_Region', description: 'Select the Region'),
                            choice(choices: ['Default: Do Nothing', 'nessdemo.local','crit.nessdemo.local', 'ds.nessdemo.local'],name: 'Select_The_Domain', description: 'Select the Domain'),
                            choice(choices: ['Default: Do Nothing', 'Deploy', 'Destroy'],name: 'Terraform_Action', description: 'Select the Action')
                            
                        ])
                    ])
            }
          }
        }
        stage('Checkout Code') {
            steps {
				script {
					git branch: 'master', url: 'https://github.com/panchnayak/terraform-test.git'
					bat 'dir'
				}
            }
        }
        
        stage('Terraform Init') {
            steps {
                script {
                    bat 'terraform init'
                }
            }
        }
        stage('Terraform Plan') {
            when { expression { params.Terraform_Action == 'Deploy'  }  }
            steps {
                script {
                        bat "echo Plan"
                        bat 'terraform plan -out=tfplan'
                }
            }
        }
        stage('Terraform Apply') {
            when { expression { params.Terraform_Action == 'Deploy'  }  }
            parallel {
                stage('Deploy to EAST Region') {
                    when { expression { params.Select_The_Region == 'AWS_US_EAST_2'  }  }
                    steps {
                        
                        script {
                                bat "echo Applying on ${AWS_REGION}"
                                bat 'terraform apply -var aws_region=us-east-2 -auto-approve'
                                bat "echo Upload State to S3"
                                withAWS(region: "us-east-2") {
                                    s3Upload(file:'terraform.tfstate', bucket:'pnayak-demo-bucket', path:'jenkins-jobs/')
                                    bat 'echo terraform state uploaded"
                                }
                                bat "echo Terraform Applied to us-east-2 region"
                        }
                    }
                }
                stage('Terraform Apply') {
                when { expression { params.Select_The_Region == 'AWS_US_WEST_2'  }  }
                    steps {
                        script {
                                bat "echo Applying on ${AWS_REGION}"
                                bat 'terraform apply -var aws_region=us-west-2 -auto-approve'
                                bat "echo Upload State to S3"
                                withAWS(region: "us-west-2") {
                                    s3Upload(file:'terraform.tfstate', bucket:'pnayak-demo-bucket', path:'jenkins-jobs/')
                                    bat 'echo terraform state uploaded"
                                }
                                bat "echo Terraform Applied to us-west-2 region"
                        }
                    }
                }
            }
        stage('Terraform Destroy') {
            when { expression { params.Terraform_Action == 'Destroy'  }  }
            stage('Terraform Apply') {
            when { expression { params.Terraform_Action == 'Deploy'  }  }
            parallel {
                stage('Deploy to EAST Region') {
                    when { expression { params.Select_The_Region == 'AWS_US_EAST_2'  }  }
                    steps {
                        script {
                                bat "echo Destroying"
                                bat "echo Get the Statefile from S3"
                                withAWS(region: "us-east-1") {
                                    s3Download(file:'terraform.tfstate', bucket:'pnayak-demo-bucket', path:'jenkins-jobs/terraform.tfstate', force:true) 
                                }
                                bat 'dir'
                                bat "terraform destroy -var aws_region=us-east-2 -auto-approve"
                        }
                    }
                }
                stage('Terraform Apply') {
                when { expression { params.Select_The_Region == 'AWS_US_WEST_2'  }  }
                    steps {
                        script {
                                bat "echo Destroying"
                                bat "echo Get the Statefile from S3"
                                withAWS(region: "us-west-1") {
                                    s3Download(file:'terraform.tfstate', bucket:'pnayak-demo-bucket', path:'jenkins-jobs/terraform.tfstate', force:true) 
                                }
                                bat 'dir'
                                bat "terraform destroy -var aws_region=us-west-2 -auto-approve"
                        }
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