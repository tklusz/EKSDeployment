resource "kubernetes_namespace" "user-1-namespace" {
  metadata {
    name = "user-1"
  }
}
