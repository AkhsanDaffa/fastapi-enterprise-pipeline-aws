from fastapi import FastAPI

app = FastAPI(title="Enterprise API Backend", version="1.0.0")

@app.get("/")
def read_root():
    return {"status": "success", "message": "Welcome to Enterprise API"}

@app.get("/health")
def health_check():
    # Di dunia nyata, di sini kita cek koneksi database/redis
    return {"status": "healthy", "code": 200}