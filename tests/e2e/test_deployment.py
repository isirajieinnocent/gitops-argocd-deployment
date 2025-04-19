from kubernetes import client, config

def test_app_running():
    config.load_kube_config()
    v1 = client.CoreV1Api()
    pods = v1.list_namespaced_pod(namespace="default", label_selector="app=time-printer")
    assert any(pod.status.phase == "Running" for pod in pods.items)
