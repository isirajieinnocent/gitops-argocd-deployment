import requests

def test_health_check():
    response = requests.get("http://localhost:8080/healthz")  # replace with service endpoint if needed
    assert response.status_code == 200
