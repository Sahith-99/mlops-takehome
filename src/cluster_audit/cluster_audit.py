#!/usr/bin/env python3
import json
import os
from datetime import datetime

from kubernetes import client, config

OUT_DIR = os.environ.get("OUT_DIR", "output")

def ensure_out():
    if not os.path.isdir(OUT_DIR):
        os.makedirs(OUT_DIR, exist_ok=True)

def k8s_connect():
    try:
        config.load_incluster_config()
    except Exception:
        config.load_kube_config()

def list_cluster_snapshot():
    v1 = client.CoreV1Api()
    nodes = v1.list_node().items
    pods  = v1.list_pod_for_all_namespaces().items
    events= v1.list_event_for_all_namespaces().items

    snapshot = {
        "generated_at": datetime.utcnow().isoformat() + "Z",
        "node_count": len(nodes),
        "pod_count": len(pods),
        "event_count": len(events),
        "nodes": [{
            "name": n.metadata.name,
            "labels": n.metadata.labels,
            "instance_type": n.metadata.labels.get("node.kubernetes.io/instance-type", ""),
            "capacity": n.status.capacity,
            "allocatable": n.status.allocatable,
            "conditions": [{ "type": c.type, "status": c.status } for c in (n.status.conditions or [])]
        } for n in nodes],
        "pods": [{
            "ns": p.metadata.namespace,
            "name": p.metadata.name,
            "node": p.spec.node_name,
            "phase": p.status.phase
        } for p in pods],
        "top_warnings": [{
            "ns": getattr(e.metadata, "namespace", ""),
            "reason": getattr(e, "reason", ""),
            "message": getattr(e, "message", "")[:300]
        } for e in events if getattr(e, "type", "") == "Warning"][:50]
    }
    return snapshot

def main():
    ensure_out()
    k8s_connect()
    snap = list_cluster_snapshot()
    ts = datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
    out_path = os.path.join(OUT_DIR, f"cluster_audit_{ts}.json")
    with open(out_path, "w") as f:
        json.dump(snap, f, indent=2)
    print(f"Wrote {out_path}")

if __name__ == "__main__":
    main()
