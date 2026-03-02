pipeline {
    agent any

    // Variabel lingkungan agar kode lebih rapi
    environment {
        AWS_REGION = 'ap-southeast-1'
        ECR_URL    = '630777583477.dkr.ecr.ap-southeast-1.amazonaws.com'
        REPO_NAME  = 'enterprise-fastapi-backend'
        IMAGE_TAG  = "${BUILD_NUMBER}" // Menggunakan nomor build Jenkins sebagai tag (misal: v1, v2)
    }

    stages {
        // TAHAP 1: Ambil kode terbaru dari GitHub
        stage('Checkout Code') {
            steps {
                echo "Mengambil kode terbaru dari GitHub..."
                checkout scm
            }
        }

        // TAHAP 2: Jalankan Unit Test
        stage('Unit Test (Pytest)') {
            steps {
                echo "Menjalankan pengecekan Unit Test..."
                // Menggunakan docker python sementara agar OS Jenkins tetap bersih
                sh '''
                docker run --rm -v ${WORKSPACE}:/app -w /app python:3.11-slim bash -c "pip install -r requirements.txt && pytest test_main.py"
                '''
            }
        }

        // TAHAP 3: Build Docker Image
        stage('Build Docker Image') {
            steps {
                echo "Membungkus aplikasi FastAPI menjadi Docker Image..."
                // Build dengan 2 tag: spesifik (nomor build) dan 'latest'
                sh "docker build -t ${ECR_URL}/${REPO_NAME}:latest -t ${ECR_URL}/${REPO_NAME}:${IMAGE_TAG} ."
            }
        }

        // TAHAP 4: Push ke Brankas AWS (ECR)
        stage('Push to AWS ECR') {
            steps {
                echo "Mengirim Image ke AWS ECR..."
                // Memanggil kunci AWS yang sudah Anda simpan di Jenkins
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding', 
                    credentialsId: 'aws-credentials', 
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID', 
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh '''
                    # Login ke ECR dengan aman menggunakan AWS CLI versi Docker (tanpa install apapun di Jenkins)
                    docker run --rm -e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} amazon/aws-cli ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_URL}
                    
                    # Push image ke ECR
                    docker push ${ECR_URL}/${REPO_NAME}:${IMAGE_TAG}
                    docker push ${ECR_URL}/${REPO_NAME}:latest
                    '''
                }
            }
        }
    }
    
    // TAHAP AKHIR: Membersihkan sisa-sisa file setelah selesai
    post {
        always {
            echo "Membersihkan workspace Jenkins..."
            cleanWs()
        }
    }
}