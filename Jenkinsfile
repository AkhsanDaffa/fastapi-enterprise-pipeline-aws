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
                // Menggunakan Docker Build sementara untuk menghindari isu Volume Mount DinD
                sh '''
                # 1. Buat Dockerfile khusus untuk testing secara otomatis (On-the-fly)
                cat <<EOF > Dockerfile.test
                FROM python:3.11-slim
                WORKDIR /app
                COPY requirements.txt .
                RUN pip install --no-cache-dir -r requirements.txt
                COPY . .
                CMD ["pytest", "test_main.py"]
EOF
                
                # 2. Build image khusus testing
                docker build -t test-runner:${BUILD_NUMBER} -f Dockerfile.test .
                
                # 3. Jalankan test-nya! (Jika pytest gagal, proses build Jenkins akan otomatis merah/berhenti)
                docker run --rm test-runner:${BUILD_NUMBER}
                
                # 4. Bersihkan sampah image agar memory Raspberry Pi tetap lega
                docker rmi test-runner:${BUILD_NUMBER}
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
                    # Menggunakan image Alpine yang dijamin kompatibel dengan arsitektur ARM Raspberry Pi
                    docker run --rm -e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} python:3.11-alpine sh -c "pip install --quiet awscli && aws ecr get-login-password --region ${AWS_REGION}" | docker login --username AWS --password-stdin ${ECR_URL}
                                        
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