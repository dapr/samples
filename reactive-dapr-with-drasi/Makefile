SHELL := /bin/bash
CLUSTER_NAME := dapr-demo

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

.PHONY: help
help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# ==================== Cluster Management ====================

.PHONY: create-cluster
create-cluster: ## Create k3d cluster
	@echo -e "$(GREEN)Creating k3d cluster...$(NC)"
	k3d cluster create $(CLUSTER_NAME) \
		--api-port 6550 \
		--port "80:80@loadbalancer" \
		--port "443:443@loadbalancer" \
		--agents 0
	@echo -e "$(GREEN)Waiting for cluster to be ready...$(NC)"
	kubectl wait --for=condition=Ready nodes --all --timeout=60s
	@echo -e "$(GREEN)Cluster created successfully!$(NC)"

.PHONY: delete-cluster
delete-cluster: ## Delete k3d cluster
	@echo -e "$(RED)Deleting k3d cluster...$(NC)"
	k3d cluster delete $(CLUSTER_NAME)
	@echo -e "$(GREEN)Cluster deleted successfully!$(NC)"

# Dapr installation is handled automatically by Drasi
# Keeping uninstall-dapr for backwards compatibility and manual cleanup if needed
.PHONY: uninstall-dapr
uninstall-dapr: ## Uninstall Dapr from the cluster (Note: Drasi installs Dapr automatically)
	@echo -e "$(YELLOW)Note: Dapr is installed automatically by Drasi$(NC)"
	@echo -e "$(YELLOW)Checking if Dapr is installed...$(NC)"
	@if kubectl get namespace dapr-system >/dev/null 2>&1; then \
		echo -e "$(RED)Uninstalling Dapr...$(NC)"; \
		kubectl delete namespace dapr-system --wait=true || true; \
		echo -e "$(GREEN)Dapr uninstalled successfully!$(NC)"; \
	else \
		echo -e "$(YELLOW)Dapr is not installed$(NC)"; \
	fi

.PHONY: install-drasi
install-drasi: ## Install Drasi on the cluster (also installs Dapr automatically)
	@echo -e "$(GREEN)Configuring Drasi for Kubernetes...$(NC)"
	drasi env kube
	@echo -e "$(GREEN)Installing Drasi (this will also install Dapr automatically)...$(NC)"
	drasi init
	@echo -e "$(GREEN)Waiting for Dapr to be ready...$(NC)"
	kubectl wait --for=condition=Ready pods --all -n dapr-system --timeout=300s || true
	@echo -e "$(GREEN)Drasi and Dapr installed successfully!$(NC)"

.PHONY: uninstall-drasi
uninstall-drasi: ## Uninstall Drasi from the cluster
	@echo -e "$(RED)Uninstalling Drasi...$(NC)"
	drasi uninstall -y
	@echo -e "$(GREEN)Drasi uninstalled successfully!$(NC)"

# ==================== Service Build Commands ====================

.PHONY: build-customers
build-customers: ## Build customers service Docker image
	@echo -e "$(GREEN)Building customers service...$(NC)"
	cd services/customers && \
	docker build -t customers:latest .
	@echo -e "$(YELLOW)Importing image to k3d cluster...$(NC)"
	k3d image import customers:latest -c $(CLUSTER_NAME)
	@echo -e "$(GREEN)customers service built and imported!$(NC)"

.PHONY: build-orders
build-orders: ## Build orders service Docker image
	@echo -e "$(GREEN)Building orders service...$(NC)"
	cd services/orders && \
	docker build -t orders:latest .
	@echo -e "$(YELLOW)Importing image to k3d cluster...$(NC)"
	k3d image import orders:latest -c $(CLUSTER_NAME)
	@echo -e "$(GREEN)Orders service built and imported!$(NC)"

.PHONY: build-products
build-products: ## Build products service Docker image
	@echo -e "$(GREEN)Building products service...$(NC)"
	cd services/products && \
	docker build -t products:latest .
	@echo -e "$(YELLOW)Importing image to k3d cluster...$(NC)"
	k3d image import products:latest -c $(CLUSTER_NAME)
	@echo -e "$(GREEN)products service built and imported!$(NC)"

.PHONY: build-reviews
build-reviews: ## Build reviews service Docker image
	@echo -e "$(GREEN)Building reviews service...$(NC)"
	cd services/reviews && \
	docker build -t reviews:latest .
	@echo -e "$(YELLOW)Importing image to k3d cluster...$(NC)"
	k3d image import reviews:latest -c $(CLUSTER_NAME)
	@echo -e "$(GREEN)Reviews service built and imported!$(NC)"

.PHONY: build-dashboard
build-dashboard: ## Build dashboard service Docker image
	@echo -e "$(GREEN)Building dashboard service...$(NC)"
	cd services/dashboard && \
	docker build -t dashboard:latest .
	@echo -e "$(YELLOW)Importing image to k3d cluster...$(NC)"
	k3d image import dashboard:latest -c $(CLUSTER_NAME)
	@echo -e "$(GREEN)Dashboard service built and imported!$(NC)"

.PHONY: build-catalogue
build-catalogue: ## Build catalogue service Docker image
	@echo -e "$(GREEN)Building catalogue service...$(NC)"
	cd services/catalogue && \
	docker build -t catalogue:latest .
	@echo -e "$(YELLOW)Importing image to k3d cluster...$(NC)"
	k3d image import catalogue:latest -c $(CLUSTER_NAME)
	@echo -e "$(GREEN)Catalogue service built and imported!$(NC)"

.PHONY: build-notifications
build-notifications: ## Build notifications service Docker image
	@echo -e "$(GREEN)Building notifications service...$(NC)"
	cd services/notifications && \
	docker build -t notifications:latest .
	@echo -e "$(YELLOW)Importing image to k3d cluster...$(NC)"
	k3d image import notifications:latest -c $(CLUSTER_NAME)
	@echo -e "$(GREEN)Notifications service built and imported!$(NC)"

.PHONY: build-all
build-all: build-customers build-orders build-products build-reviews build-dashboard build-catalogue build-notifications ## Build all service Docker images

# ==================== Service Deployment Commands ====================

.PHONY: deploy-customers-infra
deploy-customers-infra: ## Deploy customers service infrastructure (PostgreSQL + Dapr components)
	@echo -e "$(GREEN)Deploying customers PostgreSQL...$(NC)"
	kubectl apply -f services/customers/k8s/postgres/postgres.yaml
	@echo -e "$(YELLOW)Waiting for customers-db to be ready...$(NC)"
	kubectl rollout status statefulset/customers-db --timeout=300s
	kubectl wait --for=condition=Ready pod -l app=customers-db --timeout=300s
	@echo -e "$(GREEN)Deploying customers Dapr components...$(NC)"
	kubectl apply -f services/customers/k8s/dapr/statestore.yaml
	@echo -e "$(GREEN)customers infrastructure deployed!$(NC)"

.PHONY: deploy-customers
deploy-customers: deploy-customers-infra ## Deploy customers service (infra + service)
	@echo -e "$(GREEN)Deploying customers service...$(NC)"
	kubectl apply -f services/customers/k8s/deployment.yaml
	kubectl rollout status deployment/customers --timeout=300s
	kubectl wait --for=condition=Ready pod -l app=customers --timeout=300s
	@echo -e "$(GREEN)customers service deployed successfully!$(NC)"

.PHONY: deploy-orders-infra
deploy-orders-infra: ## Deploy orders service infrastructure (PostgreSQL + Dapr components)
	@echo -e "$(GREEN)Deploying orders PostgreSQL...$(NC)"
	kubectl apply -f services/orders/k8s/postgres/postgres.yaml
	@echo -e "$(YELLOW)Waiting for orders-db to be ready...$(NC)"
	kubectl rollout status statefulset/orders-db --timeout=300s
	kubectl wait --for=condition=Ready pod -l app=orders-db --timeout=300s
	@echo -e "$(GREEN)Deploying orders Dapr components...$(NC)"
	kubectl apply -f services/orders/k8s/dapr/statestore.yaml
	@echo -e "$(GREEN)Orders infrastructure deployed!$(NC)"

.PHONY: deploy-orders
deploy-orders: deploy-orders-infra ## Deploy orders service (infra + service)
	@echo -e "$(GREEN)Deploying orders service...$(NC)"
	kubectl apply -f services/orders/k8s/deployment.yaml
	kubectl rollout status deployment/orders --timeout=300s
	kubectl wait --for=condition=Ready pod -l app=orders --timeout=300s
	@echo -e "$(GREEN)Orders service deployed successfully!$(NC)"

.PHONY: deploy-products-infra
deploy-products-infra: ## Deploy products service infrastructure (PostgreSQL + Dapr components)
	@echo -e "$(GREEN)Deploying products PostgreSQL...$(NC)"
	kubectl apply -f services/products/k8s/postgres/postgres.yaml
	@echo -e "$(YELLOW)Waiting for products-db to be ready...$(NC)"
	kubectl rollout status statefulset/products-db --timeout=300s
	kubectl wait --for=condition=Ready pod -l app=products-db --timeout=300s
	@echo -e "$(GREEN)Deploying products Dapr components...$(NC)"
	kubectl apply -f services/products/k8s/dapr/statestore.yaml
	@echo -e "$(GREEN)products infrastructure deployed!$(NC)"

.PHONY: deploy-products
deploy-products: deploy-products-infra ## Deploy products service (infra + service)
	@echo -e "$(GREEN)Deploying products service...$(NC)"
	kubectl apply -f services/products/k8s/deployment.yaml
	kubectl rollout status deployment/products --timeout=300s
	kubectl wait --for=condition=Ready pod -l app=products --timeout=300s
	@echo -e "$(GREEN)products service deployed successfully!$(NC)"

.PHONY: deploy-reviews-infra
deploy-reviews-infra: ## Deploy reviews service infrastructure (PostgreSQL + Dapr components)
	@echo -e "$(GREEN)Deploying reviews PostgreSQL...$(NC)"
	kubectl apply -f services/reviews/k8s/postgres/postgres.yaml
	@echo -e "$(YELLOW)Waiting for reviews-db to be ready...$(NC)"
	kubectl rollout status statefulset/reviews-db --timeout=300s
	kubectl wait --for=condition=Ready pod -l app=reviews-db --timeout=300s
	@echo -e "$(GREEN)Deploying reviews Dapr components...$(NC)"
	kubectl apply -f services/reviews/k8s/dapr/statestore.yaml
	@echo -e "$(GREEN)Reviews infrastructure deployed!$(NC)"

.PHONY: deploy-reviews
deploy-reviews: deploy-reviews-infra ## Deploy reviews service (infra + service)
	@echo -e "$(GREEN)Deploying reviews service...$(NC)"
	kubectl apply -f services/reviews/k8s/deployment.yaml
	kubectl rollout status deployment/reviews --timeout=300s
	kubectl wait --for=condition=Ready pod -l app=reviews --timeout=300s
	@echo -e "$(GREEN)Reviews service deployed successfully!$(NC)"

.PHONY: deploy-dashboard-infra
deploy-dashboard-infra: ## Deploy dashboard infrastructure (SignalR ingress)
	@echo -e "$(GREEN)Deploying SignalR ingress for dashboard...$(NC)"
	kubectl apply -f services/dashboard/k8s/signalr-ingress.yaml
	@echo -e "$(GREEN)Dashboard infrastructure deployed!$(NC)"

.PHONY: deploy-dashboard
deploy-dashboard: deploy-dashboard-infra ## Deploy dashboard service (infra + service)
	@echo -e "$(GREEN)Deploying dashboard service...$(NC)"
	kubectl apply -f services/dashboard/k8s/deployment.yaml
	kubectl rollout status deployment/dashboard --timeout=300s
	kubectl wait --for=condition=Ready pod -l app=dashboard --timeout=300s
	@echo -e "$(GREEN)Dashboard service deployed successfully!$(NC)"

.PHONY: deploy-catalogue-infra
deploy-catalogue-infra: ## Deploy catalogue service infrastructure (PostgreSQL + Dapr components)
	@echo -e "$(GREEN)Deploying catalogue PostgreSQL...$(NC)"
	kubectl apply -f services/catalogue/k8s/postgres/postgres.yaml
	@echo -e "$(YELLOW)Waiting for catalogue-db to be ready...$(NC)"
	kubectl rollout status statefulset/catalogue-db --timeout=300s
	kubectl wait --for=condition=Ready pod -l app=catalogue-db --timeout=300s
	@echo -e "$(GREEN)Deploying catalogue Dapr components...$(NC)"
	kubectl apply -f services/catalogue/k8s/dapr/statestore.yaml
	@echo -e "$(GREEN)Deploying catalogue Dapr component for Drasi (in drasi-system namespace)...$(NC)"
	kubectl apply -f services/catalogue/k8s/dapr/statestore-drasi.yaml
	@echo -e "$(GREEN)Catalogue infrastructure deployed!$(NC)"

.PHONY: deploy-catalogue
deploy-catalogue: deploy-catalogue-infra ## Deploy catalogue service (infra + service)
	@echo -e "$(GREEN)Deploying catalogue service...$(NC)"
	kubectl apply -f services/catalogue/k8s/deployment.yaml
	kubectl rollout status deployment/catalogue --timeout=300s
	kubectl wait --for=condition=Ready pod -l app=catalogue --timeout=300s
	@echo -e "$(GREEN)Catalogue service deployed successfully!$(NC)"

.PHONY: deploy-notifications-infra
deploy-notifications-infra: ## Deploy notifications service infrastructure (Redis + Dapr components)
	@echo -e "$(GREEN)Deploying notifications Redis...$(NC)"
	kubectl apply -f services/notifications/k8s/redis/redis.yaml
	@echo -e "$(YELLOW)Waiting for notifications-redis to be ready...$(NC)"
	kubectl rollout status statefulset/notifications-redis --timeout=300s
	kubectl wait --for=condition=Ready pod -l app=notifications-redis --timeout=300s
	@echo -e "$(GREEN)Deploying notifications Dapr pubsub components...$(NC)"
	kubectl apply -f services/notifications/k8s/dapr/pubsub.yaml
	@echo -e "$(GREEN)Deploying notifications Dapr pubsub component for Drasi (in drasi-system namespace)...$(NC)"
	kubectl apply -f services/notifications/k8s/dapr/pubsub-drasi.yaml
	@echo -e "$(GREEN)Notifications infrastructure deployed!$(NC)"

.PHONY: deploy-notifications
deploy-notifications: deploy-notifications-infra ## Deploy notifications service (infra + service)
	@echo -e "$(GREEN)Deploying notifications service...$(NC)"
	kubectl apply -f services/notifications/k8s/deployment.yaml
	kubectl rollout status deployment/notifications --timeout=300s
	kubectl wait --for=condition=Ready pod -l app=notifications --timeout=300s
	@echo -e "$(GREEN)Notifications service deployed successfully!$(NC)"

.PHONY: deploy-all
deploy-all: deploy-customers deploy-orders deploy-products deploy-reviews deploy-dashboard deploy-catalogue deploy-notifications ## Deploy all services with infrastructure

# ==================== Service Redeploy Commands ====================

.PHONY: redeploy-customers
redeploy-customers: ## Redeploy customers service (service only, not infra)
	@echo -e "$(YELLOW)Redeploying customers service...$(NC)"
	kubectl delete -f services/customers/k8s/deployment.yaml --ignore-not-found=true
	kubectl apply -f services/customers/k8s/deployment.yaml
	kubectl rollout status deployment/customers --timeout=300s
	kubectl wait --for=condition=Ready pod -l app=customers --timeout=300s
	@echo -e "$(GREEN)customers service redeployed!$(NC)"

.PHONY: redeploy-orders
redeploy-orders: ## Redeploy orders service (service only, not infra)
	@echo -e "$(YELLOW)Redeploying orders service...$(NC)"
	kubectl delete -f services/orders/k8s/deployment.yaml --ignore-not-found=true
	kubectl apply -f services/orders/k8s/deployment.yaml
	kubectl rollout status deployment/orders --timeout=300s
	kubectl wait --for=condition=Ready pod -l app=orders --timeout=300s
	@echo -e "$(GREEN)Orders service redeployed!$(NC)"

.PHONY: redeploy-products
redeploy-products: ## Redeploy products service (service only, not infra)
	@echo -e "$(YELLOW)Redeploying products service...$(NC)"
	kubectl delete -f services/products/k8s/deployment.yaml --ignore-not-found=true
	kubectl apply -f services/products/k8s/deployment.yaml
	kubectl rollout status deployment/products --timeout=300s
	kubectl wait --for=condition=Ready pod -l app=products --timeout=300s
	@echo -e "$(GREEN)products service redeployed!$(NC)"

.PHONY: redeploy-reviews
redeploy-reviews: ## Redeploy reviews service (service only, not infra)
	@echo -e "$(YELLOW)Redeploying reviews service...$(NC)"
	kubectl delete -f services/reviews/k8s/deployment.yaml --ignore-not-found=true
	kubectl apply -f services/reviews/k8s/deployment.yaml
	kubectl rollout status deployment/reviews --timeout=300s
	kubectl wait --for=condition=Ready pod -l app=reviews --timeout=300s
	@echo -e "$(GREEN)Reviews service redeployed!$(NC)"

.PHONY: redeploy-dashboard
redeploy-dashboard: ## Redeploy dashboard service
	@echo -e "$(YELLOW)Redeploying dashboard service...$(NC)"
	kubectl delete -f services/dashboard/k8s/deployment.yaml --ignore-not-found=true
	kubectl apply -f services/dashboard/k8s/deployment.yaml
	kubectl rollout status deployment/dashboard --timeout=300s
	kubectl wait --for=condition=Ready pod -l app=dashboard --timeout=300s
	@echo -e "$(GREEN)Dashboard service redeployed!$(NC)"

.PHONY: redeploy-catalogue
redeploy-catalogue: ## Redeploy catalogue service (service only, not infra)
	@echo -e "$(YELLOW)Redeploying catalogue service...$(NC)"
	kubectl delete -f services/catalogue/k8s/deployment.yaml --ignore-not-found=true
	kubectl apply -f services/catalogue/k8s/deployment.yaml
	kubectl rollout status deployment/catalogue --timeout=300s
	kubectl wait --for=condition=Ready pod -l app=catalogue --timeout=300s
	@echo -e "$(GREEN)Catalogue service redeployed!$(NC)"

.PHONY: redeploy-notifications
redeploy-notifications: ## Redeploy notifications service (service only, not infra)
	@echo -e "$(YELLOW)Redeploying notifications service...$(NC)"
	kubectl delete -f services/notifications/k8s/deployment.yaml --ignore-not-found=true
	kubectl apply -f services/notifications/k8s/deployment.yaml
	kubectl rollout status deployment/notifications --timeout=300s
	kubectl wait --for=condition=Ready pod -l app=notifications --timeout=300s
	@echo -e "$(GREEN)Notifications service redeployed!$(NC)"

.PHONY: redeploy-all
redeploy-all: redeploy-customers redeploy-orders redeploy-products redeploy-reviews redeploy-dashboard redeploy-catalogue redeploy-notifications ## Redeploy all services (services only, not infra)

# ==================== Service Clean Commands ====================

.PHONY: clean-customers
clean-customers: ## Clean customers service and infrastructure (keeps data)
	@echo -e "$(RED)Cleaning customers service...$(NC)"
	-kubectl delete -f services/customers/k8s/deployment.yaml --ignore-not-found=true
	-kubectl delete -f services/customers/k8s/dapr/statestore.yaml --ignore-not-found=true
	-kubectl delete -f services/customers/k8s/postgres/postgres.yaml --ignore-not-found=true
	@echo -e "$(GREEN)customers service cleaned!$(NC)"

.PHONY: clean-orders
clean-orders: ## Clean orders service and infrastructure (keeps data)
	@echo -e "$(RED)Cleaning orders service...$(NC)"
	-kubectl delete -f services/orders/k8s/deployment.yaml --ignore-not-found=true
	-kubectl delete -f services/orders/k8s/dapr/statestore.yaml --ignore-not-found=true
	-kubectl delete -f services/orders/k8s/postgres/postgres.yaml --ignore-not-found=true
	@echo -e "$(GREEN)Orders service cleaned!$(NC)"

.PHONY: clean-products
clean-products: ## Clean products service and infrastructure (keeps data)
	@echo -e "$(RED)Cleaning products service...$(NC)"
	-kubectl delete -f services/products/k8s/deployment.yaml --ignore-not-found=true
	-kubectl delete -f services/products/k8s/dapr/statestore.yaml --ignore-not-found=true
	-kubectl delete -f services/products/k8s/postgres/postgres.yaml --ignore-not-found=true
	@echo -e "$(GREEN)products service cleaned!$(NC)"

.PHONY: clean-reviews
clean-reviews: ## Clean reviews service and infrastructure (keeps data)
	@echo -e "$(RED)Cleaning reviews service...$(NC)"
	-kubectl delete -f services/reviews/k8s/deployment.yaml --ignore-not-found=true
	-kubectl delete -f services/reviews/k8s/dapr/statestore.yaml --ignore-not-found=true
	-kubectl delete -f services/reviews/k8s/postgres/postgres.yaml --ignore-not-found=true
	@echo -e "$(GREEN)Reviews service cleaned!$(NC)"

.PHONY: clean-dashboard
clean-dashboard: ## Clean dashboard service and infrastructure
	@echo -e "$(RED)Cleaning dashboard service...$(NC)"
	-kubectl delete -f services/dashboard/k8s/deployment.yaml --ignore-not-found=true
	-kubectl delete -f services/dashboard/k8s/signalr-ingress.yaml --ignore-not-found=true
	@echo -e "$(GREEN)Dashboard service cleaned!$(NC)"

.PHONY: clean-catalogue
clean-catalogue: ## Clean catalogue service and infrastructure (keeps data)
	@echo -e "$(RED)Cleaning catalogue service...$(NC)"
	-kubectl delete -f services/catalogue/k8s/deployment.yaml --ignore-not-found=true
	-kubectl delete -f services/catalogue/k8s/dapr/statestore.yaml --ignore-not-found=true
	-kubectl delete -f services/catalogue/k8s/dapr/statestore-drasi.yaml --ignore-not-found=true
	-kubectl delete -f services/catalogue/k8s/postgres/postgres.yaml --ignore-not-found=true
	@echo -e "$(GREEN)Catalogue service cleaned!$(NC)"

.PHONY: clean-notifications
clean-notifications: ## Clean notifications service and infrastructure (keeps data)
	@echo -e "$(RED)Cleaning notifications service...$(NC)"
	-kubectl delete -f services/notifications/k8s/deployment.yaml --ignore-not-found=true
	-kubectl delete -f services/notifications/k8s/dapr/pubsub.yaml --ignore-not-found=true
	-kubectl delete -f services/notifications/k8s/dapr/pubsub-drasi.yaml --ignore-not-found=true
	-kubectl delete -f services/notifications/k8s/redis/redis.yaml --ignore-not-found=true
	@echo -e "$(GREEN)Notifications service cleaned!$(NC)"

.PHONY: clean-all
clean-all: clean-customers clean-orders clean-products clean-reviews clean-dashboard clean-catalogue clean-notifications ## Clean all services and infrastructure

# ==================== Deep Clean Commands (removes persistent data) ====================

.PHONY: deep-clean-customers
deep-clean-customers: clean-customers ## Deep clean customers service (removes all data)
	@echo -e "$(RED)Deep cleaning customers service data...$(NC)"
	-kubectl delete pvc customers-db-data-customers-db-0 --ignore-not-found=true
	@echo -e "$(GREEN)customers service deep cleaned!$(NC)"

.PHONY: deep-clean-orders
deep-clean-orders: clean-orders ## Deep clean orders service (removes all data)
	@echo -e "$(RED)Deep cleaning orders service data...$(NC)"
	-kubectl delete pvc orders-db-data-orders-db-0 --ignore-not-found=true
	@echo -e "$(GREEN)Orders service deep cleaned!$(NC)"

.PHONY: deep-clean-products
deep-clean-products: clean-products ## Deep clean products service (removes all data)
	@echo -e "$(RED)Deep cleaning products service data...$(NC)"
	-kubectl delete pvc products-db-data-products-db-0 --ignore-not-found=true
	@echo -e "$(GREEN)products service deep cleaned!$(NC)"

.PHONY: deep-clean-reviews
deep-clean-reviews: clean-reviews ## Deep clean reviews service (removes all data)
	@echo -e "$(RED)Deep cleaning reviews service data...$(NC)"
	-kubectl delete pvc reviews-db-data-reviews-db-0 --ignore-not-found=true
	@echo -e "$(GREEN)Reviews service deep cleaned!$(NC)"

.PHONY: deep-clean-catalogue
deep-clean-catalogue: clean-catalogue ## Deep clean catalogue service (removes all data)
	@echo -e "$(RED)Deep cleaning catalogue service data...$(NC)"
	-kubectl delete pvc catalogue-db-data-catalogue-db-0 --ignore-not-found=true
	@echo -e "$(GREEN)Catalogue service deep cleaned!$(NC)"

.PHONY: deep-clean-notifications
deep-clean-notifications: clean-notifications ## Deep clean notifications service (removes all data)
	@echo -e "$(RED)Deep cleaning notifications service data...$(NC)"
	-kubectl delete pvc redis-data-notifications-redis-0 --ignore-not-found=true
	@echo -e "$(GREEN)Notifications service deep cleaned!$(NC)"

.PHONY: deep-clean-dashboard
deep-clean-dashboard: clean-dashboard ## Deep clean dashboard service (no persistent data)
	@echo -e "$(YELLOW)Dashboard has no persistent data to deep clean$(NC)"
	@echo -e "$(GREEN)Dashboard service deep cleaned!$(NC)"

.PHONY: deep-clean-all
deep-clean-all: deep-clean-customers deep-clean-orders deep-clean-products deep-clean-reviews deep-clean-dashboard deep-clean-catalogue deep-clean-notifications ## Deep clean all services (removes all data)

# ==================== Utility Commands ====================

.PHONY: setup
setup: create-cluster install-drasi ## Complete setup: create cluster and install Drasi (includes Dapr)

.PHONY: teardown
teardown: deep-clean-all uninstall-drasi uninstall-dapr delete-cluster ## Complete teardown: remove everything

.PHONY: status
status: ## Show status of all services and databases
	@echo -e "$(GREEN)=== Cluster Nodes ===$(NC)"
	kubectl get nodes
	@echo -e "\n$(GREEN)=== Dapr Status ===$(NC)"
	kubectl get pods -n dapr-system 2>/dev/null || echo "Dapr not installed"
	@echo -e "\n$(GREEN)=== Drasi Status ===$(NC)"
	kubectl get pods -n drasi-system 2>/dev/null || echo "Drasi not installed"
	@echo -e "\n$(GREEN)=== PostgreSQL Databases ===$(NC)"
	kubectl get statefulsets | grep -E "(customers|orders|products|reviews|catalogue)-db" || echo "No databases found"
	@echo -e "\n$(GREEN)=== Redis Instances ===$(NC)"
	kubectl get statefulsets | grep -E "notifications-redis" || echo "No Redis instances found"
	@echo -e "\n$(GREEN)=== Services ===$(NC)"
	kubectl get pods | grep -E "^(customers|orders|products|reviews|catalogue|dashboard|notifications)-" || echo "No services found"
	@echo -e "\n$(GREEN)=== Persistent Volumes ===$(NC)"
	kubectl get pvc | grep -E "(customers|orders|products|reviews|catalogue)-db-data|redis-data-notifications" || echo "No PVCs found"

.PHONY: logs-customers
logs-customers: ## Show logs for customers service
	kubectl logs -l app=customers -f

.PHONY: logs-orders
logs-orders: ## Show logs for orders service
	kubectl logs -l app=orders -f

.PHONY: logs-products
logs-products: ## Show logs for products service
	kubectl logs -l app=products -f

.PHONY: logs-reviews
logs-reviews: ## Show logs for reviews service
	kubectl logs -l app=reviews -f

.PHONY: logs-dashboard
logs-dashboard: ## Show logs for dashboard service
	kubectl logs -l app=dashboard -f

.PHONY: logs-catalogue
logs-catalogue: ## Show logs for catalogue service
	kubectl logs -l app=catalogue -f

.PHONY: logs-notifications
logs-notifications: ## Show logs for notifications service
	kubectl logs -l app=notifications -f

.PHONY: show-urls
show-urls: ## Show service URLs (services are accessible directly via k3d)
	@echo -e "$(GREEN)Services are accessible at:$(NC)"
	@echo -e "$(YELLOW)User Interfaces:$(NC)"
	@echo -e "  Dashboard:     http://localhost/dashboard"
	@echo -e "  Catalogue:     http://localhost/catalogue-service"
	@echo -e "  Notifications: http://localhost/notifications-service"
	@echo -e ""
	@echo -e "$(YELLOW)Service APIs:$(NC)"
	@echo -e "  Products:  http://localhost/products-service/products"
	@echo -e "  Customers: http://localhost/customers-service/customers"
	@echo -e "  Orders:    http://localhost/orders-service/orders"
	@echo -e "  Reviews:   http://localhost/reviews-service/reviews"
	@echo -e ""
	@echo -e "$(GREEN)Note: k3d automatically exposes port 80, no port-forwarding needed!$(NC)"

# ==================== Quick Start Commands ====================

.PHONY: quickstart
quickstart: setup build-all deploy-all ## Complete quickstart: setup, build, and deploy everything
	@echo -e "$(GREEN)=====================================$(NC)"
	@echo -e "$(GREEN)Dapr microservices deployed!$(NC)"
	@echo -e "$(GREEN)=====================================$(NC)"
	@echo -e "Run 'make status' to check the deployment"
	@echo -e "Run 'make show-urls' to see service URLs"
	@echo -e ""
	@echo -e "$(YELLOW)Next steps:$(NC)"
	@echo -e "1. Wait for pods: kubectl wait --for=condition=Ready pod --all --timeout=300s"
	@echo -e "2. Load test data: make load-all-data"
	@echo -e "3. Deploy Drasi components: kubectl apply -f drasi/"

.PHONY: rebuild-redeploy-customers
rebuild-redeploy-customers: build-customers redeploy-customers ## Rebuild and redeploy customers service

.PHONY: rebuild-redeploy-orders
rebuild-redeploy-orders: build-orders redeploy-orders ## Rebuild and redeploy orders service

.PHONY: rebuild-redeploy-products
rebuild-redeploy-products: build-products redeploy-products ## Rebuild and redeploy products service

.PHONY: rebuild-redeploy-reviews
rebuild-redeploy-reviews: build-reviews redeploy-reviews ## Rebuild and redeploy reviews service

.PHONY: rebuild-redeploy-dashboard
rebuild-redeploy-dashboard: build-dashboard redeploy-dashboard ## Rebuild and redeploy dashboard service

.PHONY: rebuild-redeploy-catalogue
rebuild-redeploy-catalogue: build-catalogue redeploy-catalogue ## Rebuild and redeploy catalogue service

.PHONY: rebuild-redeploy-notifications
rebuild-redeploy-notifications: build-notifications redeploy-notifications ## Rebuild and redeploy notifications service

.PHONY: rebuild-redeploy-all
rebuild-redeploy-all: rebuild-redeploy-customers rebuild-redeploy-orders rebuild-redeploy-products rebuild-redeploy-reviews rebuild-redeploy-dashboard rebuild-redeploy-catalogue rebuild-redeploy-notifications ## Rebuild and redeploy all services

# ==================== Service setup Commands ====================

.PHONY: load-customers-data
load-customers-data: ## Load initial customers data
	@echo -e "$(GREEN)Loading initial customers data...$(NC)"
	@cd services/customers/setup && ./load-initial-data.sh

.PHONY: test-customers-apis
test-customers-apis: ## Run basic tests on customers APIs
	@echo -e "$(GREEN)Running customers API tests...$(NC)"
	@cd services/customers/setup && ./test-apis.sh

.PHONY: load-products-data
load-products-data: ## Load initial products data
	@echo -e "$(GREEN)Loading initial products data...$(NC)"
	@cd services/products/setup && ./load-initial-data.sh

.PHONY: test-products-apis
test-products-apis: ## Run basic tests on products APIs
	@echo -e "$(GREEN)Running products API tests...$(NC)"
	@cd services/products/setup && ./test-apis.sh

.PHONY: load-reviews-data
load-reviews-data: ## Load initial review data
	@echo -e "$(GREEN)Loading initial review data...$(NC)"
	@cd services/reviews/setup && ./load-initial-data.sh

.PHONY: test-reviews-apis
test-reviews-apis: ## Run basic tests on reviews APIs
	@echo -e "$(GREEN)Running reviews API tests...$(NC)"
	@cd services/reviews/setup && ./test-apis.sh

.PHONY: load-orders-data
load-orders-data: ## Load initial order data
	@echo -e "$(GREEN)Loading initial order data...$(NC)"
	@cd services/orders/setup && ./load-initial-data.sh

.PHONY: test-orders-apis
test-orders-apis: ## Run basic tests on orders APIs
	@echo -e "$(GREEN)Running orders API tests...$(NC)"
	@cd services/orders/setup && ./test-apis.sh

.PHONY: test-catalogue-apis
test-catalogue-apis: ## Run basic tests on catalogue APIs
	@echo -e "$(GREEN)Running catalogue API tests...$(NC)"
	@cd services/catalogue/setup && ./test-apis.sh

.PHONY: test-notifications-apis
test-notifications-apis: ## Run basic tests on notifications APIs
	@echo -e "$(GREEN)Running notifications API tests...$(NC)"
	@cd services/notifications/setup && ./test-apis.sh

.PHONY: load-all-data
load-all-data: load-customers-data load-products-data load-reviews-data load-orders-data ## Load initial data for all services

.PHONY: test-all-apis
test-all-apis: test-customers-apis test-products-apis test-reviews-apis test-orders-apis test-catalogue-apis test-notifications-apis ## Run basic tests on all service APIs